# Firebase Architecture & Security Specification: Surplus Food Redistribution System Android MVP

## 1. Document Control

| Field | Details |
|---|---|
| Project | Surplus Food Redistribution System Android MVP |
| Document type | Firebase Architecture & Security Specification |
| Related documents | PRD_Surplus_Food_Android_MVP.md (v1.0), SRD_Surplus_Food_Android_MVP.md (v1.0), UserFlow_UIScreenFlow_Surplus_Food_Android_MVP.md (v1.0), UIDesign_Surplus_Food_Android_MVP.md (v1.0), ServiceContract_Backend_API_Surplus_Food_Android_MVP.md (v1.0) |
| Platform | Android (Flutter + Firebase) |
| Backend | Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions (`reserveFood` required, optional scheduled sweeper) |
| Version | 1.1 |

This document defines the complete Firebase implementation layer for the MVP: project topology, Firestore data model, composite indexes, security rules for Firestore and Storage, backend logic (reserve / cancel / timeout / OTP / Drop & Done), and the accepted security tradeoffs for the 2-week capstone scope.

**Primary architecture change in v1.1:** reservation creation is a server-side `reserveFood` Callable Cloud Function. The client sends only `foodId` and never writes reservations, never writes `food.status = reserved`, never generates the OTP, and never decides the pickup deadline. Client-side validation exists purely for UX; Firebase is the source of truth. The detailed request/response and error contract lives in `ServiceContract_Backend_API_Surplus_Food_Android_MVP.md`.

---

## 2. Architecture Overview

```text
+------------------------------------------------------------------+
|                        Android App (Flutter)                       |
|                                                                    |
|  UI layer  ->  Controllers (Provider / Riverpod / ChangeNotifier) |
|                    |                                               |
|                    v                                               |
|              Services / Repositories (UX validation lives here;    |
|              Firebase is the authoritative source of truth)        |
|                                                                    |
|   AuthService       FirebaseAuth (email/password)                  |
|   UserRepository    users collection reads/writes                  |
|   FoodRepository    foods collection + Storage image upload        |
|   ReservationService  calls reserveFood() callable; OTP entry;     |
|                       cancel / timeout / status transitions        |
|   LocationService   device location + maps intent                  |
|   LogService        pickup_logs writes                             |
|                                                                    |
|   Firebase SDK  -------------------------------------------------- |
+------------------------------------------------------------------+
          |                  |                |                |
          v                  v                v                v
   Firebase Auth     Callable Cloud     Cloud Firestore   Cloud Storage
   (identity)        Functions          users / foods     users/{uid}/...
                       |                reservations      foods/{foodId}/...
                       |                pickup_logs
                       |                (composite indexes)
                       |                     ^
                       |                     |
                       +-- reserveFood ----->|  server writes (admin SDK,
                           releaseExpired    |  bypasses client rules)
                           (scheduled)       |
                                             +-- client reads/writes
                                                 (scoped by rules)
```

### 2.1 Component responsibilities

| Component | Responsibility in MVP |
|---|---|
| Firebase Authentication | Email/password sign-up and sign-in. Auth UID is the identity anchor for all rules. |
| Cloud Firestore | Single source of truth for users, foods, reservations, pickup_logs. Local cache enabled for offline reads. |
| Cloud Storage | Food and profile images. One object per image, download URL stored in the Firestore document. |
| Cloud Functions | **Required** for the reservation path. `reserveFood` is the authoritative reservation operation: server-side authentication, role check, atomic reservation creation inside a Firestore transaction, server-time deadline, and server-side OTP generation. `releaseExpiredReservations` is an optional scheduled sweeper that releases timed-out reservations and expires food for demo cleanliness. |
| Firebase Console | Manual updates for the MVP: verification status changes, demo data seeding, inspecting logs. Console writes bypass security rules by design. |

### 2.2 Logic ownership (where each rule is enforced)

| Business rule | App (UX) | Security rules | Cloud Function |
|---|---|---|---|
| Expiry = +4h cooked / +8h packed | Preview only | Yes (create-time timestamp arithmetic) | — |
| Donors create food; receivers cannot | Role routing | Yes (`isDonor()`) | — |
| Reservation created by server only | No; client sends `foodId` only | Denied for clients (`allow create: if false`) | Yes (`reserveFood`) |
| Caller authenticated and role is `receiver` | Role routing | N/A (no client reservation writes) | Yes |
| Food exists / `available` / not expired | UX pre-check | N/A | Yes (transaction checks) |
| Donor cannot reserve own food | UX block | N/A | Yes |
| One active reservation per food (race-safe) | No | N/A | Yes (server transaction) |
| OTP generated server-side (6 digits) | No | N/A | Yes |
| Pickup deadline = reserved + 30 min, server time | No | N/A | Yes |
| No partial data on validation failure | No | N/A | Yes (transaction abort) |
| Receiver cancels / timeout release | Client transaction | Yes (transition checks) | Sweeper (optional) |
| OTP valid only before deadline | Client compares | Yes (`request.time` check on update) | — |
| Drop & Done only after OTP verification | UI gating | Yes (food + reservation update checks) | — |
| Timeout release / expiry | On-load reconcile | Yes (transition checks) | Sweeper (optional) |

Rule of thumb: **the app enforces for UX, the rules enforce for data integrity, the function enforces for time and for reservation authority.** Reservation creation is the one operation no client may ever perform directly.

---

## 3. Firestore Data Model

Four collections, all top-level. Field names are `snake_case`. All documents use the auto-generated document ID as the primary key.

### 3.1 `users/{userId}` — one doc per auth UID

| Field | Type | Notes / constraints |
|---|---|---|
| userId | string | Must equal the document ID and `request.auth.uid` at create |
| name | string | Editable |
| email | string | Immutable (managed by Auth) |
| phone | string | Editable |
| role | string | `donor` or `receiver`; immutable after create |
| organizationName | string | Editable |
| profileImageUrl | string / null | Download URL from Storage; nullable |
| latitude | number / null | Profile location; editable |
| longitude | number / null | Profile location; editable |
| verificationStatus | string | `pending` / `verified` / `rejected`; owner cannot change it (console-managed, FR-11) |
| createdAt | timestamp | `serverTimestamp()` |
| updatedAt | timestamp | `serverTimestamp()` |

### 3.2 `foods/{foodId}`

| Field | Type | Notes / constraints |
|---|---|---|
| foodId | string | Document ID |
| donorId | string | Set by rules to `request.auth.uid` |
| foodName | string | Editable content field |
| foodType | string | `cooked` or `packed`; immutable after create |
| quantity | string | e.g. "12 servings"; editable |
| description | string | Editable |
| imageUrl | string / null | Download URL from Storage |
| preparedAt | timestamp | Client timestamp; drives expiry. NOT `serverTimestamp()` — rules arithmetic needs it at write time |
| expiryAt | timestamp | Client timestamp = `preparedAt + 4h/8h`; rules re-verify on create and content edit |
| latitude | number | Pickup coordinates; required |
| longitude | number | Pickup coordinates; required |
| status | string | `available` / `reserved` / `completed` / `expired` |
| currentReservationId | string / null | Set when reserved, cleared on release |
| createdAt | timestamp | `serverTimestamp()` |
| updatedAt | timestamp | `serverTimestamp()` |

### 3.3 `reservations/{reservationId}`

| Field | Type | Notes / constraints |
|---|---|---|
| reservationId | string | Document ID |
| foodId | string | Must match the food being reserved |
| donorId | string | Copied from the food at create; rules verify against food doc |
| receiverId | string | Must equal `request.auth.uid` at create |
| reservedAt | timestamp | Server time, set by `reserveFood`; NOT `serverTimestamp()` (function arithmetic) |
| pickupDeadline | timestamp | Server time = `reservedAt + 30 min`, set by `reserveFood` |
| otp | string | 6-digit string, generated server-side by `reserveFood` |
| otpVerified | boolean | `false` at create |
| status | string | `active` / `otp_verified` / `completed` / `cancelled` / `expired` |
| completedAt | timestamp / null | Set by donor on Drop & Done |
| cancelledAt | timestamp / null | Set by receiver on cancel |
| createdAt | timestamp | `serverTimestamp()` |
| updatedAt | timestamp | `serverTimestamp()` |

> **Creation is server-only.** `reservations` documents are created exclusively by the `reserveFood` Cloud Function (admin SDK, bypasses client rules). Clients may only read reservations they participate in and update their own participant transitions (cancel, OTP verify, timeout). No client write path exists to create a reservation (Service Contract section 4.2).

### 3.4 `pickup_logs/{logId}`

| Field | Type | Notes / constraints |
|---|---|---|
| logId | string | Document ID |
| foodId | string | Related food |
| reservationId | string / null | Related reservation |
| actorId | string | Set by rules to `request.auth.uid` |
| action | string | `FOOD_POSTED`, `RESERVED`, `RESERVATION_CANCELLED`, `RESERVATION_EXPIRED`, `OTP_VERIFIED`, `PICKUP_COMPLETED`, `FOOD_EXPIRED` |
| timestamp | timestamp | `serverTimestamp()` |
| notes | string / null | Optional |

### 3.5 Timestamp policy (important)

Fields compared against each other in security rules (`preparedAt`, `expiryAt`, `reservedAt`, `pickupDeadline`) must be written as concrete `Timestamp` values because `FieldValue.serverTimestamp()` is resolved after rules evaluate and cannot be used in rules arithmetic.

- `preparedAt`, `expiryAt`: client `Timestamp`s (set by the food form; the create rule re-verifies the expiry arithmetic).
- `reservedAt`, `pickupDeadline`: **server `Timestamp`s set by `reserveFood`** — the client never supplies them.
- `createdAt`, `updatedAt`, log `timestamp`: `serverTimestamp()`.

---

## 4. Composite Indexes

Firestore auto-creates single-field indexes. Composite indexes must be created explicitly. Create them in the Firebase Console (Firestore → Indexes → Composite) or via `gcloud firestore indexes composite create`.

| # | Collection | Fields (order) | Direction | Used by |
|---|---|---|---|---|
| 1 | foods | donorId, createdAt | ASC, DESC | Donor Dashboard: all donations of a donor |
| 2 | foods | donorId, status, createdAt | ASC, ASC, DESC | Donor Dashboard: status filter chips |
| 3 | foods | status, expiryAt | ASC, ASC | Receiver feed: `status == available && expiryAt > now`, ordered by expiry |
| 4 | foods | status, expiryAt | ASC, DESC | Receiver feed "soonest first" / newest-first variant (optional) |
| 5 | reservations | receiverId, reservedAt | ASC, DESC | My Reservations (receiver) |
| 6 | reservations | receiverId, status, reservedAt | ASC, ASC, DESC | My Reservations status tabs |
| 7 | reservations | donorId, reservedAt | ASC, DESC | Donor monitoring of reservations |
| 8 | reservations | foodId, status | ASC, ASC | Optional — admin/tooling lookups only. `reserveFood` reads the food by document ID inside a transaction and does not need this index |
| 9 | reservations | status, pickupDeadline | ASC, ASC | Cloud Function sweeper (if deployed) |
| 10 | pickup_logs | foodId, timestamp | ASC, DESC | Log history per food |
| 11 | pickup_logs | actorId, timestamp | ASC, DESC | Log history per user |

Notes:

- Indexes 1–8 are required for the app to run without runtime errors. Index 9 is required only if the Cloud Function sweeper is deployed.
- If a query fails at runtime, Firestore prints a link to create the missing index; use that link as the source of truth over this list.
- Distance sorting is done client-side (section 7.7); Firestore has no native geo-query, so no geo index is needed.

---

## 5. Firestore Security Rules

Complete ruleset for `firestore.rules`. Rules v2.

Key structural consequences of the server-side reservation model:

- **Clients can never create reservations** (`allow create: if false` on `reservations`). `reserveFood` uses the Admin SDK and bypasses rules.
- **Clients can never set `food.status = reserved`.** The `receiverReservesFood()` update path is removed; only the server writes the `available → reserved` transition.
- The remaining client update helpers (cancel, timeout release, OTP verify, Drop & Done) still write the reservation document before the food document in the same batch/transaction, so the rules `get()` check below can validate the fresh reservation.

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ---------- shared helpers ----------
    function uid() {
      return request.auth.uid;
    }
    function isSignedIn() {
      return request.auth != null;
    }
    function isDonor() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(uid())).data.role == 'donor';
    }
    function isReceiver() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(uid())).data.role == 'receiver';
    }
    function expiryMatchesRule(foodData) {
      return (foodData.foodType == 'cooked'
          && foodData.expiryAt == foodData.preparedAt + duration(4, 'hours'))
        || (foodData.foodType == 'packed'
          && foodData.expiryAt == foodData.preparedAt + duration(8, 'hours'));
    }
    function reservationRef(id) {
      return /databases/$(database)/documents/reservations/$(id);
    }

    // ================= users =================
    match /users/{userId} {

      allow read: if isSignedIn();

      allow create: if uid() == userId
        && request.resource.data.userId == userId
        && request.resource.data.role in ['donor', 'receiver']
        && request.resource.data.verificationStatus == 'pending';

      allow update: if uid() == userId
        && request.resource.data.userId == resource.data.userId
        && request.resource.data.email == resource.data.email
        && request.resource.data.role == resource.data.role
        && request.resource.data.verificationStatus == resource.data.verificationStatus;

      allow delete: if false;
    }

    // ================= foods =================
    match /foods/{foodId} {

      allow read: if isSignedIn();

      allow create: if isDonor()
        && request.resource.data.donorId == uid()
        && request.resource.data.foodType in ['cooked', 'packed']
        && request.resource.data.status == 'available'
        && request.resource.data.currentReservationId == null
        && expiryMatchesRule(request.resource.data);

      allow update: if (
          isDonor() && foodContentEditOnly()
        ) || (
          isReceiver() && (receiverCancelsFood() || receiverReleasesFood())
        ) || (
          isDonor() && (donorCompletesFood() || donorReleasesFood())
        );

      allow delete: if false;
    }

    // ================= reservations =================
    match /reservations/{reservationId} {

      allow read: if isSignedIn()
        && (resource.data.receiverId == uid() || resource.data.donorId == uid());

      // Creation is server-only: the reserveFood callable (admin SDK) writes
      // reservations. Clients must never create a reservation directly.
      allow create: if false;

      allow update: if (
          isReceiver() && resource.data.receiverId == uid()
            && (receiverCancelsReservation() || receiverVerifiesOtp() || receiverTimesOut())
        ) || (
          isDonor() && resource.data.donorId == uid()
            && (donorCompletesReservation() || donorTimesOut())
        );

      allow delete: if false;
    }

    // ================= pickup_logs =================
    match /pickup_logs/{logId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn()
        && request.resource.data.actorId == uid()
        && request.resource.data.action in [
          'FOOD_POSTED', 'RESERVED', 'RESERVATION_CANCELLED',
          'RESERVATION_EXPIRED', 'OTP_VERIFIED', 'PICKUP_COMPLETED', 'FOOD_EXPIRED'
        ];
      allow update, delete: if false;
    }

    // ================= food update helpers =================
    function foodContentEditOnly() {
      return request.resource.data.donorId == resource.data.donorId
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['foodName', 'quantity', 'description', 'imageUrl',
                      'preparedAt', 'expiryAt', 'updatedAt'])
        && expiryMatchesRule(request.resource.data);
    }

    function receiverCancelsFood() {
      return resource.data.status == 'reserved'
        && resource.data.currentReservationId != null
        && request.resource.data.status in ['available', 'expired']
        && request.resource.data.currentReservationId == null
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'currentReservationId', 'updatedAt'])
        && get(reservationRef(resource.data.currentReservationId)).data.receiverId == uid()
        && get(reservationRef(resource.data.currentReservationId)).data.status == 'cancelled';
    }

    function receiverReleasesFood() {
      return resource.data.status == 'reserved'
        && resource.data.currentReservationId != null
        && request.resource.data.status in ['available', 'expired']
        && request.resource.data.currentReservationId == null
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'currentReservationId', 'updatedAt'])
        && get(reservationRef(resource.data.currentReservationId)).data.receiverId == uid()
        && get(reservationRef(resource.data.currentReservationId)).data.status == 'expired';
    }

    function donorReleasesFood() {
      return resource.data.status == 'reserved'
        && resource.data.currentReservationId != null
        && request.resource.data.status in ['available', 'expired']
        && request.resource.data.currentReservationId == null
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'currentReservationId', 'updatedAt'])
        && get(reservationRef(resource.data.currentReservationId)).data.donorId == uid()
        && get(reservationRef(resource.data.currentReservationId)).data.status == 'expired';
    }

    function donorCompletesFood() {
      return resource.data.status == 'reserved'
        && resource.data.currentReservationId != null
        && request.resource.data.status == 'completed'
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'updatedAt'])
        && get(reservationRef(resource.data.currentReservationId)).data.donorId == uid()
        && get(reservationRef(resource.data.currentReservationId)).data.status == 'completed'
        && get(reservationRef(resource.data.currentReservationId)).data.otpVerified == true;
    }

    // ================= reservation update helpers =================
    function receiverCancelsReservation() {
      return resource.data.status == 'active'
        && request.resource.data.status == 'cancelled'
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'cancelledAt', 'updatedAt']);
    }

    function receiverVerifiesOtp() {
      return resource.data.status == 'active'
        && request.resource.data.status == 'otp_verified'
        && request.resource.data.otpVerified == true
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'otpVerified', 'updatedAt'])
        && request.time < resource.data.pickupDeadline;
    }

    function receiverTimesOut() {
      return resource.data.status == 'active'
        && request.resource.data.status == 'expired'
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'updatedAt']);
    }

    function donorCompletesReservation() {
      return resource.data.status == 'otp_verified'
        && resource.data.otpVerified == true
        && request.resource.data.status == 'completed'
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'completedAt', 'updatedAt']);
    }

    function donorTimesOut() {
      return resource.data.status == 'active'
        && request.resource.data.status == 'expired'
        && request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['status', 'updatedAt']);
    }
  }
}
```

### 5.1 Design notes

| Decision | Reason |
|---|---|
| Rules read the linked reservation doc (`get()`) on every food status change | Prevents any actor from flipping food status without a matching reservation event. This is the core integrity guard. |
| Reservation creation denied to clients (`allow create: if false`) | The only writer is `reserveFood` (admin SDK). Clients send only `foodId` and receive the result; they cannot create arbitrary reservations. |
| `available → reserved` has no client update path | Only the server writes this transition. A client cannot mark food as reserved by any Firestore write. |
| Client flows write reservation first, food second (cancel / timeout release / OTP verify / Drop & Done) | Rules `get()` sees documents written earlier in the same transaction, so the food update can validate the fresh reservation. Do not reverse the order. |
| `request.time < pickupDeadline` on OTP verify | Server-side deadline enforcement — a client with a wrong clock cannot verify after the window (SR-FR-048). |
| `verificationStatus` immutable by owner | Verification is console-managed (FR-11); a user must not self-verify. |
| `role`, `email`, `userId` immutable after create | Role is the permission anchor; changing it mid-flight would break rule assumptions. |
| Status-specific `hasOnly()` allowlists | A status update can change only status + the one timestamp + `updatedAt`. No data smuggling in the same write. |
| `otp_verified` cannot cancel/timeout; only the donor completes it | Matches SRD 10.2 exactly. |

---

## 6. Firebase Storage

### 6.1 Path structure

```text
<bucket>
  users/{uid}/avatar_{timestamp}.jpg       profile images (max 2 MB)
  foods/{foodId}/food_{timestamp}.jpg      food images (max 5 MB)
```

- Timestamps in the file name bust the browser/app cache when an image is replaced.
- Store the **download URL** (`...?alt=media&token=...`) in the Firestore doc (`imageUrl`, `profileImageUrl`).

### 6.2 Storage security rules

```text
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /users/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.contentType.matches('image/(png|jpe?g|webp)')
        && request.resource.size < 2 * 1024 * 1024;
    }

    match /foods/{foodId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.contentType.matches('image/(png|jpe?g|webp)')
        && request.resource.size < 5 * 1024 * 1024;
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 6.3 Known limitation and mitigation

Storage rules **cannot read Firestore**, so a `foods/{foodId}` write cannot be restricted to that food's donor at the Storage layer. In the MVP the risk is acceptable (foodId is an unpredictable auto-ID known only to the donor's app session). Hardening options for later:

1. Move uploads behind a Cloud Function that validates the food's `donorId` against `auth.uid` before issuing a signed URL.
2. Key upload paths by the uploader UID: `foods/{donorUid}/{foodId}/food.jpg` and use the `users/{userId}`-style owner check.

### 6.4 Upload flow

```text
pick image -> compress (target < 1 MB, keep aspect) -> upload to Storage path
  -> on success, getDownloadURL() -> write imageUrl into the Firestore doc
  -> on failure, show retry error and DO NOT submit the food (SR-EC-009/010)
```

If an image already exists for that food and a new one replaces it, delete the old object after the new upload succeeds.

---

## 7. Backend Logic and Data Operations

State-changing operations fall into two groups:

- **Server-side (authoritative):** reservation creation via the `reserveFood` callable (7.1).
- **Client-side with Firestore transactions/batches:** cancel, timeout release, OTP verify, Drop & Done — the app runs these directly, and rules enforce the allowed transitions.

The reservation-creation path is the only one where "create a reservation" and "change food to reserved" are possible, and it runs entirely on the server. Everything below uses server timestamps and aborts atomically on any failure.

### 7.1 Reserve food — authoritative server-side callable

The client does **not** run a reservation transaction. It calls the callable with only `foodId` (Service Contract section 3) and receives the created reservation.

```js
// functions/index.js — Node.js 18+, firebase-functions v2, firebase-admin v11+
const functions = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

function generateOtp() {
  return String(Math.floor(Math.random() * 1000000)).padStart(6, '0');
}

exports.reserveFood = functions.onCall(async (request) => {

  // 1. Authenticate the caller
  if (!request.auth) {
    throw new functions.HttpsError('unauthenticated', 'You must be signed in.');
  }
  const callerUid = request.auth.uid;

  // 2. Verify the caller is a Receiver
  const userSnap = await db.collection('users').doc(callerUid).get();
  if (!userSnap.exists || userSnap.data().role !== 'receiver') {
    throw new functions.HttpsError('permission-denied',
      'Only receiver accounts can reserve food.');
  }

  // 3. Validate input (the only field the client may send)
  const foodId = request.data?.foodId;
  if (typeof foodId !== 'string' || foodId.length === 0) {
    throw new functions.HttpsError('invalid-argument', 'A valid foodId is required.');
  }

  const foodRef = db.collection('foods').doc(foodId);
  const reservationsRef = db.collection('reservations');
  const logsRef = db.collection('pickup_logs');
  const now = admin.firestore.Timestamp.now();

  // 4. Atomic server-side transaction.
  //    Any throw below aborts the whole transaction: no reservation, no food
  //    change, no log is persisted (no partial data).
  const reservationId = reservationsRef.doc().id;
  const otp = generateOtp();

  const created = await db.runTransaction(async (tx) => {
    const foodSnap = await tx.get(foodRef);
    if (!foodSnap.exists) {
      throw new functions.HttpsError('not-found', 'This food is no longer available.');
    }
    const food = foodSnap.data();

    if (food.status !== 'available') {
      throw new functions.HttpsError('already-reserved',
        'This food has already been reserved.');
    }
    if (food.expiryAt.toMillis() <= now.toMillis()) {
      throw new functions.HttpsError('expired', 'This food has expired.');
    }
    if (food.donorId === callerUid) {
      throw new functions.HttpsError('permission-denied',
        "You can't reserve your own donation.");
    }

    const reservedAt = now;                       // server time
    const pickupDeadline = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 30 * 60 * 1000);           // + 30 minutes

    tx.set(reservationsRef.doc(reservationId), {
      reservationId, foodId, donorId: food.donorId, receiverId: callerUid,
      reservedAt, pickupDeadline, otp, otpVerified: false, status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(foodRef, {
      status: 'reserved',
      currentReservationId: reservationId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(logsRef.doc(), {
      foodId, reservationId, actorId: callerUid, action: 'RESERVED',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { reservationId, donorId: food.donorId,
             reservedAt, pickupDeadline, otp };
  });

  // 5. Return the created reservation details to the client
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
```

**Guarantees delivered by this function**

| Guarantee | How |
|---|---|
| Caller authenticated | `request.auth` required, else `unauthenticated` |
| Caller is a Receiver | Role read from `users/{uid}` before the transaction |
| Food exists / `available` / not expired | Read inside the transaction with server time |
| Donor cannot reserve own food | `food.donorId === callerUid` rejected |
| OTP generated server-side | `generateOtp()` in the function |
| Server-time `reservedAt` + deadline | `now` and `now + 30 min` from the server clock |
| Atomic create + reserve | Single `runTransaction`; any throw aborts all writes |
| Reservation details returned | Response schema in Service Contract 3.3 |

**Client invocation (Flutter)** — this is the *entire* client reservation path:

```dart
final res = await FirebaseFunctions.instance
    .httpsCallable('reserveFood')
    .call<Map<String, dynamic>>({'foodId': foodId});
final reservation = Reservation.fromJson(res.data);
```

**Client boundary — the app must never:** write `food.status = 'reserved'` or `currentReservationId`, create or delete a reservation document, generate the OTP, or set `reservedAt`/`pickupDeadline`. These are blocked by the rules (section 5) and structurally impossible via the callable interface.

### 7.2 Cancel reservation (receiver)

```text
runTransaction((tx) async {
  res  = await tx.get(reservationRef)
  food = await tx.get(foodRef)

  guard res.status == 'active' && res.receiverId == currentUserId

  tx.update(reservationRef, { status: 'cancelled', cancelledAt: now, updatedAt: serverTimestamp() })

  if (food.expiryAt.isAfter(now)) {
    tx.update(foodRef, { status: 'available', currentReservationId: null, updatedAt: serverTimestamp() })
  } else {
    tx.update(foodRef, { status: 'expired', currentReservationId: null, updatedAt: serverTimestamp() })
    tx.set(logRef, { action: 'FOOD_EXPIRED', ... })
  }

  tx.set(logRef, { action: 'RESERVATION_CANCELLED', ... })
})
```

### 7.3 Timeout release (on app load / resume, or the optional sweeper)

The app must reconcile on every load and resume (SR-FR-036, SR-FR-003, EC-04). For each active reservation of the current user whose `pickupDeadline <= now`:

```text
runTransaction((tx) async {
  res  = await tx.get(reservationRef)
  food = await tx.get(foodRef)

  guard res.status == 'active'

  tx.update(reservationRef, { status: 'expired', updatedAt: serverTimestamp() })

  if (food.expiryAt.isAfter(now)) {
    tx.update(foodRef, { status: 'available', currentReservationId: null, updatedAt: serverTimestamp() })
  } else {
    tx.update(foodRef, { status: 'expired', currentReservationId: null, updatedAt: serverTimestamp() })
    tx.set(logRef, { action: 'FOOD_EXPIRED', ... })
  }

  tx.set(logRef, { action: 'RESERVATION_EXPIRED', ... })
})
```

This same logic is what the optional Cloud Function runs on a schedule; having it in the app makes correctness independent of the function.

### 7.4 OTP verification (receiver)

```text
runTransaction((tx) async {
  res = await tx.get(reservationRef)

  guard res.status == 'active'
  guard now.isBefore(res.pickupDeadline)          // SR-FR-048
  guard enteredOtp == res.otp                     // else "That code doesn't match."

  tx.update(reservationRef, {
    status: 'otp_verified', otpVerified: true, updatedAt: serverTimestamp()
  })

  tx.set(logRef, { action: 'OTP_VERIFIED', ... })
})
```

The OTP is generated server-side by `reserveFood` (section 7.1) and stored on the reservation document. The receiver compares the entered code locally against the reservation's OTP, then writes only the `otpVerified` flag; rules reject the write after the deadline. This client-side comparison is an MVP tradeoff (see section 10).

### 7.5 Drop & Done (donor)

```text
runTransaction((tx) async {
  res  = await tx.get(reservationRef)
  food = await tx.get(foodRef)

  guard res.status == 'otp_verified' && res.otpVerified == true   // SR-FR-050
  guard res.donorId == currentUserId

  tx.update(reservationRef, { status: 'completed', completedAt: now, updatedAt: serverTimestamp() })
  tx.update(foodRef, { status: 'completed', updatedAt: serverTimestamp() })
  tx.set(logRef, { action: 'PICKUP_COMPLETED', ... })
})
```

Idempotency: the `guard res.status == 'otp_verified'` re-read makes a second tap fail cleanly; the button also disables on first tap. Completed/cancelled/expired records are terminal (EC-12) — no rule or code path reopens them.

### 7.6 OTP generation (server-side)

OTP generation lives in the `reserveFood` function (section 7.1) and is never performed by the client.

```js
function generateOtp() {
  return String(Math.floor(Math.random() * 1000000)).padStart(6, '0');
}
```

- 6 digits, leading zeros allowed, stored as a string.
- Collision probability is ~1/1,000,000 per active reservation; accepted for MVP. Do not reuse an OTP across reservations.
- Never log the OTP to console/analytics.

### 7.7 Distance and location

- Distance is computed client-side with the Haversine formula from `food.latitude/longitude` and the receiver's profile coordinates (SR-FR-023, SR-FR-057).
- No geo indexing needed. Optional "Nearest first" sort happens on the already-fetched page.
- "Open in Maps" launches the platform maps intent via `url_launcher` with `geo:` or the Google Maps URI.

### 7.8 Offline and cache behavior

| Scenario | Behavior |
|---|---|
| Reads while offline | Local cache returns last-synced data (passive offline banner in UI). |
| Reservation (`reserveFood` callable) | Requires connectivity. Callable errors surface via `FirebaseFunctionsException`; the UI never flips to reserved without a successful response (SR-EC-010). |
| Other writes (cancel / verify / complete) | Client transactions/batches require connectivity; failures show a network error and never optimistically succeed. |
| Resume after background | Reconcile active reservations from timestamps before rendering the Reservation screen. |

---

## 8. Cloud Functions

Two functions. `reserveFood` is **required** and is the authoritative reservation path (fully specified in section 7.1 and the Service Contract). `releaseExpiredReservations` is an optional scheduled sweeper.

### 8.1 `reserveFood` (required)

Server-side authoritative reservation creation. See section 7.1 for the implementation and the Service Contract (section 3) for the request/response/error contract.

### 8.2 `releaseExpiredReservations` (optional sweeper)

Keeps the demo database tidy and catches states the app never reopens.

```text
// functions/index.js — scheduled sweeper (separate export)
exports.releaseExpiredReservations =
  functions.pubsub.schedule('every 1 minutes').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const snap = await db
      .collection('reservations')
      .where('status', '==', 'active')
      .where('pickupDeadline', '<=', now)      // requires index #9
      .limit(400)
      .get();

    for (const doc of snap.docs) {
      const batch = db.batch();
      const res = doc.data();

      batch.update(doc.ref, { status: 'expired', updatedAt: now });

      const foodRef = db.collection('foods').doc(res.foodId);
      const foodSnap = await foodRef.get();
      const food = foodSnap.data();
      if (food.expiryAt.toMillis() > now.toMillis()) {
        batch.update(foodRef, { status: 'available', currentReservationId: null, updatedAt: now });
      } else {
        batch.update(foodRef, { status: 'expired', currentReservationId: null, updatedAt: now });
        batch.set(db.collection('pickup_logs').doc(), { action: 'FOOD_EXPIRED', ... });
      }
      batch.set(db.collection('pickup_logs').doc(), { action: 'RESERVATION_EXPIRED', ... });

      await batch.commit();
    }
  });
```

Notes:

- Admin SDK bypasses rules — safe here because the function only writes the transitions defined in section 7.3 (timeout release).
- This function is **optional** (SRD section 9.3). The app already reconciles on load; the sweeper simply guarantees the database is tidy even for reservations the app never reopens.
- Further production hardening (explicitly out of MVP scope): move OTP verification into a server-side callable so the code is verified (and can be hashed) on the server rather than compared on the client.

---

## 9. Deployment, Emulation, and Testing

### 9.1 Local development

```text
firebase emulators:start --only auth,firestore,storage,functions
```

- Run the Flutter app against the emulator via the Firebase emulator SDK configuration. Callable functions must be emulated locally so the `reserveFood` flow works in development.
- Seed demo data through the Emulator UI.

### 9.2 Deploy

```text
firebase deploy --only firestore:rules
firebase deploy --only storage
firebase deploy --only functions          # reserveFood required; sweeper optional
```

- Create composite indexes before first deploy test (console links from runtime errors).

### 9.3 Rules testing

Write unit tests with `@firebase/rules-unit-testing` against the emulator:

| Test case | Expect |
|---|---|
| Receiver creates food | DENIED |
| Donor creates food with mismatched `donorId` | DENIED |
| Donor creates cooked food with expiry != +4h | DENIED |
| Donor creates valid cooked/packed food | ALLOWED |
| Any client creates a reservation document | DENIED |
| Any client sets `food.status = 'reserved'` directly | DENIED |
| Receiver verifies OTP after `pickupDeadline` | DENIED |
| Donor completes reservation without `otpVerified` | DENIED |
| Donor completes after OTP verified | ALLOWED |
| Non-participant reads a reservation | DENIED |
| Owner edits own `verificationStatus` | DENIED |

Plus callable contract tests for `reserveFood` (run against the emulator's functions):

| Test case | Expect |
|---|---|
| Unauthenticated call | `unauthenticated` |
| Donor caller | `permission-denied` |
| `foodId` missing | `invalid-argument` |
| Food document missing | `not-found` |
| Food already reserved | `already-reserved` |
| Food expired (backdated `expiryAt`) | `expired` |
| Donor reserves own food | `permission-denied` |
| Two simultaneous calls on one food | Exactly one succeeds, other `already-reserved` |
| Valid call | Reservation + food `reserved` + log created, deadline = +30 min, OTP 6 digits |

---

## 10. Security Tradeoffs (MVP) and Roadmap

Accepted for the 2-week capstone; each has a documented production fix.

| # | MVP behavior | Risk | Production hardening |
|---|---|---|---|
| 1 | Reservation creation is a server-side `reserveFood` callable; clients only send `foodId` and receive the result | **Resolved** — atomicity, validation, and server-time deadline are server-owned; client rules deny direct reservation writes | Keep it; no further action needed |
| 2 | OTP is generated server-side but still compared on the client; both participants can read it | OTP is visible to the two trusted parties (acceptable) but would not survive a hostile client | Server-side OTP verification (callable `verifyOtp`); store only a hash |
| 3 | `users` documents readable by all authenticated users | Privacy of phone/email (SR-NFR-008) is enforced only in the app | Split into `users/public/{uid}` (name, org, image) and `users/private/{uid}` (owner-only) |
| 4 | Food image writes are not donor-restricted in Storage rules | Any signed-in user could overwrite a food image path | Cloud Function signed uploads, or UID-keyed paths (section 6.3) |
| 5 | `pickup_logs` readable by all signed-in users | Log detail leaks across users | Restrict reads to donor/receiver of the referenced food/reservation |
| 6 | No notifications | Time-sensitive demo relies on in-app timers | Firebase Cloud Messaging as a post-MVP enhancement |
| 7 | Verification status console-managed | Manual only | Admin panel / Cloud Function verification flow (out of scope) |

---

## 11. Implementation Checklist

1. Create Firebase project; enable Auth (email/password), Firestore, Storage, and Functions in the default (or `us-central1`) region.
2. Deploy the rulesets in sections 5 and 6, and the `reserveFood` Cloud Function (section 7.1).
3. Create composite indexes 1–8 from section 4; add 9 if the sweeper is deployed.
4. Set Firestore client `persistenceEnabled: true`; keep all writes online-only.
5. Implement services per section 2.1; keep all rules/timestamps exactly as specified (client timestamps for `preparedAt`/`expiryAt`; server values for reservation fields).
6. Client reservation path sends only `foodId` to `reserveFood`; verify via rules tests that direct reservation creates and `food.status = reserved` writes are DENIED.
7. Add on-load reconciliation for active reservations (section 7.3) to the Dashboard and Reservation controllers.
8. Run the rules test suite and the callable contract tests (section 9.3) against the emulator.
9. Smoke-test the full donor→receiver demo against the live project with a second device/emulator to prove the race guards work.
10. Verify the sweeper (if deployed) releases a manually-backdated active reservation within one minute.

---

## 12. Version

| Version | Date | Change |
|---|---|---|
| 1.0 | — | Initial Firebase architecture & security specification, companion to User Flow v1.0 and UI/UX Design v1.0 |
| 1.1 | — | Reservation creation moved server-side: `reserveFood` Callable Cloud Function is the authoritative reservation operation; clients send only `foodId`; rules deny client reservation creates and `food.status = reserved` writes; service contract added (ServiceContract_Backend_API_Surplus_Food_Android_MVP.md v1.0) |
