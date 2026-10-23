# Product Requirements Document: Surplus Food Redistribution System Android MVP

## 1. Document Control

| Field | Details |
|---|---|
| Project | Surplus Food Redistribution System Android MVP |
| Document type | Product Requirements Document |
| Target users | Donors and Receivers |
| Academic context | BCA capstone project |
| MVP duration | 2 weeks |
| Platform | Android |
| Recommended stack | Flutter + Firebase |
| Version | 1.0 |

## 2. Source And Scope Traceability

This PRD separates requirements by source:

| Label | Meaning |
|---|---|
| DOC | Requirement supported by the uploaded project report/presentation as recovered from the referenced project discussion. The report/presentation described restaurant/donor, NGO/receiver, and admin actors; food posting; reservation; pickup verification; expiry handling; location matching; notifications; audit/Digital Clean Chain logs; Flutter/Firebase architecture; Google Maps; and QR/OTP pickup verification. |
| MVP | Requirement locked in the conversation for the 2-week Android MVP. These decisions intentionally reduce the original project into a buildable capstone demo. |

The original uploaded files are not present in the local workspace mirror, so this document uses the prior conversation's recovered summaries of the report and presentation as the project source record.

## 3. Product Overview

The Surplus Food Redistribution System Android MVP is a mobile application that connects food donors with receivers so safe surplus food can be posted, reserved, picked up, and marked complete before expiry.

The MVP focuses on one working end-to-end flow:

```text
Donor registers/logs in
  -> Donor posts surplus food
  -> Food becomes available
  -> Receiver views food details
  -> Receiver reserves food
  -> 30-minute pickup timer starts
  -> Receiver reaches pickup location
  -> OTP verification confirms handover
  -> Drop & Done completes the donation
```

## 4. Product Goals

| ID | Goal | Source |
|---|---|---|
| PG-01 | Enable donors to post surplus food with quantity, type, image, location, and expiry details. | DOC, MVP |
| PG-02 | Enable receivers to discover available food and reserve a single food item. | DOC, MVP |
| PG-03 | Prevent reserved food from being claimed by multiple receivers. | DOC, MVP |
| PG-04 | Enforce a 30-minute pickup window after reservation. | DOC, MVP |
| PG-05 | Release reserved food automatically or manually if pickup does not happen. | DOC, MVP |
| PG-06 | Confirm pickup using OTP verification. | DOC, MVP |
| PG-07 | Maintain a clear donation lifecycle from posting to completion. | DOC, MVP |
| PG-08 | Keep the MVP small enough to build, test, and present in 2 weeks. | MVP |

## 5. Explicit MVP Scope

### 5.1 In Scope

| Feature | Requirement | Source |
|---|---|---|
| Authentication | Donor and Receiver login/register. | MVP |
| Role-based accounts | User role controls dashboard and permissions. | DOC, MVP |
| Donor Dashboard | Donor can view donation status and post food. | DOC, MVP |
| Post Food | Donor can create a surplus food listing. | DOC, MVP |
| Automatic expiry | Cooked food expires after 4 hours; packed food expires after 8 hours. | MVP |
| Food Details | Both roles can view food details according to permissions. | DOC, MVP |
| Reserve Food | Receiver can reserve available food. | DOC, MVP |
| 30-minute pickup timer | Reservation creates a pickup deadline 30 minutes later. | DOC, MVP |
| Cancel/Release Reservation | Receiver can cancel; system can release missed reservations. | DOC, MVP |
| Pickup Confirmation | Food handover can be confirmed. | DOC, MVP |
| OTP Verification | OTP confirms the receiver at pickup time. | DOC, MVP |
| Location | Store pickup location and allow map navigation/basic distance display. | DOC, MVP |
| User Profile/Verification | Users maintain profile details and a verification status. | DOC, MVP |
| Drop & Done | Final action after OTP that marks donation completed. | MVP |

### 5.2 Out Of Scope For MVP

| Feature | Reason |
|---|---|
| AI expiry prediction | Replaced by fixed rule: cooked = 4 hours, packed = 8 hours. |
| AI image verification | Not needed for 2-week core demo. |
| Admin panel | Verification can be handled manually in Firebase during demo/testing. |
| Advanced NGO matching | MVP uses basic available listing and optional distance sorting. |
| Chatbot | Not required for core redistribution workflow. |
| Analytics dashboard | Not required for MVP completion. |
| Full notification system | Optional only after core flow is complete. |
| Payment, rewards, or monetization | Not part of project MVP. |

## 6. Personas And Roles

### 6.1 Donor

| Field | Details |
|---|---|
| Examples | Restaurant, canteen, event organizer, food provider |
| Goal | Quickly post safe surplus food and complete handover |
| Primary actions | Register, complete profile, post food, monitor reservation, share OTP, mark Drop & Done |
| Pain points | Food may expire quickly; donor needs a simple posting flow |
| Success measure | Food is picked up before expiry with minimal manual coordination |
| Source | DOC, MVP |

### 6.2 Receiver

| Field | Details |
|---|---|
| Examples | NGO, volunteer group, receiver organization |
| Goal | Find nearby available food and collect it within time |
| Primary actions | Register, complete profile, view available food, reserve, navigate, verify pickup |
| Pain points | Must know food details, location, and remaining time clearly |
| Success measure | Reservation is completed within 30 minutes |
| Source | DOC, MVP |

## 7. Product Success Metrics

For the BCA capstone MVP, success is measured by functional completion rather than production-scale adoption.

| ID | Metric | Target |
|---|---|---|
| SM-01 | Donor-to-receiver demo flow completion | 100% for prepared demo users |
| SM-02 | Food expiry calculation correctness | 100% for cooked and packed test cases |
| SM-03 | Duplicate reservation prevention | 100% in manual test cases |
| SM-04 | OTP validation correctness | Correct OTP succeeds; wrong OTP fails |
| SM-05 | Reservation release behavior | Cancelled/timed-out reservations return food to available if not expired |
| SM-06 | Core screens implemented | Login, Register, Donor Dashboard, Post Food, Receiver Dashboard, Food Details, Reservation, OTP/Drop & Done, Profile |

## 8. User Journeys

### 8.1 Donor Registration And Profile

| Step | User Action | System Response | Source |
|---|---|---|---|
| 1 | Donor opens app and selects Register. | App displays registration form. | MVP |
| 2 | Donor enters name, email, phone, password, organization, role = Donor. | App creates account and user profile. | DOC, MVP |
| 3 | Donor adds location/profile details. | App saves profile and verification status. | DOC, MVP |
| 4 | Donor logs in later. | App routes donor to Donor Dashboard. | MVP |

### 8.2 Donor Posts Food

| Step | User Action | System Response | Source |
|---|---|---|---|
| 1 | Donor taps Post Food. | App opens food posting form. | DOC, MVP |
| 2 | Donor enters food name, type, quantity, description, preparation time, image, and pickup location. | App validates required fields. | DOC, MVP |
| 3 | Donor chooses food type: Cooked or Packed. | App calculates expiry automatically. | MVP |
| 4 | Donor submits. | Food listing is created with status `available`. | DOC, MVP |
| 5 | Donor returns to dashboard. | Listing appears under active donations. | MVP |

### 8.3 Receiver Reserves Food

| Step | User Action | System Response | Source |
|---|---|---|---|
| 1 | Receiver logs in. | App routes receiver to Receiver Dashboard. | MVP |
| 2 | Receiver views available food. | App lists non-expired food with status `available`. | DOC, MVP |
| 3 | Receiver opens Food Details. | App shows image, quantity, expiry, donor details, location, and status. | DOC, MVP |
| 4 | Receiver taps Reserve. | App creates reservation, generates OTP, and changes food status to `reserved`. | DOC, MVP |
| 5 | App starts countdown. | Pickup deadline = reservation time + 30 minutes. | DOC, MVP |

### 8.4 Cancel Or Release Reservation

| Step | Trigger | System Response | Source |
|---|---|---|---|
| 1 | Receiver taps Cancel before pickup. | Reservation becomes `cancelled`. | MVP |
| 2 | Food has not expired. | Food returns to `available`. | DOC, MVP |
| 3 | Pickup deadline passes before confirmation. | Reservation becomes `expired`; food returns to `available` only if food expiry has not passed. | DOC, MVP |
| 4 | Food expiry has passed. | Food becomes `expired` and cannot be reserved. | DOC, MVP |

### 8.5 OTP Pickup And Drop & Done

| Step | User Action | System Response | Source |
|---|---|---|---|
| 1 | Receiver reaches pickup location. | Receiver opens reservation screen. | MVP |
| 2 | Donor shares OTP shown for the reservation. | Receiver enters OTP. | DOC, MVP |
| 3 | OTP is correct. | App marks OTP verified and enables Drop & Done. | DOC, MVP |
| 4 | Drop & Done is completed. | Food becomes `completed`; reservation becomes `completed`. | MVP |
| 5 | OTP is wrong. | App shows validation error and keeps reservation active if time remains. | MVP |

## 9. Functional Requirements

### 9.1 Authentication And Role Management

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-01 | The app shall allow users to register using email, password, name, phone, role, and organization name. | Must | MVP |
| FR-02 | The app shall support exactly two MVP roles: Donor and Receiver. | Must | MVP |
| FR-03 | The app shall save the selected role in the user profile. | Must | MVP |
| FR-04 | The app shall route Donor users to the Donor Dashboard after login. | Must | MVP |
| FR-05 | The app shall route Receiver users to the Receiver Dashboard after login. | Must | MVP |
| FR-06 | The app shall prevent users from accessing screens not allowed for their role. | Must | MVP |

### 9.2 User Profile And Verification

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-07 | The app shall allow users to view and edit basic profile information. | Must | DOC, MVP |
| FR-08 | Donor profile shall include name, organization/business name, phone, email, location, profile image, and verification status. | Must | MVP |
| FR-09 | Receiver profile shall include name, organization/NGO name, phone, email, location, optional ID/document information, and verification status. | Must | MVP |
| FR-10 | The app shall store verification status as `pending`, `verified`, or `rejected`. | Must | MVP |
| FR-11 | For MVP, verification status may be updated manually in Firebase instead of an in-app admin panel. | Must | MVP |

### 9.3 Donor Dashboard

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-12 | Donor Dashboard shall show the donor's active, reserved, completed, and expired donations. | Must | MVP |
| FR-13 | Donor Dashboard shall include a clear Post Food action. | Must | MVP |
| FR-14 | Donor Dashboard shall show current status for each food item. | Must | DOC, MVP |

### 9.4 Post Food

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-15 | Donor shall be able to create a food listing. | Must | DOC, MVP |
| FR-16 | Food posting form shall include food name, food type, quantity/servings, description, preparation time, image, and pickup location. | Must | DOC, MVP |
| FR-17 | Food type shall be limited to `cooked` or `packed`. | Must | MVP |
| FR-18 | If food type is `cooked`, expiry time shall be preparation time + 4 hours. | Must | MVP |
| FR-19 | If food type is `packed`, expiry time shall be preparation time + 8 hours. | Must | MVP |
| FR-20 | Donor shall not manually enter expiry duration. | Must | MVP |
| FR-21 | A newly posted valid food item shall be saved with status `available`. | Must | DOC, MVP |

### 9.5 Receiver Dashboard And Food Discovery

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-22 | Receiver Dashboard shall list available, non-expired food items. | Must | DOC, MVP |
| FR-23 | Each food card shall show image, name, quantity, distance if available, expiry countdown, and View Details action. | Must | MVP |
| FR-24 | The app may sort food by nearest distance when receiver location is available. | Should | DOC, MVP |
| FR-25 | The app shall hide or disable food that is expired, reserved, or completed. | Must | DOC, MVP |

### 9.6 Food Details

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-26 | Food Details shall show food name, image, type, quantity, description, preparation time, expiry time, donor details, pickup location, distance, and status. | Must | DOC, MVP |
| FR-27 | Receiver shall see Reserve Food only when food status is `available` and food is not expired. | Must | MVP |
| FR-28 | Donor shall see reservation and pickup status for their own food items. | Must | MVP |

### 9.7 Reservation

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-29 | Receiver shall be able to reserve one available food listing. | Must | DOC, MVP |
| FR-30 | The system shall prevent more than one active reservation per food item. | Must | DOC, MVP |
| FR-31 | On reservation, food status shall change from `available` to `reserved`. | Must | DOC, MVP |
| FR-32 | On reservation, system shall create a reservation record with receiver ID, donor ID, food ID, reserved time, pickup deadline, OTP, and status. | Must | MVP |
| FR-33 | Pickup deadline shall be reservation time + 30 minutes. | Must | DOC, MVP |

### 9.8 Pickup Timer

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-34 | Reservation screen shall display a countdown timer until pickup deadline. | Must | MVP |
| FR-35 | If countdown reaches zero before pickup confirmation, reservation shall be released or expired according to food expiry rules. | Must | DOC, MVP |
| FR-36 | Timer shall be based on stored server/database timestamps, not only local screen state. | Must | MVP |

### 9.9 Cancel And Release

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-37 | Receiver shall be able to cancel an active reservation before pickup confirmation. | Must | MVP |
| FR-38 | Cancelled reservation shall update status to `cancelled`. | Must | MVP |
| FR-39 | Cancelled food shall return to `available` if food expiry time has not passed. | Must | DOC, MVP |
| FR-40 | Cancelled food shall become `expired` if food expiry time has passed. | Must | DOC, MVP |

### 9.10 OTP Verification And Pickup Confirmation

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-41 | System shall generate an OTP when a reservation is created. | Must | DOC, MVP |
| FR-42 | OTP shall be associated with only one active reservation. | Must | MVP |
| FR-43 | Receiver shall enter OTP during pickup confirmation. | Must | MVP |
| FR-44 | Correct OTP shall mark the reservation as OTP verified. | Must | DOC, MVP |
| FR-45 | Wrong OTP shall show an error and shall not complete pickup. | Must | MVP |
| FR-46 | After successful OTP verification, Drop & Done shall mark food and reservation as completed. | Must | MVP |

### 9.11 Location

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-47 | Donor shall be able to attach current GPS location or manually selected pickup coordinates to a food listing. | Must | DOC, MVP |
| FR-48 | Receiver shall be able to view pickup location. | Must | DOC, MVP |
| FR-49 | Receiver shall be able to open pickup location in Google Maps or the device maps app. | Must | MVP |
| FR-50 | App shall display approximate distance when donor and receiver coordinates are available. | Should | DOC, MVP |

### 9.12 Drop & Done

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-51 | Drop & Done shall be the final transaction completion action. | Must | MVP |
| FR-52 | Drop & Done shall be available only after valid OTP verification. | Must | MVP |
| FR-53 | Drop & Done shall set food status to `completed` and reservation status to `completed`. | Must | MVP |

## 10. Business Rules

| ID | Rule | Source |
|---|---|---|
| BR-01 | Only registered users can access dashboards. | MVP |
| BR-02 | Each user must have exactly one MVP role: Donor or Receiver. | MVP |
| BR-03 | Donors can create food listings; receivers cannot. | MVP |
| BR-04 | Receivers can reserve food; donors cannot reserve their own listings. | MVP |
| BR-05 | Cooked food expiry = preparation time + 4 hours. | MVP |
| BR-06 | Packed food expiry = preparation time + 8 hours. | MVP |
| BR-07 | Expired food cannot be reserved. | DOC, MVP |
| BR-08 | Only one active reservation is allowed per food item. | DOC, MVP |
| BR-09 | Pickup deadline = reserved time + 30 minutes. | DOC, MVP |
| BR-10 | A cancelled reservation releases the food only if the food has not expired. | DOC, MVP |
| BR-11 | A timed-out reservation releases the food only if the food has not expired. | DOC, MVP |
| BR-12 | Correct OTP is required before Drop & Done completion. | DOC, MVP |
| BR-13 | Completed food cannot return to available. | MVP |
| BR-14 | User verification status is shown in profile. For MVP, verified test users may be created or updated manually through Firebase. | MVP |

## 11. Screen And Module Requirements

### 11.1 Common Screens

| Screen | Main Elements | Actions |
|---|---|---|
| Splash/Startup | App logo/name, loading state | Check login state |
| Login | Email, password, login button, register link | Login and route by role |
| Register | Name, email, phone, password, role, organization | Create user account/profile |
| Profile | User details, verification status, location, profile image | View/edit profile |

### 11.2 Donor Screens

| Screen | Main Elements | Actions |
|---|---|---|
| Donor Dashboard | Summary counts, donation list, status tags, Post Food button | Open donation details, post food |
| Post Food | Food name, type, quantity, description, preparation time, expiry preview, image picker, location selector | Submit listing |
| Donor Food Details | Food info, reservation status, receiver info when reserved, OTP display when active | Monitor pickup |
| Drop & Done/Pickup Status | OTP status, pickup status, completion action | Complete handover after OTP |

### 11.3 Receiver Screens

| Screen | Main Elements | Actions |
|---|---|---|
| Receiver Dashboard | Available food list, expiry countdown, distance, empty state | Open food details |
| Food Details | Full food details, donor info, map option, Reserve button | Reserve food |
| Reservation Screen | Food info, donor info, location, OTP entry, 30-minute timer, cancel button | Enter OTP, cancel, open maps |
| My Reservations | Active, cancelled, completed reservations | Resume active pickup flow |

## 12. Permissions

| Permission | Purpose | Required For MVP |
|---|---|---|
| Internet | Firebase authentication, database, storage | Yes |
| Location | Save pickup location and show receiver distance/navigation | Yes |
| Camera | Capture food image or profile image if implemented | Optional |
| Photos/Media | Upload food image/profile image | Yes if image upload is included |
| Notifications | Notify about reservation/status changes | Optional for MVP |

## 13. Data Model Summary

### 13.1 User

| Field | Type | Required | Notes |
|---|---|---|---|
| userId | string | Yes | Firebase Auth UID |
| name | string | Yes | User full name |
| email | string | Yes | Login email |
| phone | string | Yes | Contact number |
| role | enum | Yes | `donor`, `receiver` |
| organizationName | string | Yes | Business/NGO name |
| profileImageUrl | string | No | Firebase Storage URL |
| latitude | number | No | User/profile location |
| longitude | number | No | User/profile location |
| verificationStatus | enum | Yes | `pending`, `verified`, `rejected` |
| createdAt | timestamp | Yes | Account creation time |
| updatedAt | timestamp | Yes | Last profile update |

### 13.2 Food

| Field | Type | Required | Notes |
|---|---|---|---|
| foodId | string | Yes | Document ID |
| donorId | string | Yes | Creator user ID |
| foodName | string | Yes | Name/title |
| foodType | enum | Yes | `cooked`, `packed` |
| quantity | string/number | Yes | Servings or quantity label |
| description | string | Yes | Food details |
| imageUrl | string | No | Food image |
| preparedAt | timestamp | Yes | Preparation/packaging time |
| expiryAt | timestamp | Yes | Auto-calculated |
| latitude | number | Yes | Pickup location |
| longitude | number | Yes | Pickup location |
| status | enum | Yes | Food lifecycle status |
| currentReservationId | string | No | Active reservation reference |
| createdAt | timestamp | Yes | Listing creation time |
| updatedAt | timestamp | Yes | Last update |

### 13.3 Reservation

| Field | Type | Required | Notes |
|---|---|---|---|
| reservationId | string | Yes | Document ID |
| foodId | string | Yes | Reserved food |
| donorId | string | Yes | Donor user ID |
| receiverId | string | Yes | Receiver user ID |
| reservedAt | timestamp | Yes | Reservation creation time |
| pickupDeadline | timestamp | Yes | Reserved time + 30 minutes |
| otp | string | Yes | Verification code |
| otpVerified | boolean | Yes | Default false |
| status | enum | Yes | Reservation lifecycle status |
| completedAt | timestamp | No | Completion time |
| cancelledAt | timestamp | No | Cancellation time |

### 13.4 Pickup Log

| Field | Type | Required | Notes |
|---|---|---|---|
| logId | string | Yes | Document ID |
| foodId | string | Yes | Related food |
| reservationId | string | No | Related reservation |
| actorId | string | Yes | User who triggered action |
| action | enum | Yes | Example: `FOOD_POSTED`, `RESERVED`, `OTP_VERIFIED`, `COMPLETED` |
| timestamp | timestamp | Yes | Event time |
| notes | string | No | Optional details |

## 14. State Transitions

### 14.1 Food Status

```text
draft/form
  -> available
  -> reserved
  -> completed

available
  -> expired

reserved
  -> available      when reservation is cancelled/timed out and food is not expired
  -> expired        when reservation is cancelled/timed out and food is expired
  -> completed      after OTP verification and Drop & Done
```

Allowed food statuses:

| Status | Meaning |
|---|---|
| available | Can be reserved by a receiver |
| reserved | Locked for one receiver |
| completed | Pickup and Drop & Done are complete |
| expired | Cannot be reserved |

### 14.2 Reservation Status

```text
active
  -> otp_verified
  -> completed

active
  -> cancelled

active
  -> expired
```

Allowed reservation statuses:

| Status | Meaning |
|---|---|
| active | Reservation is within pickup window |
| otp_verified | OTP has been validated but final completion is not yet recorded |
| completed | Food pickup is completed |
| cancelled | Receiver cancelled before pickup |
| expired | Pickup deadline passed |

## 15. Edge Cases

| ID | Edge Case | Expected Behavior |
|---|---|---|
| EC-01 | Two receivers tap Reserve at the same time. | Only one reservation succeeds through transaction/atomic update. |
| EC-02 | Receiver tries to reserve expired food. | App blocks reservation and updates/hides food as expired. |
| EC-03 | Receiver cancels after food expiry. | Reservation becomes cancelled; food becomes expired, not available. |
| EC-04 | Pickup timer reaches zero while app is closed. | On next read or scheduled check, reservation is expired/released based on stored timestamps. |
| EC-05 | Wrong OTP entered. | Show error; do not complete pickup. |
| EC-06 | Correct OTP entered after deadline. | Reject unless business logic explicitly allows grace period; MVP default is reject. |
| EC-07 | Donor deletes app or logs out after posting. | Food remains in database; receiver can still reserve if available and not expired. |
| EC-08 | Location permission denied. | Allow manual location entry or show clear error before posting/reserving. |
| EC-09 | Image upload fails. | Prevent submit or allow retry; do not create incomplete listing unless image is optional. |
| EC-10 | Network unavailable during reserve. | Show failure and do not assume reservation succeeded until database confirms. |
| EC-11 | Donor attempts to reserve own food from receiver flow. | Block action. |
| EC-12 | Completed reservation is opened again. | Show completed status; disable OTP, cancel, and reserve actions. |

## 16. Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Usability | Core flow should be understandable without training during demo. |
| NFR-02 | Performance | Dashboard list should load within 3 seconds on normal network for demo data. |
| NFR-03 | Reliability | Reservation and status updates must use atomic database operations. |
| NFR-04 | Security | Users can only update their own profile; donors can only manage their own food; receivers can only manage their own reservations. |
| NFR-05 | Privacy | Phone/profile details should be shown only when needed for pickup coordination. |
| NFR-06 | Maintainability | Code should separate UI, models, services/repositories, and business rules. |
| NFR-07 | Compatibility | App should run on current Android emulator/device supported by Flutter. |
| NFR-08 | Data integrity | Food and reservation statuses must remain consistent. |

## 17. Acceptance Criteria

### 17.1 MVP Complete Definition

The MVP is accepted when this full demo can be completed:

```text
Register/Login as Donor
  -> Post cooked food
  -> Expiry automatically shows +4 hours
  -> Login as Receiver
  -> View food in available list
  -> Open Food Details
  -> Reserve Food
  -> 30-minute timer appears
  -> OTP is generated
  -> Enter wrong OTP and see error
  -> Enter correct OTP
  -> Complete Drop & Done
  -> Food status becomes completed
  -> Donor and Receiver histories show completed transaction
```

### 17.2 Feature Acceptance Criteria

| Feature | Acceptance Criteria |
|---|---|
| Login/Register | A new Donor and Receiver can register and log in successfully. |
| Role routing | Donor lands on Donor Dashboard; Receiver lands on Receiver Dashboard. |
| Post Food | Donor can submit a valid food listing with required fields. |
| Expiry | Cooked food expiry is exactly +4 hours; packed food expiry is exactly +8 hours from preparation time. |
| Receiver listing | Receiver sees only available, non-expired food. |
| Food Details | Details screen shows all required food, donor, expiry, and location details. |
| Reservation | First receiver can reserve; second receiver cannot reserve same item. |
| Timer | Reservation displays countdown based on pickup deadline. |
| Cancel | Cancel returns food to available if it has not expired. |
| Timeout | Expired reservation is released or food is expired based on food expiry time. |
| OTP | Wrong OTP fails; correct OTP verifies pickup. |
| Drop & Done | Completion updates reservation and food to completed. |
| Location | Receiver can open pickup location in maps. |
| Profile | User can view profile and verification status. |

## 18. Two-Week Implementation Scope

### Week 1: Core Functional Flow

| Day | Scope |
|---|---|
| Day 1 | Flutter project setup, Firebase Auth, Firestore, Storage, app routing |
| Day 2 | Login, register, role selection, user profile creation |
| Day 3 | Donor Dashboard, Post Food form, expiry rule implementation |
| Day 4 | Food model, image upload, location capture, food details |
| Day 5 | Receiver Dashboard, available food listing, reserve action |
| Day 6 | Reservation model, atomic reservation update, 30-minute timer |
| Day 7 | OTP verification, Drop & Done completion, basic history/status views |

### Week 2: Stabilization And Demo Readiness

| Day | Scope |
|---|---|
| Day 8 | Cancel/release reservation, expired food handling |
| Day 9 | Maps integration, distance display if location data is available |
| Day 10 | Profile/verification status screens and Firebase demo data |
| Day 11 | Pickup logs/Digital Clean Chain-lite event history |
| Day 12 | Validation, loading states, empty states, error messages |
| Day 13 | End-to-end testing for donor and receiver flows |
| Day 14 | Bug fixes, UI polish, APK build/demo preparation |

## 19. MVP Risks And Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Firebase setup delay | Blocks app integration | Create Firebase project on Day 1 and test Auth/Firestore immediately. |
| Reservation race condition | Duplicate reservation bug | Use Firestore transaction for reserve action. |
| Timer only works while screen is open | Incorrect release behavior | Store `pickupDeadline` and calculate from timestamp on every load. |
| Scope creep | Missed 2-week deadline | Keep AI/admin/chat/analytics out of MVP. |
| Location permission issues | Posting/reserve flow blocked | Support manual fallback or clear retry path. |
| OTP confusion during demo | Failed handover demo | Show OTP clearly on donor side and OTP input clearly on receiver side. |

## 20. Final MVP Statement

The Android MVP is complete when a Donor can post surplus food, a Receiver can reserve it, the system enforces expiry and pickup timing, OTP verifies the handover, and Drop & Done marks the transaction completed. The MVP must prioritize this complete working lifecycle over additional future features.
