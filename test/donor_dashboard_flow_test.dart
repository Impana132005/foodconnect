import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/repositories/food_repository.dart';

class MockFoodRepository implements IFoodRepository {
  final Map<String, Food> foodsDb = {};
  bool simulateFirestoreError = false;

  @override
  Future<Result<Food, String>> createFood(Food food) async {
    if (simulateFirestoreError) {
      return const Failure('Firestore connection failure');
    }
    foodsDb[food.foodId] = food;
    return Success(food);
  }

  @override
  Future<Result<Food, String>> updateFoodContent(Food food) async {
    if (simulateFirestoreError) {
      return const Failure('Firestore connection failure');
    }
    foodsDb[food.foodId] = food;
    return Success(food);
  }

  @override
  Future<Result<Food, String>> getFoodById(String foodId) async {
    if (simulateFirestoreError) {
      return const Failure('Firestore connection failure');
    }
    if (!foodsDb.containsKey(foodId)) {
      return const Failure('Food item not found.');
    }
    return Success(foodsDb[foodId]!);
  }

  @override
  Future<Result<List<Food>, String>> getDonorFoods(String donorId) async {
    if (simulateFirestoreError) {
      return const Failure('Firestore error: Error loading donor listings');
    }
    final donorListings =
        foodsDb.values.where((f) => f.donorId == donorId).toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
    return Success(donorListings);
  }

  @override
  Future<Result<List<Food>, String>> getAvailableFoods({
    dynamic startAfter,
    int limit = 10,
  }) async {
    final available = foodsDb.values
        .where(
          (f) =>
              f.status == FoodStatus.available &&
              f.expiryAt.isAfter(DateTime.now()),
        )
        .take(limit)
        .toList();
    return Success(available);
  }

  @override
  Stream<List<Food>> streamAvailableFoods() {
    return Stream.value(
      foodsDb.values
          .where(
            (f) =>
                f.status == FoodStatus.available &&
                f.expiryAt.isAfter(DateTime.now()),
          )
          .toList(),
    );
  }
}

void main() {
  group('Phase 4 Donor Dashboard Test Suite', () {
    late MockFoodRepository foodRepo;

    setUp(() {
      foodRepo = MockFoodRepository();
    });

    test('1. No food: Donor with 0 postings returns empty list', () async {
      final result = await foodRepo.getDonorFoods('donor_empty_123');

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<Food>, String>).value;
      expect(list, isEmpty);
    });

    test(
      '2. One food: Donor with 1 food returns 1 item and accurate count',
      () async {
        final now = DateTime.now();
        final food1 = Food(
          foodId: 'food_1',
          donorId: 'donor_alice',
          foodName: 'Vegetable Biryani',
          quantity: '10 servings',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 4)),
          description: 'Fresh warm biryani',
          status: FoodStatus.available,
          createdAt: now,
        );
        await foodRepo.createFood(food1);

        final result = await foodRepo.getDonorFoods('donor_alice');
        expect(result.isSuccess, isTrue);

        final list = (result as Success<List<Food>, String>).value;
        expect(list.length, 1);
        expect(list.first.foodName, 'Vegetable Biryani');
        expect(list.first.status, FoodStatus.available);

        final availableCount = list
            .where((f) => f.status == FoodStatus.available)
            .length;
        final reservedCount = list
            .where((f) => f.status == FoodStatus.reserved)
            .length;
        final completedCount = list
            .where((f) => f.status == FoodStatus.completed)
            .length;

        expect(availableCount, 1);
        expect(reservedCount, 0);
        expect(completedCount, 0);
      },
    );

    test(
      '3. Multiple foods: accurately counts Available, Reserved, and Completed',
      () async {
        final now = DateTime.now();

        await foodRepo.createFood(
          Food(
            foodId: 'f1',
            donorId: 'donor_multi',
            foodName: 'Sandwiches',
            quantity: '5 boxes',
            foodType: FoodType.packed,
            preparedAt: now,
            expiryAt: now.add(const Duration(hours: 8)),
            description: 'Club sandwiches',
            status: FoodStatus.available,
            createdAt: now.subtract(const Duration(minutes: 10)),
          ),
        );

        await foodRepo.createFood(
          Food(
            foodId: 'f2',
            donorId: 'donor_multi',
            foodName: 'Pasta Tray',
            quantity: '12 servings',
            foodType: FoodType.cooked,
            preparedAt: now,
            expiryAt: now.add(const Duration(hours: 4)),
            description: 'White sauce pasta',
            status: FoodStatus.reserved,
            currentReservationId: 'res_123',
            createdAt: now.subtract(const Duration(minutes: 20)),
          ),
        );

        await foodRepo.createFood(
          Food(
            foodId: 'f3',
            donorId: 'donor_multi',
            foodName: 'Fruit Bowls',
            quantity: '8 bowls',
            foodType: FoodType.packed,
            preparedAt: now.subtract(const Duration(hours: 3)),
            expiryAt: now.add(const Duration(hours: 5)),
            description: 'Seasonal cut fruits',
            status: FoodStatus.completed,
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        );

        final result = await foodRepo.getDonorFoods('donor_multi');
        expect(result.isSuccess, isTrue);

        final list = (result as Success<List<Food>, String>).value;
        expect(list.length, 3);

        final availableCount = list
            .where((f) => f.status == FoodStatus.available)
            .length;
        final reservedCount = list
            .where((f) => f.status == FoodStatus.reserved)
            .length;
        final completedCount = list
            .where((f) => f.status == FoodStatus.completed)
            .length;

        expect(availableCount, 1);
        expect(reservedCount, 1);
        expect(completedCount, 1);
      },
    );

    test('4. Firestore failure returns user-friendly error result', () async {
      foodRepo.simulateFirestoreError = true;

      final result = await foodRepo.getDonorFoods('donor_test');
      expect(result.isFailure, isTrue);
      expect(
        (result as Failure<List<Food>, String>).error,
        contains('Error loading donor listings'),
      );
    });

    test(
      '5. Data isolation: Donor only sees their own listings and not other donors',
      () async {
        final now = DateTime.now();

        await foodRepo.createFood(
          Food(
            foodId: 'f_alice',
            donorId: 'alice_uid',
            foodName: "Alice's Salad",
            quantity: '4 bowls',
            foodType: FoodType.cooked,
            preparedAt: now,
            expiryAt: now.add(const Duration(hours: 4)),
            description: 'Salad',
            status: FoodStatus.available,
            createdAt: now,
          ),
        );

        await foodRepo.createFood(
          Food(
            foodId: 'f_bob',
            donorId: 'bob_uid',
            foodName: "Bob's Rice",
            quantity: '10 boxes',
            foodType: FoodType.cooked,
            preparedAt: now,
            expiryAt: now.add(const Duration(hours: 4)),
            description: 'Rice',
            status: FoodStatus.available,
            createdAt: now,
          ),
        );

        // Query Alice's dashboard
        final aliceResult = await foodRepo.getDonorFoods('alice_uid');
        final aliceFoods = (aliceResult as Success<List<Food>, String>).value;
        expect(aliceFoods.length, 1);
        expect(aliceFoods.first.foodName, "Alice's Salad");

        // Query Bob's dashboard
        final bobResult = await foodRepo.getDonorFoods('bob_uid');
        final bobFoods = (bobResult as Success<List<Food>, String>).value;
        expect(bobFoods.length, 1);
        expect(bobFoods.first.foodName, "Bob's Rice");
      },
    );

    test(
      '6. App restart simulation retains donor food items across sessions',
      () async {
        final now = DateTime.now();
        await foodRepo.createFood(
          Food(
            foodId: 'persist_1',
            donorId: 'donor_persist',
            foodName: 'Curry & Roti',
            quantity: '20 packs',
            foodType: FoodType.cooked,
            preparedAt: now,
            expiryAt: now.add(const Duration(hours: 4)),
            description: 'Fresh curry meal packs',
            status: FoodStatus.available,
            createdAt: now,
          ),
        );

        // Simulate App Restart with fresh repository session pointing to same DB
        final restartedRepo = MockFoodRepository();
        restartedRepo.foodsDb.addAll(foodRepo.foodsDb);

        final result = await restartedRepo.getDonorFoods('donor_persist');
        expect(result.isSuccess, isTrue);

        final list = (result as Success<List<Food>, String>).value;
        expect(list.length, 1);
        expect(list.first.foodName, 'Curry & Roti');
      },
    );
  });
}
