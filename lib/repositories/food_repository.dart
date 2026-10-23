import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/food_model.dart';

abstract class IFoodRepository {
  Future<Result<Food, String>> createFood(Food food);
  Future<Result<Food, String>> updateFoodContent(Food food);
  Future<Result<List<Food>, String>> getAvailableFoods({
    DocumentSnapshot? startAfter,
    int limit = 10,
  });
  Future<Result<List<Food>, String>> getDonorFoods(String donorId);
  Future<Result<Food, String>> getFoodById(String foodId);
  Stream<List<Food>> streamAvailableFoods();
}

class FoodRepository implements IFoodRepository {
  final FirebaseFirestore _firestore;

  FoodRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _foodsCollection =>
      _firestore.collection(AppConstants.foodsCollection);

  @override
  Future<Result<Food, String>> createFood(Food food) async {
    try {
      // Validate concrete expiry rule before writing
      final expectedExpiry = Food.calculateExpiryAt(
        food.foodType,
        food.preparedAt,
      );
      final finalFood = food.copyWith(
        status: FoodStatus.available,
        currentReservationId: null,
        expiryAt: expectedExpiry,
      );

      final docRef = _foodsCollection.doc();
      final newFood = Food(
        foodId: docRef.id,
        donorId: finalFood.donorId,
        foodName: finalFood.foodName,
        quantity: finalFood.quantity,
        foodType: finalFood.foodType,
        preparedAt: finalFood.preparedAt,
        expiryAt: finalFood.expiryAt,
        description: finalFood.description,
        imageUrl: finalFood.imageUrl,
        status: finalFood.status,
        currentReservationId: null,
        latitude: finalFood.latitude,
        longitude: finalFood.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(newFood.toMap());

      // Log creation
      await _firestore.collection(AppConstants.logsCollection).add({
        'foodId': docRef.id,
        'actorId': finalFood.donorId,
        'action': 'FOOD_POSTED',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return Success(newFood);
    } catch (e, stack) {
      AppLogger.error('Failed to create food post', e, stack);
      return Failure('Failed to post food: ${e.toString()}');
    }
  }

  @override
  Future<Result<Food, String>> updateFoodContent(Food food) async {
    try {
      // Re-verify expiry matches calculation rules
      final expectedExpiry = Food.calculateExpiryAt(
        food.foodType,
        food.preparedAt,
      );
      final updatedFood = food.copyWith(expiryAt: expectedExpiry);

      await _foodsCollection.doc(food.foodId).update({
        'foodName': updatedFood.foodName,
        'quantity': updatedFood.quantity,
        'description': updatedFood.description,
        'imageUrl': updatedFood.imageUrl,
        'preparedAt': Timestamp.fromDate(updatedFood.preparedAt),
        'expiryAt': Timestamp.fromDate(updatedFood.expiryAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Success(updatedFood);
    } catch (e, stack) {
      AppLogger.error('Failed to update food content', e, stack);
      return Failure('Failed to update food details: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<Food>, String>> getAvailableFoods({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now();
      Query<Map<String, dynamic>> query = _foodsCollection
          .where('status', isEqualTo: FoodStatus.available.value)
          .where('expiryAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiryAt', descending: false)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final foods = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();

      return Success(foods);
    } catch (e, stack) {
      AppLogger.error('Failed to query available foods', e, stack);
      return Failure('Error loading food feed: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<Food>, String>> getDonorFoods(String donorId) async {
    try {
      final snapshot = await _foodsCollection
          .where('donorId', isEqualTo: donorId)
          .orderBy('createdAt', descending: true)
          .get();

      final foods = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();
      return Success(foods);
    } catch (e, stack) {
      AppLogger.error('Failed to query donor foods', e, stack);
      return Failure('Error loading donor listings: ${e.toString()}');
    }
  }

  @override
  Future<Result<Food, String>> getFoodById(String foodId) async {
    try {
      final doc = await _foodsCollection.doc(foodId).get();
      if (!doc.exists || doc.data() == null) {
        return const Failure('Food item not found.');
      }
      return Success(Food.fromMap(doc.data()!, doc.id));
    } catch (e, stack) {
      AppLogger.error('Failed to get food by ID', e, stack);
      return Failure('Error fetching food details: ${e.toString()}');
    }
  }

  @override
  Stream<List<Food>> streamAvailableFoods() {
    final now = DateTime.now();
    return _foodsCollection
        .where('status', isEqualTo: FoodStatus.available.value)
        .where('expiryAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiryAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Food.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
