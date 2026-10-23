import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';

abstract class IStorageRepository {
  Future<Result<String, String>> uploadUserAvatar(String uid, File file);
  Future<Result<String, String>> uploadFoodImage(String foodId, File file);
}

class StorageRepository implements IStorageRepository {
  final FirebaseStorage _storage;

  StorageRepository({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<Result<String, String>> uploadUserAvatar(String uid, File file) async {
    try {
      // Enforce 2 MB max size limit
      final sizeInBytes = await file.length();
      if (sizeInBytes > 2 * 1024 * 1024) {
        return const Failure('Profile avatar image must be less than 2 MB.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${AppConstants.userAvatarsPath}/$uid/avatar_$timestamp.jpg';
      final ref = _storage.ref().child(path);

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return Success(downloadUrl);
    } catch (e, stack) {
      AppLogger.error('Failed to upload user avatar', e, stack);
      return Failure('Avatar upload failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<String, String>> uploadFoodImage(
    String foodId,
    File file,
  ) async {
    try {
      // Enforce 5 MB max size limit
      final sizeInBytes = await file.length();
      if (sizeInBytes > 5 * 1024 * 1024) {
        return const Failure('Food photo must be less than 5 MB.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${AppConstants.foodImagesPath}/$foodId/food_$timestamp.jpg';
      final ref = _storage.ref().child(path);

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return Success(downloadUrl);
    } catch (e, stack) {
      AppLogger.error('Failed to upload food image', e, stack);
      return Failure('Food photo upload failed: ${e.toString()}');
    }
  }
}
