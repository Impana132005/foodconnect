import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums.dart';

class Reservation {
  final String reservationId;
  final String foodId;
  final String donorId;
  final String receiverId;
  final DateTime reservedAt;
  final DateTime pickupDeadline;
  final String otp;
  final bool otpVerified;
  final ReservationStatus status;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reservation({
    required this.reservationId,
    required this.foodId,
    required this.donorId,
    required this.receiverId,
    required this.reservedAt,
    required this.pickupDeadline,
    required this.otp,
    required this.otpVerified,
    required this.status,
    this.cancelledAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to parse reservation data returned by the server callable `reserveFood`
  factory Reservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val is String) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    return Reservation(
      reservationId: json['reservationId'] ?? '',
      foodId: json['foodId'] ?? '',
      donorId: json['donorId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      reservedAt: parseDate(json['reservedAt']),
      pickupDeadline: parseDate(json['pickupDeadline']),
      otp: json['otp'] ?? '',
      otpVerified: json['otpVerified'] ?? false,
      status: ReservationStatus.fromString(json['status']),
      cancelledAt: parseOptionalDate(json['cancelledAt']),
      completedAt: parseOptionalDate(json['completedAt']),
      createdAt: parseOptionalDate(json['createdAt']),
      updatedAt: parseOptionalDate(json['updatedAt']),
    );
  }

  factory Reservation.fromMap(Map<String, dynamic> map, String documentId) {
    return Reservation(
      reservationId: documentId,
      foodId: map['foodId'] ?? '',
      donorId: map['donorId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      reservedAt: (map['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pickupDeadline:
          (map['pickupDeadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      otp: map['otp'] ?? '',
      otpVerified: map['otpVerified'] ?? false,
      status: ReservationStatus.fromString(map['status']),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'foodId': foodId,
      'donorId': donorId,
      'receiverId': receiverId,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'pickupDeadline': Timestamp.fromDate(pickupDeadline),
      'otp': otp,
      'otpVerified': otpVerified,
      'status': status.value,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Alias for backward compatibility if referenced as ReservationModel elsewhere
typedef ReservationModel = Reservation;
