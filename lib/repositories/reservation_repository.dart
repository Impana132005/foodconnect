import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/reservation_model.dart';

abstract class IReservationRepository {
  /// HARD BOUNDARY: Calls the authoritative server-side `reserveFood` Callable Cloud Function.
  /// Clients MUST NOT attempt to create reservations directly in Firestore.
  Future<Result<Reservation, String>> reserveFood(String foodId);

  Future<Result<void, String>> cancelReservation({
    required String reservationId,
    required String foodId,
    required String receiverId,
  });

  Future<Result<void, String>> verifyOtp({
    required String reservationId,
    required String enteredOtp,
    required String receiverId,
  });

  Future<Result<void, String>> completeReservation({
    required String reservationId,
    required String foodId,
    required String donorId,
  });

  Future<Result<List<Reservation>, String>> getReceiverReservations(
    String receiverId,
  );
  Future<Result<List<Reservation>, String>> getDonorReservations(
    String donorId,
  );
  Future<Result<Reservation, String>> getReservationById(String reservationId);
  Stream<Reservation?> streamReservation(String reservationId);
}

class ReservationRepository implements IReservationRepository {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  ReservationRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reservationsCollection =>
      _firestore.collection(AppConstants.reservationsCollection);

  @override
  Future<Result<Reservation, String>> reserveFood(String foodId) async {
    try {
      AppLogger.info('Calling reserveFood Cloud Function for foodId: $foodId');

      // HARD BOUNDARY: Callable Cloud Function execution ONLY
      final callable = _functions.httpsCallable('reserveFood');
      final response = await callable.call<Map<String, dynamic>>({
        'foodId': foodId,
      });

      final data = Map<String, dynamic>.from(response.data);
      final reservation = Reservation.fromJson(data);

      AppLogger.info(
        'Successfully reserved food via server: ${reservation.reservationId}',
      );
      return Success(reservation);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('reserveFood Cloud Function error: ${e.code}', e);
      String userMessage = 'Failed to reserve food. Please try again.';
      switch (e.message) {
        case 'already-reserved':
          userMessage = 'Someone just reserved this food.';
          break;
        case 'expired':
          userMessage = 'This food has expired.';
          break;
        case "You can't reserve your own donation.":
          userMessage = "You can't reserve your own donation.";
          break;
        default:
          if (e.code == 'already-exists') {
            userMessage = 'Someone just reserved this food.';
          } else if (e.code == 'not-found') {
            userMessage = 'This food item is no longer available.';
          } else if (e.code == 'permission-denied') {
            userMessage = e.message ?? 'Only receivers can reserve food.';
          }
      }
      return Failure(userMessage);
    } catch (e, stack) {
      AppLogger.error('Unexpected reservation error', e, stack);
      return Failure(
        'Unexpected connection error during reservation: ${e.toString()}',
      );
    }
  }

  @override
  Future<Result<void, String>> cancelReservation({
    required String reservationId,
    required String foodId,
    required String receiverId,
  }) async {
    try {
      AppLogger.info('Calling cancelReservation Cloud Function for: $reservationId');
      final callable = _functions.httpsCallable('cancelReservation');
      await callable.call<Map<String, dynamic>>({
        'reservationId': reservationId,
      });
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('cancelReservation Cloud Function error: ${e.code}', e);
      String userMessage = 'Cancellation failed. Please try again.';
      switch (e.message) {
        case 'already-cancelled':
          userMessage = 'This reservation is already cancelled.';
          break;
        case 'completed':
          userMessage = 'Cannot cancel a completed reservation.';
          break;
        case 'expired':
          userMessage = 'This reservation has already expired.';
          break;
        case 'otp-verified':
          userMessage = 'Cannot cancel after the OTP has been verified.';
          break;
        default:
          if (e.code == 'not-found') {
            userMessage = 'Reservation not found.';
          } else if (e.code == 'permission-denied') {
            userMessage = e.message ?? 'Only the receiver can cancel.';
          }
      }
      return Failure(userMessage);
    } catch (e, stack) {
      AppLogger.error('Failed to cancel reservation', e, stack);
      return Failure('Cancellation failed due to a network error.');
    }
  }

  @override
  Future<Result<void, String>> verifyOtp({
    required String reservationId,
    required String enteredOtp,
    required String receiverId,
  }) async {
    try {
      AppLogger.info(
        'Calling verifyOtp Cloud Function for reservationId: $reservationId',
      );

      final callable = _functions.httpsCallable('verifyOtp');
      await callable.call<Map<String, dynamic>>({
        'reservationId': reservationId,
        'otp': enteredOtp.trim(),
      });

      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('verifyOtp Cloud Function error: ${e.code}', e);
      return Failure(e.message ?? 'OTP verification failed. Please try again.');
    } catch (e, stack) {
      AppLogger.error('Unexpected OTP verification error', e, stack);
      return Failure('OTP verification failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<void, String>> completeReservation({
    required String reservationId,
    required String foodId,
    required String donorId,
  }) async {
    try {
      AppLogger.info('Calling completeReservation Cloud Function for: $reservationId');
      final callable = _functions.httpsCallable('completeReservation');
      await callable.call<Map<String, dynamic>>({
        'reservationId': reservationId,
      });
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error('completeReservation Cloud Function error: ${e.code}', e);
      String userMessage = 'Completion failed. Please try again.';
      switch (e.message) {
        case 'already-completed':
          userMessage = 'This handover is already completed.';
          break;
        case 'cancelled':
          userMessage = 'Cannot complete a cancelled reservation.';
          break;
        case 'expired':
          userMessage = 'This reservation has expired.';
          break;
        case 'otp-not-verified':
          userMessage = 'The receiver must verify the OTP first.';
          break;
        default:
          if (e.code == 'not-found') {
            userMessage = 'Reservation not found.';
          } else if (e.code == 'permission-denied') {
            userMessage = e.message ?? 'Only the donor can complete this.';
          }
      }
      return Failure(userMessage);
    } catch (e, stack) {
      AppLogger.error('Failed to complete reservation', e, stack);
      return Failure('Completion failed due to a network error.');
    }
  }

  @override
  Future<Result<List<Reservation>, String>> getReceiverReservations(
    String receiverId,
  ) async {
    try {
      final snapshot = await _reservationsCollection
          .where('receiverId', isEqualTo: receiverId)
          .orderBy('reservedAt', descending: true)
          .get();

      final reservations = snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
      return Success(reservations);
    } catch (e, stack) {
      AppLogger.error('Failed to fetch receiver reservations', e, stack);
      return Failure('Failed to load reservations: ${e.toString()}');
    }
  }

  @override
  Future<Result<List<Reservation>, String>> getDonorReservations(
    String donorId,
  ) async {
    try {
      final snapshot = await _reservationsCollection
          .where('donorId', isEqualTo: donorId)
          .orderBy('reservedAt', descending: true)
          .get();

      final reservations = snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data(), doc.id))
          .toList();
      return Success(reservations);
    } catch (e, stack) {
      AppLogger.error('Failed to fetch donor reservations', e, stack);
      return Failure('Failed to load donor reservations: ${e.toString()}');
    }
  }

  @override
  Future<Result<Reservation, String>> getReservationById(
    String reservationId,
  ) async {
    try {
      final doc = await _reservationsCollection.doc(reservationId).get();
      if (!doc.exists || doc.data() == null) {
        return const Failure('Reservation not found.');
      }
      return Success(Reservation.fromMap(doc.data()!, doc.id));
    } catch (e, stack) {
      AppLogger.error('Failed to fetch reservation by ID', e, stack);
      return Failure('Error fetching reservation: ${e.toString()}');
    }
  }

  @override
  Stream<Reservation?> streamReservation(String reservationId) {
    return _reservationsCollection.doc(reservationId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Reservation.fromMap(doc.data()!, doc.id);
    });
  }
}
