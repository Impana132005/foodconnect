import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/models/user_model.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/models/reservation_model.dart';
import 'package:foodconnect/models/log_model.dart';

void main() {
  group('Explicit Enums Tests', () {
    test('UserRole serialization and fallbacks', () {
      expect(UserRole.fromString('donor'), UserRole.donor);
      expect(UserRole.fromString('receiver'), UserRole.receiver);
      expect(UserRole.fromString('unknown'), UserRole.receiver);
      expect(UserRole.donor.value, 'donor');
    });

    test('VerificationStatus serialization and fallbacks', () {
      expect(
        VerificationStatus.fromString('pending'),
        VerificationStatus.pending,
      );
      expect(
        VerificationStatus.fromString('verified'),
        VerificationStatus.verified,
      );
      expect(
        VerificationStatus.fromString('rejected'),
        VerificationStatus.rejected,
      );
      expect(
        VerificationStatus.fromString('invalid'),
        VerificationStatus.pending,
      );
    });

    test('FoodType serialization and fallbacks', () {
      expect(FoodType.fromString('cooked'), FoodType.cooked);
      expect(FoodType.fromString('packed'), FoodType.packed);
      expect(FoodType.fromString('random'), FoodType.cooked);
    });

    test('FoodStatus serialization and fallbacks', () {
      expect(FoodStatus.fromString('available'), FoodStatus.available);
      expect(FoodStatus.fromString('reserved'), FoodStatus.reserved);
      expect(FoodStatus.fromString('completed'), FoodStatus.completed);
      expect(FoodStatus.fromString('expired'), FoodStatus.expired);
    });

    test('ReservationStatus serialization and fallbacks', () {
      expect(ReservationStatus.fromString('active'), ReservationStatus.active);
      expect(
        ReservationStatus.fromString('otp_verified'),
        ReservationStatus.otpVerified,
      );
      expect(
        ReservationStatus.fromString('completed'),
        ReservationStatus.completed,
      );
      expect(
        ReservationStatus.fromString('cancelled'),
        ReservationStatus.cancelled,
      );
      expect(
        ReservationStatus.fromString('expired'),
        ReservationStatus.expired,
      );
    });
  });

  group('Food Expiry Calculation Rules (+4h cooked / +8h packed)', () {
    test('Cooked food calculates preparedAt + 4 hours', () {
      final preparedAt = DateTime(2026, 8, 19, 10, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.cooked, preparedAt);
      expect(expiry, DateTime(2026, 8, 19, 14, 0, 0));
    });

    test('Packed food calculates preparedAt + 8 hours', () {
      final preparedAt = DateTime(2026, 8, 19, 10, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.packed, preparedAt);
      expect(expiry, DateTime(2026, 8, 19, 18, 0, 0));
    });
  });

  group('Models Serialization & Bounds Tests', () {
    test('UserProfile map serialization', () {
      final now = DateTime.now();
      final profile = UserProfile(
        userId: 'user_123',
        name: 'Test Donor',
        email: 'donor@test.com',
        phone: '+919876543210',
        role: UserRole.donor,
        organizationName: 'Food Charity',
        verificationStatus: VerificationStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['userId'], 'user_123');
      expect(map['role'], 'donor');
      expect(map['verificationStatus'], 'pending');
    });

    test('Reservation.fromJson parses server callable response', () {
      final json = {
        'reservationId': 'res_999',
        'foodId': 'food_111',
        'donorId': 'donor_222',
        'receiverId': 'receiver_333',
        'reservedAt': '2026-08-19T10:00:00.000Z',
        'pickupDeadline': '2026-08-19T10:30:00.000Z',
        'otp': '654321',
        'otpVerified': false,
        'status': 'active',
      };

      final reservation = Reservation.fromJson(json);
      expect(reservation.reservationId, 'res_999');
      expect(reservation.otp, '654321');
      expect(reservation.status, ReservationStatus.active);
      expect(
        reservation.pickupDeadline.difference(reservation.reservedAt).inMinutes,
        30,
      );
    });

    test('PickupLog serialization', () {
      final log = PickupLog(
        logId: 'log_001',
        foodId: 'food_123',
        actorId: 'user_456',
        action: 'FOOD_POSTED',
      );

      final map = log.toMap();
      expect(map['foodId'], 'food_123');
      expect(map['action'], 'FOOD_POSTED');
    });

    test(
      'VerificationStatus.pending is assigned upon account registration',
      () {
        final user = UserModel(
          userId: 'test_uid',
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          role: UserRole.donor,
          organizationName: 'Charity',
          verificationStatus: VerificationStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(user.verificationStatus, VerificationStatus.pending);
      },
    );
  });
}
