import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/enums.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/views/forgot_password_view.dart';
import '../features/auth/presentation/views/login_view.dart';
import '../features/auth/presentation/views/register_view.dart';
import '../features/auth/presentation/views/verify_email_otp_view.dart';
import '../features/auth/presentation/views/verify_email_view.dart';
import '../features/auth/presentation/views/all_set_view.dart';
import '../models/user_model.dart';
import '../features/donor/presentation/views/donor_dashboard_view.dart';
import '../features/donor/presentation/views/donor_food_details_view.dart';
import '../features/donor/presentation/views/drop_and_done_view.dart';
import '../features/food/presentation/views/food_details_view.dart';
import '../features/food/presentation/views/post_food_view.dart';
import '../features/profile/presentation/views/change_password_view.dart';
import '../features/profile/presentation/views/profile_view.dart';
import '../features/receiver/presentation/views/receiver_dashboard_view.dart';
import '../features/reservation/presentation/views/my_reservations_view.dart';
import '../features/reservation/presentation/views/reservation_view.dart';
import '../views/splash_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String verifyEmailOtp = '/verify-email-otp';
  static const String verifyEmail = '/verify-email';
  static const String profile = '/profile';
  static const String donorDashboard = '/donor-dashboard';
  static const String postFood = '/post-food';
  static const String donorFoodDetails = '/donor-food-details';
  static const String receiverDashboard = '/receiver-dashboard';
  static const String foodDetails = '/food-details';
  static const String reservation = '/reservation';
  static const String myReservations = '/my-reservations';
  static const String dropAndDone = '/drop-and-done';
  static const String allSet = '/all-set';
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = RouterNotifier(ref);
  ref.onDispose(() {
    routerNotifier.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final userProfileAsync = ref.read(userProfileProvider);

      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.verifyEmailOtp;
      final isGoingToVerifyEmail =
          state.matchedLocation == AppRoutes.verifyEmail;
      final isGoingToAllSet =
          state.matchedLocation == AppRoutes.allSet;

      // 0. If authState is still loading initial auth status, stay on splash or show splash
      if (authState.isLoading) {
        return isGoingToSplash ? null : AppRoutes.splash;
      }

      final firebaseUser = authState.value;
      final isLoggedIn = firebaseUser != null;
      final isEmailVerified =
          ref.read(emailVerifiedProvider) ||
          (firebaseUser?.emailVerified ?? false);

      // 1. If not logged in, route to Login page (unless already on Auth screen)
      if (!isLoggedIn) {
        if (isGoingToAuth) {
          return null;
        }
        return AppRoutes.login;
      }

      // 2. If logged in but email is NOT verified, enforce verify email screen
      if (!isEmailVerified) {
        if (isGoingToAllSet) {
          return null;
        }
        if (!isGoingToVerifyEmail) {
          return AppRoutes.verifyEmail;
        }
        return null;
      }

      // 3. If logged in and email IS verified, but trying to view verify screen or auth screens or splash:
      if (isGoingToVerifyEmail || isGoingToAuth || isGoingToSplash) {
        if (userProfileAsync.isLoading) {
          return null; // Stay on current screen (login, register, or splash) while profile loads
        }
        final profile = userProfileAsync.value;
        if (profile == null) {
          return AppRoutes.login;
        }
        return profile.role == UserRole.donor
            ? AppRoutes.donorDashboard
            : AppRoutes.receiverDashboard;
      }

      // 4. If profile is still loading for protected routes, show splash/loading
      if (userProfileAsync.isLoading) {
        return AppRoutes.splash;
      }

      final profile = userProfileAsync.value;

      // If profile could not be loaded, logout and redirect to login
      if (profile == null) {
        return AppRoutes.login;
      }

      // 5. User is logged in with profile details loaded & email verified
      final isDonor = profile.role == UserRole.donor;

      // Role-based routing guard (cross-role leak prevention)
      final matched = state.matchedLocation;
      if (isDonor) {
        final donorRoutesPrefixes = [
          AppRoutes.donorDashboard,
          AppRoutes.postFood,
          AppRoutes.donorFoodDetails,
          AppRoutes.dropAndDone,
          AppRoutes.profile,
          AppRoutes.changePassword,
          AppRoutes.allSet,
        ];
        final isAllowed = donorRoutesPrefixes.any(
          (prefix) => matched.startsWith(prefix),
        );
        if (!isAllowed) {
          return AppRoutes.donorDashboard;
        }
      } else {
        final receiverRoutesPrefixes = [
          AppRoutes.receiverDashboard,
          AppRoutes.foodDetails,
          AppRoutes.reservation,
          AppRoutes.myReservations,
          AppRoutes.profile,
          AppRoutes.changePassword,
          AppRoutes.allSet,
        ];
        final isAllowed = receiverRoutesPrefixes.any(
          (prefix) => matched.startsWith(prefix),
        );
        if (!isAllowed) {
          return AppRoutes.receiverDashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoutes.allSet,
        builder: (context, state) => AllSetView(
          user: state.extra as UserModel?,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordView(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailView(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmailOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VerifyEmailOtpView(
            email: extra['email'] ?? '',
            name: extra['name'] ?? '',
            phone: extra['phone'] ?? '',
            password: extra['password'] ?? '',
            role: extra['role'] ?? 'receiver',
            initialOtp: extra['initialOtp'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(
        path: AppRoutes.donorDashboard,
        builder: (context, state) => const DonorDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.postFood,
        builder: (context, state) => const PostFoodView(),
      ),
      GoRoute(
        path: '${AppRoutes.donorFoodDetails}/:foodId',
        builder: (context, state) {
          final foodId = state.pathParameters['foodId'] ?? '';
          return DonorFoodDetailsView(foodId: foodId);
        },
      ),
      GoRoute(
        path: AppRoutes.receiverDashboard,
        builder: (context, state) => const ReceiverDashboardView(),
      ),
      GoRoute(
        path: '${AppRoutes.foodDetails}/:foodId',
        builder: (context, state) {
          final foodId = state.pathParameters['foodId'] ?? '';
          return FoodDetailsView(foodId: foodId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.reservation}/:reservationId',
        builder: (context, state) {
          final reservationId = state.pathParameters['reservationId'] ?? '';
          return ReservationView(reservationId: reservationId);
        },
      ),
      GoRoute(
        path: AppRoutes.myReservations,
        builder: (context, state) => const MyReservationsView(),
      ),
      GoRoute(
        path: '${AppRoutes.dropAndDone}/:reservationId',
        builder: (context, state) {
          final reservationId = state.pathParameters['reservationId'] ?? '';
          return DropAndDoneView(reservationId: reservationId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri}')),
    ),
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _disposed = false;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      _scheduleNotify();
    });
    _ref.listen(emailVerifiedProvider, (previous, next) {
      _scheduleNotify();
    });
    _ref.listen(userProfileProvider, (previous, next) {
      _scheduleNotify();
    });
  }

  void _scheduleNotify() {
    if (_disposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
