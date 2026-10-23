import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/auth_repository_interface.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final emailVerifiedProvider = StateProvider<bool>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  return authUser?.emailVerified ?? false;
});

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;

  final repository = ref.read(authRepositoryProvider);
  final result = await repository.fetchUserProfile(authState.uid);

  return result.fold((profile) => profile, (error) => null);
});
