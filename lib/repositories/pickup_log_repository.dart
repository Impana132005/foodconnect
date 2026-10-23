import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/log_model.dart';

abstract class IPickupLogRepository {
  Future<Result<void, String>> createLog(PickupLog log);
  Future<Result<List<PickupLog>, String>> getLogsForFood(String foodId);
  Future<Result<List<PickupLog>, String>> getLogsForActor(String actorId);
}

class PickupLogRepository implements IPickupLogRepository {
  final FirebaseFirestore _firestore;

  PickupLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logsCollection =>
      _firestore.collection(AppConstants.logsCollection);

  @override
  Future<Result<void, String>> createLog(PickupLog log) async {
    try {
      await _logsCollection.add(log.toMap());
      return const Success(null);
    } catch (e, stack) {
      AppLogger.error('Failed to create pickup log', e, stack);
      return Failure('Failed to record log: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PickupLog>, String>> getLogsForFood(String foodId) async {
    try {
      final snapshot = await _logsCollection
          .where('foodId', isEqualTo: foodId)
          .orderBy('timestamp', descending: true)
          .get();

      final logs = snapshot.docs
          .map((doc) => PickupLog.fromMap(doc.data(), doc.id))
          .toList();
      return Success(logs);
    } catch (e, stack) {
      AppLogger.error('Failed to get logs for food', e, stack);
      return Failure('Error fetching food logs: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<PickupLog>, String>> getLogsForActor(
    String actorId,
  ) async {
    try {
      final snapshot = await _logsCollection
          .where('actorId', isEqualTo: actorId)
          .orderBy('timestamp', descending: true)
          .get();

      final logs = snapshot.docs
          .map((doc) => PickupLog.fromMap(doc.data(), doc.id))
          .toList();
      return Success(logs);
    } catch (e, stack) {
      AppLogger.error('Failed to get logs for actor', e, stack);
      return Failure('Error fetching user activity logs: ${e.toString()}');
    }
  }
}
