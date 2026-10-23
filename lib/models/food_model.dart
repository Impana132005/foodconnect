import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums.dart';

class Food {
  final String foodId;
  final String donorId;
  final String foodName;
  final String quantity;
  final FoodType foodType;
  final DateTime preparedAt;
  final DateTime expiryAt;
  final String description;
  final String? imageUrl;
  final FoodStatus status;
  final String? currentReservationId;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Food({
    required this.foodId,
    required this.donorId,
    required this.foodName,
    required this.quantity,
    required this.foodType,
    required this.preparedAt,
    required this.expiryAt,
    required this.description,
    this.imageUrl,
    required this.status,
    this.currentReservationId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  /// Authoritative static helper calculating expiry duration based on food type:
  /// +4 hours for cooked food, +8 hours for packed food.
  static DateTime calculateExpiryAt(FoodType type, DateTime preparedAt) {
    if (type == FoodType.cooked) {
      return preparedAt.add(const Duration(hours: 4));
    } else {
      return preparedAt.add(const Duration(hours: 8));
    }
  }

  factory Food.fromMap(Map<String, dynamic> map, String documentId) {
    final preparedAtDate =
        (map['preparedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final foodType = FoodType.fromString(map['foodType']);

    return Food(
      foodId: documentId,
      donorId: map['donorId'] ?? '',
      foodName: map['foodName'] ?? '',
      quantity: map['quantity'] ?? '',
      foodType: foodType,
      preparedAt: preparedAtDate,
      expiryAt:
          (map['expiryAt'] as Timestamp?)?.toDate() ??
          calculateExpiryAt(foodType, preparedAtDate),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      status: FoodStatus.fromString(map['status']),
      currentReservationId: map['currentReservationId'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'donorId': donorId,
      'foodName': foodName,
      'quantity': quantity,
      'foodType': foodType.value,
      'preparedAt': Timestamp.fromDate(preparedAt),
      'expiryAt': Timestamp.fromDate(expiryAt),
      'description': description,
      'imageUrl': imageUrl,
      'status': status.value,
      'currentReservationId': currentReservationId,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Food copyWith({
    String? foodName,
    String? quantity,
    FoodType? foodType,
    DateTime? preparedAt,
    DateTime? expiryAt,
    String? description,
    String? imageUrl,
    FoodStatus? status,
    String? currentReservationId,
    double? latitude,
    double? longitude,
  }) {
    final newType = foodType ?? this.foodType;
    final newPrepared = preparedAt ?? this.preparedAt;
    final newExpiry =
        expiryAt ??
        (preparedAt != null || foodType != null
            ? calculateExpiryAt(newType, newPrepared)
            : this.expiryAt);

    return Food(
      foodId: foodId,
      donorId: donorId,
      foodName: foodName ?? this.foodName,
      quantity: quantity ?? this.quantity,
      foodType: newType,
      preparedAt: newPrepared,
      expiryAt: newExpiry,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      currentReservationId: currentReservationId ?? this.currentReservationId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// Alias for backward compatibility if referenced as FoodModel elsewhere
typedef FoodModel = Food;
