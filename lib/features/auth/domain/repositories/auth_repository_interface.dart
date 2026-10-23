import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/result.dart';
import '../../../../models/user_model.dart';

abstract class IAuthRepository {
  Stream<firebase_auth.User?> get authStateChanges;
  String? get currentUid;
  Future<Result<UserModel, String>> login(String email, String password);
  Future<Result<UserModel, String>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? organizationName,
  });
  Future<Result<String, String>> sendEmailOtp(String email);
  Future<Result<UserModel, String>> verifyEmailOtp({
    required String email,
    required String otp,
    required String name,
    required String phone,
    required String password,
    required String role,
  });
  Future<Result<void, String>> sendEmailVerification();
  Future<Result<void, String>> sendPasswordResetEmail(String email);
  Future<Result<void, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<firebase_auth.User?> reloadUser();
  Future<Result<UserModel, String>> fetchUserProfile(String uid);
  Future<void> logout();
}
