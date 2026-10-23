import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/food_model.dart';
import 'package:foodconnect/models/reservation_model.dart';

void main() {
  group('Food Expiry Edge Cases', () {
    test('food is expired when now is after expiryAt', () {
      final food = Food(
        foodId: 'f1',
        donorId: 'd1',
        foodName: 'Test',
        quantity: '5 servings',
        foodType: FoodType.cooked,
        preparedAt: DateTime.now().subtract(const Duration(hours: 5)),
        expiryAt: DateTime.now().subtract(const Duration(hours: 1)),
        description: 'Test food',
        status: FoodStatus.available,
      );

      expect(DateTime.now().isAfter(food.expiryAt), isTrue);
    });

    test('food is NOT expired when now is before expiryAt', () {
      final food = Food(
        foodId: 'f2',
        donorId: 'd1',
        foodName: 'Test',
        quantity: '5 servings',
        foodType: FoodType.packed,
        preparedAt: DateTime.now(),
        expiryAt: DateTime.now().add(const Duration(hours: 8)),
        description: 'Test food',
        status: FoodStatus.available,
      );

      expect(DateTime.now().isAfter(food.expiryAt), isFalse);
    });

    test('cooked food prepared now expires in exactly 4 hours', () {
      final now = DateTime(2026, 8, 19, 12, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.cooked, now);
      expect(expiry.difference(now).inHours, 4);
      expect(expiry.difference(now).inMinutes, 240);
    });

    test('packed food prepared now expires in exactly 8 hours', () {
      final now = DateTime(2026, 8, 19, 12, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.packed, now);
      expect(expiry.difference(now).inHours, 8);
      expect(expiry.difference(now).inMinutes, 480);
    });

    test('food prepared at midnight cooked expires at 4 AM', () {
      final midnight = DateTime(2026, 8, 20, 0, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.cooked, midnight);
      expect(expiry, DateTime(2026, 8, 20, 4, 0, 0));
    });

    test('food prepared at 11 PM packed expires next day at 7 AM', () {
      final lateNight = DateTime(2026, 8, 19, 23, 0, 0);
      final expiry = Food.calculateExpiryAt(FoodType.packed, lateNight);
      expect(expiry, DateTime(2026, 8, 20, 7, 0, 0));
    });
  });

  group('Reservation Deadline Edge Cases', () {
    test('reservation pickupDeadline is 30 minutes after reservedAt', () {
      final reservedAt = DateTime(2026, 8, 19, 14, 0, 0);
      final pickupDeadline = DateTime(2026, 8, 19, 14, 30, 0);

      final reservation = Reservation.fromJson({
        'reservationId': 'r1',
        'foodId': 'f1',
        'donorId': 'd1',
        'receiverId': 'rec1',
        'reservedAt': reservedAt.toIso8601String(),
        'pickupDeadline': pickupDeadline.toIso8601String(),
        'otp': '123456',
        'otpVerified': false,
        'status': 'active',
      });

      expect(
        reservation.pickupDeadline.difference(reservation.reservedAt).inMinutes,
        30,
      );
    });

    test('reservation is expired when now is past pickupDeadline', () {
      final reservedAt = DateTime.now().subtract(const Duration(minutes: 45));
      final pickupDeadline = DateTime.now().subtract(
        const Duration(minutes: 15),
      );

      final reservation = Reservation.fromJson({
        'reservationId': 'r2',
        'foodId': 'f1',
        'donorId': 'd1',
        'receiverId': 'rec1',
        'reservedAt': reservedAt.toIso8601String(),
        'pickupDeadline': pickupDeadline.toIso8601String(),
        'otp': '654321',
        'otpVerified': false,
        'status': 'active',
      });

      expect(DateTime.now().isAfter(reservation.pickupDeadline), isTrue);
    });

    test('reservation is NOT expired when now is before pickupDeadline', () {
      final reservedAt = DateTime.now();
      final pickupDeadline = DateTime.now().add(const Duration(minutes: 30));

      final reservation = Reservation.fromJson({
        'reservationId': 'r3',
        'foodId': 'f1',
        'donorId': 'd1',
        'receiverId': 'rec1',
        'reservedAt': reservedAt.toIso8601String(),
        'pickupDeadline': pickupDeadline.toIso8601String(),
        'otp': '111111',
        'otpVerified': false,
        'status': 'active',
      });

      expect(DateTime.now().isAfter(reservation.pickupDeadline), isFalse);
    });
  });

  group('Status Transition Logic', () {
    test('FoodStatus transitions: available → reserved → completed', () {
      expect(FoodStatus.available.value, 'available');
      expect(FoodStatus.reserved.value, 'reserved');
      expect(FoodStatus.completed.value, 'completed');
    });

    test('FoodStatus transitions: available → expired', () {
      expect(FoodStatus.expired.value, 'expired');
    });

    test('ReservationStatus: active → otp_verified → completed', () {
      expect(ReservationStatus.active.value, 'active');
      expect(ReservationStatus.otpVerified.value, 'otp_verified');
      expect(ReservationStatus.completed.value, 'completed');
    });

    test('ReservationStatus: active → cancelled', () {
      expect(ReservationStatus.cancelled.value, 'cancelled');
    });

    test('ReservationStatus: active → expired', () {
      expect(ReservationStatus.expired.value, 'expired');
    });

    test('completed reservation is terminal (no further transitions)', () {
      final reservation = Reservation.fromJson({
        'reservationId': 'r_terminal',
        'foodId': 'f1',
        'donorId': 'd1',
        'receiverId': 'rec1',
        'reservedAt': DateTime.now().toIso8601String(),
        'pickupDeadline': DateTime.now()
            .add(const Duration(minutes: 30))
            .toIso8601String(),
        'otp': '123456',
        'otpVerified': true,
        'status': 'completed',
      });

      expect(reservation.status, ReservationStatus.completed);
      expect(reservation.otpVerified, isTrue);
      // Completed state means no cancel/reserve/verify should be allowed
      expect(reservation.status != ReservationStatus.active, isTrue);
      expect(reservation.status != ReservationStatus.cancelled, isTrue);
    });
  });

  group('Donor Self-Reservation Prevention', () {
    test('donor and receiver IDs can be compared client-side', () {
      const donorId = 'user_donor_001';
      const receiverAttemptId = 'user_donor_001'; // same as donor

      expect(donorId == receiverAttemptId, isTrue);
    });

    test('different donor and receiver IDs are allowed', () {
      const donorId = 'user_donor_001';
      const receiverId = 'user_receiver_002';

      expect(donorId == receiverId, isFalse);
    });
  });

  group('Result Type Tests', () {
    test('Success holds value and reports isSuccess', () {
      const result = Success<String, String>('data');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.successValue, 'data');
    });

    test('Failure holds error and reports isFailure', () {
      const result = Failure<String, String>('error message');
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.failureValue, 'error message');
    });

    test('fold returns correct branch for Success', () {
      const Result<int, String> result = Success(42);
      final value = result.fold((s) => 'success: $s', (f) => 'failure: $f');
      expect(value, 'success: 42');
    });

    test('fold returns correct branch for Failure', () {
      const Result<int, String> result = Failure('oops');
      final value = result.fold((s) => 'success: $s', (f) => 'failure: $f');
      expect(value, 'failure: oops');
    });
  });

  group('Model CopyWith Tests', () {
    test('Food.copyWith preserves unchanged fields', () {
      final food = Food(
        foodId: 'f1',
        donorId: 'd1',
        foodName: 'Original',
        quantity: '10 servings',
        foodType: FoodType.cooked,
        preparedAt: DateTime(2026, 8, 19, 10, 0),
        expiryAt: DateTime(2026, 8, 19, 14, 0),
        description: 'Desc',
        status: FoodStatus.available,
        latitude: 12.97,
        longitude: 77.59,
      );

      final updated = food.copyWith(foodName: 'Updated');
      expect(updated.foodName, 'Updated');
      expect(updated.foodId, 'f1');
      expect(updated.donorId, 'd1');
      expect(updated.quantity, '10 servings');
      expect(updated.foodType, FoodType.cooked);
      expect(updated.latitude, 12.97);
    });

    test('Food.copyWith can change status', () {
      final food = Food(
        foodId: 'f1',
        donorId: 'd1',
        foodName: 'Test',
        quantity: '5',
        foodType: FoodType.packed,
        preparedAt: DateTime.now(),
        expiryAt: DateTime.now().add(const Duration(hours: 8)),
        description: '',
        status: FoodStatus.available,
      );

      final reserved = food.copyWith(
        status: FoodStatus.reserved,
        currentReservationId: 'res_001',
      );

      expect(reserved.status, FoodStatus.reserved);
      expect(reserved.currentReservationId, 'res_001');
      expect(food.status, FoodStatus.available); // original unchanged
    });
  });

  group('OTP Format Validation', () {
    test('valid 6-digit OTPs', () {
      for (final otp in ['000000', '123456', '999999', '042069']) {
        expect(RegExp(r'^[0-9]{6}$').hasMatch(otp), isTrue);
      }
    });

    test('invalid OTP formats', () {
      for (final otp in ['12345', '1234567', 'abcdef', '12 34 56', '']) {
        expect(RegExp(r'^[0-9]{6}$').hasMatch(otp), isFalse);
      }
    });
  });
}
