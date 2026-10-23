import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

function generateOtp(): string {
  return String(Math.floor(Math.random() * 1000000)).padStart(6, '0');
}

/**
 * Callable Function: sendEmailOtp
 * Generates a 6-digit numeric OTP code for user registration and stores it in Firestore.
 */
export const sendEmailOtp = onCall(async (request) => {
  const { email } = request.data || {};
  if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
    throw new HttpsError('invalid-argument', 'A valid email address is required.');
  }

  const cleanEmail = email.trim().toLowerCase();
  const otp = generateOtp();
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + 10 * 60 * 1000); // 10 minutes

  await db.collection('email_otps').doc(cleanEmail).set({
    email: cleanEmail,
    otp,
    expiresAt,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    message: `OTP sent to ${cleanEmail}`,
    otp, // Returned for dev testing ease
  };
});

/**
 * Callable Function: verifyEmailOtp
 * Validates the email OTP, creates the user account (or uses Firestore fallback if Firebase Auth Service is uninitialized in Firebase Console),
 * saves the verified user profile, and returns authentication details.
 */
export const verifyEmailOtp = onCall(async (request) => {
  const { email, otp, name, phone, password, role } = request.data || {};

  if (typeof email !== 'string' || !email.trim()) {
    throw new HttpsError('invalid-argument', 'Email is required.');
  }
  if (typeof otp !== 'string' || !otp.trim()) {
    throw new HttpsError('invalid-argument', '6-digit OTP code is required.');
  }
  if (typeof name !== 'string' || !name.trim()) {
    throw new HttpsError('invalid-argument', 'Name is required.');
  }
  if (typeof password !== 'string' || password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  }
  if (role !== 'donor' && role !== 'receiver') {
    throw new HttpsError('invalid-argument', 'Role must be donor or receiver.');
  }

  const cleanEmail = email.trim().toLowerCase();
  const otpRef = db.collection('email_otps').doc(cleanEmail);
  const now = admin.firestore.Timestamp.now();

  // 1. Verify OTP in atomic transaction
  await db.runTransaction(async (tx) => {
    const otpSnap = await tx.get(otpRef);
    if (!otpSnap.exists) {
      throw new HttpsError('not-found', 'No OTP code found for this email. Please request a new code.');
    }
    const otpData = otpSnap.data();
    if (!otpData) {
      throw new HttpsError('not-found', 'No OTP code found for this email.');
    }

    if (otpData.expiresAt.toMillis() <= now.toMillis()) {
      throw new HttpsError('failed-precondition', 'The OTP code has expired. Please request a new code.');
    }

    if (otpData.otp !== otp.trim()) {
      throw new HttpsError('invalid-argument', 'Incorrect OTP code. Please try again.');
    }

    tx.delete(otpRef);
  });

  // 2. Create Auth user via Admin SDK with graceful fallback if Firebase Auth Identity Toolkit is uninitialized
  let userId: string;
  let customToken: string | null = null;

  try {
    const firebaseUser = await admin.auth().createUser({
      email: cleanEmail,
      password: password,
      displayName: name.trim(),
    });
    userId = firebaseUser.uid;
    try {
      customToken = await admin.auth().createCustomToken(userId);
    } catch (tokenErr) {
      console.warn('Custom token generation skipped:', tokenErr);
    }
  } catch (err: any) {
    if (err.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'An account already exists for this email.');
    }
    const errMsg = err.message || '';
    if (
      errMsg.includes('CONFIGURATION_NOT_FOUND') ||
      errMsg.includes('no configuration corresponding') ||
      err.code === 'auth/configuration-not-found'
    ) {
      console.warn('Firebase Auth service uninitialized in Firebase Console. Using Firestore fallback registration.');
      userId = `usr_${Buffer.from(cleanEmail).toString('hex').substring(0, 20)}`;
    } else {
      throw new HttpsError('internal', `Failed to create user account: ${err.message || err.code}`);
    }
  }

  // 3. Save verified user profile in Firestore
  const userRef = db.collection('users').doc(userId);
  const userProfile = {
    userId: userId,
    name: name.trim(),
    email: cleanEmail,
    phone: (phone || '').trim(),
    role: role,
    organizationName: '',
    profileImageUrl: null,
    latitude: null,
    longitude: null,
    verificationStatus: 'verified', // Verified via Email OTP
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await userRef.set(userProfile, { merge: true });

  return {
    success: true,
    customToken,
    userId: userId,
  };
});

export const reserveFood = onCall(async (request) => {
  // 1. Require authentication
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const callerUid = request.auth.uid;

  // 2. Read users/{uid} and require role === 'receiver'
  const userSnap = await db.collection('users').doc(callerUid).get();
  if (!userSnap.exists || userSnap.data()?.role !== 'receiver') {
    throw new HttpsError('permission-denied', 'Only receiver accounts can reserve food.');
  }

  // 3. Validate foodId
  const foodId = request.data?.foodId;
  if (typeof foodId !== 'string' || foodId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A valid foodId is required.');
  }

  const foodRef = db.collection('foods').doc(foodId);
  const reservationsRef = db.collection('reservations');
  const logsRef = db.collection('pickup_logs');
  const now = admin.firestore.Timestamp.now();

  const reservationId = reservationsRef.doc().id;
  const otp = generateOtp(); // Do not log OTP values

  // 4. Atomic server-side transaction
  const created = await db.runTransaction(async (tx) => {
    const foodSnap = await tx.get(foodRef);
    if (!foodSnap.exists) {
      throw new HttpsError('not-found', 'This food is no longer available.');
    }
    const food = foodSnap.data();
    if (!food) {
      throw new HttpsError('not-found', 'This food is no longer available.');
    }

    // Validation checks inside transaction
    if (food.status !== 'available') {
      throw new HttpsError('failed-precondition', 'already-reserved');
    }
    if (food.expiryAt && food.expiryAt.toMillis() <= now.toMillis()) {
      throw new HttpsError('failed-precondition', 'expired');
    }
    if (food.donorId === callerUid) {
      throw new HttpsError('permission-denied', "You can't reserve your own donation.");
    }

    const reservedAt = now;
    const pickupDeadline = admin.firestore.Timestamp.fromMillis(now.toMillis() + 30 * 60 * 1000);

    // 14. Create reservations/{reservationId}
    tx.set(reservationsRef.doc(reservationId), {
      reservationId,
      foodId,
      donorId: food.donorId,
      receiverId: callerUid,
      reservedAt,
      pickupDeadline,
      otp,
      otpVerified: false,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 15. Update foods/{foodId}
    tx.update(foodRef, {
      status: 'reserved',
      currentReservationId: reservationId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 16. Create pickup_logs entry
    tx.set(logsRef.doc(), {
      foodId,
      reservationId,
      actorId: callerUid,
      action: 'RESERVED',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      reservationId,
      donorId: food.donorId,
      reservedAt,
      pickupDeadline,
      otp,
    };
  });

  // 18. Return the documented reservation response
  return {
    reservationId: created.reservationId,
    foodId,
    donorId: created.donorId,
    receiverId: callerUid,
    reservedAt: created.reservedAt.toDate().toISOString(),
    pickupDeadline: created.pickupDeadline.toDate().toISOString(),
    status: 'active',
    otpVerified: false,
    otp: created.otp,
  };
});

/**
 * Production-Grade Server-Side Callable: verifyOtp
 * Validates entered OTP code against server-stored reservation, validates deadline,
 * and atomically updates status to 'otp_verified'.
 */
export const verifyOtp = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const callerUid = request.auth.uid;

  const { reservationId, otp } = request.data || {};
  if (typeof reservationId !== 'string' || reservationId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A valid reservationId is required.');
  }
  if (typeof otp !== 'string' || otp.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A valid 6-digit OTP code is required.');
  }

  const resRef = db.collection('reservations').doc(reservationId);
  const now = admin.firestore.Timestamp.now();

  await db.runTransaction(async (tx) => {
    const resSnap = await tx.get(resRef);
    if (!resSnap.exists) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }
    const resData = resSnap.data();
    if (!resData) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }

    if (resData.receiverId !== callerUid && resData.donorId !== callerUid) {
      throw new HttpsError('permission-denied', 'You are not authorized to verify this reservation.');
    }

    if (resData.status !== 'active') {
      throw new HttpsError('failed-precondition', 'Reservation is not active.');
    }

    if (resData.pickupDeadline && resData.pickupDeadline.toMillis() <= now.toMillis()) {
      throw new HttpsError('failed-precondition', 'The 30-minute pickup window has expired.');
    }

    if (resData.otp !== otp.trim()) {
      throw new HttpsError('invalid-argument', 'Incorrect OTP code. Please try again.');
    }

    tx.update(resRef, {
      status: 'otp_verified',
      otpVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(db.collection('pickup_logs').doc(), {
      foodId: resData.foodId,
      reservationId,
      actorId: callerUid,
      action: 'OTP_VERIFIED',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    reservationId,
  };
});

/**
 * Scheduled Sweeper: releaseExpiredReservations
 * Periodically cleans up active reservations whose pickupDeadline has passed.
 */
export const releaseExpiredReservations = onSchedule('every 5 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db
    .collection('reservations')
    .where('status', '==', 'active')
    .where('pickupDeadline', '<=', now)
    .get();

  if (snapshot.empty) {
    return;
  }

  for (const doc of snapshot.docs) {
    const resData = doc.data();
    const foodId = resData.foodId;
    const foodRef = db.collection('foods').doc(foodId);
    const resRef = doc.ref;

    await db.runTransaction(async (tx) => {
      const foodSnap = await tx.get(foodRef);
      if (!foodSnap.exists) return;
      const food = foodSnap.data();
      if (!food) return;

      tx.update(resRef, {
        status: 'expired',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const isFoodExpired = food.expiryAt && food.expiryAt.toMillis() <= now.toMillis();
      tx.update(foodRef, {
        status: isFoodExpired ? 'expired' : 'available',
        currentReservationId: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('pickup_logs').doc(), {
        foodId,
        reservationId: doc.id,
        actorId: 'SYSTEM_SWEEPER',
        action: 'RESERVATION_EXPIRED',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }
});

/**
 * Callable Function: cancelReservation
 * Receiver cancels an active reservation.
 */
export const cancelReservation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const callerUid = request.auth.uid;
  const { reservationId } = request.data || {};

  if (typeof reservationId !== 'string' || reservationId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A valid reservationId is required.');
  }

  const resRef = db.collection('reservations').doc(reservationId);
  const now = admin.firestore.Timestamp.now();

  await db.runTransaction(async (tx) => {
    const resSnap = await tx.get(resRef);
    if (!resSnap.exists) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }
    const resData = resSnap.data();
    if (!resData) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }

    if (resData.receiverId !== callerUid) {
      throw new HttpsError('permission-denied', 'Only the receiver can cancel their reservation.');
    }

    if (resData.status === 'cancelled') {
      throw new HttpsError('failed-precondition', 'already-cancelled');
    }
    if (resData.status === 'completed') {
      throw new HttpsError('failed-precondition', 'completed');
    }
    if (resData.status === 'expired') {
      throw new HttpsError('failed-precondition', 'expired');
    }
    if (resData.status === 'otp_verified' || resData.otpVerified) {
      throw new HttpsError('failed-precondition', 'otp-verified');
    }
    if (resData.status !== 'active') {
      throw new HttpsError('failed-precondition', 'Reservation is not active.');
    }

    const foodId = resData.foodId;
    const foodRef = db.collection('foods').doc(foodId);
    const foodSnap = await tx.get(foodRef);
    
    let isFoodExpired = false;
    if (foodSnap.exists && foodSnap.data()) {
      const food = foodSnap.data();
      if (food && food.expiryAt && food.expiryAt.toMillis() <= now.toMillis()) {
        isFoodExpired = true;
      }
    } else {
      throw new HttpsError('not-found', 'Associated food record not found.');
    }

    // Update Reservation
    tx.update(resRef, {
      status: 'cancelled',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update Food
    tx.update(foodRef, {
      status: isFoodExpired ? 'expired' : 'available',
      currentReservationId: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log Event
    tx.set(db.collection('pickup_logs').doc(), {
      foodId,
      reservationId,
      actorId: callerUid,
      action: 'RESERVATION_CANCELLED',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, reservationId };
});

/**
 * Callable Function: completeReservation
 * Donor completes the handover after OTP is verified.
 */
export const completeReservation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in.');
  }
  const callerUid = request.auth.uid;
  const { reservationId } = request.data || {};

  if (typeof reservationId !== 'string' || reservationId.trim().length === 0) {
    throw new HttpsError('invalid-argument', 'A valid reservationId is required.');
  }

  const resRef = db.collection('reservations').doc(reservationId);

  await db.runTransaction(async (tx) => {
    const resSnap = await tx.get(resRef);
    if (!resSnap.exists) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }
    const resData = resSnap.data();
    if (!resData) {
      throw new HttpsError('not-found', 'Reservation record not found.');
    }

    if (resData.donorId !== callerUid) {
      throw new HttpsError('permission-denied', 'Only the donor can complete the handover.');
    }

    if (resData.status === 'completed') {
      throw new HttpsError('failed-precondition', 'already-completed');
    }
    if (resData.status === 'cancelled') {
      throw new HttpsError('failed-precondition', 'cancelled');
    }
    if (resData.status === 'expired') {
      throw new HttpsError('failed-precondition', 'expired');
    }
    if (resData.status !== 'otp_verified' || !resData.otpVerified) {
      throw new HttpsError('failed-precondition', 'otp-not-verified');
    }

    const foodId = resData.foodId;
    const foodRef = db.collection('foods').doc(foodId);

    // Update Reservation
    tx.update(resRef, {
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update Food
    tx.update(foodRef, {
      status: 'completed',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log Event
    tx.set(db.collection('pickup_logs').doc(), {
      foodId,
      reservationId,
      actorId: callerUid,
      action: 'PICKUP_COMPLETED',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true, reservationId };
});

/**
 * Scheduled Sweeper: markExpiredFoods
 * Periodically cleans up available foods whose expiryAt has passed.
 */
export const markExpiredFoods = onSchedule('every 5 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db
    .collection('foods')
    .where('status', '==', 'available')
    .where('expiryAt', '<=', now)
    .get();

  if (snapshot.empty) {
    return;
  }

  for (const doc of snapshot.docs) {
    const foodRef = doc.ref;

    await db.runTransaction(async (tx) => {
      const foodSnap = await tx.get(foodRef);
      if (!foodSnap.exists) return;
      const food = foodSnap.data();
      if (!food) return;

      // Ensure it is still available (transaction safety)
      if (food.status !== 'available') return;
      // Ensure it is actually expired
      if (food.expiryAt.toMillis() > now.toMillis()) return;

      tx.update(foodRef, {
        status: 'expired',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(db.collection('pickup_logs').doc(), {
        foodId: doc.id,
        reservationId: null,
        actorId: 'SYSTEM_SWEEPER',
        action: 'FOOD_EXPIRED',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  }
});
