import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/food_model.dart';
import '../../../../repositories/food_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  return FoodRepository();
});

final availableFoodsStreamProvider =
    StreamProvider.autoDispose<List<Food>>((ref) {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null) {
        return Stream.value([]);
      }
      final repository = ref.watch(foodRepositoryProvider);
      return repository.streamAvailableFoods();
    });

final donorFoodsProvider =
    FutureProvider.autoDispose.family<List<Food>, String>((
      ref,
      donorId,
    ) async {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null || donorId.isEmpty) return [];
      final repository = ref.watch(foodRepositoryProvider);
      final result = await repository.getDonorFoods(donorId);
      return result.fold((foods) => foods, (error) => throw Exception(error));
    });

final foodDetailsProvider =
    FutureProvider.autoDispose.family<Food, String>((ref, foodId) async {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null || foodId.isEmpty) throw Exception('Not signed in');
      final repository = ref.watch(foodRepositoryProvider);
      final result = await repository.getFoodById(foodId);
      return result.fold((food) => food, (error) => throw Exception(error));
    });
