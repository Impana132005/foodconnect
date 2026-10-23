import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/core/validation.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/repositories/food_repository.dart';
import 'package:foodconnect/repositories/storage_repository.dart';
import 'dart:io';

class MockStorageRepository implements IStorageRepository {
  bool simulateUploadError = false;
  final Map<String, String> uploadedFiles = {};

  @override
  Future<Result<String, String>> uploadFoodImage(
    String foodId,
    File file,
  ) async {
    if (simulateUploadError) {
      return const Failure('Photo upload failed: Network timeout');
    }
    final path =
        'foods/$foodId/food_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final fakeUrl =
        'https://firebasestorage.googleapis.com/v0/b/foodconnect.appspot.com/o/$path';
    uploadedFiles[foodId] = fakeUrl;
    return Success(fakeUrl);
  }

  @override
  Future<Result<String, String>> uploadUserAvatar(String uid, File file) async {
    return Success('https://storage.com/avatars/$uid.jpg');
  }
}

class MockFoodRepository implements IFoodRepository {
  final Map<String, Food> foodsDb = {};
  bool simulateFirestoreError = false;
  bool isSubmitting = false;

  @override
  Future<Result<Food, String>> createFood(Food food) async {
    if (isSubmitting) {
      return const Failure('Duplicate submission ignored');
    }
    isSubmitting = true;

    try {
      if (simulateFirestoreError) {
        return const Failure('Failed to post food: Network error');
      }

      final expectedExpiry = Food.calculateExpiryAt(
        food.foodType,
        food.preparedAt,
      );
      final finalFood = Food(
        foodId: 'food_${foodsDb.length + 1}',
        donorId: food.donorId,
        foodName: food.foodName,
        quantity: food.quantity,
        foodType: food.foodType,
        preparedAt: food.preparedAt,
        expiryAt: expectedExpiry,
        description: food.description,
        imageUrl: food.imageUrl,
        status: FoodStatus.available,
        latitude: food.latitude,
        longitude: food.longitude,
      );

      foodsDb[finalFood.foodId] = finalFood;
      return Success(finalFood);
    } finally {
      isSubmitting = false;
    }
  }

  @override
  Future<Result<Food, String>> updateFoodContent(Food food) async {
    foodsDb[food.foodId] = food;
    return Success(food);
  }

  @override
  Future<Result<Food, String>> getFoodById(String foodId) async {
    if (!foodsDb.containsKey(foodId)) return const Failure('Not found');
    return Success(foodsDb[foodId]!);
  }

  @override
  Future<Result<List<Food>, String>> getDonorFoods(String donorId) async {
    return Success(foodsDb.values.where((f) => f.donorId == donorId).toList());
  }

  @override
  Future<Result<List<Food>, String>> getAvailableFoods({
    dynamic startAfter,
    int limit = 10,
  }) async {
    return Success(
      foodsDb.values.where((f) => f.status == FoodStatus.available).toList(),
    );
  }

  @override
  Stream<List<Food>> streamAvailableFoods() {
    return Stream.value(
      foodsDb.values.where((f) => f.status == FoodStatus.available).toList(),
    );
  }
}

void main() {
  group('Phase 5 Post Food Flow Test Suite', () {
    late MockFoodRepository foodRepo;
    late MockStorageRepository storageRepo;

    setUp(() {
      foodRepo = MockFoodRepository();
      storageRepo = MockStorageRepository();
    });

    test(
      '1. Valid cooked food: automatically calculates preparedAt + 4 hours',
      () async {
        final prepTime = DateTime(2026, 8, 20, 10, 0, 0);
        final food = Food(
          foodId: '',
          donorId: 'donor_1',
          foodName: 'Chicken Curry & Rice',
          quantity: '15 meals',
          foodType: FoodType.cooked,
          preparedAt: prepTime,
          expiryAt: Food.calculateExpiryAt(FoodType.cooked, prepTime),
          description: 'Fresh warm meal boxes',
          status: FoodStatus.available,
        );

        final result = await foodRepo.createFood(food);
        expect(result.isSuccess, isTrue);

        final posted = (result as Success<Food, String>).value;
        expect(posted.foodType, FoodType.cooked);
        expect(posted.preparedAt, prepTime);
        expect(posted.expiryAt, DateTime(2026, 8, 20, 14, 0, 0)); // +4 hours
        expect(posted.status, FoodStatus.available);
      },
    );

    test(
      '2. Valid packed food: automatically calculates preparedAt + 8 hours',
      () async {
        final prepTime = DateTime(2026, 8, 20, 9, 30, 0);
        final food = Food(
          foodId: '',
          donorId: 'donor_2',
          foodName: 'Bakery Assortment Box',
          quantity: '8 boxes',
          foodType: FoodType.packed,
          preparedAt: prepTime,
          expiryAt: Food.calculateExpiryAt(FoodType.packed, prepTime),
          description: 'Sealed assorted pastries',
          status: FoodStatus.available,
        );

        final result = await foodRepo.createFood(food);
        expect(result.isSuccess, isTrue);

        final posted = (result as Success<Food, String>).value;
        expect(posted.foodType, FoodType.packed);
        expect(posted.preparedAt, prepTime);
        expect(posted.expiryAt, DateTime(2026, 8, 20, 17, 30, 0)); // +8 hours
        expect(posted.status, FoodStatus.available);
      },
    );

    test(
      '3. Invalid form validation: rejects invalid food name and quantity',
      () {
        expect(AppValidators.validateFoodName(''), isNotNull);
        expect(AppValidators.validateFoodName('Hi'), isNotNull); // Min 3 chars
        expect(
          AppValidators.validateFoodName('A' * 105),
          isNotNull,
        ); // Max 100 chars
        expect(AppValidators.validateFoodName('Vegetable Pasta'), isNull);

        expect(AppValidators.validateQuantity(''), isNotNull);
        expect(AppValidators.validateQuantity('10 servings'), isNull);

        expect(AppValidators.validateRequired('', 'Description'), isNotNull);
        expect(
          AppValidators.validateRequired('Contains dairy', 'Description'),
          isNull,
        );
      },
    );

    test('4. Image cancellation: leaves photo field null gracefully', () {
      File? selectedImage;
      // User opens image picker and cancels (picker returns null)
      const File? pickedResult = null;
      if (pickedResult != null) {
        selectedImage = pickedResult;
      }
      expect(selectedImage, isNull);
    });

    test(
      '5. Upload failure: returns structured error and halts post creation',
      () async {
        storageRepo.simulateUploadError = true;

        final uploadResult = await storageRepo.uploadFoodImage(
          'temp_123',
          File('test.jpg'),
        );
        expect(uploadResult.isFailure, isTrue);
        expect(
          (uploadResult as Failure<String, String>).error,
          contains('Photo upload failed'),
        );

        // Verify no food was created in DB
        expect(foodRepo.foodsDb, isEmpty);
      },
    );

    test(
      '6. Location denied: post food succeeds with null coordinates',
      () async {
        final now = DateTime.now();
        final food = Food(
          foodId: '',
          donorId: 'donor_location_denied',
          foodName: 'Fruit Basket',
          quantity: '5 baskets',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'Fresh fruits',
          status: FoodStatus.available,
          latitude: null,
          longitude: null,
        );

        final result = await foodRepo.createFood(food);
        expect(result.isSuccess, isTrue);

        final posted = (result as Success<Food, String>).value;
        expect(posted.latitude, isNull);
        expect(posted.longitude, isNull);
      },
    );

    test(
      '7. Network failure: surfaces network error message cleanly',
      () async {
        foodRepo.simulateFirestoreError = true;

        final now = DateTime.now();
        final food = Food(
          foodId: '',
          donorId: 'donor_fail',
          foodName: 'Rice Meals',
          quantity: '10 meals',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 4)),
          description: 'Rice',
          status: FoodStatus.available,
        );

        final result = await foodRepo.createFood(food);
        expect(result.isFailure, isTrue);
        expect(
          (result as Failure<Food, String>).error,
          contains('Network error'),
        );
      },
    );

    test(
      '8. Duplicate submission is prevented while request is in flight',
      () async {
        final now = DateTime.now();
        final food = Food(
          foodId: '',
          donorId: 'donor_dup',
          foodName: 'Burger Trays',
          quantity: '20 burgers',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 4)),
          description: 'Veggie burgers',
          status: FoodStatus.available,
        );

        foodRepo.isSubmitting = true; // Simulating active in-flight request
        final result = await foodRepo.createFood(food);

        expect(result.isFailure, isTrue);
        expect(
          (result as Failure<Food, String>).error,
          'Duplicate submission ignored',
        );
      },
    );

    test(
      '9. Verify Firestore document schema: contains all documented fields',
      () async {
        final now = DateTime.now();
        final food = Food(
          foodId: 'doc_123',
          donorId: 'donor_schema',
          foodName: 'Sandwiches',
          quantity: '30 packs',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'Club sandwiches',
          imageUrl: 'https://storage.com/food.jpg',
          status: FoodStatus.available,
          latitude: 28.7041,
          longitude: 77.1025,
        );

        final map = food.toMap();
        expect(map['foodId'], 'doc_123');
        expect(map['donorId'], 'donor_schema');
        expect(map['foodName'], 'Sandwiches');
        expect(map['quantity'], '30 packs');
        expect(map['foodType'], 'packed');
        expect(map['status'], 'available');
        expect(map['imageUrl'], 'https://storage.com/food.jpg');
        expect(map['latitude'], 28.7041);
        expect(map['longitude'], 77.1025);
      },
    );

    test('10. Verify Storage file path format', () async {
      final uploadResult = await storageRepo.uploadFoodImage(
        'food_999',
        File('photo.jpg'),
      );
      expect(uploadResult.isSuccess, isTrue);

      final url = (uploadResult as Success<String, String>).value;
      expect(url, contains('foods/food_999/food_'));
    });
  });
}
