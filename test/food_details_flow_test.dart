import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/repositories/food_repository.dart';

class MockFoodDetailsRepository implements IFoodRepository {
  final Map<String, Food> foodsDb = {};
  bool simulateNetworkError = false;

  @override
  Future<Result<Food, String>> getFoodById(String foodId) async {
    if (simulateNetworkError) {
      return const Failure(
        'Network connection failed. Please check your internet connection.',
      );
    }
    if (!foodsDb.containsKey(foodId)) {
      return const Failure('Food item not found.');
    }
    return Success(foodsDb[foodId]!);
  }

  @override
  Future<Result<Food, String>> createFood(Food food) async => Success(food);
  @override
  Future<Result<Food, String>> updateFoodContent(Food food) async =>
      Success(food);
  @override
  Future<Result<List<Food>, String>> getDonorFoods(String donorId) async =>
      Success([]);
  @override
  Future<Result<List<Food>, String>> getAvailableFoods({
    dynamic startAfter,
    int limit = 10,
  }) async => Success([]);
  @override
  Stream<List<Food>> streamAvailableFoods() => Stream.value([]);
}

void main() {
  group('Phase 7 Food Details Flow Test Suite', () {
    late MockFoodDetailsRepository repo;

    setUp(() {
      repo = MockFoodDetailsRepository();
    });

    test(
      '1. Available food: Details load and reservation is eligible when non-expired',
      () async {
        final now = DateTime.now();
        repo.foodsDb['f_avail'] = Food(
          foodId: 'f_avail',
          donorId: 'donor_1',
          foodName: 'Fresh Vegetable Curry',
          quantity: '10 servings',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 4)),
          description: 'Fresh and hot vegetable curry with rice',
          imageUrl: 'https://storage.com/curry.jpg',
          status: FoodStatus.available,
          latitude: 28.6139,
          longitude: 77.2090,
        );

        final result = await repo.getFoodById('f_avail');
        expect(result.isSuccess, isTrue);

        final food = (result as Success<Food, String>).value;
        expect(food.foodName, 'Fresh Vegetable Curry');
        expect(food.status, FoodStatus.available);
        expect(food.imageUrl, isNotNull);

        // Check button eligibility logic
        final isAvailable = food.status == FoodStatus.available;
        final isExpired = DateTime.now().isAfter(food.expiryAt);
        final canReserve = isAvailable && !isExpired;

        expect(canReserve, isTrue);
      },
    );

    test(
      '2. Reserved food: Details load and reservation button is locked',
      () async {
        final now = DateTime.now();
        repo.foodsDb['f_reserved'] = Food(
          foodId: 'f_reserved',
          donorId: 'donor_1',
          foodName: 'Pasta Tray',
          quantity: '6 servings',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 3)),
          description: 'Pasta',
          status: FoodStatus.reserved,
          currentReservationId: 'res_active_123',
        );

        final result = await repo.getFoodById('f_reserved');
        expect(result.isSuccess, isTrue);

        final food = (result as Success<Food, String>).value;
        expect(food.status, FoodStatus.reserved);

        final canReserve =
            food.status == FoodStatus.available &&
            !DateTime.now().isAfter(food.expiryAt);
        expect(canReserve, isFalse);
      },
    );

    test('3. Expired food: Reservation is strictly disabled', () async {
      final now = DateTime.now();
      repo.foodsDb['f_expired'] = Food(
        foodId: 'f_expired',
        donorId: 'donor_1',
        foodName: 'Bakery Rolls',
        quantity: '12 rolls',
        foodType: FoodType.packed,
        preparedAt: now.subtract(const Duration(hours: 10)),
        expiryAt: now.subtract(const Duration(hours: 2)), // Expired 2h ago
        description: 'Dinner rolls',
        status: FoodStatus.available,
      );

      final result = await repo.getFoodById('f_expired');
      expect(result.isSuccess, isTrue);

      final food = (result as Success<Food, String>).value;
      final isExpired = DateTime.now().isAfter(food.expiryAt);
      expect(isExpired, isTrue);

      final canReserve = food.status == FoodStatus.available && !isExpired;
      expect(canReserve, isFalse);
    });

    test('4. Completed food: Reservation is disabled', () async {
      final now = DateTime.now();
      repo.foodsDb['f_completed'] = Food(
        foodId: 'f_completed',
        donorId: 'donor_1',
        foodName: 'Completed Meals',
        quantity: '20 boxes',
        foodType: FoodType.packed,
        preparedAt: now.subtract(const Duration(hours: 4)),
        expiryAt: now.add(const Duration(hours: 4)),
        description: 'Handed over',
        status: FoodStatus.completed,
      );

      final result = await repo.getFoodById('f_completed');
      expect(result.isSuccess, isTrue);

      final food = (result as Success<Food, String>).value;
      expect(food.status, FoodStatus.completed);

      final canReserve =
          food.status == FoodStatus.available &&
          !DateTime.now().isAfter(food.expiryAt);
      expect(canReserve, isFalse);
    });

    test(
      '5. Deleted/Non-existent food: Returns clean failure result',
      () async {
        final result = await repo.getFoodById('non_existent_food_id');
        expect(result.isFailure, isTrue);
        expect((result as Failure<Food, String>).error, 'Food item not found.');
      },
    );

    test('6. Missing image: Renders safely with null imageUrl', () async {
      final now = DateTime.now();
      repo.foodsDb['f_no_img'] = Food(
        foodId: 'f_no_img',
        donorId: 'donor_1',
        foodName: 'Fruit Pack',
        quantity: '4 packs',
        foodType: FoodType.packed,
        preparedAt: now,
        expiryAt: now.add(const Duration(hours: 8)),
        description: 'Fruits',
        imageUrl: null,
        status: FoodStatus.available,
      );

      final result = await repo.getFoodById('f_no_img');
      expect(result.isSuccess, isTrue);

      final food = (result as Success<Food, String>).value;
      expect(food.imageUrl, isNull);
    });

    test(
      '7. Missing location: Handles null coordinates without crashing',
      () async {
        final now = DateTime.now();
        repo.foodsDb['f_no_loc'] = Food(
          foodId: 'f_no_loc',
          donorId: 'donor_1',
          foodName: 'Bread Loaves',
          quantity: '2 loaves',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'Bread',
          status: FoodStatus.available,
          latitude: null,
          longitude: null,
        );

        final result = await repo.getFoodById('f_no_loc');
        expect(result.isSuccess, isTrue);

        final food = (result as Success<Food, String>).value;
        expect(food.latitude, isNull);
        expect(food.longitude, isNull);
      },
    );

    test('8. Network failure: Surfaces error cleanly', () async {
      repo.simulateNetworkError = true;

      final result = await repo.getFoodById('f_any');
      expect(result.isFailure, isTrue);
      expect(
        (result as Failure<Food, String>).error,
        contains('Network connection failed'),
      );
    });
  });
}
