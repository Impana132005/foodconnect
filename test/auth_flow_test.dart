import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/user_model.dart';
import 'package:foodconnect/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Mock test implementation of IAuthRepository for Phase 2 test suite
class MockAuthRepository implements IAuthRepository {
  final Map<String, UserModel> usersDb = {};
  final Map<String, String> passwordsDb = {};
  final Set<String> verifiedEmails = {};
  final List<String> sentVerificationEmails = [];

  String? _currentUid;
  bool _networkError = false;
  bool _accountDisabled = false;
  final _authStateController =
      StreamController<firebase_auth.User?>.broadcast();

  void setNetworkError(bool value) => _networkError = value;
  void setAccountDisabled(bool value) => _accountDisabled = value;
  void markEmailVerifiedExternally(String email) => verifiedEmails.add(email);

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _authStateController.stream;

  @override
  String? get currentUid => _currentUid;

  @override
  Future<Result<UserModel, String>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? organizationName,
  }) async {
    if (_networkError) {
      return const Failure(
        'Network connection failed. Please check your internet connection.',
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if (usersDb.values.any((u) => u.email.toLowerCase() == cleanEmail)) {
      return const Failure('An account already exists for this email address.');
    }
    if (password.length < 6) {
      return const Failure(
        'Password is too weak. Please use at least 6 characters.',
      );
    }

    final uid =
        'uid_${DateTime.now().millisecondsSinceEpoch}_${cleanEmail.hashCode}';
    final now = DateTime.now();
    final profile = UserModel(
      userId: uid,
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      role: UserRole.fromString(role),
      organizationName: organizationName ?? '',
      verificationStatus: VerificationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    usersDb[uid] = profile;
    passwordsDb[cleanEmail] = password;
    _currentUid = uid;

    // Send initial verification email
    sentVerificationEmails.add(cleanEmail);
    return Success(profile);
  }

  @override
  Future<Result<UserModel, String>> login(String email, String password) async {
    if (_networkError) {
      return const Failure(
        'Network connection failed. Please check your internet connection.',
      );
    }
    if (_accountDisabled) {
      return const Failure(
        'This user account has been disabled. Please contact support.',
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if (!passwordsDb.containsKey(cleanEmail)) {
      return const Failure(
        'No account found with this email. Please check or register.',
      );
    }
    if (passwordsDb[cleanEmail] != password) {
      return const Failure('Incorrect password. Please try again.');
    }

    final user = usersDb.values.firstWhere(
      (u) => u.email.toLowerCase() == cleanEmail,
    );
    _currentUid = user.userId;
    return Success(user);
  }

  @override
  Future<Result<void, String>> sendEmailVerification() async {
    if (_networkError) {
      return const Failure(
        'Network error. Please check your internet connection.',
      );
    }
    if (_currentUid == null || !usersDb.containsKey(_currentUid)) {
      return const Failure('No authenticated user found.');
    }
    final email = usersDb[_currentUid]!.email;
    sentVerificationEmails.add(email);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> sendPasswordResetEmail(String email) async {
    if (_networkError) {
      return const Failure(
        'Couldn\'t send the reset email. Check your connection and try again.',
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const Failure('Enter a valid email address.');
    }
    sentVerificationEmails.add(cleanEmail);
    return const Success(null);
  }

  @override
  Future<Result<void, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_networkError) {
      return const Failure(
        'Couldn\'t change your password. Check your connection and try again.',
      );
    }
    if (_currentUid == null || !usersDb.containsKey(_currentUid)) {
      return const Failure('No authenticated user found. Please sign in again.');
    }
    final email = usersDb[_currentUid]!.email.toLowerCase();
    if (passwordsDb[email] != currentPassword) {
      return const Failure('Your current password is incorrect.');
    }
    if (newPassword.length < 6) {
      return const Failure('Password is too weak. Please use at least 6 characters.');
    }
    passwordsDb[email] = newPassword;
    return const Success(null);
  }

  @override
  Future<firebase_auth.User?> reloadUser() async {
    return null;
  }

  bool isCurrentEmailVerified() {
    if (_currentUid == null) return false;
    final user = usersDb[_currentUid];
    if (user == null) return false;
    return verifiedEmails.contains(user.email);
  }

  @override
  Future<Result<UserModel, String>> fetchUserProfile(String uid) async {
    if (_networkError) {
      return const Failure('Connection issue: Failed to load profile.');
    }
    if (usersDb.containsKey(uid)) {
      return Success(usersDb[uid]!);
    }
    // Missing profile recovery
    final recovered = UserModel(
      userId: uid,
      name: 'Recovered User',
      email: 'recovered@example.com',
      phone: '',
      role: UserRole.receiver,
      organizationName: '',
      verificationStatus: VerificationStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    usersDb[uid] = recovered;
    return Success(recovered);
  }

  @override
  Future<void> logout() async {
    _currentUid = null;
  }

  @override
  Future<Result<String, String>> sendEmailOtp(String email) async {
    return const Success('123456');
  }

  @override
  Future<Result<UserModel, String>> verifyEmailOtp({
    required String email,
    required String otp,
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    return register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
  }
}

void main() {
  group('Phase 2 Authentication Flows Test Suite', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    test(
      '1. New donor registration succeeds, sends verification email, stores uid',
      () async {
        final result = await authRepo.register(
          name: 'Green Harvest NGO',
          email: 'donor@greenharvest.org',
          phone: '+15551234567',
          password: 'securePassword123',
          role: 'donor',
          organizationName: 'Green Harvest Organization',
        );

        expect(result.isSuccess, isTrue);
        final profile = (result as Success<UserModel, String>).value;
        expect(profile.email, 'donor@greenharvest.org');
        expect(profile.role, UserRole.donor);
        expect(profile.organizationName, 'Green Harvest Organization');
        expect(profile.verificationStatus, VerificationStatus.pending);
        expect(
          authRepo.sentVerificationEmails,
          contains('donor@greenharvest.org'),
        );
        expect(authRepo.currentUid, profile.userId);
      },
    );

    test(
      '2. Duplicate registration is rejected with friendly message',
      () async {
        await authRepo.register(
          name: 'Receiver One',
          email: 'receiver@charity.org',
          phone: '+15559876543',
          password: 'password123',
          role: 'receiver',
        );

        final duplicateResult = await authRepo.register(
          name: 'Receiver Duplicate',
          email: 'receiver@charity.org',
          phone: '+15550001111',
          password: 'anotherPassword123',
          role: 'receiver',
        );

        expect(duplicateResult.isFailure, isTrue);
        expect(
          (duplicateResult as Failure<UserModel, String>).error,
          'An account already exists for this email address.',
        );
      },
    );

    test('3. Weak password registration is rejected', () async {
      final result = await authRepo.register(
        name: 'User Short Pass',
        email: 'user@test.org',
        phone: '+15551112222',
        password: '123',
        role: 'receiver',
      );

      expect(result.isFailure, isTrue);
      expect(
        (result as Failure<UserModel, String>).error,
        'Password is too weak. Please use at least 6 characters.',
      );
    });

    test('4. Resend verification email delivers new email', () async {
      await authRepo.register(
        name: 'Receiver Two',
        email: 'receiver2@test.com',
        phone: '+15553334444',
        password: 'password123',
        role: 'receiver',
      );

      expect(authRepo.sentVerificationEmails.length, 1);

      final resendResult = await authRepo.sendEmailVerification();
      expect(resendResult.isSuccess, isTrue);
      expect(authRepo.sentVerificationEmails.length, 2);
      expect(authRepo.sentVerificationEmails[1], 'receiver2@test.com');
    });

    test('5. Login before verification detects unverified status', () async {
      await authRepo.register(
        name: 'Unverified Receiver',
        email: 'unverified@test.com',
        phone: '+15554445555',
        password: 'password123',
        role: 'receiver',
      );

      // Login succeeds at auth layer
      final loginResult = await authRepo.login(
        'unverified@test.com',
        'password123',
      );
      expect(loginResult.isSuccess, isTrue);

      // Verification check identifies email is not verified yet
      expect(authRepo.isCurrentEmailVerified(), isFalse);
    });

    test(
      '6. External email verification is recognized on reload/check',
      () async {
        await authRepo.register(
          name: 'Externally Verified User',
          email: 'verified@test.com',
          phone: '+15555556666',
          password: 'password123',
          role: 'donor',
        );

        expect(authRepo.isCurrentEmailVerified(), isFalse);

        // User clicks link in external email client
        authRepo.markEmailVerifiedExternally('verified@test.com');

        // Subsequent check confirms verified status
        expect(authRepo.isCurrentEmailVerified(), isTrue);
      },
    );

    test(
      '7. Login with invalid password fails with sanitized error message',
      () async {
        await authRepo.register(
          name: 'Valid User',
          email: 'valid@test.com',
          phone: '+15556667777',
          password: 'correctPassword',
          role: 'receiver',
        );

        final wrongPassResult = await authRepo.login(
          'valid@test.com',
          'wrongPassword',
        );
        expect(wrongPassResult.isFailure, isTrue);
        expect(
          (wrongPassResult as Failure<UserModel, String>).error,
          'Incorrect password. Please try again.',
        );
      },
    );

    test(
      '8. Login with non-existent email fails with sanitized error message',
      () async {
        final notFoundResult = await authRepo.login(
          'nonexistent@test.com',
          'password123',
        );
        expect(notFoundResult.isFailure, isTrue);
        expect(
          (notFoundResult as Failure<UserModel, String>).error,
          'No account found with this email. Please check or register.',
        );
      },
    );

    test(
      '9. Missing Firestore profile document recovers without forcing registration',
      () async {
        // Simulate authenticated user with missing document
        const orphanUid = 'orphan_uid_123';
        final profileResult = await authRepo.fetchUserProfile(orphanUid);

        expect(profileResult.isSuccess, isTrue);
        final profile = (profileResult as Success<UserModel, String>).value;
        expect(profile.userId, orphanUid);
        expect(profile.role, UserRole.receiver);
      },
    );

    test('10. Logout clears active session state', () async {
      await authRepo.register(
        name: 'Logout Test User',
        email: 'logout@test.com',
        phone: '+15557778888',
        password: 'password123',
        role: 'donor',
      );

      expect(authRepo.currentUid, isNotNull);

      await authRepo.logout();
      expect(authRepo.currentUid, isNull);
    });

    test(
      '11. Network failure returns user-friendly network error without raw exception',
      () async {
        authRepo.setNetworkError(true);

        final registerResult = await authRepo.register(
          name: 'Net Fail',
          email: 'net@test.com',
          phone: '+15559990000',
          password: 'password123',
          role: 'receiver',
        );

        expect(registerResult.isFailure, isTrue);
        expect(
          (registerResult as Failure<UserModel, String>).error,
          contains('Network connection failed'),
        );
      },
    );

    test('12. Password reset: Valid email sends reset link', () async {
      final resetResult = await authRepo.sendPasswordResetEmail('reset@test.com');
      expect(resetResult.isSuccess, isTrue);
      expect(authRepo.sentVerificationEmails, contains('reset@test.com'));
    });

    test('13. Password reset: Empty email returns validation failure', () async {
      final resetResult = await authRepo.sendPasswordResetEmail('   ');
      expect(resetResult.isFailure, isTrue);
      expect(
        (resetResult as Failure<void, String>).error,
        'Enter a valid email address.',
      );
    });

    test(
      '14. Change password: Valid current password updates to new password',
      () async {
        await authRepo.register(
          name: 'Change Pass User',
          email: 'changepass@test.com',
          phone: '+15554443333',
          password: 'oldPassword123',
          role: 'donor',
        );

        final changeResult = await authRepo.changePassword(
          currentPassword: 'oldPassword123',
          newPassword: 'newPassword456',
        );
        expect(changeResult.isSuccess, isTrue);

        // Verify login with new password succeeds
        final newLoginResult = await authRepo.login(
          'changepass@test.com',
          'newPassword456',
        );
        expect(newLoginResult.isSuccess, isTrue);
      },
    );

    test(
      '15. Change password: Wrong current password returns friendly error',
      () async {
        await authRepo.register(
          name: 'Change Pass User 2',
          email: 'changepass2@test.com',
          phone: '+15554443332',
          password: 'correctOldPass',
          role: 'receiver',
        );

        final changeResult = await authRepo.changePassword(
          currentPassword: 'wrongOldPassword',
          newPassword: 'newPassword456',
        );
        expect(changeResult.isFailure, isTrue);
        expect(
          (changeResult as Failure<void, String>).error,
          'Your current password is incorrect.',
        );
      },
    );
  });
}
