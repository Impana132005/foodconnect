import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/pickup_log_repository.dart';

import '../core/logger.dart';

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return StorageRepository();
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return UserRepository();
});

final pickupLogRepositoryProvider = Provider<IPickupLogRepository>((ref) {
  return PickupLogRepository();
});

/// Riverpod Observer for lifecycle and error logging across all providers in debug mode
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider [${provider.name ?? provider.runtimeType}] updated',
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider [${provider.name ?? provider.runtimeType}] failed',
      error,
      stackTrace,
    );
  }
}
