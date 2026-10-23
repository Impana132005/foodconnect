import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:foodconnect/app/app.dart';
import 'package:foodconnect/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:foodconnect/features/auth/presentation/providers/auth_providers.dart';
import 'package:foodconnect/core/result.dart';
import 'package:foodconnect/models/user_model.dart';

class MockAuthRepository implements IAuthRepository {
  @override
  Stream<firebase_auth.User?> get authStateChanges => const Stream.empty();

  @override
  String? get currentUid => null;

  @override
  Future<Result<UserModel, String>> login(String email, String password) async {
    return const Failure('Mock failure');
  }

  @override
  Future<Result<UserModel, String>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? organizationName,
  }) async {
    return const Failure('Mock failure');
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
    return const Failure('Mock failure');
  }

  @override
  Future<Result<UserModel, String>> fetchUserProfile(String uid) async {
    return const Failure('Mock failure');
  }

  @override
  Future<Result<void, String>> sendEmailVerification() async {
    return const Success(null);
  }

  @override
  Future<Result<void, String>> sendPasswordResetEmail(String email) async {
    return const Success(null);
  }

  @override
  Future<Result<void, String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Success(null);
  }

  @override
  Future<firebase_auth.User?> reloadUser() async {
    return null;
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('App displays splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: const FoodConnectApp(),
      ),
    );

    await tester.pump();

    // Verify that the splash screen shows the brand title
    expect(find.text('Surplus'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });
}
