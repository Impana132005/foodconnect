import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/user_model.dart';

abstract class IUserRepository {
  Future<Result<UserProfile, String>> getUserProfile(String uid);
  Future<Result<UserProfile, String>> updateUserProfile(UserProfile profile);
}

class UserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<UserProfile, String>> getUserProfile(String uid) async {
    try {
      if (uid.isEmpty) {
        return const Failure('Invalid user ID.');
      }

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const Failure('User profile not found.');
      }

      final profile = UserProfile.fromMap(doc.data()!, doc.id);
      return Success(profile);
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting profile: ${e.code}', e);
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return const Failure(
          'Network error. Please check your internet connection.',
        );
      } else if (e.code == 'permission-denied') {
        return const Failure('Unauthorized to access this profile.');
      }
      return Failure(e.message ?? 'Failed to retrieve profile.');
    } catch (e, stack) {
      AppLogger.error('Failed to get user profile', e, stack);
      return Failure('Error retrieving profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<UserProfile, String>> updateUserProfile(
    UserProfile profile,
  ) async {
    try {
      if (profile.userId.isEmpty) {
        return const Failure('Invalid user ID.');
      }

      // Explicitly update only editable fields; role, email, and verificationStatus remain untouched
      final updateData = <String, dynamic>{
        'name': profile.name.trim(),
        'phone': profile.phone.trim(),
        'organizationName': profile.organizationName.trim(),
        'profileImageUrl': profile.profileImageUrl,
        'latitude': profile.latitude,
        'longitude': profile.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(profile.userId)
          .update(updateData);

      AppLogger.info(
        'Successfully updated user profile for: ${profile.userId}',
      );
      return Success(profile);
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating profile: ${e.code}', e);
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        return const Failure(
          'Network error. Please check your internet connection.',
        );
      } else if (e.code == 'permission-denied') {
        return const Failure(
          'Unauthorized: You can only edit your own profile.',
        );
      } else if (e.code == 'not-found') {
        return const Failure('User profile document does not exist.');
      }
      return Failure(e.message ?? 'Failed to update profile.');
    } catch (e, stack) {
      AppLogger.error('Failed to update user profile', e, stack);
      return Failure('Error updating profile: ${e.toString()}');
    }
  }
}
