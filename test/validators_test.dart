import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/validation.dart';

void main() {
  group('AppValidators.validateName', () {
    test('rejects null', () {
      expect(AppValidators.validateName(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateName(''), isNotNull);
      expect(AppValidators.validateName('   '), isNotNull);
    });

    test('rejects single character', () {
      expect(AppValidators.validateName('A'), isNotNull);
    });

    test('accepts valid names', () {
      expect(AppValidators.validateName('John Doe'), isNull);
      expect(AppValidators.validateName('Dr. Smith'), isNull);
      expect(AppValidators.validateName("O'Brien"), isNull);
      expect(AppValidators.validateName('Anne-Marie'), isNull);
    });

    test('rejects names with numbers', () {
      expect(AppValidators.validateName('John123'), isNotNull);
    });

    test('rejects names exceeding 60 characters', () {
      final longName = 'A' * 61;
      expect(AppValidators.validateName(longName), isNotNull);
    });

    test('accepts exactly 60 characters', () {
      final exactName = 'A' * 60;
      expect(AppValidators.validateName(exactName), isNull);
    });
  });

  group('AppValidators.validateEmail', () {
    test('rejects null', () {
      expect(AppValidators.validateEmail(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateEmail(''), isNotNull);
    });

    test('rejects invalid emails', () {
      expect(AppValidators.validateEmail('notanemail'), isNotNull);
      expect(AppValidators.validateEmail('@domain.com'), isNotNull);
      expect(AppValidators.validateEmail('user@'), isNotNull);
      expect(AppValidators.validateEmail('user@.com'), isNotNull);
    });

    test('accepts valid emails', () {
      expect(AppValidators.validateEmail('user@example.com'), isNull);
      expect(AppValidators.validateEmail('test.user+tag@domain.co'), isNull);
      expect(AppValidators.validateEmail('a@b.cd'), isNull);
    });
  });

  group('AppValidators.validatePassword', () {
    test('rejects null', () {
      expect(AppValidators.validatePassword(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validatePassword(''), isNotNull);
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(AppValidators.validatePassword('12345'), isNotNull);
      expect(AppValidators.validatePassword('abc'), isNotNull);
    });

    test('accepts passwords 6 or more characters', () {
      expect(AppValidators.validatePassword('123456'), isNull);
      expect(AppValidators.validatePassword('securePassword!'), isNull);
    });
  });

  group('AppValidators.validatePhone', () {
    test('rejects null', () {
      expect(AppValidators.validatePhone(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validatePhone(''), isNotNull);
    });

    test('rejects too short phone numbers', () {
      expect(AppValidators.validatePhone('12345'), isNotNull);
    });

    test('accepts valid phone numbers', () {
      expect(AppValidators.validatePhone('+919876543210'), isNull);
      expect(AppValidators.validatePhone('1234567890'), isNull);
      expect(AppValidators.validatePhone('+1 (555) 123-4567'), isNull);
    });

    test('rejects phone numbers with letters', () {
      expect(AppValidators.validatePhone('abcdefghij'), isNotNull);
    });
  });

  group('AppValidators.validateFoodName', () {
    test('rejects null', () {
      expect(AppValidators.validateFoodName(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateFoodName(''), isNotNull);
    });

    test('rejects names shorter than 3 characters', () {
      expect(AppValidators.validateFoodName('Ab'), isNotNull);
    });

    test('accepts valid food names', () {
      expect(AppValidators.validateFoodName('Biryani'), isNull);
      expect(AppValidators.validateFoodName('Rice and Curry'), isNull);
    });

    test('rejects food names exceeding 100 characters', () {
      final longName = 'A' * 101;
      expect(AppValidators.validateFoodName(longName), isNotNull);
    });
  });

  group('AppValidators.validateQuantity', () {
    test('rejects null', () {
      expect(AppValidators.validateQuantity(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateQuantity(''), isNotNull);
    });

    test('accepts valid quantities', () {
      expect(AppValidators.validateQuantity('12 servings'), isNull);
      expect(AppValidators.validateQuantity('5 kg'), isNull);
    });

    test('rejects quantities exceeding 50 characters', () {
      final longQty = 'A' * 51;
      expect(AppValidators.validateQuantity(longQty), isNotNull);
    });
  });

  group('AppValidators.validateOtp', () {
    test('rejects null', () {
      expect(AppValidators.validateOtp(null), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateOtp(''), isNotNull);
    });

    test('rejects non-numeric OTP', () {
      expect(AppValidators.validateOtp('abcdef'), isNotNull);
    });

    test('rejects OTP shorter than 6 digits', () {
      expect(AppValidators.validateOtp('12345'), isNotNull);
    });

    test('rejects OTP longer than 6 digits', () {
      expect(AppValidators.validateOtp('1234567'), isNotNull);
    });

    test('accepts valid 6-digit OTP', () {
      expect(AppValidators.validateOtp('123456'), isNull);
      expect(AppValidators.validateOtp('000000'), isNull);
      expect(AppValidators.validateOtp('999999'), isNull);
    });
  });

  group('AppValidators.validateRequired', () {
    test('rejects null', () {
      expect(AppValidators.validateRequired(null, 'Field'), isNotNull);
    });

    test('rejects empty string', () {
      expect(AppValidators.validateRequired('', 'Field'), isNotNull);
    });

    test('rejects whitespace-only string', () {
      expect(AppValidators.validateRequired('   ', 'Field'), isNotNull);
    });

    test('accepts non-empty value', () {
      expect(AppValidators.validateRequired('value', 'Field'), isNull);
    });

    test('includes field name in error message', () {
      final result = AppValidators.validateRequired(null, 'Description');
      expect(result, contains('Description'));
    });
  });
}
