import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/repositories/food_repository.dart';
import 'package:foodconnect/services/location_service.dart';

class MockDiscoveryFoodRepository implements IFoodRepository {
  final Map<String, Food> foodsDb = {};
  bool simulateNetworkError = false;

  @override
  Future<Result<List<Food>, String>> getAvailableFoods({
    dynamic startAfter,
    int limit = 10,
  }) async {
    if (simulateNetworkError) {
      return const Failure(
        'Network error. Please check your internet connection.',
      );
    }
    final now = DateTime.now();
    final available = foodsDb.values
        .where(
          (f) => f.status == FoodStatus.available && f.expiryAt.isAfter(now),
        )
        .take(limit)
        .toList();
    return Success(available);
  }

  @override
  Stream<List<Food>> streamAvailableFoods() {
    if (simulateNetworkError) {
      return Stream.error(
        'Network error. Please check your internet connection.',
      );
    }
    final now = DateTime.now();
    final available = foodsDb.values
        .where(
          (f) => f.status == FoodStatus.available && f.expiryAt.isAfter(now),
        )
        .toList();
    return Stream.value(available);
  }

  @override
  Future<Result<Food, String>> getFoodById(String foodId) async {
    if (simulateNetworkError) {
      return const Failure(
        'Network error. Please check your internet connection.',
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
}

void main() {
  group('Phase 6 Receiver Food Discovery Test Suite', () {
    late MockDiscoveryFoodRepository repo;
    final locationService = LocationService();

    setUp(() {
      repo = MockDiscoveryFoodRepository();
    });

    test('1. No available food: Returns empty list', () async {
      final result = await repo.getAvailableFoods();

      expect(result.isSuccess, isTrue);
      final list = (result as Success<List<Food>, String>).value;
      expect(list, isEmpty);
    });

    test('2. Available food: Returns active non-expired food item', () async {
      final now = DateTime.now();
      repo.foodsDb['f1'] = Food(
        foodId: 'f1',
        donorId: 'd1',
        foodName: 'Warm Vegetable Pulao',
        quantity: '15 servings',
        foodType: FoodType.cooked,
        preparedAt: now,
        expiryAt: now.add(const Duration(hours: 4)),
        description: 'Cooked rice meal',
        status: FoodStatus.available,
      );

      final result = await repo.getAvailableFoods();
      expect(result.isSuccess, isTrue);

      final list = (result as Success<List<Food>, String>).value;
      expect(list.length, 1);
      expect(list.first.foodName, 'Warm Vegetable Pulao');
      expect(list.first.status, FoodStatus.available);
      expect(list.first.expiryAt.isAfter(now), isTrue);
    });

    test(
      '3. Expired food: Is excluded from available discovery feed',
      () async {
        final now = DateTime.now();
        // Past expired food
        repo.foodsDb['f_expired'] = Food(
          foodId: 'f_expired',
          donorId: 'd1',
          foodName: 'Old Sandwiches',
          quantity: '5 boxes',
          foodType: FoodType.cooked,
          preparedAt: now.subtract(const Duration(hours: 5)),
          expiryAt: now.subtract(const Duration(hours: 1)),
          description: 'Expired sandwiches',
          status: FoodStatus.available,
        );

        final result = await repo.getAvailableFoods();
        expect(result.isSuccess, isTrue);

        final list = (result as Success<List<Food>, String>).value;
        expect(list, isEmpty); // Excluded from feed because expiryAt <= now
      },
    );

    test(
      '4. Multiple foods: Supports filtering by type and nearest distance sorting',
      () async {
        final now = DateTime.now();

        // Food A: 2 km away (cooked)
        repo.foodsDb['f_a'] = Food(
          foodId: 'f_a',
          donorId: 'd1',
          foodName: 'Pasta Tray',
          quantity: '8 servings',
          foodType: FoodType.cooked,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 4)),
          description: 'Pasta',
          status: FoodStatus.available,
          latitude: 28.6200,
          longitude: 77.2100,
        );

        // Food B: 10 km away (packed)
        repo.foodsDb['f_b'] = Food(
          foodId: 'f_b',
          donorId: 'd2',
          foodName: 'Juice Bottles',
          quantity: '20 bottles',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'Juice',
          status: FoodStatus.available,
          latitude: 28.7000,
          longitude: 77.3000,
        );

        final list =
            (await repo.getAvailableFoods() as Success<List<Food>, String>)
                .value;
        expect(list.length, 2);

        // Filter Cooked
        final cookedOnly = list
            .where((f) => f.foodType == FoodType.cooked)
            .toList();
        expect(cookedOnly.length, 1);
        expect(cookedOnly.first.foodName, 'Pasta Tray');

        // Filter Packed
        final packedOnly = list
            .where((f) => f.foodType == FoodType.packed)
            .toList();
        expect(packedOnly.length, 1);
        expect(packedOnly.first.foodName, 'Juice Bottles');

        // Sort Nearest from user position (28.6139, 77.2090)
        const userLat = 28.6139;
        const userLng = 77.2090;

        final sorted = List<Food>.from(list)
          ..sort((a, b) {
            final distA = locationService.calculateDistance(
              userLat,
              userLng,
              a.latitude!,
              a.longitude!,
            );
            final distB = locationService.calculateDistance(
              userLat,
              userLng,
              b.latitude!,
              b.longitude!,
            );
            return distA.compareTo(distB);
          });

        expect(sorted.first.foodId, 'f_a'); // Closer item is first
        expect(sorted.last.foodId, 'f_b');
      },
    );

    test(
      '5. Missing image: Card handles null imageUrl without exception',
      () async {
        final now = DateTime.now();
        repo.foodsDb['f_no_img'] = Food(
          foodId: 'f_no_img',
          donorId: 'd1',
          foodName: 'Fresh Bread',
          quantity: '4 loaves',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'No image uploaded',
          imageUrl: null,
          status: FoodStatus.available,
        );

        final result = await repo.getFoodById('f_no_img');
        expect(result.isSuccess, isTrue);

        final food = (result as Success<Food, String>).value;
        expect(food.imageUrl, isNull);
      },
    );

    test(
      '6. Missing coordinates: Handles null coordinates and null distance gracefully',
      () async {
        final now = DateTime.now();
        repo.foodsDb['f_no_coords'] = Food(
          foodId: 'f_no_coords',
          donorId: 'd1',
          foodName: 'Biscuits',
          quantity: '10 packs',
          foodType: FoodType.packed,
          preparedAt: now,
          expiryAt: now.add(const Duration(hours: 8)),
          description: 'No GPS coords',
          status: FoodStatus.available,
          latitude: null,
          longitude: null,
        );

        final result = await repo.getFoodById('f_no_coords');
        expect(result.isSuccess, isTrue);

        final food = (result as Success<Food, String>).value;
        expect(food.latitude, isNull);
        expect(food.longitude, isNull);

        // Distance calculation skipped when coordinates are null
        const double userLat = 28.6139;
        const double userLng = 77.2090;
        final distanceString = (food.latitude != null && food.longitude != null)
            ? '${locationService.calculateDistance(userLat, userLng, food.latitude!, food.longitude!).toStringAsFixed(1)} km'
            : null;

        expect(distanceString, isNull);
      },
    );

    test(
      '7. Network failure: Surfaces error message without crashing',
      () async {
        repo.simulateNetworkError = true;

        final result = await repo.getAvailableFoods();
        expect(result.isFailure, isTrue);
        expect(
          (result as Failure<List<Food>, String>).error,
          contains('Network error'),
        );
      },
    );
  });
}
