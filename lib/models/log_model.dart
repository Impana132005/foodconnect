import 'package:cloud_firestore/cloud_firestore.dart';

class PickupLog {
  final String logId;
  final String foodId;
  final String? reservationId;
  final String actorId;
  final String action;
  final DateTime? timestamp;

  PickupLog({
    required this.logId,
    required this.foodId,
    this.reservationId,
    required this.actorId,
    required this.action,
    this.timestamp,
  });

  factory PickupLog.fromMap(Map<String, dynamic> map, String documentId) {
    return PickupLog(
      logId: documentId,
      foodId: map['foodId'] ?? '',
      reservationId: map['reservationId'],
      actorId: map['actorId'] ?? '',
      action: map['action'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'reservationId': reservationId,
      'actorId': actorId,
      'action': action,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }
}

// Alias for backward compatibility if referenced as LogModel elsewhere
typedef LogModel = PickupLog;
