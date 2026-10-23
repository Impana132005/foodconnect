import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/reservation_model.dart';
import '../../../../repositories/reservation_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final reservationRepositoryProvider = Provider<IReservationRepository>((ref) {
  return ReservationRepository();
});

final receiverReservationsProvider =
    FutureProvider.autoDispose.family<List<Reservation>, String>((ref, receiverId) async {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null || receiverId.isEmpty) return [];
      final repository = ref.watch(reservationRepositoryProvider);
      final result = await repository.getReceiverReservations(receiverId);
      return result.fold(
        (reservations) => reservations,
        (error) => throw Exception(error),
      );
    });

final donorReservationsProvider =
    FutureProvider.autoDispose.family<List<Reservation>, String>((ref, donorId) async {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null || donorId.isEmpty) return [];
      final repository = ref.watch(reservationRepositoryProvider);
      final result = await repository.getDonorReservations(donorId);
      return result.fold(
        (reservations) => reservations,
        (error) => throw Exception(error),
      );
    });

final reservationStreamProvider =
    StreamProvider.autoDispose.family<Reservation?, String>((
      ref,
      reservationId,
    ) {
      final authUser = ref.watch(authStateProvider).value;
      if (authUser == null || reservationId.isEmpty) {
        return Stream.value(null);
      }
      final repository = ref.watch(reservationRepositoryProvider);
      return repository.streamReservation(reservationId);
    });
