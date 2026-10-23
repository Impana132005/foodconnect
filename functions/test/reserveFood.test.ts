import { expect } from 'chai';

// -------------------------------------------------------------------
// Pure In-Memory Firestore Mock for 100% Offline Backend Unit Testing
// -------------------------------------------------------------------

class MockDocRef {
  constructor(public collectionName: string, public docId: string, private store: MockFirestoreStore) {}

  async get() {
    const data = this.store.getDoc(this.collectionName, this.docId);
    return {
      exists: !!data,
      data: () => data,
    };
  }

  async update(fields: Record<string, any>) {
    this.store.updateDoc(this.collectionName, this.docId, fields);
  }

  async set(data: Record<string, any>) {
    this.store.setDoc(this.collectionName, this.docId, data);
  }

  async delete() {
    this.store.deleteDoc(this.collectionName, this.docId);
  }
}

class MockCollectionRef {
  constructor(public collectionName: string, private store: MockFirestoreStore) {}

  doc(id?: string) {
    const docId = id || this.store.generateId();
    return new MockDocRef(this.collectionName, docId, this.store);
  }

  where(field: string, op: string, value: any) {
    return {
      get: async () => {
        const docs = this.store.queryDocs(this.collectionName, field, op, value);
        return {
          empty: docs.length === 0,
          docs: docs.map((d) => ({
            id: d.id,
            data: () => d.data,
          })),
        };
      },
      where(field2: string, op2: string, value2: any) {
        return this;
      },
    };
  }
}

class MockFirestoreStore {
  private collections = new Map<string, Map<string, any>>();
  private autoIdCounter = 1;
  private transactionLock: Promise<void> = Promise.resolve();

  generateId() {
    return `auto_id_${this.autoIdCounter++}`;
  }

  getDoc(collection: string, id: string) {
    return this.collections.get(collection)?.get(id);
  }

  setDoc(collection: string, id: string, data: Record<string, any>) {
    if (!this.collections.has(collection)) {
      this.collections.set(collection, new Map());
    }
    const current = this.collections.get(collection)!.get(id) || {};
    this.collections.get(collection)!.set(id, { ...current, ...data });
  }

  updateDoc(collection: string, id: string, fields: Record<string, any>) {
    const current = this.getDoc(collection, id);
    if (current) {
      this.collections.get(collection)!.set(id, { ...current, ...fields });
    }
  }

  deleteDoc(collection: string, id: string) {
    this.collections.get(collection)?.delete(id);
  }

  queryDocs(collection: string, field: string, op: string, value: any) {
    const col = this.collections.get(collection);
    if (!col) return [];
    const results: Array<{ id: string; data: any }> = [];
    col.forEach((data, id) => {
      if (op === '==' && data[field] === value) {
        results.push({ id, data });
      }
    });
    return results;
  }

  async runTransaction<T>(updateFunction: (tx: any) => Promise<T>): Promise<T> {
    const previousLock = this.transactionLock;
    let resolveLock!: () => void;
    this.transactionLock = new Promise<void>((res) => {
      resolveLock = res;
    });

    await previousLock;
    try {
      const tx = {
        get: async (ref: MockDocRef) => ref.get(),
        set: (ref: MockDocRef, data: any) => ref.set(data),
        update: (ref: MockDocRef, fields: any) => ref.update(fields),
        delete: (ref: MockDocRef) => ref.delete(),
      };
      return await updateFunction(tx);
    } finally {
      resolveLock();
    }
  }

  collection(name: string) {
    return new MockCollectionRef(name, this);
  }
}

const mockDb = new MockFirestoreStore();

// -------------------------------------------------------------------
// Simulation of reserveFood Callable
// -------------------------------------------------------------------

async function simulateReserveFood(
  data: { foodId?: unknown },
  context: { auth?: { uid: string } }
) {
  // 1. Require authentication
  if (!context || !context.auth || !context.auth.uid) {
    throw { code: 'unauthenticated', message: 'You must be signed in.' };
  }
  const callerUid = context.auth.uid;

  // 2. Read users/{uid} and require role === 'receiver'
  const userSnap = await mockDb.collection('users').doc(callerUid).get();
  if (!userSnap.exists || userSnap.data()?.role !== 'receiver') {
    throw { code: 'permission-denied', message: 'Only receiver accounts can reserve food.' };
  }

  // 3. Validate foodId
  const foodId = data?.foodId;
  if (typeof foodId !== 'string' || foodId.trim().length === 0) {
    throw { code: 'invalid-argument', message: 'A valid foodId is required.' };
  }

  const foodRef = mockDb.collection('foods').doc(foodId);
  const reservationsRef = mockDb.collection('reservations');
  const logsRef = mockDb.collection('pickup_logs');
  const now = Date.now();

  const reservationId = mockDb.generateId();
  const otp = String(Math.floor(Math.random() * 1000000)).padStart(6, '0');

  // 4. Atomic server-side transaction
  const created = await mockDb.runTransaction(async (tx) => {
    const foodSnap = await tx.get(foodRef);
    if (!foodSnap.exists) {
      throw { code: 'not-found', message: 'This food is no longer available.' };
    }
    const food = foodSnap.data();
    
    if (food.status !== 'available') {
      throw { code: 'failed-precondition', message: 'already-reserved' };
    }
    // Simple numeric expiry check for tests
    if (food.expiryAt && food.expiryAt <= now) {
      throw { code: 'failed-precondition', message: 'expired' };
    }
    if (food.donorId === callerUid) {
      throw { code: 'permission-denied', message: "You can't reserve your own donation." };
    }

    const reservedAt = now;
    const pickupDeadline = now + 30 * 60 * 1000; // +30 mins

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
      createdAt: now,
      updatedAt: now,
    });

    tx.update(foodRef, {
      status: 'reserved',
      currentReservationId: reservationId,
      updatedAt: now,
    });

    tx.set(logsRef.doc(), {
      foodId,
      reservationId,
      actorId: callerUid,
      action: 'RESERVED',
      timestamp: now,
    });

    return {
      reservationId,
      donorId: food.donorId,
      reservedAt,
      pickupDeadline,
      otp,
    };
  });

  return {
    reservationId: created.reservationId,
    foodId,
    donorId: created.donorId,
    receiverId: callerUid,
    reservedAt: new Date(created.reservedAt).toISOString(),
    pickupDeadline: new Date(created.pickupDeadline).toISOString(),
    status: 'active',
    otpVerified: false,
    otp: created.otp,
  };
}


describe('Reservation Backend Phase 8 Suite', () => {
  const donorUid = 'donor_123';
  const receiverUid = 'receiver_456';
  const receiver2Uid = 'receiver_789';
  const validFoodId = 'food_1';
  
  beforeEach(() => {
    // Setup test users
    mockDb.collection('users').doc(donorUid).set({ role: 'donor' });
    mockDb.collection('users').doc(receiverUid).set({ role: 'receiver' });
    mockDb.collection('users').doc(receiver2Uid).set({ role: 'receiver' });
    
    // Setup valid food
    mockDb.collection('foods').doc(validFoodId).set({
      status: 'available',
      donorId: donorUid,
      expiryAt: Date.now() + 60 * 60 * 1000, // 1 hour in future
    });
  });

  it('1. successful reservation', async () => {
    const result = await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: receiverUid } });
    
    expect(result.reservationId).to.be.a('string');
    expect(result.otp).to.match(/^\d{6}$/);
    
    const food = (await mockDb.collection('foods').doc(validFoodId).get()).data();
    expect(food.status).to.equal('reserved');
    expect(food.currentReservationId).to.equal(result.reservationId);
    
    const reservation = (await mockDb.collection('reservations').doc(result.reservationId).get()).data();
    expect(reservation.status).to.equal('active');
    expect(reservation.receiverId).to.equal(receiverUid);
  });

  it('2. already reserved', async () => {
    // Reserve once
    await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: receiverUid } });
    
    // Try again
    try {
      await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: receiver2Uid } });
      expect.fail('Should have thrown already-reserved error');
    } catch (e: any) {
      expect(e.code).to.equal('failed-precondition');
      expect(e.message).to.equal('already-reserved');
    }
  });

  it('3. expired food', async () => {
    const expiredFoodId = 'expired_food';
    mockDb.collection('foods').doc(expiredFoodId).set({
      status: 'available',
      donorId: donorUid,
      expiryAt: Date.now() - 1000, // in the past
    });

    try {
      await simulateReserveFood({ foodId: expiredFoodId }, { auth: { uid: receiverUid } });
      expect.fail('Should have thrown expired error');
    } catch (e: any) {
      expect(e.code).to.equal('failed-precondition');
      expect(e.message).to.equal('expired');
    }
  });

  it('4. unavailable food', async () => {
    const unavailableFoodId = 'unavail_food';
    mockDb.collection('foods').doc(unavailableFoodId).set({
      status: 'completed',
      donorId: donorUid,
      expiryAt: Date.now() + 10000,
    });

    try {
      await simulateReserveFood({ foodId: unavailableFoodId }, { auth: { uid: receiverUid } });
      expect.fail('Should have thrown already-reserved error');
    } catch (e: any) {
      expect(e.code).to.equal('failed-precondition');
    }
  });

  it('5. donor attempts own food', async () => {
    try {
      await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: donorUid } });
      expect.fail('Should have thrown permission-denied error');
    } catch (e: any) {
      expect(e.code).to.equal('permission-denied');
      expect(e.message).to.include('Only receiver accounts can reserve'); // caught by receiver check first
    }
  });
  
  it('5b. donor attempts own food but somehow is a receiver', async () => {
    // Edge case: what if they have receiver role but it is their own food?
    mockDb.collection('users').doc(donorUid).update({ role: 'receiver' });
    try {
      await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: donorUid } });
      expect.fail('Should have thrown permission-denied error');
    } catch (e: any) {
      expect(e.code).to.equal('permission-denied');
      expect(e.message).to.equal("You can't reserve your own donation.");
    }
  });

  it('6. unauthenticated', async () => {
    try {
      await simulateReserveFood({ foodId: validFoodId }, {} as any);
      expect.fail('Should have thrown unauthenticated error');
    } catch (e: any) {
      expect(e.code).to.equal('unauthenticated');
    }
  });

  it('7. wrong role', async () => {
    const randomUid = 'random_guy';
    mockDb.collection('users').doc(randomUid).set({ role: 'admin' });
    try {
      await simulateReserveFood({ foodId: validFoodId }, { auth: { uid: randomUid } });
      expect.fail('Should have thrown permission-denied error');
    } catch (e: any) {
      expect(e.code).to.equal('permission-denied');
      expect(e.message).to.equal('Only receiver accounts can reserve food.');
    }
  });

  it('8. simultaneous reservation race condition', async () => {
    // Both receivers try to reserve at the exact same millisecond
    const req1 = simulateReserveFood({ foodId: validFoodId }, { auth: { uid: receiverUid } });
    const req2 = simulateReserveFood({ foodId: validFoodId }, { auth: { uid: receiver2Uid } });
    
    const results = await Promise.allSettled([req1, req2]);
    
    // Exactly one should succeed, exactly one should fail with failed-precondition
    const successes = results.filter(r => r.status === 'fulfilled');
    const failures = results.filter(r => r.status === 'rejected');
    
    expect(successes.length).to.equal(1);
    expect(failures.length).to.equal(1);
    
    if (failures[0].status === 'rejected') {
      expect(failures[0].reason.code).to.equal('failed-precondition');
    }
  });
});

// -------------------------------------------------------------------
// Simulation of verifyOtp Callable
// -------------------------------------------------------------------
async function simulateVerifyOtp(
  data: { reservationId?: unknown; otp?: unknown },
  context: { auth?: { uid: string } }
) {
  if (!context || !context.auth || !context.auth.uid) {
    throw { code: 'unauthenticated', message: 'You must be signed in.' };
  }
  const callerUid = context.auth.uid;

  const { reservationId, otp } = data || {};
  if (typeof reservationId !== 'string' || reservationId.trim().length === 0) {
    throw { code: 'invalid-argument', message: 'A valid reservationId is required.' };
  }
  if (typeof otp !== 'string' || otp.trim().length === 0) {
    throw { code: 'invalid-argument', message: 'A valid 6-digit OTP code is required.' };
  }

  const resRef = mockDb.collection('reservations').doc(reservationId);
  const now = Date.now();

  await mockDb.runTransaction(async (tx) => {
    const resSnap = await tx.get(resRef);
    if (!resSnap.exists) {
      throw { code: 'not-found', message: 'Reservation record not found.' };
    }
    const resData = resSnap.data();

    if (resData.receiverId !== callerUid && resData.donorId !== callerUid) {
      throw { code: 'permission-denied', message: 'You are not authorized to verify this reservation.' };
    }

    if (resData.status !== 'active') {
      throw { code: 'failed-precondition', message: 'Reservation is not active.' };
    }

    if (resData.pickupDeadline && resData.pickupDeadline <= now) {
      throw { code: 'failed-precondition', message: 'The 30-minute pickup window has expired.' };
    }

    if (resData.otp !== (otp as string).trim()) {
      throw { code: 'invalid-argument', message: 'Incorrect OTP code. Please try again.' };
    }

    tx.update(resRef, {
      status: 'otp_verified',
      otpVerified: true,
      updatedAt: now,
    });
  });

  return { success: true, reservationId };
}

describe('OTP Verification Phase 12 Suite', () => {
  const receiverUid = 'recv_otp';
  const donorUid = 'donor_otp';
  const activeReservationId = 'res_active';
  const expiredReservationId = 'res_expired';
  const correctOtp = '123456';
  
  beforeEach(() => {
    mockDb.collection('reservations').doc(activeReservationId).set({
      receiverId: receiverUid,
      donorId: donorUid,
      status: 'active',
      otp: correctOtp,
      pickupDeadline: Date.now() + 15 * 60 * 1000,
    });
    
    mockDb.collection('reservations').doc(expiredReservationId).set({
      receiverId: receiverUid,
      donorId: donorUid,
      status: 'active',
      otp: correctOtp,
      pickupDeadline: Date.now() - 1000,
    });
  });

  it('1. correct OTP', async () => {
    const res = await simulateVerifyOtp(
      { reservationId: activeReservationId, otp: correctOtp },
      { auth: { uid: receiverUid } }
    );
    expect(res.success).to.be.true;
    
    const doc = (await mockDb.collection('reservations').doc(activeReservationId).get()).data();
    expect(doc.status).to.equal('otp_verified');
    expect(doc.otpVerified).to.be.true;
  });

  it('2. wrong OTP', async () => {
    try {
      await simulateVerifyOtp(
        { reservationId: activeReservationId, otp: '654321' },
        { auth: { uid: receiverUid } }
      );
      expect.fail();
    } catch (e: any) {
      expect(e.code).to.equal('invalid-argument');
      expect(e.message).to.equal('Incorrect OTP code. Please try again.');
    }
  });

  it('3. expired reservation', async () => {
    try {
      await simulateVerifyOtp(
        { reservationId: expiredReservationId, otp: correctOtp },
        { auth: { uid: receiverUid } }
      );
      expect.fail();
    } catch (e: any) {
      expect(e.code).to.equal('failed-precondition');
      expect(e.message).to.equal('The 30-minute pickup window has expired.');
    }
  });

  it('4. empty OTP / invalid length', async () => {
    try {
      await simulateVerifyOtp(
        { reservationId: activeReservationId, otp: '   ' },
        { auth: { uid: receiverUid } }
      );
      expect.fail();
    } catch (e: any) {
      expect(e.code).to.equal('invalid-argument');
    }
  });

  it('5. unauthenticated', async () => {
    try {
      await simulateVerifyOtp(
        { reservationId: activeReservationId, otp: correctOtp },
        {} as any
      );
      expect.fail();
    } catch (e: any) {
      expect(e.code).to.equal('unauthenticated');
    }
  });
});
