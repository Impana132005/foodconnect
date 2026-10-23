class AppConstants {
  AppConstants._();

  // App Name
  static const String appName = 'Food Connect';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String foodsCollection = 'foods';
  static const String reservationsCollection = 'reservations';
  static const String logsCollection = 'pickup_logs';

  // Storage Paths
  static const String userAvatarsPath = 'users';
  static const String foodImagesPath = 'foods';

  // Cloud Functions & Backend Configuration
  static const String functionsRegion = 'us-central1';
  static const Duration defaultNetworkTimeout = Duration(seconds: 10);

  // Storage Limits
  static const int maxAvatarSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxFoodImageSizeBytes = 5 * 1024 * 1024; // 5 MB

  // Business Rule Constants
  static const Duration cookedFoodExpiryDuration = Duration(hours: 4);
  static const Duration packedFoodExpiryDuration = Duration(hours: 8);
  static const Duration pickupWindowDuration = Duration(minutes: 30);

  // Shared Preferences / Cache Keys
  static const String userRoleKey = 'user_role';

  // Layout Grid Rules
  static const double baseUnit = 4.0;
  static const double screenGutter = 24.0;
  static const double minTouchTarget = 48.0;
}
