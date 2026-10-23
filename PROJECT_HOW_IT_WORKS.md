# PROJECT_HOW_IT_WORKS.md

> **FoodConnect** — Quick technical breakdown of the entire surplus food rescue app.

---

## 1. PROJECT IN ONE MINUTE

### What is this project?
FoodConnect is a Flutter + Firebase mobile app that reduces food waste. Donors post surplus food with photos, quantity, and auto-calculated expiry times. Receivers find nearby food on a live feed, reserve it, and pick it up. Handover is verified using a 6-digit OTP within a 30-minute window.

### The basic idea
```text
Donor posts food ──► Available on Feed ──► Receiver reserves (30m timer) ──► OTP verification ──► Drop & Done (Completed)
```

---

## 2. WHO USES THE APP?

| Role | Who they are | What they do |
|---|---|---|
| **Donor** | Restaurants, caterers, households | Posts food, monitors active listings, verifies pickup via Drop & Done. |
| **Receiver** | Individuals, charities, volunteers | Browses food, reserves items, travels to location, gives OTP to donor. |

---

## 3. HOW THE APP WORKS

### Donor Flow
1. **Register & Verify** → Create account with `donor` role and verify email.
2. **Login & Dashboard** → Sign in and view active, completed, and expired listings.
3. **Post Food** → Enter title, quantity, type (cooked/packed), photo, and location.
4. **Food Available** → Post appears instantly on the receiver feed.
5. **Receiver Reserves** → Status changes to `reserved` with a 30-minute pickup timer.
6. **Pickup & OTP** → Receiver arrives and OTP is verified.
7. **Drop & Done** → Donor confirms handover to mark listing `completed`.

### Receiver Flow
1. **Register & Verify** → Create account with `receiver` role and verify email.
2. **Login & Dashboard** → Sign in and browse unexpired food feed.
3. **Food Details** → View quantity, expiry timer, donor details, and map distance.
4. **Reserve** → Tap Reserve to trigger atomic server lock.
5. **Pickup Timer & OTP** → 30-minute deadline starts and 6-digit OTP is shown.
6. **Pickup & OTP Verification** → Travel to location (via Google Maps) and verify OTP.
7. **Completion** → Handover completed by donor.

---

## 4. MAIN TECHNOLOGIES

| Technology | What it does in this project |
|---|---|
| **Flutter & Dart** | Cross-platform mobile UI and client-side logic. |
| **Firebase Auth** | User authentication, identity tokens, and email verification. |
| **Cloud Firestore** | Real-time database for users, foods, reservations, and logs. |
| **Firebase Storage** | Cloud storage for profile avatars and food photos. |
| **Cloud Functions** | Node.js backend for atomic reservations, OTP checks, and sweepers. |
| **Riverpod** | State management and dependency injection. |
| **GoRouter** | Declarative routing and role-based access guards. |

---

## 5. HOW THE FLUTTER APP IS STRUCTURED

### Folder Structure
- `lib/app/` → App setup, theme, and GoRouter route definitions.
- `lib/core/` → Constants, enums, validators, logger, and Result type.
- `lib/design_system/` → Reusable UI components (buttons, text fields, cards, countdowns).
- `lib/features/` → Feature modules (`auth`, `donor`, `food`, `receiver`, `reservation`, `profile`).
- `lib/models/` → Dart data models (`Food`, `Reservation`, `UserProfile`, `PickupLog`).
- `lib/repositories/` → Data layer talking to Firestore, Functions, and Storage.
- `lib/services/` → Hardware services (GPS location, Google Maps launcher).

### Architecture Flow
```text
Screen (UI) ──► Provider (Riverpod State) ──► Repository (Data Logic) ──► Firebase
```

---

## 6. AUTHENTICATION

- **Identity**: Firebase Auth manages UID, email, and password.
- **Profile**: Firestore stores app data in `users/{uid}`.
- **Email Verification**: Enforced via `user.emailVerified` / `user.reload()`. GoRouter blocks unverified users.
- **Role Check**: App reads `users/{uid}.role` to route users to the correct dashboard.

---

## 7. USER PROFILE

Stored in `users/{uid}`:
- `name`, `email`, `phone`, `role` (`donor` / `receiver`), `organizationName`, `profileImageUrl`, `verificationStatus`.
- **Created**: At registration.
- **Read**: Loaded on startup via `userProfileProvider`.
- **Updated**: User can edit contact info and photo, but **cannot** change `role` or `verificationStatus` (blocked by Firestore rules).

---

## 8. FOOD POSTING

1. Donor fills food details and selects food type.
2. **Expiry Auto-Calculation**:
   - **Cooked Food**: Prepared time + **4 hours**.
   - **Packed Food**: Prepared time + **8 hours**.
3. Photo is uploaded to Firebase Storage (`foods/{foodId}/...`).
4. GPS coordinates are fetched via `Geolocator`.
5. Food saved to Firestore `foods/{foodId}` with `status = 'available'`.
6. Audit log `FOOD_POSTED` written to `pickup_logs`.

---

## 9. FOOD DISCOVERY

- Receiver dashboard queries Firestore `foods` where `status == 'available'` and `expiryAt > now`, sorted by `expiryAt ASC` (soonest expiring first).
- Live countdown shows remaining shelf-life.
- App calculates straight-line distance in km using receiver coordinates and food coordinates.

---

## 10. FOOD LIFECYCLE

```text
available ──(reserved)──► reserved ──(OTP verified + Drop & Done)──► completed
    │                         │
(expiry time passes)     (cancelled or 30m timeout)
    │                         │
    ▼                         ▼
 expired                  available (or expired if past expiryAt)
```

---

## 11. RESERVATION

```text
Receiver taps "Reserve"
  ↓
Flutter calls Cloud Function: reserveFood(foodId)
  ↓
Server validates: caller is receiver + food is available + not expired + not own donation
  ↓
Atomic Firestore Transaction:
  • Generates random 6-digit OTP
  • Sets pickupDeadline = now + 30 minutes
  • Creates reservations/{id} (status: 'active')
  • Updates foods/{id} (status: 'reserved')
  • Writes pickup_logs entry (action: 'RESERVED')
  ↓
Returns reservation to Flutter client
```

**Why Cloud Functions?** Guarantees atomicity, stops race conditions (two people reserving at once), and prevents client tampering.

---

## 12. IMPORTANT RESERVATION RULE

> [!IMPORTANT]  
> **The Flutter client NEVER directly creates a reservation in Firestore.**

- Clients cannot set `food.status = 'reserved'`.
- Clients cannot generate OTPs or deadlines.
- Direct client writes to `/reservations/{id}` are strictly blocked by Firestore rules (`allow create, update: if false;`).

---

## 13. RESERVATION TIMER

- Server assigns `pickupDeadline = serverTimestamp + 30 minutes`.
- Flutter displays a live remaining countdown.
- Phone clock is **not** trusted for security — Cloud Functions validate the actual server timestamp on OTP verification, cancellation, and completion.

---

## 14. OTP (ONE-TIME PASSCODE)

- **Generated by**: `reserveFood` Cloud Function (6 digits).
- **Seen by**: Reserving receiver on their active reservation screen.
- **Used at**: Pickup spot — receiver shares OTP with the donor.
- **Verified by**: `verifyOtp` Cloud Function.
- **On Success**: Reservation status updates to `otp_verified`, unlocking the donor's completion button.

---

## 15. CANCEL / EXPIRE

- **Receiver Cancels**: Calls `cancelReservation` Cloud Function → reservation becomes `cancelled`, food reverts to `available` (if unexpired).
- **30-Min Pickup Expires**: Scheduled sweeper `releaseExpiredReservations` (every 5 mins) marks reservation `expired` and reverts food to `available` (or `expired`).
- **Food Expires**: Scheduled sweeper `markExpiredFoods` (every 5 mins) marks unreserved past-expiry food as `expired`.

---

## 16. DROP & DONE

- **What is it?** The donor's final handover confirmation screen.
- **When available?** Only after OTP verification (`otpVerified == true`).
- **Action**: Donor taps "Complete donation" → calls `completeReservation` Cloud Function → food & reservation status set to `completed`.

---

## 17. LOCATION

- **Capture**: Donor GPS coordinates captured on food posting via `Geolocator`.
- **Display**: Receiver sees distance in kilometers.
- **Navigation**: Receiver taps "Open in Google Maps" → `LocationService` launches Google Maps with destination coordinates.

---

## 18. FIRESTORE DATABASE

| Collection | Stored Data |
|---|---|
| **`users`** | User profiles, roles, contact info, and verification state. |
| **`foods`** | Food posts, quantities, photos, expiry times, and status. |
| **`reservations`** | Active/past reservations, OTPs, deadlines, and status. |
| **`pickup_logs`** | Append-only audit history of all lifecycle events. |

```text
User ──(posts)──► Food ──(reserved by)──► Reservation ──(tracked by)──► Pickup Log
```

---

## 19. FIREBASE STORAGE

- **Paths**:
  - `users/{uid}/avatar_<timestamp>.jpg` (max 2 MB)
  - `foods/{foodId}/food_<timestamp>.jpg` (max 5 MB)
- **Rules**: Authenticated users can read. Users can only write to their own folder path with valid image content types.

---

## 20. CLOUD FUNCTIONS

| Function | Type | Purpose |
|---|---|---|
| **`sendEmailOtp`** | Callable | Generates and saves 6-digit registration OTP. |
| **`verifyEmailOtp`** | Callable | Verifies registration OTP and creates verified user account. |
| **`reserveFood`** | Callable | Atomic transaction to reserve food, generate OTP, and set 30m deadline. |
| **`verifyOtp`** | Callable | Validates OTP before deadline and sets status to `otp_verified`. |
| **`cancelReservation`** | Callable | Cancels active reservation and restores food availability. |
| **`completeReservation`** | Callable | Donor completes handover after OTP verification. |
| **`releaseExpiredReservations`** | Cron (5 min) | Sweeps expired 30-minute reservations. |
| **`markExpiredFoods`** | Cron (5 min) | Sweeps unreserved foods past their expiry time. |

---

## 21. SECURITY

- **Users**: Users can only update their own profile and cannot modify their `role` or `verificationStatus`.
- **Foods**: Donors can only edit metadata of their own foods; they cannot directly change `status` to `reserved` or `completed`.
- **Reservations**: Direct client create/update is completely forbidden (`allow create, update: if false;`).
- **Pickup Logs**: Append-only audit trail; clients can only log `FOOD_POSTED`.

---

## 22. ERROR HANDLING

- **Login / Auth Errors**: Localized user messages ("Incorrect password", "No account found").
- **Unverified Email**: GoRouter forces redirect to `VerifyEmailView`.
- **Already Reserved**: Cloud Function throws `already-reserved` → UI shows "Someone just reserved this food."
- **Invalid OTP**: Function throws `invalid-argument` → UI shows "Incorrect OTP code. Please try again."
- **App Resilience**: All repo calls return `Result<T, String>` (Success/Failure); errors are displayed via Snackbars without app crashes.

---

## 23. IMPORTANT FILES

| File | Purpose |
|---|---|
| [lib/main.dart](file:///Users/apple/Codes/foodconnect/lib/main.dart) | App startup, Firebase initialization, global error catchers, and Riverpod root. |
| [lib/app/router.dart](file:///Users/apple/Codes/foodconnect/lib/app/router.dart) | GoRouter routes, auth redirect guards, and role protection. |
| [lib/features/auth/data/repositories/auth_repository.dart](file:///Users/apple/Codes/foodconnect/lib/features/auth/data/repositories/auth_repository.dart) | Auth operations, session management, and Firestore profile sync. |
| [lib/repositories/food_repository.dart](file:///Users/apple/Codes/foodconnect/lib/repositories/food_repository.dart) | Food posting, expiry calculation, and available food streams. |
| [lib/repositories/reservation_repository.dart](file:///Users/apple/Codes/foodconnect/lib/repositories/reservation_repository.dart) | Client bridge calling Cloud Functions for reserve, cancel, OTP, and complete. |
| [lib/models/food_model.dart](file:///Users/apple/Codes/foodconnect/lib/models/food_model.dart) | Food entity and expiry rules (+4h cooked, +8h packed). |
| [lib/models/reservation_model.dart](file:///Users/apple/Codes/foodconnect/lib/models/reservation_model.dart) | Reservation entity, deadlines, and OTP tracking. |
| [lib/services/location_service.dart](file:///Users/apple/Codes/foodconnect/lib/services/location_service.dart) | GPS fetching, distance calculation, and Google Maps launching. |
| [functions/src/index.ts](file:///Users/apple/Codes/foodconnect/functions/src/index.ts) | Server backend for reservations, OTP verification, completion, and cron sweepers. |
| [firestore.rules](file:///Users/apple/Codes/foodconnect/firestore.rules) | Security rules protecting Firestore collections. |

---

## 24. SIMPLE DATA FLOW

### Login Flow
```text
Login Screen ──► Auth Repository ──► Firebase Auth ──► Firestore users/{uid} ──► Role Checked ──► Dashboard
```

### Post Food Flow
```text
Post Food Screen ──► Storage Repo (Photo) ──► Food Repo (+4h/+8h Expiry) ──► Firestore foods/{id} ──► Live on Feed
```

### Reserve & Complete Flow
```text
Food Details ──► reserveFood Function ──► 30m Timer & OTP ──► OTP Verified ──► Drop & Done ──► Completed
```

---

## 25. STATE CHANGES

| Entity | States |
|---|---|
| **Food** | `available` ──► `reserved` ──► `completed` *(or `expired`)* |
| **Reservation** | `active` ──► `otp_verified` ──► `completed` *(or `cancelled` / `expired`)* |

---

## 26. WHAT HAPPENS IN FIREBASE?

- **Firebase Auth** → Manages user credentials & login tokens.
- **Firestore** → Stores application collections (`users`, `foods`, `reservations`, `pickup_logs`).
- **Firebase Storage** → Stores avatar & food photo files.
- **Cloud Functions** → Executes secure transactions, OTP validation, and cron cleanup.
- **Security Rules** → Enforces access boundaries and blocks unauthorized client writes.

---

## 27. WHAT HAPPENS WHEN THE APP STARTS?

```text
App Starts ──► Firebase.initializeApp() ──► Check Auth State
  ├── Not logged in ──► /login
  └── Logged in
        ├── Email not verified ──► /verify-email
        └── Email verified ──► Load users/{uid} ──► Donor / Receiver Dashboard
```

---

## 28. WHAT HAPPENS IF SOMETHING GOES WRONG?

```text
User Action ──► Repository catches Exception ──► Returns Failure(errorMessage) ──► UI shows SnackBar (No Crash)
```

---

## 29. CURRENT IMPLEMENTATION STATUS

- **Working**: Auth, role routing, food posting, automatic expiry (+4h/+8h), live discovery feed, GPS distance, Cloud Function reservations, 6-digit OTP verification, Drop & Done handover, cancellation, scheduled sweepers, security rules.
- **Partial**: SMTP production email sending (falls back to Firebase Auth/console OTP), in-app GPS navigation (delegated to external Google Maps).
- **Missing**: Push notifications (FCM), in-app live chat.
- **Not Verified**: Production SMS verification.

---

## 30. QUICK REVISION

# Remember These 15 Things

1. **FoodConnect connects food donors with receivers to eliminate food waste.**
2. **Built with Flutter (client UI) and Firebase (backend & database).**
3. **Firebase Auth handles login; Firestore `users/{uid}` stores user profiles.**
4. **GoRouter strictly enforces role-based navigation (Donor vs Receiver).**
5. **Cooked food expires in 4 hours; packed food expires in 8 hours.**
6. **Riverpod manages reactive UI state and data streams.**
7. **The Flutter client NEVER directly writes reservations in Firestore.**
8. **`reserveFood` Cloud Function authoritatively locks food and creates reservations.**
9. **Reservations have a strict 30-minute pickup deadline based on server time.**
10. **The server generates a 6-digit OTP shown only to the reserving receiver.**
11. **The receiver gives the OTP to the donor at pickup to verify identity.**
12. **The donor taps "Drop & Done" after OTP verification to finish the handover.**
13. **Cancelled or timed-out reservations automatically return food to `available`.**
14. **`pickup_logs` records an immutable audit history of all lifecycle actions.**
15. **Firestore Security Rules block unauthorized client writes across all collections.**
