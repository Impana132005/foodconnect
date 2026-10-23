# System Requirements Document: Surplus Food Redistribution System Android MVP

## 1. Document Control

| Field | Details |
|---|---|
| Project | Surplus Food Redistribution System Android MVP |
| Document type | System Requirements Document |
| Target platform | Android |
| Recommended implementation | Flutter + Firebase (incl. Callable Cloud Functions) |
| Academic context | BCA capstone project |
| Version | 1.1 |

> v1.1: Reservation creation moved to the authoritative server-side `reserveFood` Callable Cloud Function. Clients send only `foodId`; they cannot create reservations, write `food.status = reserved`, generate OTPs, or set deadlines. Client validation is UX-only; Firebase is the source of truth. See SR-FR-028 and SR-FR-061..072, and the companion `ServiceContract_Backend_API_Surplus_Food_Android_MVP.md`.

## 2. Source And Requirement Labels

| Label | Meaning |
|---|---|
| DOC | Requirement is supported by the uploaded project report/presentation as recovered from the referenced project discussion. The source described donor/restaurant, receiver/NGO, admin, food posting, reservation, pickup verification, expiry handling, location, QR/OTP, Firebase/Flutter architecture, notifications, and Digital Clean Chain/audit logging. |
| MVP | Requirement was locked during the Android MVP scope conversation. |

This SRD intentionally implements only the locked MVP and excludes AI, admin panel, advanced NGO matching, chatbot, analytics, and other future modules.

## 3. System Overview

The system is a single Android application with role-based behavior. Users register as either Donor or Receiver. Donors post surplus food with automatic expiry. Receivers view available food, reserve one listing, complete pickup within 30 minutes, verify the pickup through OTP, and complete the transaction using Drop & Done.

Recommended high-level architecture:

```text
Android App: Flutter
  -> Firebase Authentication
  -> Firebase Callable Cloud Functions (reserveFood — authoritative reservation)
  -> Cloud Firestore
  -> Firebase Storage
  -> Device Location Services
  -> Google Maps / Maps Intent
```

For the 2-week MVP, Firebase is sufficient as the backend; the required `reserveFood` Callable Cloud Function provides the server-side reservation logic, so a separate Java/Spring backend is not required unless mandated externally.

## 4. System Actors

| Actor | Description | Permissions | Source |
|---|---|---|---|
| Donor | Restaurant/business/person posting surplus food. | Create and view own food listings, view reservation status, complete handover. | DOC, MVP |
| Receiver | NGO/organization/user collecting surplus food. | View available food, reserve food, cancel reservation, complete OTP verification. | DOC, MVP |
| Firebase Console Operator | Developer/demo operator, not an app role. | May manually update verification status during MVP testing. | MVP |

Admin is described in the broader project source but is out of scope for this MVP.

## 5. Technology Requirements

| Layer | Requirement | Recommended Choice |
|---|---|---|
| Mobile framework | Build one Android app with reusable UI and role routing. | Flutter |
| Language | Application code. | Dart |
| Authentication | Email/password login and registration. | Firebase Authentication |
| Database | Users, foods, reservations, logs. | Cloud Firestore |
| File storage | Food/profile images. | Firebase Storage |
| Location | Current GPS coordinates and map navigation. | Android location APIs through Flutter plugin |
| Maps | Open pickup point in map app. | Google Maps intent/url launcher |
| State management | Keep app state predictable. | Provider, Riverpod, or simple ChangeNotifier |
| Server-side logic | Authoritative reservation creation, server-time deadlines, OTP generation. | Firebase Callable Cloud Functions (Node.js): `reserveFood` (required); optional scheduled `releaseExpiredReservations` sweeper |

## 6. Functional System Requirements

### 6.1 Authentication

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-001 | System shall allow email/password registration. | MVP |
| SR-FR-002 | System shall allow email/password login. | MVP |
| SR-FR-003 | System shall create a `users` record after successful registration. | MVP |
| SR-FR-004 | System shall store `role` as either `donor` or `receiver`. | MVP |
| SR-FR-005 | System shall route users based on role after login. | MVP |
| SR-FR-006 | System shall reject access when an authenticated user has no valid user profile. | MVP |

### 6.2 Profile And Verification

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-007 | System shall store user name, email, phone, organization name, role, location, and verification status. | DOC, MVP |
| SR-FR-008 | System shall allow users to view their profile. | MVP |
| SR-FR-009 | System shall allow users to update editable profile fields. | MVP |
| SR-FR-010 | System shall store verification status as `pending`, `verified`, or `rejected`. | MVP |
| SR-FR-011 | System shall display verification status on the profile screen. | MVP |
| SR-FR-012 | For the MVP, system shall not include an in-app admin verification panel. | MVP |

### 6.3 Food Listing

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-013 | System shall allow Donor users to create food listings. | DOC, MVP |
| SR-FR-014 | System shall prevent Receiver users from creating food listings. | MVP |
| SR-FR-015 | Food listing shall store donor ID, name, type, quantity, description, image URL, preparation time, expiry time, pickup coordinates, status, and timestamps. | DOC, MVP |
| SR-FR-016 | System shall calculate expiry time automatically from food type. | MVP |
| SR-FR-017 | For `cooked`, system shall set `expiryAt = preparedAt + 4 hours`. | MVP |
| SR-FR-018 | For `packed`, system shall set `expiryAt = preparedAt + 8 hours`. | MVP |
| SR-FR-019 | System shall save valid new listings with status `available`. | DOC, MVP |
| SR-FR-020 | System shall not allow manual expiry duration input in the MVP. | MVP |

### 6.4 Food Discovery

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-021 | System shall show Receiver users food where `status = available` and `expiryAt > current time`. | DOC, MVP |
| SR-FR-022 | System shall hide, mark, or disable expired food. | DOC, MVP |
| SR-FR-023 | System should calculate approximate distance when receiver and food coordinates exist. | DOC, MVP |
| SR-FR-024 | System shall provide Food Details for a selected listing. | DOC, MVP |

### 6.5 Reservation

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-025 | System shall allow Receiver users to reserve available food. | DOC, MVP |
| SR-FR-026 | System shall prevent Donor users from reserving food. | MVP |
| SR-FR-027 | System shall prevent a donor from reserving their own food. | MVP |
| SR-FR-028 | System shall create reservations through the server-side `reserveFood` Callable Cloud Function, which performs an atomic Firestore transaction; no client code shall create a reservation directly. | MVP |
| SR-FR-029 | System shall create a reservation record when reservation succeeds. | DOC, MVP |
| SR-FR-030 | System shall update food status from `available` to `reserved` when reservation succeeds. | DOC, MVP |
| SR-FR-031 | System shall reject reservation if food is no longer available or already expired. | DOC, MVP |
| SR-FR-032 | System shall set `pickupDeadline = reservedAt + 30 minutes`. | DOC, MVP |

### 6.5.1 Server-Side Reservation (Authoritative)

Reservation creation is performed only by the `reserveFood` Callable Cloud Function, which acts as the source of truth for the reservation operation. The client submits only the `foodId` and never writes reservation data directly. See ServiceContract_Backend_API_Surplus_Food_Android_MVP.md for the request/response contract.

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-061 | `reserveFood` shall authenticate the caller; unauthenticated calls shall be rejected. | MVP |
| SR-FR-062 | `reserveFood` shall reject calls from users whose role is not `receiver`. | MVP |
| SR-FR-063 | `reserveFood` shall read the food document inside a Firestore transaction. | MVP |
| SR-FR-064 | `reserveFood` shall reject reservation when the food document does not exist. | MVP |
| SR-FR-065 | `reserveFood` shall reject reservation unless `food.status == available`. | MVP |
| SR-FR-066 | `reserveFood` shall reject reservation when `food.expiryAt <= server time`. | MVP |
| SR-FR-067 | `reserveFood` shall prevent a donor from reserving their own food. | MVP |
| SR-FR-068 | `reserveFood` shall generate the OTP server-side. | MVP |
| SR-FR-069 | `reserveFood` shall set `reservedAt` and `pickupDeadline` from server time, with `pickupDeadline = reservedAt + 30 minutes`. | MVP |
| SR-FR-070 | `reserveFood` shall create the reservation and update the food to `reserved` atomically in one transaction; any validation failure shall leave no partial data. | MVP |
| SR-FR-071 | `reserveFood` shall return the created reservation details (including reservation ID, deadline, and OTP) to the calling client. | MVP |
| SR-FR-072 | Client applications shall not directly change `food.status` to `reserved`, create reservations, generate OTPs, or decide pickup deadlines; the client shall send only `foodId` and handle the returned result. | MVP |

### 6.6 Timer And Release

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-033 | System shall display remaining pickup time on active reservation screen. | MVP |
| SR-FR-034 | System shall calculate remaining time from stored `pickupDeadline`. | MVP |
| SR-FR-035 | System shall mark active reservation as `expired` when pickup deadline passes. | DOC, MVP |
| SR-FR-036 | System shall return food to `available` after reservation timeout if food has not expired. | DOC, MVP |
| SR-FR-037 | System shall mark food as `expired` after reservation timeout if food expiry has passed. | DOC, MVP |

### 6.7 Cancel Reservation

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-038 | System shall allow a Receiver to cancel their active reservation before pickup completion. | MVP |
| SR-FR-039 | System shall set reservation status to `cancelled` on cancellation. | MVP |
| SR-FR-040 | System shall return food to `available` if cancelled before food expiry. | DOC, MVP |
| SR-FR-041 | System shall set food to `expired` if cancellation occurs after food expiry. | DOC, MVP |

### 6.8 OTP Verification

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-042 | System shall generate the OTP server-side (in `reserveFood`) when a reservation is created. | DOC, MVP |
| SR-FR-043 | OTP shall be stored with the reservation. | MVP |
| SR-FR-044 | System shall display the OTP to the Donor for the active reservation. | MVP |
| SR-FR-045 | System shall allow Receiver to enter OTP on reservation screen. | MVP |
| SR-FR-046 | System shall validate entered OTP against active reservation OTP. | DOC, MVP |
| SR-FR-047 | System shall reject incorrect OTP. | MVP |
| SR-FR-048 | System shall reject OTP verification after reservation deadline has passed. | MVP |
| SR-FR-049 | System shall set `otpVerified = true` and reservation status to `otp_verified` after correct OTP. | MVP |

### 6.9 Drop & Done Completion

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-050 | System shall expose Drop & Done only after OTP verification. | MVP |
| SR-FR-051 | System shall set food status to `completed` after Drop & Done. | MVP |
| SR-FR-052 | System shall set reservation status to `completed` after Drop & Done. | MVP |
| SR-FR-053 | System shall record completion timestamp. | MVP |

### 6.10 Location

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-054 | System shall request location permission when location is needed. | DOC, MVP |
| SR-FR-055 | System shall save pickup latitude and longitude on food listing. | DOC, MVP |
| SR-FR-056 | System shall open pickup location in maps app from receiver reservation/details screen. | MVP |
| SR-FR-057 | System should display approximate distance in kilometers when coordinates are available. | DOC, MVP |

### 6.11 Event Logs

| ID | System Requirement | Source |
|---|---|---|
| SR-FR-058 | System should record important actions in pickup logs. | DOC, MVP |
| SR-FR-059 | Log actions should include food posted, reserved, cancelled, timed out, OTP verified, and completed. | DOC, MVP |
| SR-FR-060 | Logs are for MVP traceability and demo; no analytics dashboard is required. | MVP |

## 7. Non-Functional Requirements

| ID | Requirement | Details |
|---|---|---|
| SR-NFR-001 | Security | Enforce role-based read/write rules in app and Firebase rules. |
| SR-NFR-002 | Data integrity | Reservation and food status changes must stay consistent. |
| SR-NFR-003 | Reliability | Timer behavior must work based on timestamps even after app restart. |
| SR-NFR-004 | Performance | Food list should load within 3 seconds for normal demo datasets. |
| SR-NFR-005 | Availability | App should show usable error states when Firebase/network is unavailable. |
| SR-NFR-006 | Usability | Forms should have clear labels, validation, and status feedback. |
| SR-NFR-007 | Maintainability | Keep business rules in services/helpers, not duplicated across screens. |
| SR-NFR-008 | Privacy | Show contact/location details only for relevant pickup context. |
| SR-NFR-009 | Compatibility | Support Android emulator and at least one physical Android device if available. |
| SR-NFR-010 | Auditability | Important lifecycle events should be logged for project demonstration. |

## 8. Database Design

### 8.1 Firestore Collections

```text
users/{userId}
foods/{foodId}
reservations/{reservationId}
pickup_logs/{logId}
```

### 8.2 `users` Collection

```json
{
  "userId": "auth_uid",
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "donor | receiver",
  "organizationName": "string",
  "profileImageUrl": "string|null",
  "latitude": 0.0,
  "longitude": 0.0,
  "verificationStatus": "pending | verified | rejected",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 8.3 `foods` Collection

```json
{
  "foodId": "auto_id",
  "donorId": "user_id",
  "foodName": "string",
  "foodType": "cooked | packed",
  "quantity": "string",
  "description": "string",
  "imageUrl": "string|null",
  "preparedAt": "timestamp",
  "expiryAt": "timestamp",
  "latitude": 0.0,
  "longitude": 0.0,
  "status": "available | reserved | completed | expired",
  "currentReservationId": "reservation_id|null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 8.4 `reservations` Collection

```json
{
  "reservationId": "auto_id",
  "foodId": "food_id",
  "donorId": "donor_user_id",
  "receiverId": "receiver_user_id",
  "reservedAt": "timestamp",
  "pickupDeadline": "timestamp",
  "otp": "string",
  "otpVerified": false,
  "status": "active | otp_verified | completed | cancelled | expired",
  "completedAt": "timestamp|null",
  "cancelledAt": "timestamp|null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Reservations are created only by the server-side `reserveFood` Cloud Function (SR-FR-028, SR-FR-061..071): `otp` is server-generated, and `reservedAt`/`pickupDeadline` come from server time. Clients may only read reservations they participate in and update their own participant transitions.

### 8.5 `pickup_logs` Collection

```json
{
  "logId": "auto_id",
  "foodId": "food_id",
  "reservationId": "reservation_id|null",
  "actorId": "user_id",
  "action": "FOOD_POSTED | RESERVED | RESERVATION_CANCELLED | RESERVATION_EXPIRED | OTP_VERIFIED | PICKUP_COMPLETED | FOOD_EXPIRED",
  "timestamp": "timestamp",
  "notes": "string|null"
}
```

## 9. Business Logic Specifications

### 9.1 Expiry Calculation

```text
if foodType == cooked:
    expiryAt = preparedAt + 4 hours

if foodType == packed:
    expiryAt = preparedAt + 8 hours
```

Rules:

| ID | Rule |
|---|---|
| BL-EXP-01 | Expiry must be calculated by the system. |
| BL-EXP-02 | User must not manually set expiry duration. |
| BL-EXP-03 | If `expiryAt <= now`, food must not be available for reservation. |

### 9.2 Reservation Transaction

Reservation creation is **server-side**: it runs inside the `reserveFood` Callable Cloud Function using an atomic Firestore transaction with server time. The client sends only `foodId`.

```text
reserveFood(foodId) runs on the server:
  -> authenticate caller, verify role == receiver
  -> BEGIN Firestore transaction
  ->   Read food
  ->     verify food exists
  ->     verify status == available
  ->     verify expiryAt > server time
  ->     verify donorId != caller uid
  ->   Generate OTP (server-side)
  ->   Set reservedAt = server time
  ->   Set pickupDeadline = reservedAt + 30 minutes
  ->   Create reservation (status active, otp, otpVerified false)
  ->   Update food.status = reserved, food.currentReservationId = reservationId
  ->   Write pickup log (action RESERVED)
  -> COMMIT (abort on any failed verify — no partial data)
  -> Return reservation details to the client
```

Failure cases:

| Case | Expected Result |
|---|---|
| Food does not exist | Reject with "not-found" error. |
| Food already reserved | Reject with message: "Food is already reserved." |
| Food expired | Reject with "expired" error. |
| User is donor / not a receiver | Reject with role error. |
| Donor reserves own food | Reject with "own donation" error. |
| Network failure | Show failure and do not update UI as reserved until confirmed. |

### 9.3 Reservation Release

```text
if reservation.status == active and now >= pickupDeadline:
    reservation.status = expired

    if food.expiryAt > now:
        food.status = available
        food.currentReservationId = null
    else:
        food.status = expired
        food.currentReservationId = null
```

This check can run:

| Trigger | Requirement |
|---|---|
| App startup | Check active reservations for logged-in user. |
| Dashboard load | Check visible food/reservation items. |
| Reservation screen timer end | Update reservation and food. |
| Optional Cloud Function | Scheduled `releaseExpiredReservations` sweeper can automate cleanup after MVP if time permits. |

### 9.4 OTP Verification

```text
if reservation.status == active
and now < pickupDeadline
and enteredOtp == reservation.otp:
    otpVerified = true
    reservation.status = otp_verified
else:
    show error
```

OTP requirements:

| ID | Requirement |
|---|---|
| OTP-01 | OTP should be 6 digits. |
| OTP-02 | OTP should be generated server-side when the reservation is created by `reserveFood`. |
| OTP-03 | OTP should be valid only for the active reservation before pickup deadline. |
| OTP-04 | OTP should not complete pickup by itself; Drop & Done finalizes completion. |

### 9.5 Drop & Done

```text
if reservation.status == otp_verified and reservation.otpVerified == true:
    reservation.status = completed
    reservation.completedAt = now
    food.status = completed
    food.currentReservationId = reservationId
```

## 10. State Transition Tables

### 10.1 Food State Transitions

| Current State | Event | Next State | Allowed |
|---|---|---|---|
| available | Receiver reserves | reserved | Yes |
| available | Expiry time passes | expired | Yes |
| reserved | Receiver cancels before food expiry | available | Yes |
| reserved | Receiver cancels after food expiry | expired | Yes |
| reserved | Pickup deadline passes before food expiry | available | Yes |
| reserved | Pickup deadline passes after food expiry | expired | Yes |
| reserved | OTP verified + Drop & Done | completed | Yes |
| completed | Any reserve/cancel action | completed | No change |
| expired | Reserve action | expired | No change |

### 10.2 Reservation State Transitions

| Current State | Event | Next State | Allowed |
|---|---|---|---|
| active | Correct OTP entered | otp_verified | Yes |
| active | Wrong OTP entered | active | Yes |
| active | Receiver cancels | cancelled | Yes |
| active | Pickup deadline passes | expired | Yes |
| otp_verified | Drop & Done | completed | Yes |
| otp_verified | Cancel | otp_verified | No |
| completed | Cancel/expire | completed | No |
| cancelled | OTP/complete | cancelled | No |
| expired | OTP/complete | expired | No |

## 11. Module Requirements

### 11.1 Auth Module

Responsibilities:

| Requirement |
|---|
| Register users with email/password. |
| Login users. |
| Fetch user profile after auth. |
| Route by role. |
| Handle logout. |

### 11.2 User/Profile Module

Responsibilities:

| Requirement |
|---|
| Create user profile document. |
| Display profile details. |
| Update editable fields. |
| Display verification status. |
| Store profile location if permission is granted. |

### 11.3 Food Module

Responsibilities:

| Requirement |
|---|
| Validate post food form. |
| Upload/select image if included. |
| Calculate expiry from type and preparation time. |
| Create food document. |
| Query donor's own listings. |
| Query receiver's available listings. |
| Mark expired listings based on timestamp. |

### 11.4 Reservation Module

Responsibilities:

| Requirement |
|---|
| Call `reserveFood` Cloud Function with only `foodId` and handle the result/errors. |
| Receive OTP, `reservedAt`, and `pickupDeadline` from the function response. |
| Display active reservation. |
| Cancel reservation. |
| Release timed-out reservation. |
| Keep food and reservation states synchronized. |

### 11.5 Pickup Module

Responsibilities:

| Requirement |
|---|
| Display OTP to donor. |
| Accept OTP from receiver. |
| Validate OTP. |
| Enable Drop & Done after OTP verification. |
| Complete pickup transaction. |

### 11.6 Location Module

Responsibilities:

| Requirement |
|---|
| Request location permission. |
| Capture current coordinates. |
| Save pickup coordinates on food listing. |
| Calculate approximate distance. |
| Open external maps app for navigation. |

### 11.7 Logging Module

Responsibilities:

| Requirement |
|---|
| Write lifecycle logs for major events. |
| Support simple history display if time allows. |
| Keep logs lightweight; no analytics dashboard. |

## 12. Screen Requirements

### 12.1 Login Screen

Fields:

| Field | Validation |
|---|---|
| Email | Required, valid email format |
| Password | Required |

Actions:

| Action | Result |
|---|---|
| Login | Authenticate and route by role |
| Go to Register | Open Register screen |

### 12.2 Register Screen

Fields:

| Field | Validation |
|---|---|
| Name | Required |
| Email | Required, valid email |
| Phone | Required |
| Password | Required, minimum length decided by Firebase/app policy |
| Role | Required: Donor or Receiver |
| Organization name | Required |

Result:

| Action | Result |
|---|---|
| Submit | Create auth account and `users/{uid}` profile |

### 12.3 Donor Dashboard

Must show:

| Element |
|---|
| Post Food action |
| List of donor's food items |
| Status badges: available, reserved, completed, expired |
| Empty state when no donations exist |

### 12.4 Post Food Screen

Fields:

| Field | Validation |
|---|---|
| Food name | Required |
| Food type | Required: cooked or packed |
| Quantity/servings | Required |
| Description | Required |
| Preparation time | Required |
| Image | Required if image upload is included in build |
| Pickup location | Required |
| Expiry preview | Read-only, calculated |

### 12.5 Receiver Dashboard

Must show:

| Element |
|---|
| Available non-expired food list |
| Food image/name/quantity |
| Expiry countdown |
| Distance if available |
| View Details action |
| Empty state when no food is available |

### 12.6 Food Details Screen

Must show:

| Field |
|---|
| Food name |
| Food image |
| Food type |
| Quantity |
| Description |
| Preparation time |
| Expiry time/countdown |
| Donor organization |
| Pickup location |
| Distance if available |
| Current status |

Receiver action:

| Action | Condition |
|---|---|
| Reserve Food | Only if food is available and not expired |

### 12.7 Reservation/Pickup Screen

Must show:

| Element |
|---|
| Food summary |
| Donor information |
| Pickup location |
| Open Maps action |
| 30-minute countdown |
| OTP input |
| Cancel reservation action |
| Verification result |
| Drop & Done action after OTP verification |

### 12.8 Profile Screen

Must show:

| Element |
|---|
| Name |
| Email |
| Phone |
| Organization name |
| Role |
| Location |
| Verification status |
| Profile image if implemented |

## 13. Permissions And Device Requirements

| Android Permission | Required | Usage |
|---|---|---|
| Internet | Yes | Firebase and storage access |
| Fine/Coarse Location | Yes | Capture user/pickup location and calculate distance |
| Camera | Optional | Capture food/profile image |
| Read Media/Photos | Yes if image upload is used | Select images from device |
| Notifications | Optional | Future status alerts, not required for MVP |

Permission handling:

| Case | Expected Behavior |
|---|---|
| Location granted | Use current coordinates. |
| Location denied | Show message and allow retry/manual location path if implemented. |
| Media permission denied | Show message and allow retry. |

## 14. Security Rules Requirement Summary

Firebase rules should enforce:

| Rule |
|---|
| Authenticated users can read their own user document. |
| Authenticated users can update their own editable profile fields. |
| Donors can create food only with `donorId == auth.uid`. |
| Donors can update only their own food records where allowed. |
| Receivers can read available food records. |
| Clients cannot create reservation documents — reservation creation is server-side only (`reserveFood` Cloud Function). |
| Clients cannot write `food.status = reserved` directly. |
| Reservation status and food status changes (cancel, timeout, OTP verify, Drop & Done) are restricted to the participant transitions allowed by the state tables. |
| Users can read reservations where they are donor or receiver. |

App-side validation must still exist for UX, but Firebase rules and the `reserveFood` Cloud Function must protect the database from invalid direct writes; Firebase is the source of truth.

## 15. Validation Rules

| Entity | Field | Validation |
|---|---|---|
| User | email | Required, valid email |
| User | phone | Required, non-empty |
| User | role | Must be `donor` or `receiver` |
| User | verificationStatus | Must be `pending`, `verified`, or `rejected` |
| Food | foodName | Required |
| Food | foodType | Must be `cooked` or `packed` |
| Food | quantity | Required and positive/meaningful |
| Food | preparedAt | Required |
| Food | expiryAt | Must match food type rule |
| Food | status | Must be valid food status |
| Reservation | pickupDeadline | Must equal `reservedAt + 30 minutes` |
| Reservation | otp | Required |
| Reservation | status | Must be valid reservation status |

## 16. Edge Cases And Error Handling

| ID | Scenario | System Behavior |
|---|---|---|
| SR-EC-001 | Duplicate reservation attempt | First `reserveFood` call succeeds; later calls fail with already-reserved error. |
| SR-EC-002 | Food expires while receiver views details | Reserve action fails and UI refreshes status. |
| SR-EC-003 | Timer ends while app is closed | On app resume/load, status is recalculated from timestamps. |
| SR-EC-004 | Receiver cancels reservation | Reservation cancelled; food available/expired based on expiry time. |
| SR-EC-005 | OTP entered incorrectly | Error shown; no status change except optional attempt counter if implemented. |
| SR-EC-006 | OTP entered after pickup deadline | Verification rejected; reservation released/expired. |
| SR-EC-007 | Donor tries to access receiver dashboard | Access denied or routed to donor dashboard. |
| SR-EC-008 | Receiver tries to post food | Access denied. |
| SR-EC-009 | Firebase write or callable fails | Show error and keep previous confirmed state; reservation state only updates after a successful `reserveFood` response. |
| SR-EC-010 | Image upload fails | Show retry error before food submission. |
| SR-EC-011 | Location unavailable | Prompt user to retry or manually proceed only if manual location is implemented. |
| SR-EC-012 | Completed food opened again | Show read-only completed state. |
| SR-EC-013 | `reserveFood` unavailable (offline / outage) | Show network error; no reservation is created or assumed. |

## 17. Testing Requirements

### 17.1 Unit Tests / Logic Tests

| Test Area | Required Cases |
|---|---|
| Expiry calculation | Cooked +4 hours, packed +8 hours |
| Reservation deadline | `pickupDeadline = reservedAt + 30 minutes` (server-set) |
| `reserveFood` callable | Auth required; role == receiver; not-found; already-reserved; expired; own-food; success returns reservation with 6-digit server OTP |
| Client boundary | Direct reservation create DENIED by rules; `food.status = reserved` write DENIED by rules |
| Status transitions | Available to reserved to completed |
| Cancel logic | Reserved to available or expired |
| OTP logic | Correct, incorrect, after deadline |

### 17.2 Integration Tests / Manual Demo Tests

| Flow | Expected Result |
|---|---|
| Donor registration | Donor profile created and donor dashboard opened |
| Receiver registration | Receiver profile created and receiver dashboard opened |
| Post cooked food | Food visible with +4 hour expiry |
| Post packed food | Food visible with +8 hour expiry |
| Receiver reserve | `reserveFood` callable creates reservation (server OTP, server deadline); food becomes reserved and timer starts |
| Second receiver reserve same food | Reservation fails with already-reserved error |
| Cancel reservation | Food returns to available if not expired |
| Timeout reservation | Food released or expired correctly |
| OTP pickup | Wrong OTP fails; correct OTP verifies |
| Drop & Done | Food and reservation become completed |

## 18. Acceptance Criteria

The SRD is satisfied when:

| ID | Acceptance Criteria |
|---|---|
| AC-01 | Donor and Receiver can register/login with separate roles. |
| AC-02 | Role-based routing and access restrictions work. |
| AC-03 | Donor can post cooked and packed food with automatic expiry. |
| AC-04 | Receiver can view available non-expired food details. |
| AC-05 | Receiver can reserve food via the `reserveFood` callable and trigger a 30-minute pickup deadline set by server time. |
| AC-06 | Duplicate reservations are prevented (exactly one `reserveFood` call succeeds). |
| AC-07 | Receiver can cancel reservation and release food if valid. |
| AC-08 | Timed-out reservation is handled correctly. |
| AC-09 | OTP verification works for success and failure cases. |
| AC-10 | Drop & Done completes the donation. |
| AC-11 | Food and reservation statuses remain consistent in Firestore. |
| AC-12 | Location can be saved and opened in maps. |
| AC-13 | Profile and verification status are visible. |
| AC-14 | AI/admin/chat/analytics are not required to complete MVP. |
| AC-15 | Reservation integrity is enforced server-side: clients cannot create reservations, generate OTPs, decide deadlines, or write `food.status = reserved` directly. |

## 19. Two-Week Build Plan

### Week 1

| Day | Deliverable | Acceptance |
|---|---|---|
| 1 | Project setup and Firebase connection | App builds and connects to Firebase |
| 2 | Auth and role profiles | Donor/Receiver can register and route correctly |
| 3 | Donor Dashboard and Post Food | Donor can create food listing |
| 4 | Expiry, image, location, food details | Food has calculated expiry and details screen |
| 5 | Receiver Dashboard and available list | Receiver sees available food |
| 6 | Server-side reservation and timer | `reserveFood` Cloud Function deployed; Reserve creates reservation (server OTP, +30 min deadline) and starts timer |
| 7 | OTP and Drop & Done | Pickup can be verified and completed |

### Week 2

| Day | Deliverable | Acceptance |
|---|---|---|
| 8 | Cancel/release/expiry handling + optional sweeper | Cancel and timeout work; optional scheduled `releaseExpiredReservations` deployed |
| 9 | Maps and distance | Pickup location opens in maps |
| 10 | Profile verification display | Profiles show status and data |
| 11 | Pickup logs | Major events are recorded |
| 12 | UI validation and error states | Forms and failures are handled |
| 13 | End-to-end testing | Full demo passes |
| 14 | Polish and APK/demo prep | App ready for capstone presentation |

## 20. Future Enhancements Outside MVP

These are intentionally excluded:

| Future Feature | Reason Not In MVP |
|---|---|
| Admin dashboard | Requires extra role and management screens. |
| AI expiry prediction | Fixed expiry rules are enough for MVP. |
| AI image validation | Adds complexity without blocking core flow. |
| Advanced NGO matching | Basic listing/distance is enough for demo. |
| Chatbot | Not part of food pickup lifecycle. |
| Analytics | Not required for transaction completion. |
| Full notification workflow | Useful later, not required for MVP acceptance. |

## 21. Final System Requirement Statement

The Android MVP system shall provide a reliable role-based surplus food donation flow where Donors post food, Receivers reserve and collect food within 30 minutes, OTP verifies pickup, and Drop & Done completes the transaction. The implementation must preserve the locked 2-week scope and avoid adding non-MVP features that could delay the capstone build.
