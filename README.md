# Galla

Daily cash book for small shops. Record money in and money out like a notebook. Galla keeps cash on hand, udhaar (who owes whom), and a simple report you can share.

This is the **MVP** described in `Galla-PRD.md` Chapter 30.

## What works in this MVP

- 3-screen welcome, then first entry with only amount + money in/out
- Optional starting cash (never blocking)
- **Today's Galla**: cash on hand, today's in/out, today's entries
- **Quick Entry** from the center button (works from any tab)
- Speak or type a sentence (`sold 500 to Hari on credit`) — parsed on-device
- Attach a receipt photo (no OCR yet; photo is saved either way)
- **Party ledger / udhaar**, payment received, settle/write-off, WhatsApp/PDF statement
- Search by name, amount, or note
- Simple profit & loss and cash-flow reports + PDF share
- English / Nepali, NPR / INR / USD
- Optional tax rate, PIN + biometric app lock
- Udhaar reminders and low-cash alert (local notifications)
- Offline-first: everything is written to local SQLite (Drift) before any network

Deferred to Version 2 (per the PRD): invoicing, inventory, bank reconciliation, staff roles, multi-branch, AI health score, Excel export, cloud OCR.

## Run it

```bash
cd /Users/rohitmandal/Downloads/Galla
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Use a physical iPhone/Android or a simulator. Camera, mic, and Face ID need a real device.

## Architecture

Flutter + Riverpod + GoRouter + Drift, feature folders for Galla, Entry, Ledger, Reports, and Business. The `Transaction` row is append-only: cash corrections and write-offs are new entries, never silent overwrites.
