import { assertFails, assertSucceeds, initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;

describe('Firestore Security Rules', () => {
  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'foodconnect-emulator',
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  it('1. Users: Client cannot falsely modify role', async () => {
    const db = testEnv.authenticatedContext('user_123').firestore();
    
    // Create initial user
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('user_123').set({
        userId: 'user_123',
        role: 'receiver',
        verificationStatus: 'pending'
      });
    });

    // Try to update role to donor
    await assertFails(db.collection('users').doc('user_123').update({
      role: 'donor'
    }));
  });

  it('2. Reservations: Client cannot create reservations directly', async () => {
    const db = testEnv.authenticatedContext('user_123').firestore();
    
    await assertFails(db.collection('reservations').doc('res_123').set({
      receiverId: 'user_123',
      donorId: 'donor_456',
      status: 'active'
    }));
  });

  it('3. Foods: Client cannot set food.status = reserved', async () => {
    // Setup donor
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('donor_1').set({
        userId: 'donor_1',
        role: 'donor',
        verificationStatus: 'pending'
      });
      await context.firestore().collection('foods').doc('food_1').set({
        donorId: 'donor_1',
        status: 'available',
        foodType: 'cooked',
        preparedAt: 1000000,
        expiryAt: 1000000 + (4 * 3600000)
      });
    });

    const db = testEnv.authenticatedContext('donor_1').firestore();
    
    // Donor tries to change status to reserved
    await assertFails(db.collection('foods').doc('food_1').update({
      status: 'reserved'
    }));
  });

  it('4. Foods: Donor can manage their own food metadata', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('donor_1').set({
        userId: 'donor_1',
        role: 'donor',
        verificationStatus: 'pending'
      });
      await context.firestore().collection('foods').doc('food_1').set({
        donorId: 'donor_1',
        status: 'available',
        foodType: 'cooked',
        preparedAt: 1000000,
        expiryAt: 1000000 + (4 * 3600000)
      });
    });

    const db = testEnv.authenticatedContext('donor_1').firestore();
    
    await assertSucceeds(db.collection('foods').doc('food_1').update({
      foodName: 'Updated Name',
      quantity: 5
    }));
  });
});
