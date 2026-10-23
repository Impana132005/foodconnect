enum UserRole {
  donor,
  receiver;

  String get value => name;

  static UserRole fromString(String? val) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => UserRole.receiver,
    );
  }
}

enum VerificationStatus {
  pending,
  verified,
  rejected;

  String get value => name;

  static VerificationStatus fromString(String? val) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => VerificationStatus.pending,
    );
  }
}

enum FoodType {
  cooked,
  packed;

  String get value => name;

  static FoodType fromString(String? val) {
    return FoodType.values.firstWhere(
      (e) => e.name.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => FoodType.cooked,
    );
  }
}

enum FoodStatus {
  available,
  reserved,
  completed,
  expired;

  String get value => name;

  static FoodStatus fromString(String? val) {
    return FoodStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (val ?? '').toLowerCase(),
      orElse: () => FoodStatus.available,
    );
  }
}

enum ReservationStatus {
  active,
  otpVerified,
  completed,
  cancelled,
  expired;

  String get value {
    if (this == ReservationStatus.otpVerified) {
      return 'otp_verified';
    }
    return name;
  }

  static ReservationStatus fromString(String? val) {
    final lower = (val ?? '').toLowerCase();
    if (lower == 'otp_verified') return ReservationStatus.otpVerified;
    return ReservationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => ReservationStatus.active,
    );
  }
}
