import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:foodconnect/core/enums.dart';
import 'package:foodconnect/features/auth/presentation/providers/auth_providers.dart';
import 'package:foodconnect/features/auth/presentation/views/all_set_view.dart';
import 'package:foodconnect/models/user_model.dart';

void main() {
  testWidgets('AllSetView displays dynamically supplied user details', (
    tester,
  ) async {
    final user = UserModel(
      userId: 'test-uid-123',
      name: 'Aditi Rao',
      email: 'aditi@example.com',
      phone: '9876543210',
      role: UserRole.donor,
      organizationName: 'Bangalore Food Bank',
      verificationStatus: VerificationStatus.pending,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream<firebase_auth.User?>.value(null),
          ),
          userProfileProvider.overrideWith(
            (ref) async => user,
          ),
          emailVerifiedProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          home: AllSetView(user: user),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text("You're all set!"), findsOneWidget);

    // Verify Name is dynamically displayed (NOT Rahul Sharma)
    expect(find.text('Aditi Rao'), findsOneWidget);
    expect(find.text('Rahul Sharma'), findsNothing);

    // Verify Subtitle contains role & org
    expect(find.text('Donor • Bangalore Food Bank'), findsOneWidget);

    // Verify Status chip
    expect(find.text('Verification Pending'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Continue to Food Connect'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });
}
