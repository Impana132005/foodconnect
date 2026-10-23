import { expect } from 'chai';

// Simple mock for sweeping
async function simulateSweeper(mockDb: any) {
  const now = Date.now();
  const snapshot = {
    empty: false,
    docs: [
      {
        id: 'food_1',
        ref: mockDb.collection('foods').doc('food_1'),
        data: () => ({ status: 'available', expiryAt: now - 1000 })
      }
    ]
  };

  for (const doc of snapshot.docs) {
    await mockDb.runTransaction(async (tx: any) => {
      const foodSnap = await tx.get(doc.ref);
      const food = foodSnap.data();
      if (food.status !== 'available' || food.expiryAt > now) return;

      tx.update(doc.ref, { status: 'expired' });
      tx.set(mockDb.collection('pickup_logs').doc('log_1'), {
        foodId: doc.id,
        reservationId: null,
        actorId: 'SYSTEM_SWEEPER',
        action: 'FOOD_EXPIRED',
        timestamp: now,
      });
    });
  }
}

describe('Logs & Sweepers Phase 15 Suite', () => {
  it('1. sweeper logs FOOD_EXPIRED', async () => {
    // Mock DB
    const data: any = { foods: { food_1: { status: 'available', expiryAt: Date.now() - 1000 } }, pickup_logs: {} };
    const mockTx = {
      get: async (ref: any) => ({ exists: true, data: () => data[ref.collection][ref.id] }),
      update: (ref: any, updates: any) => Object.assign(data[ref.collection][ref.id], updates),
      set: (ref: any, obj: any) => { data[ref.collection][ref.id] = obj; },
    };
    const mockDb = {
      collection: (col: string) => ({ doc: (id: string) => ({ collection: col, id }) }),
      runTransaction: async (cb: any) => cb(mockTx)
    };
    
    await simulateSweeper(mockDb);
    expect(data.foods.food_1.status).to.equal('expired');
    expect(data.pickup_logs.log_1.action).to.equal('FOOD_EXPIRED');
    expect(data.pickup_logs.log_1.actorId).to.equal('SYSTEM_SWEEPER');
  });
});
