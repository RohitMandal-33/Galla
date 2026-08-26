# Galla

A fast, trustworthy offline khata for small merchants. Record every sale,
expense and udhaar in seconds, and always know where your money stands.

## What Galla does

- **Galla (home)** — today's cash position, one big **Add transaction**
  action, compact sales/expense/to-collect figures (all real), attention
  items only when something actually needs doing, and today's activity.
- **Quick entry** — sale, expense, received, paid, udhaar, invoice or
  **Speak** ("sold 500 to Hari on credit" — parsed on-device). Every save
  shows an **Undo** affordance; nothing fails silently.
- **Khata** — who owes you and whom you owe. Party pages read like a
  statement: balance up top, *Receive payment / Give udhaar* actions that
  are genuinely distinct, a reminder button that works, and an edit sheet
  that persists.
- **Stock** — items, quantities, prices, low-stock alerts. Stock changes are
  explainable via a movement history (sale / purchase / adjustment).
- **Reports** — Today / week / month / year / custom ranges over real data.
  Charts are built from actual daily/weekly/monthly buckets — if there
  isn't enough data, the app says so instead of drawing decorative bars.
  Share as PDF (Devanagari-capable) or real CSV files.
- **App lock** — PIN (salted, iterated hash) + biometric unlock with
  attempt throttling.

## Design principles

1. Trust over novelty — never show fake, estimated or fabricated numbers.
2. Numbers are the visual hierarchy; metadata stays quiet.
3. One obvious primary action per screen.
4. Flat rows and typography before cards and chrome.
5. Motion only when it communicates state change.
6. Merchant vocabulary: *sale, expense, udhaar, to collect*.

## Architecture

Flutter + Riverpod + GoRouter + Drift (SQLite), feature-first folders:
`core/` (theme, router, parser, money, notifications), `data/`
(repository + demo seeder), `domain/`, `shared/` (design system + PDF
fonts), `features/` (galla, entry, ledger, invoicing, inventory,
reconciliation, reports, business, lock, shell, onboarding).

The `Transaction` row is append-only: corrections, write-offs and
reconciliation adjustments are new entries; deletes are soft so the ledger
can be undone but never silently rewritten.

## Run it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Use a physical device or simulator; camera, mic and biometrics need real
hardware.

## Tests

```bash
flutter test        # 32 tests: cash math, entry semantics, invoice lifecycle,
                    # report-filter persistence, lock gate, dashboard reactivity
flutter analyze     # clean: 0 errors, 0 warnings
```
