# Paradise Funeral Home — Management System

A Flutter + Firebase management system for Paradise Funeral Home: customer
accounts, payments, discount approvals, staff administration, notifications,
email alerts, and scannable QR receipts for customers.

## Features

- **Role-aware login** — pick Admin or Staff before signing in; staff accounts
  work only after an administrator approves them.
- **Customer registry** — newest customers appear first, Philippine mobile
  number validation (11 digits starting with `09`), 10-day default due date.
- **Payments & discounts** — staff record payments and request discounts with
  a reason; admins approve or reject them (from the approvals page or directly
  inside the notification).
- **Notifications** — Unread/Read tabs, per-item mark as read/unread,
  inline staff-approval and discount review after opening a notification.
- **Email notifications** — every notification is also emailed via a Cloud
  Function (see below).
- **Customer QR receipts** — admins and staff can show a QR code per customer;
  scanning it opens a public, view-only receipt page.

## Development

```bash
flutter pub get
flutter run            # pick a device
flutter test           # run the test suite
flutter analyze        # static analysis
```

## Deployment

### 1. Web app + hosting (customer QR portal)

The QR codes link to `https://management-system-6aefa.web.app/view/<id>?k=<key>`
(see `lib/config/app_config.dart` — change `kCustomerPortalBaseUrl` if you use
a custom domain).

```bash
flutter build web
firebase deploy --only hosting,firestore:rules
```

### 2. Email notifications (Cloud Functions)

The `functions/` folder contains a Cloud Function that listens to every new
`notifications` document and emails it:

- notifications with a `recipientUid` go to that user's email;
- notifications with an `audienceRole` go to every admin.

Deploy it once and configure an SMTP provider (e.g. Gmail app password,
Brevo, SendGrid):

```bash
firebase functions:secrets:set SMTP_HOST
firebase functions:secrets:set SMTP_PORT
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASS
firebase functions:secrets:set MAIL_FROM

firebase deploy --only functions
```

Delivery status is written back to each notification document
(`emailSent`, `emailedTo`, `emailError`).

### 3. Firestore security notes

- `customerViews` documents are **publicly readable** (that is what makes QR
  scanning work without login), but only by their unguessable
  `<customerId>-<viewKey>` document id — listing/enumeration is blocked, and
  they contain receipt-safe fields only.
- Notification `readBy` updates allow both adding and removing your own uid
  (mark as read / unread).
