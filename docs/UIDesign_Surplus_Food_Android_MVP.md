# UI/UX Design Specification: Surplus Food Redistribution System Android MVP

## 1. Document Control

| Field | Details |
|---|---|
| Project | Surplus Food Redistribution System Android MVP |
| Document type | UI/UX Design Specification |
| Related documents | PRD_Surplus_Food_Android_MVP.md (v1.0), SRD_Surplus_Food_Android_MVP.md (v1.0), UserFlow_UIScreenFlow_Surplus_Food_Android_MVP.md (v1.0) |
| Platform | Android (Flutter + Firebase) |
| Design model | Material 3 as the base layer, deliberately restyled (custom identity layer) |
| Version | 1.0 |

This document is the visual and interaction counterpart to the User Flow document. It defines one cohesive design system and specifies every screen at component level: composition, states, interactions, and the design rationale behind each choice. Screen inventory, fields, and business rules are pulled from the PRD (section 11), SRD (section 12), and User Flow (section 4) documents.

---

## 2. Design Intent: "Calm Rescue"

This app mediates a time-critical, trust-heavy exchange between two strangers: a donor giving away food before it expires, and a receiver who must reach the pickup point within 30 minutes. The interface must do two things at once:

1. **Stay calm.** Reading and acting on the screen must feel effortless under pressure.
2. **Make urgency visible only where it matters.** The pickup timer is the single most important number on screen. It earns the only loud treatment in the whole app.

The resulting identity is **quiet, structured, and warm** — closer to a well-set restaurant menu than to a typical startup landing page. Every visual decision below exists to serve trust (neutral surfaces, hairline borders, no decorative gradients), clarity (one primary action per screen), and warmth (humanist display type, soft green identity).

### 2.1 Product goals the design must serve

| Goal | Design consequence |
|---|---|
| Receiver can reserve before expiry | Expiry countdown is always readable at a glance; unavailable states are explicit |
| 30-minute pickup window is respected | The timer is the hero element of the Reservation screen |
| Trust between strangers | Verification status and donor/receiver identity are surfaced early; nothing is hidden behind vague labels |
| 2-week build | The system is deliberately small: ~6 colors, 2 fonts, ~8 components, no dark mode |

---

## 3. Why This Won't Look Like a "Vibe-Coded" App

The most reliable way to look AI-generated is to follow generic defaults. This document names each common failure mode and replaces it with a deliberate decision. Any screen that violates this table should be treated as a bug.

| # | Common AI/quick-MVP tell | Why it reads as cheap | Our replacement |
|---|---|---|---|
| 1 | Random gradient header + purple/blue accent | Signals a template, not a product | Single deep-green identity; surfaces are warm neutrals; color is a signal, never decoration |
| 2 | Emoji used as icons (🍔 ✅ 📍) | Renders inconsistently, breaks at small sizes, looks like a draft | Material Symbols (outlined set) everywhere; emoji banned from functional UI |
| 3 | Default Material card shadows everywhere | The stock Flutter look | Flat white cards with a 1px hairline border; shadow reserved for floating elements (timer card, sheets, CTA footer) |
| 4 | Everything spans the full width edge-to-edge | No rhythm, no breathing room | 24dp gutters, consistent 4dp spacing grid, centered content on large screens |
| 5 | One-off layout per screen, hand-assembled each time | Feels like six different apps | One shared component library (section 5); screens are compositions of the same parts |
| 6 | No empty / loading / error states | Demo breaks the moment data is missing | Every screen has a defined default, loading, empty, and error state (section 7) |
| 7 | Every corner rounded the same amount | Mushy, generic | A small radius scale where radius carries meaning (section 4.4) |
| 8 | Default Roboto/System font | No identity | Fraunces (display, warm, editorial) + Inter (body, precise). See 4.2 |
| 9 | Every screen has 3 competing actions | No clear next step | One primary action per screen, docked in a fixed footer |
| 10 | Success/failure shown as bare toasts | Feels unfinished | Status banners, inline form validation, and structured empty states |
| 11 | Timer text changes color randomly | Confusing | A single timer color language: green > 15 min, amber 5–15 min, red < 5 min (section 4.8) |

---

## 4. Design System

### 4.1 Color

Warm, food-grade neutrals carry the interface; green carries meaning. **Rule of thumb: on any given screen, ~85% of the pixels are neutral surface.** Color appears only as status, action, or countdown.

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#0E6B3A` | Primary buttons, links, active states, Reserve action |
| `onPrimary` | `#FFFFFF` | Text/icon on primary |
| `primaryContainer` | `#D5F0DF` | Soft green fills: status chips (available), selected option cards, verified banners |
| `onPrimaryContainer` | `#0A2E1B` | Text on primaryContainer |
| `surface` | `#F7F6F2` | App background (warm off-white, not pure white) |
| `surfaceContainer` | `#FFFFFF` | Cards |
| `surfaceContainerHigh` | `#EDEBE4` | Raised wells, chips background, disabled fills |
| `outline` | `#7D7B74` | Input borders, dividers |
| `outlineVariant` | `#DCDAD2` | Card hairline borders |
| `textPrimary` | `#1C1B18` | Body text |
| `textSecondary` | `#5B5A53` | Supporting text, metadata |
| `textTertiary` | `#85837B` | Captions, placeholders |
| `success` | `#1E7D4E` | Completed states |
| `warning` | `#B45309` | Amber: timer 5–15 min, "pending" verification, reserved status |
| `error` | `#B3261E` | Errors, timer < 5 min, cancelled/rejected |
| `onError` | `#FFFFFF` | Text on error |
| `errorContainer` | `#F9DEDC` | Error banners, invalid field fills |
| `onErrorContainer` | `#410E0B` | Text on errorContainer |
| `scrim` | `#1C1B18` @ 45% | Modal backdrop |

**Status chip colors** (dot + soft container, no border):

| Status | Dot | Container / text |
|---|---|---|
| available | `primary` | `primaryContainer` / `onPrimaryContainer` |
| reserved | `warning` | `#FBE7CF` / `#5A2E00` |
| otp_verified | `primary` | `primaryContainer` / `onPrimaryContainer` (with check glyph) |
| completed | `textTertiary` | `surfaceContainerHigh` / `textSecondary` |
| expired | `outline` (hollow) | `surfaceContainerHigh` / `textTertiary` |

**Timer color language (global):**

| Remaining | Color | Behavior |
|---|---|---|
| > 15:00 | `textSecondary` | Calm, neutral |
| 05:00 – 15:00 | `warning` | Amber |
| < 05:00 | `error` | Red + subtle 1.2s pulse on the timer digits only |

### 4.2 Typography

Two fonts, both via Google Fonts (bundled, no runtime fetch):

- **Fraunces** (variable, soft serif) — display and hero numbers. Warm, human, slightly editorial. Used sparingly: greetings, page titles, big countdowns, summary counts.
- **Inter** (sans) — everything else: body, labels, forms, chips. Precise and neutral; pairs with Fraunces without clashing.

| Style | Family / weight | Size / line-height | Tracking | Used for |
|---|---|---|---|---|
| Display | Fraunces 600 | 40 / 44 | -0.5% | Hero countdown (Reservation), summary counts (dashboard) |
| Title Large | Fraunces 600 | 24 / 30 | -0.25% | Screen titles, food names |
| Title | Fraunces 600 | 20 / 26 | -0.25% | Card titles, dialog headings |
| Headline | Inter 600 | 16 / 22 | 0% | Card titles on dense lists |
| Section Label | Inter 600 | 13 / 18 | +6% (uppercase) | Group headers on forms and detail screens |
| Body L | Inter 400 | 16 / 24 | 0% | Primary paragraphs, form inputs |
| Body M | Inter 400 | 15 / 22 | 0% | Supporting text |
| Body S | Inter 400 | 14 / 20 | 0% | Metadata, helper text |
| Label M | Inter 600 | 14 / 20 | 0% | Buttons, list item titles |
| Label S | Inter 600 | 12 / 16 | +2% | Chips, tags, tab labels |
| Caption | Inter 400 | 12 / 16 | +1% | Timestamps, footnotes |
| Timer | Inter 600, `tabular figures` | 40 / 44 or 24 / 28 | +1% | All countdowns (tabular so digits don't jitter) |

### 4.3 Spacing and layout grid

- Base unit **4dp**. All margins/paddings are multiples of 4.
- Screen gutters: **24dp** (drop to 16dp on screens < 360dp wide).
- Vertical rhythm: 8dp between related elements, **24–32dp between sections**.
- Card padding: **16–20dp**.
- Touch targets: **≥ 48dp** in both dimensions (visual height may be less, hit area not).
- Content column max width **640dp**; on tablets/landscape the content is centered with generous side margins.
- Any screen that opens the keyboard: content scrolls, footer CTA stays reachable (no fixed footer over keyboard — use `viewInsets` padding).

### 4.4 Shape and elevation

Radius is meaningful, not uniform:

| Radius | Used for |
|---|---|
| 4dp | OTP box internals, tiny tags |
| 8dp | Inputs, buttons, chips, menu items |
| 12dp | Cards (standard) |
| 16dp | Bottom sheets, dialogs, modal pickers |
| 20dp | Hero image containers (detail screens, image picker) |

Elevation rules:

- **Cards:** flat (0 shadow) + `1px` border in `outlineVariant`. The hairline is the primary "designed" cue and keeps cards from floating.
- **Floating elements** (docked CTA footer, Reservation timer card, bottom sheets, snackbars): subtle elevation + `8dp` shadow, no border.
- **Selected cards** (role picker, active tab): `2px` border in `primary` + `primaryContainer` fill, no shadow.

### 4.5 Iconography

- **Material Symbols, outlined weight** (bundled). 
- Sizes: 16dp metadata, 20dp inline, 24dp interactive targets.
- Stroke weight stays consistent (default outline). Never mix filled and outlined icons in the same screen.
- Emoji are banned in functional UI. If a demo device renders an emoji in a spec below, that is an implementation bug.
- Custom logomark: a simple rounded leaf/seed shape, drawn with the same stroke geometry as status dots, reused as splash mark, empty-state glyph, and app icon. One motif, repeated — this is a cheap way to look intentional.

### 4.6 Motion

| Context | Duration | Curve | Notes |
|---|---|---|---|
| Tap feedback (buttons, chips) | 120ms | ease-out | Scale 0.98 + ink |
| Screen transition (push) | 200ms | ease-out | Fade + 16dp slide-up |
| Bottom sheet / dialog | 250ms | ease-out | Slide up, scrim fades |
| List reorder / filter change | 300ms | ease-in-out | Cards move, never pop |
| Form errors | 200ms | ease-out | Inline message fades in; OTP boxes shake on wrong code |
| Timer pulse (< 5 min) | 1.2s loop | ease-in-out | Subtle opacity 1.0 → 0.82, digits only |
| Skeleton shimmer | 1.4s loop | linear | Section-width shimmer |

Motion must never block comprehension: no full-screen transitions, no parallax, no bouncy springs. Respect `MediaQuery.disableAnimations` (reduced motion → all motion disabled, pulse becomes a static red).

### 4.7 Language and tone

- Buttons: short, imperative, concrete — "Log in", "Post food", "Reserve this food", "Drop & Done". Never "Submit", "OK", or "Proceed".
- Status chips use the product's words: `Available`, `Reserved`, `Ready for pickup`, `Completed`, `Expired`.
- Empty states explain what the screen is for and give one action, e.g. "Nothing available right now. Donors in your area will appear here — pull to refresh."
- Error copy states the cause and the next step. "Something went wrong" is banned.
- Numbers are always concrete: "12 servings", "1.4 km", "23:41". Never "approx." alone.

### 4.8 Countdown semantics

Pickup timers are the only element that reads from a live `pickupDeadline` timestamp (SR-FR-034). All countdowns on a screen must agree with each other and be recomputed from the timestamp on every load/resume (SR-FR-036, SR-FR-003 EC). Format: `MM:SS` (or `H:MM:SS` for food expiry > 1 h), tabular figures, `leading zeros`.

---

## 5. Core Component Library

Every screen is assembled from these parts. New ad-hoc components are discouraged — if a screen needs something new, the system must be extended, not the screen.

### 5.1 AppBar
- Transparent on `surface`, 56dp. Large-title style: screen title in `Title Large` (Fraunces), right-side icon actions.
- On scrollable screens the title may collapse to `Headline` (16/22) once the content passes it — title stays visible, no full-height colored bar.

### 5.2 Docked CTA footer
- Fixed bottom bar: `surfaceContainer` background, 1px top border `outlineVariant`, 16dp padding, one full-width primary button.
- Used on: Login, Register, Post Food, Food Details (Reserve), Donor Food Details (Drop & Done). Guarantees the single primary action is always in thumb range.

### 5.3 StatusChip
- Anatomy: 6dp status dot + 8–16dp label in `Label S`, soft container fill, radius 8, height 24.
- Colors per table in 4.1. Never two chips with the same text but different colors.

### 5.4 FoodCard — donor variant
- Flat white card, hairline border, radius 12, 16dp padding.
- Layout: 72×72dp rounded image left | right column: name (`Headline`), metadata line (`Body S`, "Cooked · 12 servings"), status chip + countdown chip row.
- Tap → Donor Food Details. Overflow (⋯) menu on the card → Edit/Delete (MVP: Edit optional, Delete available).

### 5.5 FoodCard — receiver variant
- Same card shell; left 72×72dp image, right column: name (`Headline`), donor org (`Body S`), bottom row: distance chip ("1.2 km", left) + expiry countdown chip (right, color-shifts).
- Full card tap → Food Details. Distance chip is hidden when receiver coordinates are missing (no broken "— km").

### 5.6 ExpiryCountdown
- Chip or standalone. Format per 4.8. Color per timer language (4.1). Includes a small schedule icon 16dp.

### 5.7 PrimaryButton / SecondaryButton / GhostButton / DestructiveButton
- Primary: filled `primary`, radius 8, 48dp height, `onPrimary` label, spinner replaces label while busy; disabled = `surfaceContainerHigh` fill + `textTertiary` label (label must stay readable).
- Secondary: `primary` text + 1px `outline` border on `surface`, same size.
- Ghost: text only, `textPrimary`, used for in-context links.
- Destructive: `error` text (or `errorContainer` fill for high-emphasis confirmations).

### 5.8 EmptyState
- Centered block: 64dp logomark glyph in `primaryContainer`, `Title` heading, one `Body M` sentence, optional single action button. Background stays `surface` (never a big illustration).

### 5.9 ErrorState / inline error
- Screen-level: card in `errorContainer` with `onErrorContainer` copy, one "Try again" button.
- Field-level: label turns `error`, 1px border `error`, helper text in `error` (not just border color — color alone fails WCAG).
- Network-loss during a write: the action fails visibly, UI state is not optimistically flipped to success (SR-EC-009).

### 5.10 LoadingSkeleton
- Cards in `surfaceContainerHigh` with `outlineVariant` shimmer blocks, same geometry as real content (image 72dp, lines at 80/60% width). Never a bare spinner in a list.

### 5.11 FormField
- Filled-style: `surfaceContainerHigh` fill, 1px `outline` border (border turns `primary` on focus, `error` on invalid), radius 8, 52dp height (multiline taller), floating label, helper text below in `textTertiary` or `error`. Show/hide password toggle on password fields.

### 5.12 OTPField
- Row of 6 square boxes, 48dp, hairline border, `Headline` digits, tabular. Typing auto-advances; backspace steps back; box turns `primary` border + fill when focused; wrong code → whole row `error` + shake (200ms).

### 5.13 OptionCard (segmented pickers)
- Selectable card, 8dp radius, 1px border; unselected = `surfaceContainer` + `outlineVariant`; selected = `primary` 2px border + `primaryContainer` fill. Contains icon 24dp, `Label M` title, `Body S` helper. Used for role picker and Cooked/Packed type picker.

### 5.14 ConfirmationDialog
- Radius 16, 1px border, 24dp padding. `Title` heading, `Body M` body, right-aligned ghost ("Cancel") + primary/destructive actions. One point of contrast: destructive confirmations get `errorContainer` fill on the confirm button.

### 5.15 Bottom sheet
- Radius 16 top corners, drag handle 4×32dp `outlineVariant`. Used for location picker, image source menu, filter options.

### 5.16 Snackbar
- `textPrimary` on `surfaceContainerHigh`, 8dp radius, icon-left optional. Reserved for non-blocking feedback (e.g. "Food posted"). Errors and confirmations use banners/dialogs, not snackbars.

### 5.17 SectionHeader
- `Section Label` (uppercase, +6% tracking) + optional right-side ghost action ("See all"). 24dp above, 12dp below.

---

## 6. Screen-by-Screen Specification

Quick reference:

| Screen | Primary action | Docked footer? | Key state risk |
|---|---|---|---|
| Splash | none (route) | no | slow auth check |
| Login | Log in | yes | wrong credentials |
| Register | Create account | yes | validation, role selection |
| Donor Dashboard | Post food | yes (CTA) | no donations yet |
| Post Food | Post food | yes | image upload, location denied |
| Donor Food Details | Drop & Done (conditional) | yes | reservation status drift |
| Pickup Status | Complete donation | yes | double completion |
| Receiver Dashboard | Open food details | no | nothing available |
| Food Details (receiver) | Reserve this food | yes | food already reserved |
| Reservation Screen | Verify code | no (inline) | timer expiry, wrong OTP |
| My Reservations | Continue pickup | no | no history |
| Profile | Edit / Log out | no | none |

---

### 6.1 Splash

**Purpose:** gate on auth state (User Flow section 2). **Entry:** app launch. **Exit:** Login (unauthenticated) or role dashboard (authenticated).

Composition (top → bottom):

| Zone | Element | Spec |
|---|---|---|
| Center | Logomark | Leaf/seed glyph 56dp in `primary` on `surface` |
| Center | App name | `Title Large` Fraunces "Surplus" (wordmark) |
| Center | Tagline | `Caption`, `textTertiary`: "Rescue food before it expires" |
| Bottom third | Activity indicator | 24dp, `primary`, centered |

Interactions: none user-facing. Hold the screen for a minimum of 1.2s so the auth check reads as deliberate, not as a hang.

States: if auth check exceeds 3s, show `ErrorState` with "Check your connection" + "Try again" (never a frozen logo). If authenticated user has no profile doc (SR-FR-006), route to Login with a one-line banner: "Your profile needs to be set up again."

Designed cues: warm background (not white), the repeated leaf motif, generous whitespace. No animations, no progress bar.

---

### 6.2 Login

**Purpose:** authenticate and route by role (SR-FR-002, SR-FR-005). **Exit:** Donor/Receiver Dashboard, or Register.

Composition:

| Zone | Element | Spec |
|---|---|---|
| Top | Brand block | Logomark 32dp + "Surplus" (`Title`), value line `Body M`: "Fresh surplus food, donated before it expires." 32dp below logo |
| Middle | Email field | `FormField`, keyboard `email`, autofill `email` |
| Middle | Password field | `FormField` with show/hide toggle, autofill `password` |
| Middle | Errors | Field-level inline per 5.9; credential failure → `errorContainer` banner above button: "That email or password didn't match. Try again." |
| Footer | Primary | Docked: "Log in" (full-width) |
| Footer | Ghost | Under button: "Don't have an account? **Create one**" → Register |

Interactions: keyboard-aware scroll; button busy state disables fields; on success route by role.

Designed cues: no social login (keeps the demo deterministic and the surface quiet); single column with strong vertical rhythm; the brand line makes the app's value obvious in one glance — important because a demo audience may see this screen first.

---

### 6.3 Register

**Purpose:** create auth account + profile (SR-FR-001, SR-FR-003, SR-FR-004). **Exit:** role dashboard after profile creation.

Composition (scrollable form, grouped):

| Zone | Element | Spec |
|---|---|---|
| Top | Screen title | `Title Large` "Create your account"; `Body M` helper "Choose the role that matches you." |
| Section: Role | `SectionHeader` "I am a" | Two `OptionCard`s stacked 8dp apart: **Donor** ("Restaurant, canteen, or event with surplus food") / **Receiver** ("NGO, volunteer group, or organization"). Selecting one fills the org field hint. Selection required. |
| Section: Your details | `SectionHeader` "Your details" | Name field (autofill `name`), Phone field (keyboard `phone`, required) |
| Section: Account | `SectionHeader` "Account" | Email field (autofill `email`, validated), Password field (min 8 chars, validated, toggle) |
| Section: Organization | `SectionHeader` "Organization" | Organization name field; placeholder switches by role: "Restaurant / canteen name" vs "Organization / NGO name" |
| Footer | Primary | Docked "Create account"; busy spinner; success routes by role |

States: every field validates on blur and shows inline errors (5.9). Duplicate email → banner "An account with this email already exists." Role must be chosen before submit — the footer CTA stays disabled until the required fields pass.

Designed cues: the card-based role picker (not a dropdown) is the strongest single design signal on the form; grouping forms into labeled sections with uppercase labels makes a long form feel organized rather than overwhelming.

---

### 6.4 Donor Dashboard

**Purpose:** overview of donations + quick Post action (FR-12..14, SRD 12.3). **Entry:** login, Post Food, Drop & Done. **Exits:** Post Food, Donor Food Details, Profile.

Composition:

| Zone | Element | Spec |
|---|---|---|
| AppBar | Greeting | `Title Large` "Good evening, Maria"; `Body S` `textSecondary` today's date. Right: avatar button → Profile. No colored bar. |
| Summary | Stat strip | 3 flat cards in a row (1px hairline): **Available / Reserved / Completed**, count in `Display` 40/44 Fraunces, label `Caption` uppercase. Tapping a stat filters the list. |
| Section | `SectionHeader` "Your donations" + filter | Horizontal scroll chips: All, Available, Reserved, Completed, Expired. Active chip = filled `primary`, `onPrimary`; inactive = `surfaceContainerHigh`. |
| List | Donor FoodCards | Per 5.4. Countdown chip only for available/reserved; `Expired` chip for expired. Tap → Donor Food Details. |
| Footer | CTA | Docked primary "Post food" (plus icon 20dp) → Post Food. |

States:

- **Loading:** 3 skeleton cards.
- **Empty:** `EmptyState` — "No donations yet" / "When you post surplus food it will appear here." Action: "Post your first donation" (primary).
- **Error:** `ErrorState` with "Try again"; pull-to-refresh available in all states.
- **Expired surge:** when ≥ 3 items expire within the hour, an amber banner tops the list: "3 of your items expire within the hour."

Designed cues: the greeting + summary strip gives the dashboard a human, useful feeling that generic list dashboards lack; stat counts in the display serif make numbers feel like the point of the app. Filtering via segmented chips is standard but the consistent chip system keeps it tidy.

---

### 6.5 Post Food

**Purpose:** create a listing with auto-expiry (SR-FR-013..020). **Exit:** Donor Dashboard on success.

Composition (scrollable form):

| Zone | Element | Spec |
|---|---|---|
| Top | Screen title | `Title Large` "Post food"; helper "Expiry is set automatically from the food type." |
| Image | Image picker | 16:9 hero slot, radius 20, dashed `outline` border when empty: centered camera icon 32dp + "Add a photo" (`Body M`). When filled: real image + small "Change" ghost chip top-right. Image is required (SRD 12.4). |
| Section: What | `SectionHeader` "What are you donating?" | Food name field (title case, autofill). Type picker: two `OptionCard`s — **Cooked** ("Expires 4 h after prep") / **Packed** ("Expires 8 h after prep"). |
| Section: Details | `SectionHeader` "Details" | Quantity/servings field (number keyboard), Description multiline (3 rows, 120-char counter, required). |
| Section: Timing | `SectionHeader` "Timing" | Preparation time field (tap → date+time picker sheet, defaults to now). Below it, a live read-only **Expiry preview card** (5.6 style): "Expires in **4h 00m**" — recomputes instantly when type or time changes. |
| Section: Location | `SectionHeader` "Pickup location" | Primary outline button "Use current location" (24dp location icon); on capture, replaces with a card: address/coords line + "Change" ghost. Manual entry fallback available. |
| Footer | Primary | Docked "Post food". Disabled until required fields valid. Busy = spinner. On success → dashboard + snackbar "Food posted". |

States:

- **Image upload fails:** inline `errorContainer` card above the image: "Upload failed. Check your connection and try again." with "Retry". Submit is blocked (SR-EC-009).
- **Location denied:** inline card: "We couldn't get your location." with "Allow location" + "Enter manually" actions (SR-EC-011).
- **Validation:** per-field inline errors on blur.

Designed cues: the live expiry preview makes the automatic rule tangible (a product differentiator, presented not explained); the hero image slot with dashed border signals "photo expected here" without needing a label; location uses one obvious action instead of a settings maze.

---

### 6.6 Donor Food Details

**Purpose:** monitor reservation + complete handover (FR-28, SRD 12.x). **Entry:** Donor Dashboard. **Exits:** Pickup Status / Drop & Done, dashboard.

This screen has four sharply different states; it must be built once with a clear state machine (food status + reservation status), not as four parallel layouts.

Composition (top → bottom):

| Zone | Element | Spec |
|---|---|---|
| Hero | Image | 20dp top radius, 16:9, with overlay: status `StatusChip` (top-left) + expiry `ExpiryCountdown` chip (top-right), both on a scrim pill. |
| Title | Name + meta | `Title Large` name; `Body S` `textSecondary` "Cooked · 12 servings". |
| Body | Description | `Body M`. |
| Details | Info card | Rows (icon + label + value): Preparation time, Type, Quantity, Posted. |
| Status block | (varies) | See state table below. |
| Footer | CTA | Docked, **conditional** (per state table). |

State table:

| Food status | Reservation status | Status block | Footer CTA |
|---|---|---|---|
| available | — | Flat card: "Waiting for a receiver." `Body M` + `Caption` "You'll be notified when someone reserves." | none (or disabled) |
| reserved | active | **"Pickup in progress"** card: receiver org name (`Headline`), reserved-time line, countdown to deadline (large, per timer language). OTP card below (dashed border, radius 12): "Share this code when the receiver arrives" + OTP in `Display` 40, letter-spaced, tabular + copy icon. | none |
| reserved | otp_verified | Green banner (primaryContainer): check + "Receiver verified the code. Complete the handover." OTP card dims (code still shown). | "Drop & Done" (primary) |
| reserved/available | expired | Amber/gray card: "Pickup window closed." + food returned to available / marked expired line. | none |
| completed | completed | Read-only summary: `StatusChip` Completed + completed timestamp. No actions (EC-12). | none |

Interactions: tapping the countdown opens a dialog with the absolute deadline ("Pickup must happen by 14:32"). OTP copy uses clipboard with a check feedback. "Drop & Done" opens `ConfirmationDialog`: "Complete this donation?" / "This marks the food as picked up." → confirm.

Designed cues: the OTP card is the one deliberately "loud" element on the screen (dashed border, big digits) because it is the trust handshake; every other state stays quiet. Conditional footer means the CTA literally cannot appear before it is valid (SR-FR-050).

---

### 6.7 Pickup Status / Drop & Done

**Purpose:** confirm handover completion (FR-51..53). This can be a dedicated screen reached from Donor Food Details (User Flow) or a full-height sheet — spec it as a screen to keep the demo deterministic.

Composition:

| Zone | Element | Spec |
|---|---|---|
| Top | Screen title | `Title Large` "Pickup status"; back → Donor Food Details. |
| Middle | Stepper | 3 steps as rows (icon + label): **Reserved** (check) → **Code verified** (check or pending) → **Completed**. Done/pending: `primary` icon; pending: hollow `outline`; current: `warning`/`primary` per phase. Rows joined by a vertical hairline. |
| Middle | Status copy | `Body M` text matching current step ("Receiver verified the code. Confirm the handover to close the donation.") |
| Footer | Primary | "Complete donation" — shown only when step 2 is complete; `ConfirmationDialog` first, then busy spinner. |
| Result | Confirmation | Post-completion: full green check + "Donation completed" (`Title`) + "Back to dashboard" primary. |

Interactions: guard against double-tap and double-write — the completion update is idempotent; a second tap shows "Already completed" rather than double-submitting (SR-FR-053).

Designed cues: the stepper gives the donor a clear mental model of the three-phase handover; the dialog before the final destructive-ish action prevents accidental closure of the donation.

---

### 6.8 Receiver Dashboard

**Purpose:** discover available food (SR-FR-021..023). **Entry:** login, after reservation flows. **Exits:** Food Details, My Reservations, Profile.

Composition:

| Zone | Element | Spec |
|---|---|---|
| AppBar | Greeting | `Title Large` "Good evening, Alex"; `Body S` date. Right: avatar → Profile. |
| Toolbar | Filter chips row | Horizontal scroll: All, Cooked, Packed + right-aligned sort toggle (ghost) "Nearest first". Active chip filled `primary`. |
| List | Receiver FoodCards | Per 5.5. Skeleton 3 cards while loading. Pull-to-refresh. |
| Footer | Secondary | Docked outline button "My reservations" (calendar icon) → My Reservations — keeps the active-pickup entry always one thumb-tap away. |

States:

- **Empty:** `EmptyState` — "No food available right now" / "When a donor posts nearby, it appears here." Action: "Refresh" (ghost) + note "Pull down to refresh anytime."
- **Error:** `ErrorState` + "Try again".
- **Just-expired edge:** if a listed item's countdown hits zero while visible, the card animates out (300ms) and a `Caption` note "1 item just expired" fades in below the toolbar.

Designed cues: distance chip only when real coordinates exist (no fake zeros); countdown chips use the global color language so a red chip reads instantly; the list is sorted nearest-first by default to match the receiver's real question ("what can I reach before it expires?").

---

### 6.9 Food Details (receiver)

**Purpose:** full info + reserve (SR-FR-024, FR-26..27). **Entry:** Receiver Dashboard. **Exit:** Reservation Screen on success.

Composition:

| Zone | Element | Spec |
|---|---|---|
| Hero | Image | 20dp top radius with status + countdown chips overlaid (as donor variant). |
| Title | Name + meta | `Title Large` name; `Body S`: "Cooked · 12 servings · Posted 2h ago". |
| Body | Description | `Body M`. |
| Info card | Details rows | Preparation time, **Expires** (countdown chip, colored), Donor organization (`Headline` + org name). |
| Pickup card | Location | Card: location icon, pickup address/coords line, distance ("1.4 km away", `Body M`), secondary button "Open in Maps" (launches maps intent, SR-FR-049). |
| Status banner | Conditional | If expires < 15 min: amber banner "This item expires soon." If item just became unavailable: `errorContainer` banner "This item was just reserved." (auto-refresh via Firestore listener). |
| Footer | Primary | Docked "Reserve this food". Enabled only when `available` + not expired. Disabled + reason text in `textSecondary` under label: "Already reserved" / "Expired". Donor's own listing → button hidden entirely, banner "You can't reserve your own donation" (EC-11). |

Interactions: Reserve → `ConfirmationDialog` ("Reserve this food?" / "You'll have 30 minutes to pick it up.") → transaction with busy state → success navigates to Reservation Screen. If the transaction fails because another receiver won the race (SR-EC-001): inline banner "Someone else just reserved this" and the button disables.

Designed cues: the disabled-button-with-reason pattern prevents the most common demo failure (tapping a dead Reserve button); "Open in Maps" is a visible, thumb-reachable action because navigation is the receiver's #1 friction.

---

### 6.10 Reservation Screen (active pickup)

**Purpose:** complete the pickup within 30 minutes (SR-FR-025..049, SR-FR-033). **Entry:** Food Details reserve success, My Reservations. **Exit:** dashboard (cancel/complete).

This is the busiest screen in the app — the timer language (4.1) and the 4dp grid must be applied strictly.

Composition (top → bottom):

| Zone | Element | Spec |
|---|---|---|
| Top | Status line | `StatusChip` Reserved (amber) + "Reserved by you" `Caption`. |
| Hero | Timer card | Floating card (borderless, elevation): circular progress ring (radius ~44dp, ring color follows timer language, fraction = remaining/30:00) with the countdown `Display` 40 in the center. Below: `Caption` "Time left to pick up". Tap → dialog with absolute deadline. |
| Summary | Food card | 72dp thumb + name (`Headline`) + donor org (`Body S`). |
| Pickup | Location card | Address/coords + "Open in Maps" outline button (thumb-first: this is what the receiver does immediately after reserving). |
| Section: Verify | `SectionHeader` "Verify pickup" | `OTPField` (6 boxes) + helper "Ask the donor to share their 6-digit code." + primary "Verify code" enabled at 6 digits. |
| Result | Banner | Correct → green banner "Code verified — collect your food" + instruction card: "Ask the donor to tap Drop & Done on their phone to close the donation." Wrong → `errorContainer` inline error "That code doesn't match. Try again." + shake + boxes clear (attempts continue; no lockout in MVP). |
| Bottom | Actions | Ghost "Cancel reservation" (`error` text) → `ConfirmationDialog` "Cancel this reservation?" / "If the food hasn't expired it returns to the available list." |

State table:

| Trigger | Behavior |
|---|---|
| Timer reaches 0 while open | Timer card flips to red, then a full-status panel replaces it: "Time's up." + one line per SR-FR-036/037 ("This food is available again." or "This food expired.") + primary "Back to available food" |
| App closed past deadline | On resume/load, recompute from `pickupDeadline` and show the same expired panel (SR-FR-003) |
| Wrong OTP after deadline | Verification rejected with "The pickup window has closed." (SR-FR-048) |
| OTP verified | Verify section collapses into the green banner; Cancel is disabled (SRD 10.2: otp_verified can't cancel) |
| Network drop during verify | Banner "We couldn't verify the code. Check your connection." — no state change until confirmed (SR-EC-009) |

Designed cues: the circular ring + big tabular digits make the countdown instantly readable from across the room (demo-friendly); OTP input is the sole bright interactive element so the physical handshake step is unambiguous; every failure mode has copy that tells the user exactly what happened and what to do next.

---

### 6.11 My Reservations

**Purpose:** resume an active pickup / review history (SRD 12.x). **Entry:** Receiver Dashboard footer. **Exits:** Reservation Screen, dashboard.

Composition:

| Zone | Element | Spec |
|---|---|---|
| AppBar | Title | `Title Large` "My reservations". |
| Tabs | Segmented control | 3 equal segments: **Active · Completed · Cancelled**. Active tab = filled `primary`; count badge optional on Active. |
| List | Reservation cards | Flat cards, 1px hairline. Active: food thumb + name + donor + countdown chip + "Continue pickup" primary-inline button → Reservation Screen. History: food thumb + name + donor + `StatusChip` + `Caption` completed/cancelled timestamp. |

States:

- **Empty (Active):** "No active pickups" + "Browse available food" ghost → Receiver Dashboard.
- **Empty (Completed):** "No completed pickups yet."
- **Error:** `ErrorState` + "Try again".
- **Resume drift:** an Active item whose deadline passed while away renders as a card with "Time's up" state instead of a broken countdown (recomputed on load).

Designed cues: segmented tabs (not a tab bar) keep the screen simple; the active card's inline CTA mirrors the Docked CTA pattern so "continue pickup" is one tap from anywhere.

---

### 6.12 Profile

**Purpose:** view/edit profile + verification status (FR-07..11, SR-FR-008..011). **Entry:** avatar from either dashboard. **Exit:** same dashboard.

Composition:

| Zone | Element | Spec |
|---|---|---|
| Header | Identity | 72dp avatar (photo, else initials on `primaryContainer`), name `Title Large`, role `StatusChip` ("Donor"/"Receiver"), verification chip below. |
| Verification | Status card | Chip + one `Body S` line: `pending` → amber "Verification under review." · `verified` → green "Verified donor/receiver." · `rejected` → red "Verification rejected — contact support." (MVP: read-only, updated in Firebase per FR-11/BR-14). |
| Info card | Details rows | Phone, Email, Organization, Location (icon rows). |
| Edit | Pencil | Icon action opens inline edit mode: editable fields (phone, organization, location) become `FormField`s; "Save" primary + "Cancel" ghost appear in a docked footer. Non-editable (email, role) show a lock caption. |
| Bottom | Ghost | "Log out" in `error` text → `ConfirmationDialog`. |

States: save failure → inline `errorContainer` card above the footer; verification chip never shows a spinner (it's static data).

Designed cues: verification status gets its own card with a human explanation — this is the trust anchor for the whole marketplace and must not be a bare chip; the lock caption on non-editable fields quietly communicates why they're fixed, avoiding the "why can't I edit this?" confusion common in thrown-together profiles.

---

## 7. Cross-Cutting States

These rules apply globally and must not be reimplemented per screen:

| Concern | Rule |
|---|---|
| Offline / cache | Firestore local cache enabled. When online but a read fails: `ErrorState` with retry. When writes fail: the UI keeps the last confirmed state, shows a banner, and never flips optimistically (SR-EC-009). |
| Auth/profile missing | An authenticated user with no `users/{uid}` doc is routed to Login with an explanatory banner (SR-FR-006). |
| Timer accuracy | Every load/resume recalculates from stored timestamps (SR-FR-036). No screen trusts a locally ticking counter alone. |
| Role guard | Routing and access are enforced at app level (SR-EC-007/008). A receiver never sees a Donor-only screen. |
| Back behavior | All forms confirm before discarding unsaved input (`ConfirmationDialog`, "Discard changes?"). |
| Keyboard | Screens with inputs scroll; docked footers pad for `viewInsets`. No content is ever hidden behind the keyboard. |
| Notifications | None in MVP (out of scope); no code paths that assume them. |

---

## 8. Accessibility

| Item | Requirement |
|---|---|
| Contrast | All text meets WCAG AA (≥ 4.5:1 body, ≥ 3:1 large/display). Status is never conveyed by color alone — every colored chip also has a label word. |
| Touch targets | ≥ 48dp; visual may be smaller. |
| Text scaling | Test with `textScaler` up to 1.3×. Timer digits scale and remain tabular; chips grow, never truncate labels. |
| Focus order | Forms: top → bottom, matching visual order. Icon buttons carry `Semantics` labels. |
| Motion | Respect reduced-motion: pulse becomes static, transitions become fades ≤ 150ms. |
| Text fields | Floating labels + `helperText`; errors announced via semantics live region. |
| OTP | Each box is a single editable field with auto-advance, so screen readers navigate the whole code as one input; the "code" is also offered via the copy affordance on the donor side (clipboard read is an accessible fallback). |

---

## 9. Implementation Mapping (Flutter)

| Concern | Mapping |
|---|---|
| Colors | `ColorScheme` seeded from `#0E6B3A` with neutral overrides (surface, containers, outline); a small `AppStatusColors` extension for the chip/timer set. No colors hardcoded in widgets. |
| Typography | `TextTheme` built from the scale in 4.2 (Google Fonts: Fraunces, Inter); `FontFeature.tabularFigures()` on all timer/label styles. |
| Component themes | `CardTheme` (flat + border), `ElevatedButtonTheme`, `OutlinedButtonTheme`, `InputDecorationTheme` (filled), `ChipTheme`, `BottomSheetThemeData` — so screens never restyle primitives inline. |
| Components | One widget per entry in section 5, in `lib/widgets/`; screens compose them (NFR-06/SR-NFR-007). |
| Theme scope | Single light theme. Dark mode is documented as future work, not shipped (keeps the 2-week scope). |
| Dynamic text | All sizes from theme; no hardcoded `fontSize`. |

---

## 10. Pre-Demo Review Checklist

Run this list before every demo build; any failure is a fix, not a tweak:

1. No screen uses a color outside the section 4.1 tokens.
2. No emoji anywhere in UI strings or icons.
3. Every card has a 1px hairline (or is a floating element with shadow — never both, never neither).
4. One primary action per screen, reachable in the thumb zone.
5. Every list screen has loading, empty, and error states verified by killing network/emptying data.
6. All countdowns on a screen agree and derive from `pickupDeadline` timestamps.
7. Timer digits are tabular and color-coded per the timer language.
8. Every disabled button carries a visible reason, and Drop & Done is unreachable until `otp_verified`.
9. All forms show inline validation with actionable copy (no generic "invalid").
10. Dynamic text at 1.3× breaks no layout.

---

## 11. Version

| Version | Date | Change |
|---|---|---|
| 1.0 | — | Initial UI/UX design specification, companion to User Flow v1.0 |
