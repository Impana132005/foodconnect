import 'package:flutter_test/flutter_test.dart';
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/user_model.dart';
import 'package:foodconnect/repositories/user_repository.dart';

class MockUserRepository implements IUserRepository {
  final Map<String, UserProfile> userDb = {};
  String authenticatedUid = 'user_123';
  bool simulateNetworkError = false;

  @override
  Future<Result<UserProfile, String>> getUserProfile(String uid) async {
    if (simulateNetworkError) {
      return const Failure(
        'Network error. Please check your internet connection.',
      );
    }
    if (uid.isEmpty) {
      return const Failure('Invalid user ID.');
    }
    if (!userDb.containsKey(uid)) {
      return const Failure('User profile not found.');
    }
    return Success(userDb[uid]!);
  }

  @override
  Future<Result<UserProfile, String>> updateUserProfile(
    UserProfile profile,
  ) async {
    if (simulateNetworkError) {
      return const Failure(
        'Network error. Please check your internet connection.',
      );
    }
    if (profile.userId.isEmpty) {
      return const Failure('Invalid user ID.');
    }
    // Security check: User can only update their own profile
    if (profile.userId != authenticatedUid) {
      return const Failure('Unauthorized: You can only edit your own profile.');
    }
    if (!userDb.containsKey(profile.userId)) {
      return const Failure('User profile document does not exist.');
    }

    final existing = userDb[profile.userId]!;
    // Security check: Role, Email, and VerificationStatus cannot be tampered with by client
    final secured = UserProfile(
      userId: existing.userId,
      email: existing.email,
      role: existing.role,
      verificationStatus: existing.verificationStatus,
      name: profile.name.trim(),
      phone: profile.phone.trim(),
      organizationName: profile.organizationName.trim(),
      profileImageUrl: profile.profileImageUrl ?? existing.profileImageUrl,
      latitude: profile.latitude,
      longitude: profile.longitude,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    userDb[profile.userId] = secured;
    return Success(secured);
  }
}

void main() {
  group('Phase 3 User Profile Test Suite', () {
    late MockUserRepository userRepo;

    setUp(() {
      userRepo = MockUserRepository();
      userRepo.userDb['user_123'] = UserProfile(
        userId: 'user_123',
        name: 'Alice Donor',
        email: 'alice@foodrescue.org',
        phone: '+15551112233',
        role: UserRole.donor,
        organizationName: 'Food Rescue Foundation',
        verificationStatus: VerificationStatus.pending,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      userRepo.userDb['user_999'] = UserProfile(
        userId: 'user_999',
        name: 'Bob Receiver',
        email: 'bob@shelter.org',
        phone: '+15554445566',
        role: UserRole.receiver,
        organizationName: 'Hope Shelter',
        verificationStatus: VerificationStatus.verified,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );
    });

    test('1. Profile loads successfully with all fields', () async {
      final result = await userRepo.getUserProfile('user_123');

      expect(result.isSuccess, isTrue);
      final profile = (result as Success<UserProfile, String>).value;
      expect(profile.userId, 'user_123');
      expect(profile.name, 'Alice Donor');
      expect(profile.email, 'alice@foodrescue.org');
      expect(profile.phone, '+15551112233');
      expect(profile.role, UserRole.donor);
      expect(profile.organizationName, 'Food Rescue Foundation');
      expect(profile.verificationStatus, VerificationStatus.pending);
    });

    test(
      '2. Profile edits update name, phone, organization, and coordinates',
      () async {
        final initial =
            (await userRepo.getUserProfile('user_123')
                    as Success<UserProfile, String>)
                .value;

        final updated = initial.copyWith(
          name: 'Alice Smith',
          phone: '+15559998877',
          organizationName: 'Global Food Rescue NGO',
          latitude: 28.6139,
          longitude: 77.2090,
        );

        final updateResult = await userRepo.updateUserProfile(updated);
        expect(updateResult.isSuccess, isTrue);

        final saved = (updateResult as Success<UserProfile, String>).value;
        expect(saved.name, 'Alice Smith');
        expect(saved.phone, '+15559998877');
        expect(saved.organizationName, 'Global Food Rescue NGO');
        expect(saved.latitude, 28.6139);
        expect(saved.longitude, 77.2090);
        expect(saved.role, UserRole.donor); // Role preserved
        expect(saved.email, 'alice@foodrescue.org'); // Email preserved
      },
    );

    test('3. App restart simulates persistent profile retrieval', () async {
      // 1st session edits profile
      final initial =
          (await userRepo.getUserProfile('user_123')
                  as Success<UserProfile, String>)
              .value;
      await userRepo.updateUserProfile(
        initial.copyWith(organizationName: 'Persisted NGO'),
      );

      // Simulate App Restart (new repository instance referencing same storage/DB)
      final newSessionRepo = MockUserRepository();
      newSessionRepo.userDb.addAll(userRepo.userDb);

      final reloaded = await newSessionRepo.getUserProfile('user_123');
      expect(reloaded.isSuccess, isTrue);
      expect(
        (reloaded as Success<UserProfile, String>).value.organizationName,
        'Persisted NGO',
      );
    });

    test(
      '4. Missing profile returns failure gracefully without crash',
      () async {
        final result = await userRepo.getUserProfile('non_existent_uid');

        expect(result.isFailure, isTrue);
        expect(
          (result as Failure<UserProfile, String>).error,
          'User profile not found.',
        );
      },
    );

    test(
      '5. Network failure handles gracefully with friendly error message',
      () async {
        userRepo.simulateNetworkError = true;

        final getResult = await userRepo.getUserProfile('user_123');
        expect(getResult.isFailure, isTrue);
        expect(
          (getResult as Failure<UserProfile, String>).error,
          contains('Network error'),
        );

        final updateResult = await userRepo.updateUserProfile(
          UserProfile(
            userId: 'user_123',
            name: 'Test',
            email: 'test@test.com',
            phone: '',
            role: UserRole.donor,
            organizationName: '',
            verificationStatus: VerificationStatus.pending,
          ),
        );
        expect(updateResult.isFailure, isTrue);
        expect(
          (updateResult as Failure<UserProfile, String>).error,
          contains('Network error'),
        );
      },
    );

    test(
      '6. Unauthorized profile access: cannot edit another user profile',
      () async {
        // Current authenticated user is user_123, attempting to edit user_999
        final targetProfile =
            (await userRepo.getUserProfile('user_999')
                    as Success<UserProfile, String>)
                .value;

        final maliciousUpdate = targetProfile.copyWith(name: 'Hacked Bob');
        final updateResult = await userRepo.updateUserProfile(maliciousUpdate);

        expect(updateResult.isFailure, isTrue);
        expect(
          (updateResult as Failure<UserProfile, String>).error,
          'Unauthorized: You can only edit your own profile.',
        );

        // Verify user_999 was not modified
        final verifyProfile =
            (await userRepo.getUserProfile('user_999')
                    as Success<UserProfile, String>)
                .value;
        expect(verifyProfile.name, 'Bob Receiver');
      },
    );

    test(
      '7. Security: role and verificationStatus cannot be tampered with via copyWith or update',
      () async {
        final initial =
            (await userRepo.getUserProfile('user_123')
                    as Success<UserProfile, String>)
                .value;

        // Maliciously attempt to set verificationStatus to verified
        final attemptedTamper = initial.copyWith(
          verificationStatus: VerificationStatus.verified,
        );

        final result = await userRepo.updateUserProfile(attemptedTamper);
        expect(result.isSuccess, isTrue);

        final saved = (result as Success<UserProfile, String>).value;
        // Repository/Rules enforce original verification status
        expect(saved.verificationStatus, VerificationStatus.pending);
      },
    );
  });
}
