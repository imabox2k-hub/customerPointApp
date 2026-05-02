# 💅 Nail Studio App — Setup Guide

## What's in this project

```
lib/
├── main.dart                          ← App entry point
├── firebase_options.dart              ← Your Firebase config (generate this)
├── theme/
│   └── app_theme.dart                 ← Colors, fonts, styles
├── models/
│   ├── customer_model.dart            ← Customer data structure
│   └── coupon_model.dart              ← Coupon + promo code structure
├── services/
│   └── firebase_service.dart         ← All Firebase read/write logic
└── screens/
    ├── home_screen.dart               ← "New" vs "Existing" customer
    ├── new_customer_screen.dart       ← Registration form
    ├── existing_customer_screen.dart  ← Phone number login
    └── customer_dashboard_screen.dart ← Points, coupons, redeem, give to friend
```

---

## Step 1 — Install Flutter

If you haven't already:
→ https://docs.flutter.dev/get-started/install/macos

---

## Step 2 — Open in VS Code

1. Open VS Code
2. File → Open Folder → select the `nail_studio` folder
3. Install extensions: **Flutter** and **Dart**

---

## Step 3 — Set up Firebase

### Create your Firebase project
1. Go to https://console.firebase.google.com
2. Click **Add Project** → name it `nail-studio`
3. Enable **Firestore Database** (start in test mode)
4. Enable **Authentication** (optional for now)

### Connect Firebase to Flutter
In VS Code terminal, run:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect to your Firebase project
flutterfire configure
```

This auto-generates `lib/firebase_options.dart` with your real config. ✅

---

## Step 4 — Install dependencies

```bash
flutter pub get
```

---

## Step 5 — Set up Firestore collections

In Firebase Console → Firestore, create these collections:

### `customers` collection
Each document auto-created when a new customer registers.
Fields: `name`, `phone`, `email`, `birthday`, `referredBy`, `howFound`, `points`, `createdAt`

### `coupons` collection
Auto-created when customers earn/redeem rewards.
Fields: `code`, `ownerId`, `ownerName`, `discount`, `status`, `givenToId`, `givenToName`, `givenByName`, `createdAt`, `redeemedAt`, `notes`

### `promo_codes` collection (you manage this)
You add codes here manually or via the admin panel (coming in Phase 2).
Example document ID: `VDAY25`
```json
{
  "code": "VDAY25",
  "discount": "15% off",
  "description": "Valentine's Day Special",
  "source": "SMS",
  "isActive": true,
  "validUntil": null
}
```

---

## Step 6 — Run on your iPad

### Option A — iPad via USB (easiest)
1. Connect iPad to Mac with USB cable
2. Trust the computer on iPad
3. In VS Code terminal:
```bash
flutter devices        # find your iPad's device ID
flutter run -d <device-id>
```

### Option B — TestFlight (share with others)
1. Open `ios/` folder in Xcode
2. Set your Apple Developer account
3. Archive → Distribute → TestFlight

---

## Firestore Security Rules (set before going live)

In Firebase Console → Firestore → Rules, paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /customers/{customerId} {
      allow read, write: if true; // tighten this with auth later
    }
    match /coupons/{couponId} {
      allow read, write: if true;
    }
    match /promo_codes/{code} {
      allow read: if true;
      allow write: if false; // only you can add promo codes via console
    }
  }
}
```

---

## How the loyalty system works

| Action | Result |
|--------|--------|
| Customer logs in | +1 point automatically |
| 5 points reached | Coupon generated (10% off) |
| Coupon redeemed | Moves to "Already Redeemed" |
| Coupon given to friend | Marked "Given to [name]" for original owner |
| Friend's coupon | Shows "Given by - [original name]" |
| SMS/Flyer code entered | Coupon logged in "Already Redeemed" |

---

## What's coming next (Phase 2)

- [ ] SMS automation (Twilio) — send discounts by text
- [ ] Appointment scheduling
- [ ] Owner admin panel (create promo codes, view all clients)
- [ ] Birthday auto-message
- [ ] Revenue dashboard
