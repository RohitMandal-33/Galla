# Galla — Product Requirements Document

**Working Name:** Galla ("galla" = cash box / till — the daily cash-and-ledger book small shopkeepers have used for generations)
**Category:** Daily Business Ledger & Financial Companion for Small-to-Medium Businesses
**Document Type:** Startup-Grade PRD v1.0
**Status:** Pre-Development — Ready for Design & Engineering Kickoff
**Owner:** Product Team
**Last Updated:** August 2026

---

## How to Read This Document

This PRD serves four audiences in parallel: **designers** who need enough behavioral and information-architecture detail to design every screen without follow-up questions; **engineers** who need functional and non-functional requirements precise enough to estimate and build; **QA** who need acceptance criteria and edge cases; and **founders/stakeholders** who need the market rationale behind every decision. Each feature chapter is self-contained enough to hand to a single engineer.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Vision](#2-vision)
3. [Mission](#3-mission)
4. [Product Philosophy](#4-product-philosophy)
5. [Problem Statement](#5-problem-statement)
6. [Market Research](#6-market-research)
7. [Competitor Analysis](#7-competitor-analysis)
8. [SWOT Analysis](#8-swot-analysis)
9. [User Personas](#9-user-personas)
10. [User Journey](#10-user-journey)
11. [Jobs To Be Done](#11-jobs-to-be-done)
12. [Product Goals](#12-product-goals)
13. [Success Metrics](#13-success-metrics)
14. [Information Architecture](#14-information-architecture)
15. [Navigation Structure](#15-navigation-structure)
16. [UX Principles](#16-ux-principles)
17. [Design Philosophy](#17-design-philosophy)
18. [Accessibility](#18-accessibility)
19. [Functional Requirements Overview](#19-functional-requirements-overview)
20. [Non-Functional Requirements](#20-non-functional-requirements)
21. [Feature Specifications](#21-feature-specifications)
   - 21.1 [Daily Galla (Cash Book)](#211-daily-galla-cash-book)
   - 21.2 [Quick Entry (Income & Expense Capture)](#212-quick-entry-income--expense-capture)
   - 21.3 [Natural Language & Voice Entry](#213-natural-language--voice-entry)
   - 21.4 [Receipt & Bill Scanning (OCR)](#214-receipt--bill-scanning-ocr)
   - 21.5 [Party Ledger (Udhaar / Credit Tracking)](#215-party-ledger-udhaar--credit-tracking)
   - 21.6 [Invoicing & Billing](#216-invoicing--billing)
   - 21.7 [Inventory Lite](#217-inventory-lite)
   - 21.8 [Bank & Cash Reconciliation](#218-bank--cash-reconciliation)
   - 21.9 [Financial Reports](#219-financial-reports)
   - 21.10 [Tax & Compliance (VAT/GST-ready)](#2110-tax--compliance-vatgst-ready)
   - 21.11 [Payment & Due Reminders](#2111-payment--due-reminders)
   - 21.12 [Staff Roles & Multi-User Access](#2112-staff-roles--multi-user-access)
   - 21.13 [Multi-Branch Support](#2113-multi-branch-support)
   - 21.14 [Business Health Score & AI Insights](#2114-business-health-score--ai-insights)
   - 21.15 [Search & Ledger History](#2115-search--ledger-history)
   - 21.16 [Notification Engine](#2116-notification-engine)
   - 21.17 [Offline Support & Cloud Sync](#2117-offline-support--cloud-sync)
   - 21.18 [Sharing & Export (PDF/Excel/WhatsApp)](#2118-sharing--export-pdfexcelwhatsapp)
   - 21.19 [Language, Currency & Localization](#2119-language-currency--localization)
   - 21.20 [Settings & Business Profile](#2120-settings--business-profile)
22. [AI Assistant System](#22-ai-assistant-system)
23. [Notification Strategy](#23-notification-strategy)
24. [Trust & Data-Confidence Strategy](#24-trust--data-confidence-strategy)
25. [Offline-First Strategy](#25-offline-first-strategy)
26. [Security](#26-security)
27. [Privacy](#27-privacy)
28. [Performance Requirements](#28-performance-requirements)
29. [Technical Constraints & Architecture](#29-technical-constraints--architecture)
30. [MVP Definition](#30-mvp-definition)
31. [Version 2 Roadmap](#31-version-2-roadmap)
32. [Version 3 Vision](#32-version-3-vision)
33. [Risks](#33-risks)
34. [Open Questions](#34-open-questions)
35. [Appendix](#35-appendix)

---

## 1. Executive Summary

**Purpose:** Give any reader a two-minute understanding of what Galla is, why it exists, and why it will win.

Galla is a mobile-first daily accounting companion for small and medium businesses — shopkeepers, restaurant owners, small manufacturers, service providers — who currently track money in a paper ledger ("khata"), a notebook, a WhatsApp chat with themselves, or nothing at all. Galla replaces that paper ledger with a screen that is just as fast to write in, but that silently turns every entry into real bookkeeping: a running cash position, a customer credit (udhaar) list, and, when the owner needs it, a proper financial report they can show a bank, an investor, or a tax officer.

**Goals:**
- Make entering today's sales and expenses at least as fast as writing them in a paper khata (under 5 seconds per entry).
- Produce a trustworthy, always-current Profit & Loss and cash position without the owner ever "doing bookkeeping" as a separate task.
- Meet small businesses where they already are: low/intermittent connectivity, mixed cash/digital payments, informal credit relationships with regular customers, and — for many — no formal accounting background.

**Research:** In markets across South Asia and similar emerging economies, the overwhelming majority of micro and small businesses keep no digital financial records at all, relying on memory, paper registers, or informal notebooks — not because owners don't value the information, but because every existing digital option (spreadsheets, desktop accounting software like Tally) requires accounting literacy and setup effort disproportionate to a single shopkeeper's day. This is the wedge: an app only needs to beat "writing in a notebook" on speed and trust, not beat professional accounting software on feature depth.

**Discussion:** Galla deliberately does not try to be a replacement for a chartered accountant or full double-entry accounting software. It is the layer between "no records at all" and "hired an accountant" — for the very large population of businesses that currently sit at the "no records" end of that spectrum. This positioning shapes every subsequent decision in this document, especially the MVP scope (Chapter 30) and the explicit avoidance of double-entry-bookkeeping jargon anywhere in the primary UI.

**Requirements:** None directly (narrative chapter); every chapter below must be traceable back to this positioning.

**Acceptance Criteria:** A stakeholder unfamiliar with the product can read this section alone and correctly explain why Galla is not "just a mobile Tally" to a third party.

**Edge Cases:** N/A.

**Future Considerations:** Revisit positioning once usage data shows what share of users are migrating *from* paper (primary target) versus migrating *from* existing digital tools (secondary, valuable but different, audience) — see Persona research, Chapter 9.

---

## 2. Vision

**Purpose:** Articulate the long-term world Galla is trying to create.

**Vision Statement:** *A world where no small business owner is guessing whether they made money this month.* Galla becomes the default first app a new small business opens, and the reason that even the smallest shop — one person, one till, one notebook today — has real, bank-ready financial records without ever hiring a bookkeeper.

**Goals:** Establish Galla as the "digital khata" — the natural upgrade path every small business takes the moment they decide to track money seriously, the way a WhatsApp Business profile became the natural upgrade path for small-business communication.

**Research:** Category-defining tools for underserved small-business segments (mobile-money ledgers, WhatsApp Business, low-literacy-friendly point-of-sale apps) succeed by being radically simpler than the "professional" tools built for accountants, while still producing outputs (statements, reports) that satisfy the formal institutions — banks, tax authorities, lenders — small businesses eventually need to interact with. Galla's vision follows this exact pattern: simple enough for a shopkeeper who has never used a spreadsheet, credible enough for a bank loan officer.

**Discussion:** The core vision risk is the same tension every "simple tool for a complex domain" product faces: staying simple enough for the least sophisticated user while remaining credible enough for formal financial use. This tension is resolved by a strict separation between the *daily entry experience* (must be as simple as a notebook) and the *report output* (must look and behave like real accounting output) — detailed throughout Chapter 21.

**Requirements:** None (narrative).

**Acceptance Criteria:** Every feature chapter includes a one-line justification tying it back to this vision.

**Edge Cases:** N/A.

**Future Considerations:** As the product matures, vision may expand from "single shop owner" to "the financial nervous system of very small teams" (Chapter 32) — deferred, not assumed at MVP.

---

## 3. Mission

**Purpose:** State the operating mission the team executes against day to day.

**Mission Statement:** Build the fastest, most trustworthy way for a small business owner to record what came in and what went out today, know exactly how much cash they actually have, know who owes them money, and — whenever they need it — produce a financial report they can hand to a bank or tax office without doing any extra work to prepare it.

**Goals:**
- Time-to-first-entry (install to first recorded transaction) under 60 seconds, with zero mandatory setup screens before it.
- Time-per-entry (opening the app to a saved income/expense line) under 5 seconds, matching or beating handwritten khata speed.
- A trustworthy real-time cash position and running Profit & Loss visible at all times without the owner opening a separate "reports" mode and interpreting it themselves.

**Research:** Field studies of micro-retailers consistently find that the single biggest reason digital record-keeping tools are abandoned within days is that the *first entry* takes too long relative to writing in a paper book — every extra tap, category selection, or mandatory field before saving a transaction directly predicts abandonment. This is the direct justification for the sub-5-second entry goal and for treating category/party selection as optional-and-inferable rather than mandatory (Chapter 21.2, 21.3).

**Discussion:** The mission intentionally optimizes speed and trust over completeness. An owner who never touches Inventory or Invoicing but records daily cash in and cash out every single day is a fully successful user under this mission.

**Requirements:** Onboarding must not require business registration details, a chart of accounts, or an opening balance before the first transaction can be recorded (deferred/optional — see Chapter 30).

**Acceptance Criteria:** New users can record a real transaction without creating a full account, entering a business registration number, or configuring categories.

**Edge Cases:** Businesses that do want an accurate opening cash balance from Day 1 — supported via an optional, skippable "starting balance" prompt, never a blocking requirement.

**Future Considerations:** Re-baseline the 5-second entry target after MVP usage data; some business types (e.g., those with frequent party/credit tracking) may have a legitimately longer natural entry time.

---

## 4. Product Philosophy

**Purpose:** Define the non-negotiable design and product beliefs every future PM, designer, or engineer inherits.

**Core beliefs:**
1. **Today's cash is the truth.** The single most important number in the app at any moment is "how much cash do I actually have right now" — every screen is designed around this being instantly visible, not buried in a report.
2. **No accounting vocabulary required.** Words like "debit," "credit" (in the accounting sense), "ledger," "chart of accounts," or "journal entry" never appear in the primary entry or daily-view experience. The owner thinks in "money in" and "money out," and the app does the accounting translation invisibly.
3. **Every entry is one tap of intent away.** Recording a sale or an expense must never require navigating more than one screen from wherever the owner currently is in the app.
4. **Offline first, sync second.** Many target businesses operate with unreliable connectivity (a shop with intermittent mobile data, a market stall with none). The app must be fully usable — record transactions, view today's cash, view party balances — with zero network connection.
5. **Reports are generated, never assembled.** The owner should never have to "prepare" a report by selecting date ranges, categorizing transactions after the fact, or exporting-then-formatting in Excel. A report is always one tap away, fully formed, from data that was already captured correctly at entry time.

**Research:** These beliefs are a direct reaction to the two failure modes observed in existing tools for this segment: spreadsheets (which require the owner to build their own structure — violates belief #5) and professional accounting software like Tally or QuickBooks (which require accounting vocabulary and setup — violates belief #2). Galla is deliberately positioned to satisfy both a paper-ledger user's need for effortless daily capture and a bank's need for structured, credible output, without asking the owner to bridge that gap themselves.

**Discussion:** Belief #2 (no accounting vocabulary) is the philosophy most likely to be challenged internally as the product matures and power users request "real" accounting features (journal entries, chart-of-accounts customization) — such requests should be evaluated as an optional "Advanced" mode (Version 2, Chapter 31), never allowed to leak into the default experience.

**Requirements:** Each feature spec in Chapter 21 must pass a philosophy checklist during design review (Appendix 35.4).

**Acceptance Criteria:** No MVP screen uses the words "debit," "credit" (accounting sense), "journal," or "chart of accounts" in default-mode UI copy.

**Edge Cases:** Accountant/bookkeeper users who serve multiple small-business clients and *do* want standard accounting terminology and exports — served via an accountant-facing export mode (21.9, 21.18) that uses standard terminology only in that specific context, not the owner's daily view.

**Future Considerations:** Revisit belief #2 if a meaningful "graduated to needing real accounting software" cohort emerges — Galla should aim to be the tool they outgrow *gracefully* (clean exports, no lock-in — Chapter 27), not a tool that traps them.

---

## 5. Problem Statement

**Purpose:** Precisely define the problem so scope decisions can be tested against it.

**The problem:** Small and medium business owners — a shop, a restaurant, a small manufacturing unit, a service business — need to know three things every single day: how much money came in, how much went out, and how much cash they actually have on hand right now. Today, most of this population tracks this either on paper, in memory, or not at all, which produces three compounding costs:
- **Invisible leakage:** Small cash expenses (a supplier paid in cash, a small personal draw from the till) go unrecorded, so month-end profit is a guess, not a number.
- **Credit blindness:** Regular customers who buy on credit ("udhaar") are tracked in memory or a paper notebook that can be lost, illegible, or simply forgotten, leading to real, recurring revenue loss.
- **Institutional exclusion:** Without organized records, these businesses cannot easily get a bank loan, apply for a vendor credit line, or respond to a tax notice — formal financial institutions require statements these businesses cannot produce.

**Research:** Studies of informal and micro-enterprise sectors consistently find that lack of access to credit is cited as a top-three barrier to small-business growth, and that lack of verifiable financial records — not lack of creditworthiness — is frequently the actual blocker, since lenders cannot assess a business that has no records to show. This reframes the core problem from "small businesses need an accounting app" to "small businesses need financial records as a byproduct of doing what they already do every day," since asking them to independently value and prioritize "bookkeeping" as a standalone task has already failed at scale (hence the continued dominance of paper ledgers despite decades of accounting-software availability).

**Discussion:** Existing digital tools solve narrow instances of this problem for the minority of businesses sophisticated enough to adopt them (Chapter 7), but none solve the *adoption* problem for the majority still on paper — that adoption gap, closed via radical entry-speed and zero-setup simplicity, is Galla's entire reason to exist.

**Requirements:** Every MVP feature must reduce either invisible leakage, credit blindness, or institutional exclusion — features that do none of the three are out of MVP scope (Chapter 30).

**Acceptance Criteria:** The Problem Statement can be read aloud in under 30 seconds and a listener can name the three costs unprompted afterward.

**Edge Cases:** Businesses that already use a digital tool but find it too complex (migration audience, not primary adoption audience — Persona research, Chapter 9).

**Future Considerations:** Re-validate the three named costs with in-app data (entry frequency, party-ledger usage, report-generation-for-external-use frequency) once 90 days of usage data exists.

---

## 6. Market Research

**Purpose:** Ground the product in the current shape of the small-business financial-tools market.

**Landscape:** The market splits into four categories: (1) desktop/legacy accounting software built for accountants (Tally, QuickBooks Desktop) — powerful but requires training and setup; (2) cloud accounting software aimed at already-formalized SMEs with a bookkeeper (QuickBooks Online, Zoho Books) — assumes accounting literacy and a somewhat mature business; (3) simple mobile expense-tracker apps — too consumer-oriented, lack party/credit ledger and proper reporting; (4) informal tools — paper notebooks, WhatsApp, memory, which remain dominant by sheer volume of businesses despite solving nothing structurally. No major player owns the specific segment of "paper-ledger business ready to go digital for the first time, with zero accounting background."

**Research:** The rapid growth of mobile-money and digital-payment adoption in emerging markets over the past several years has meant most small-business owners now already have a smartphone and are comfortable with basic transactional apps (payment apps, messaging apps) even without ever having used a "business" app — this closes the device/comfort gap that made mobile bookkeeping tools impractical a decade ago and is a market-timing argument for building now.

**Discussion:** Two adjacent product categories are instructive. Mobile-money ledger apps proved that a shopkeeper will adopt a digital tool that mirrors an existing paper habit exactly (a running balance, additions and subtractions) without needing to be "taught" a new mental model. Simple invoicing apps aimed at freelancers proved that a single, focused digital workflow (create and send one document) can displace an entrenched paper habit when it is faster than the paper alternative. Galla combines both patterns — a paper-habit-mirroring cash book plus focused, fast document generation (invoices, reports) — an unclaimed combination for this specific segment as of this writing.

**Requirements:** Positioning materials must never describe Galla as "accounting software" in owner-facing marketing (evokes the complexity this product is explicitly avoiding) — "your digital khata" or equivalent local-language framing is preferred (Chapter 17, 19).

**Acceptance Criteria:** N/A (research chapter).

**Edge Cases:** Regulatory environments vary significantly by country/region on tax and invoicing requirements (Chapter 10); Chapter 21.10 must be designed as a configurable, regionally-extensible module, not hardcoded to a single jurisdiction.

**Future Considerations:** Commission a lightweight quantitative survey among target-segment business owners pre-Series A to validate willingness-to-pay for premium tiers (Chapter 12 discusses monetization at a goal level only).

---

## 7. Competitor Analysis

**Purpose:** Map named competitors against Galla's differentiation axis.

| Competitor | Core Strength | Core Gap vs. Galla |
|---|---|---|
| **Tally / desktop accounting software** | Deep, powerful, industry-standard accounting depth | Requires accounting knowledge and setup; desktop-bound or clunky mobile experience; overwhelming for a first-time digital user |
| **QuickBooks Online / Zoho Books** | Professional cloud accounting, integrates with formal banking/tax workflows | Built for businesses that already have (or plan to hire) a bookkeeper; onboarding assumes accounting literacy; pricing and complexity mismatched to the smallest businesses |
| **Generic mobile expense trackers** | Fast personal expense capture, simple UX | No party/credit ledger, no proper business financial reports (P&L, balance sheet), not built for business-specific workflows like invoicing or inventory |
| **Paper ledger / khata notebook** | Zero learning curve, instant, culturally embedded habit | No backup (lost/damaged risk), no reports, no automatic calculations, cannot be shared digitally, no reminders |
| **WhatsApp / memory-based tracking** | Zero friction, already-adopted communication tool | Not structured data at all; nothing can be calculated, searched, or reported from it |
| **Regional POS (point-of-sale) systems** | Strong for retail-specific transaction flow at checkout | Often hardware-dependent, expensive, overkill for a small shop's actual need (many shops don't need a full POS, they need a ledger) |

**Research:** Across every row, incumbents are either too complex for a paper-ledger user (Tally, QuickBooks) or too shallow for real business use (expense trackers, WhatsApp) — the pattern mirrors the "Today" PRD's competitor analysis structurally: a synthesis/adoption gap exists between minimal tools and professional tools that no player currently owns for this specific segment.

**Discussion:** Galla does not need to beat Tally at multi-warehouse inventory accounting or beat QuickBooks at multi-currency consolidated reporting. It needs to be dramatically easier to start using than either, while producing output credible enough to satisfy a bank loan officer — a strategy of "radical simplicity at entry, credible depth at output," directly paralleling the "adequate breadth, exceptional synthesis" strategy used in the companion "Today" app PRD, adapted to this domain's own axis of complexity (setup/vocabulary) versus output credibility.

**Requirements:** Feature specs for Inventory (21.7) and Tax/Compliance (21.10) are explicitly scoped as "adequate, not exhaustive" — enough for a small business's real needs, not an attempt to match dedicated inventory or tax software feature-for-feature.

**Acceptance Criteria:** Each competitor row maps to at least one explicit scope decision in Chapter 30 (MVP Definition).

**Edge Cases:** A business that outgrows Galla's depth (e.g., needs multi-warehouse inventory) is expected to eventually graduate to dedicated software — Galla should make that transition easy (clean data export, Chapter 27) rather than trying to retain them past their genuine needs.

**Future Considerations:** Evaluate partnership/API integration with formal accounting software (e.g., exporting Galla data directly into QuickBooks/Tally-compatible formats) for businesses in transition — candidate for Version 2 (Chapter 31).

---

## 8. SWOT Analysis

**Purpose:** Summarize internal and external factors shaping strategy.

**Strengths:**
- Clear, differentiated positioning (radical simplicity + credible output) in a market where incumbents sit at either extreme.
- Direct mirroring of an existing, trusted paper habit (the khata) lowers the adoption barrier further than a "generic" accounting app framing would.
- Offline-first architecture matches the real connectivity conditions of the target segment, unlike cloud-only competitors.

**Weaknesses:**
- Cross-functional scope (cash book + party ledger + invoicing + inventory + reports + tax) is broad for a small team to execute well simultaneously; execution risk is real (mirrors the scope-discipline risk identified in the companion "Today" PRD).
- No existing brand trust with small-business owners, a population that is often (reasonably) skeptical of new financial tools given past experience with unreliable or predatory fintech products.
- Regional/regulatory variance (tax rules, invoicing requirements, language) adds real engineering and localization complexity that a single-market competitor doesn't face.

**Opportunities:**
- Large, underserved population still on paper ledgers represents a genuine greenfield opportunity rather than a zero-sum battle for existing app users.
- Growing smartphone and mobile-payment comfort in the target demographic lowers the adoption barrier that existed even five years ago.
- Financial inclusion initiatives (government and private-sector) increasingly reward businesses with digital financial records (loan eligibility, formalization incentives), creating external pull toward adoption, not just internal product pull.

**Threats:**
- A well-funded regional fintech or payments company could bundle a similar ledger feature into an existing, already-trusted app (e.g., a mobile-payments app adding a "business ledger" tab), leveraging distribution Galla doesn't have.
- Trust/security failure risk is especially high-stakes for this audience — a breach or data-loss incident could set back adoption across the entire target segment's trust in *any* digital ledger tool, not just Galla specifically.
- Regulatory change (tax reporting requirements) could require rapid compliance feature changes on a timeline outside the product team's control.

**Research:** The threat of a payments/fintech incumbent bundling a similar feature is the most structurally serious threat in this analysis, since such players already have the trust and distribution this product must earn from zero — this elevates "speed to meaningful market presence" as a strategic priority alongside product quality.

**Discussion:** The biggest controllable risk remains the Weaknesses column (scope and execution), consistent with the equivalent finding in the companion "Today" PRD — this PRD's MVP discipline (Chapter 30) exists specifically to manage it.

**Requirements:** None directly; SWOT informs prioritization throughout.

**Acceptance Criteria:** N/A.

**Edge Cases:** N/A.

**Future Considerations:** Re-run this SWOT at each major version milestone as the competitive and regulatory landscape shifts.

---

## 9. User Personas

**Purpose:** Give designers and engineers concrete people to design for.

### Persona 1 — "Sita," The Neighborhood Kirana/General Store Owner (Age 42)
Sita runs a small general store alone, six days a week. She tracks sales by memory and keeps a paper notebook for customers who buy on credit. Her core frustration: at month's end she genuinely doesn't know if she made a profit, and she has, more than once, lost track of who owes her how much when the notebook got wet or pages went missing. She has a smartphone, uses a mobile payment app daily for personal use, but has never used a business app. She wants something that feels as simple as her notebook but doesn't get lost.

### Persona 2 — "Ramesh," The Small Restaurant Owner (Age 35)
Ramesh runs a small restaurant with two staff. He deals with daily cash sales, supplier payments (often cash, sometimes credit), and occasional digital payments. His core frustration is not knowing his actual daily profit after ingredient costs and small cash expenses, and he has no way to see which days/items are actually profitable versus busy-but-unprofitable. He wants his two staff to be able to record sales without seeing his overall financial reports.

### Persona 3 — "Anita," The Small Manufacturer / Workshop Owner (Age 38)
Anita runs a small garment workshop with a handful of workers, selling to a mix of retail customers and a few regular wholesale buyers who pay on delayed terms. Her core frustration is tracking outstanding payments from wholesale buyers (multi-week credit terms, not simple daily udhaar) and needing to show organized financial records when she applied for a small business loan last year — she was rejected partly for lack of documentation.

### Persona 4 — "Bikash," The Freelance Service Provider / Small Contractor (Age 29)
Bikash does electrical contracting work, invoicing clients per job. His core frustration is inconsistent, ad hoc invoicing (sometimes a WhatsApp message, sometimes nothing formal at all) making it hard to track which clients have paid and which haven't, and no clear picture of his monthly income given irregular job timing.

**Research:** These four personas were synthesized to cover the primary business archetypes in the target segment (retail with credit relationships, food service with staff and ingredient-cost tracking, small manufacturing with delayed B2B payment terms, and service/contracting with invoice-based income) — deliberately spanning the full range of "how money flows through the business" since that variable most affects which Galla features matter most to each (Party Ledger for Sita and Anita, Staff Roles for Ramesh, Invoicing for Bikash).

**Discussion:** Note that none of the four personas want double-entry bookkeeping, a chart of accounts, or multi-warehouse inventory — each wants a thin, trustworthy signal (how much cash do I have, who owes me, was today profitable) directly justifying the "radical simplicity at entry, credible depth at output" strategy (Chapter 7).

**Requirements:** Every feature spec in Chapter 21 must name which persona(s) it primarily serves.

**Acceptance Criteria:** A designer handed only a persona name and Chapter 21 feature specs can produce a coherent, persona-appropriate Daily Galla mockup.

**Edge Cases:** Persona overlap — a real business may blend traits (a restaurant that also does some catering invoicing); personalization/onboarding must handle blended signals, not force a single "business type" selection to permanently gate features.

**Future Considerations:** Add a fifth persona ("accountant/bookkeeper serving multiple small clients") once the accountant-facing export mode (Chapter 4, 21.9) is scoped in detail for Version 2.

---

## 10. User Journey

**Purpose:** Trace a single representative user (Sita, Persona 1) from install through habitual daily use.

**Day 0 — Install & First Value:** Sita installs the app after seeing it recommended in a local shopkeepers' community group. No account or business registration required. A short (3-screen) welcome explains "record what comes in and goes out, just like your notebook — we'll do the rest." She's dropped directly into Quick Entry. She taps "Money In," enters an amount, and saves — no category, no customer name required unless she wants to add one.

**Day 0 — Later:** A regular customer buys on credit. Sita opens Quick Entry, taps "Money In," enters the amount, then taps "Add to Udhaar" and types the customer's name (or picks from an auto-suggested list after the first few entries). The sale is recorded and the customer's running balance updates automatically.

**Day 0 — Evening:** Sita opens the app to see "Today's Galla" — a simple, large summary: total in, total out, net cash for the day, shown exactly like the bottom line she used to calculate by hand at closing time, but instant.

**Day 7 — Habitual Use:** Sita now records transactions 5–15 times a day as they happen, checks the udhaar list weekly to follow up with customers who owe her, and has started glancing at the simple weekly summary.

**Day 30 — Retained Use:** Sita has a full month of organized records for the first time. When a supplier asks about her monthly purchase volume, she pulls up a report in seconds instead of estimating. She has begun trusting the app enough to stop keeping a backup paper notebook.

**Research:** This journey directly tests the core-loop features (Quick Entry → Party Ledger → Daily Galla summary → Reports) as one continuous thread, built from the mission's stated speed goals (Chapter 3: under 60s to first value, under 5s per entry).

**Discussion:** Notice Reports and Tax/Compliance appear only as an on-demand destination Sita visits when she has an external reason to (a supplier question, eventually a loan application) — never a screen she must proactively interpret daily, reinforcing the "reduce thinking, generate don't assemble" philosophy (Chapter 4).

**Requirements:** The onboarding flow (Chapter 30) must support a first real transaction with zero fields beyond amount and direction (in/out).

**Acceptance Criteria:** A first-time user journey from install to first recorded transaction, with zero setup, completes in under 60 seconds in usability testing.

**Edge Cases:** Users who abandon after Day 0 without any party/credit entries — Daily Galla summary must still render meaningfully from cash-only entries (see 21.1 empty/failure states).

**Future Considerations:** Instrument this exact journey as a funnel (Chapter 13) to identify the highest-drop-off step post-launch.

---

## 11. Jobs To Be Done

**Purpose:** State the functional, emotional, and social jobs users hire Galla to do.

**Functional jobs:**
- "When I make a sale or pay for something, let me record it instantly without deciding how to categorize it."
- "When I want to know if I'm actually making money, tell me directly, not through a report I have to interpret."
- "When a customer owes me money, help me remember exactly who and how much, reliably."
- "When I need to show my finances to a bank or tax office, let me produce something credible in seconds, not hours."

**Emotional jobs:**
- "Make me feel in control of my own money, not confused by financial jargon I never learned."
- "Don't make me feel embarrassed for not having 'proper' bookkeeping until now."
- "Give me peace of mind that my records are safe, even if my phone is lost or broken."

**Social jobs:**
- "Help me be the kind of business owner a bank or supplier takes seriously."
- "Let me give my staff limited access without exposing my full financial picture."

**Research:** Jobs-to-be-done framing forces every feature in Chapter 21 back through the emotional and social lens, not just the functional one — critical for this product because financial shame and jargon-intimidation are well-documented, real barriers to adoption for first-time digital bookkeeping users, distinct from a simple feature gap.

**Discussion:** The emotional jobs ("don't make me feel embarrassed," "give me peace of mind") directly justify the plain-language philosophy (Chapter 4) and the strong offline/backup reliability requirements (Chapter 20, 25) — data loss for this audience isn't just inconvenient, it can mean genuine financial harm.

**Requirements:** Copywriting guidelines (Chapter 21 feature specs) must never use accounting jargon or condescending "you should have been tracking this already" framing.

**Acceptance Criteria:** A copy review of onboarding and empty-state strings finds zero instances of jargon or shaming language.

**Edge Cases:** Users who already have some accounting literacy (e.g., Persona 3, Anita, who has dealt with a loan application before) and want more standard terminology available — addressed via an optional "detailed view" toggle on reports (21.9), not the default.

**Future Considerations:** Validate the social jobs (particularly "be taken seriously by a bank") against actual Financial Report generation-for-external-use data once available.

---

## 12. Product Goals

**Purpose:** Translate vision/mission into goals the team can plan sprints against.

**Goals (12 months):**
1. Become the primary (not supplementary) record-keeping tool for active users — measured by whether users stop maintaining a parallel paper ledger (Chapter 13).
2. Make Quick Entry and Daily Galla the two most-used surfaces, each touched by the large majority of active users daily.
3. Ship offline-first architecture such that zero core-loop actions (recording a transaction, viewing today's cash, viewing a party's balance) require network connectivity.
4. Enable at least one real, verifiable external outcome per active business within 12 months (e.g., a report used for a loan application, a tax filing, a supplier negotiation) — validating the "credible output" half of the product's value proposition, not just the "easy entry" half.
5. Validate at least one monetizable premium-tier hypothesis (e.g., multi-branch, advanced reports, additional staff seats) without gating any core-loop MVP feature behind payment.

**Research:** Goal #3 (offline-first) is elevated to a top-5 product goal, not merely a technical requirement, because the target personas operate in contexts (small shops, workshops, markets) where connectivity is frequently unreliable, and a record-keeping tool that fails offline is worse than the paper ledger it's replacing.

**Discussion:** Goal #4 is included specifically because "easy to use" alone does not prove the product's full value proposition — the credibility of the *output* (Chapter 2's vision, "bank-ready records") must be validated with real external outcomes, not just internal engagement metrics.

**Requirements:** Engineering roadmap (Chapter 29, 30) must sequence offline-first architecture before any single online-only feature is prioritized.

**Acceptance Criteria:** Each of the 5 goals above has a named, measurable metric in Chapter 13.

**Edge Cases:** N/A.

**Future Considerations:** Revisit goal #5 (monetization) with real usage data before committing to a specific premium feature set.

---

## 13. Success Metrics

**Purpose:** Define the specific, measurable metrics the team is accountable to.

| Metric | Definition | Target (Post-MVP Baseline) |
|---|---|---|
| **D1 Retention** | % of new users who open the app again within 24 hours | ≥ 50% |
| **D30 Retention** | % of new users still active 30 days post-install | ≥ 30% |
| **Time-to-First-Entry** | Seconds from app open to first recorded transaction | < 60s |
| **Entry Latency** | Seconds from tapping Quick Entry to a saved transaction | < 5s |
| **Daily Entries per Active Business** | Average number of transactions recorded per active-day | ≥ 3 |
| **Paper-Ledger Displacement Rate** | % of surveyed active users who report they've stopped keeping a parallel paper record | ≥ 40% by Month 6 |
| **Offline Session Success Rate** | % of app sessions with no network that complete core actions without error | 100% |
| **Report Generation Rate** | % of active businesses generating at least one financial report per month | ≥ 50% |
| **External-Use Rate** | % of generated reports the user indicates were used externally (bank, supplier, tax) | Tracked, no hard target pre-MVP |
| **NPS** | Standard Net Promoter Score, quarterly survey | ≥ 40 |

**Research:** Targets are set conservatively relative to general consumer habit-app benchmarks given this is both a new category for the target users (first digital financial tool) and a business-critical-trust category (financial data), where adoption curves are typically slower but retention, once trust is established, tends to be durable — financial record-keeping is a sustained necessity, not a discretionary habit.

**Discussion:** Paper-Ledger Displacement Rate is tracked as a primary metric (not just retention) because it directly operationalizes Product Goal #1 (Chapter 12) — a business that keeps using Galla *alongside* a paper backup has not yet fully trusted the product, even if raw app-open retention looks healthy.

**Requirements:** Analytics events (Chapter 20 Non-Functional Requirements, Chapter 21.20 Settings) must be instrumented to compute every row in this table from day one, with the Paper-Ledger Displacement and External-Use rates collected via lightweight, optional in-app surveys given they cannot be inferred from usage data alone.

**Acceptance Criteria:** A dashboard exists (internal, not user-facing) capable of producing all metrics on demand.

**Edge Cases:** Seasonal businesses (e.g., festival-driven retail) will show natural usage volatility unrelated to product health — cohort analysis should account for business type/seasonality where possible.

**Future Considerations:** Add cohort-based retention curves segmented by persona/business type (Chapter 9) once sample size allows statistically meaningful splits.

---

## 14. Information Architecture

**Purpose:** Define the complete structural map of screens and data objects so navigation (Chapter 15) and every feature spec (Chapter 21) share one consistent model.

**Top-level surfaces (5, tab-bar based):**
1. **Galla** (home/default tab) — Today's cash summary, recent entries, quick access to Quick Entry
2. **Entry** (center action, not a passive tab — see Chapter 15) — Quick Entry / Natural Language / Receipt Scan entry point
3. **Ledger** — full chronological transaction history, Party Ledger (udhaar) list, Search
4. **Reports** — Financial Reports, Business Health Score, Tax/Compliance documents, Inventory summary
5. **Business** — Settings, Business Profile, Staff Roles, Branches, Invoicing tools

**Core data objects:**
- **Transaction** — the atomic unit created by Quick Entry; has a `direction` (in/out), `amount`, optional `party_id`, optional `category`, optional `is_credit` flag (udhaar), optional linked `invoice_id` or `inventory_item_id`.
- **Party** — a customer or supplier record with a running balance (positive = owes the business, negative = business owes them), built from linked Transactions.
- **DailySummary** — a generated, read-only object aggregating a day's Transactions into total in, total out, and net cash; cached offline, recomputed on new entries.
- **Invoice** — a formatted, shareable document generated from one or more Transactions or created standalone, optionally linked to a Party.
- **Report** — an on-demand generated object (P&L, cash flow, balance summary) computed from a date-range of Transactions, never manually assembled by the user.

**Research:** Collapsing "sale," "expense," "credit sale," and "payment received" into a single underlying `Transaction` object (differentiated by `direction` and flags) directly mirrors how a paper khata actually works — a single running column of entries — and is a deliberate implementation of the "no accounting vocabulary" philosophy (Chapter 4): the user never picks a transaction "type" from an accounting taxonomy, only in/out and, optionally, who it involves.

**Discussion:** A 5-tab IA isolates "Reports" (credible, formal output) from "Business" (configuration/staff/branches) because mixing report generation with settings undermines the "reports are generated, never assembled" philosophy (Chapter 4) — Reports should feel like a dedicated, trustworthy output surface, not buried in settings.

**Requirements:** All feature specs in Chapter 21 must map to exactly one primary top-level surface above; cross-surface appearances (e.g., a party balance appearing inside Galla home) must be explicitly marked as "ambient," not a duplicate primary destination.

**Acceptance Criteria:** Every screen a designer produces can be traced to exactly one node in this IA map with no orphaned screens.

**Edge Cases:** Deep-linked notifications (e.g., a payment-due reminder) must resolve to a real IA node (Ledger's Party detail), never a standalone screen with no back-navigation into the map.

**Future Considerations:** If Version 3 (Chapter 32) introduces accountant/multi-client features, an alternate IA mode for accountant users will need to be evaluated rather than assumed.

---

## 15. Navigation Structure

**Purpose:** Specify exact navigation mechanics for engineering (GoRouter route table) and designers.

**Structure:** Bottom tab bar, 5 destinations per Chapter 14, with the Entry destination rendered as a raised center action button (not a flat tab), opening a modal sheet over the current tab so context is never lost mid-entry — critical given the sub-5-second entry goal (Chapter 3).

**Route table (top-level):**
```
/galla                  → Galla tab (default route, today's summary)
/galla/day/:date        → Full day detail (expanded from summary)
/entry (modal)           → Quick Entry sheet, dismissible, stackable over any route
/entry/scan             → Receipt/Bill scan flow (within Entry modal)
/ledger                 → Ledger tab (transaction history)
/ledger/transaction/:id → Single transaction detail
/ledger/parties         → Party Ledger list (udhaar)
/ledger/parties/:id     → Single party detail (balance + history)
/ledger/search          → Search
/reports                → Reports tab
/reports/pnl            → Profit & Loss report
/reports/cashflow       → Cash flow report
/reports/tax            → Tax/compliance documents
/reports/health         → Business Health Score
/reports/inventory      → Inventory summary
/business                → Business tab (settings root)
/business/profile       → Business Profile
/business/staff         → Staff Roles & Access
/business/branches      → Multi-Branch management
/business/invoices      → Invoicing tools
/business/settings/*    → Settings sub-tree
```

**Research:** Modal (not routed) Quick Entry is modeled on the same fast-capture pattern validated in the companion "Today" app PRD, where preserving the user's current screen context measurably reduces abandonment mid-entry versus a full navigation transition — directly relevant here given entry speed is a top-3 mission goal (Chapter 3).

**Discussion:** Deep links (from push notifications, e.g., a due-payment reminder) must resolve into this same route table rather than a parallel notification-only screen set, consistent with the "no orphaned screens" requirement (Chapter 14).

**Requirements:** GoRouter configuration must support the Entry sheet as an overlay independent of the active tab's navigation stack.

**Acceptance Criteria:** From any of the 5 tabs, Quick Entry can be invoked and dismissed without changing the tab bar's active state.

**Edge Cases:** Android hardware back-button and iOS swipe-back gestures must dismiss the Entry modal without navigating the underlying tab stack backward.

**Future Considerations:** Evaluate a persistent, always-visible "quick add" floating shortcut (beyond the tab bar center button) if usage data shows entry friction remains a drop-off point post-MVP.

---

## 16. UX Principles

**Purpose:** Set the behavioral rules designers apply across every screen.

1. **One primary action per screen.** Every screen has exactly one obvious next action; secondary actions are visually subordinate.
2. **Progressive disclosure over upfront configuration.** Advanced options (categories, tax rates, multi-branch settings) are revealed only when relevant, never presented at first use.
3. **Confirm, don't force-correct.** When the app infers something (a party name from a partial match, a category from NL/OCR input), show the inference and let the user override with one tap — never require a form the app could have inferred.
4. **Numbers are always in context.** Every number shown (a balance, a total) is paired with a plain-language label ("You have," "They owe you") rather than an abstract accounting term, so the number is self-explanatory without external knowledge.
5. **Every empty state teaches.** An empty Party Ledger or Reports screen must explain, in one sentence, how to fill it — never a bare "Nothing here yet."

**Research:** Principle #4 (numbers always in context) is elevated specifically because the target audience (Chapter 9) often has no prior exposure to financial statement conventions (e.g., whether a number represents money owed *to* them or *by* them is not obvious from a bare "Balance: 4,500" the way it might be to someone with accounting background) — ambiguity here directly risks real financial misunderstanding, not just UX confusion.

**Discussion:** These principles are written to be testable during design review: a reviewer can ask "would a first-time user immediately understand what this number means without me explaining it?" as a binary check for every numeric display.

**Requirements:** Design review checklist (Appendix 35.4) includes all 5 principles as pass/fail gates before a screen is handed to engineering.

**Acceptance Criteria:** No MVP screen ships with a bare numeric balance lacking a plain-language directional label (owed to/by).

**Edge Cases:** Screens with genuinely dual-purpose actions (e.g., a transaction detail with both "edit" and "delete") — resolved by making one primary and the other an overflow-menu action.

**Future Considerations:** Extend these principles into formal design-system documentation once the design system (Chapter 17) stabilizes post-MVP.

---

## 17. Design Philosophy

**Purpose:** Define the visual and tonal identity distinct from behavioral UX principles above.

**Visual identity:** Clean, high-contrast, numbers-forward design — large, unambiguous typography for monetary values (the single most-glanced-at content in the app), a restrained neutral base palette with two clear accent colors used consistently and exclusively to mean "money in" (positive/green-family) and "money out" (negative/red-family) across every screen, so color alone communicates direction at a glance even before reading text — critical for fast recognition during busy in-person transactions.

**Tone of voice:** Plain, respectful, never condescending and never overly casual/gimmicky. Copy reads like a trusted shop assistant, not a corporate finance product and not a cutesy consumer app. E.g., a low-cash alert reads "Cash on hand is lower than usual today" rather than a jargon-heavy alert or an alarmist "WARNING: Low funds!"

**Research:** The consistent in/out color-coding convention is modeled on universally intuitive traffic-light-style color association (validated broadly across financial and non-financial interfaces alike) and is especially important for an audience that may have lower reading literacy in the app's displayed language in some markets — color and iconography must carry meaning independent of text wherever possible.

**Discussion:** This tonal register deliberately avoids both the sterile, dense register of professional accounting software (Chapter 7 competitor analysis) and an overly playful, gamified register that would undermine trust for a genuinely high-stakes use case — financial record-keeping for a livelihood is not a domain where cute mascots or aggressive gamification (contrast with the "Today" app's Companion Character, Chapter 4 of that PRD) are appropriate.

**Requirements:** A single shared design token set (color, type, spacing) must be defined before any screen in Chapter 21 is designed, with the in/out color pairing treated as a locked, non-negotiable token used identically across every feature.

**Acceptance Criteria:** A blind visual audit of 10 random screens shows consistent type scale, spacing, and correct in/out color usage without needing token documentation open.

**Edge Cases:** Users with color vision deficiency must not rely on color alone — every in/out indicator must be paired with a directional icon (e.g., an arrow) and/or explicit text label (Chapter 18).

**Future Considerations:** Evaluate a small set of regional visual variations (e.g., currency symbol placement, number formatting conventions) as part of localization (21.19) rather than a purely cosmetic theme system.

---

## 18. Accessibility

**Purpose:** Ensure Galla is usable by people with visual, motor, hearing, and cognitive differences, and by users with varying literacy levels — a first-class concern for this specific audience.

**Requirements:**
- All interactive elements meet a minimum touch target of 44×44pt (iOS HIG) / 48×48dp (Material) regardless of visual size, important given many target users are older and/or using budget devices with smaller screens.
- Text contrast ratios meet WCAG AA (4.5:1 body text, 3:1 large text); monetary figures specifically should exceed this minimum given their outsized importance on-screen.
- All screens fully navigable via screen reader (VoiceOver/TalkBack) with meaningful labels, including color-coded in/out indicators (paired text/icon labels per Chapter 17).
- Dynamic type / font scaling support up to at least 200% without breaking layout, tested explicitly on Daily Galla summary and transaction entry — the two most frequently glanced-at screens.
- **Low-literacy support:** icon-first design for core actions (a clear "+" for money in, "–" for money out) so the app is operable by users with limited reading ability in the app's displayed language; voice entry (21.3) is treated as a first-class accessibility feature, not just a convenience, for this reason.
- Reduced-motion setting respected for any confirmation animations (e.g., a save confirmation) — state change must still be conveyed via a static, clear confirmation, not skipped.

**Research:** Literacy-level accessibility is elevated to a primary, not edge-case, concern for this product specifically because the target segment (Chapter 9) includes business owners with a meaningfully wide range of formal education and reading proficiency in whatever language(s) the app is displayed in — a text-only interface would systematically exclude part of the intended primary audience, unlike a general consumer productivity app.

**Discussion:** Voice entry's accessibility role is distinct from its convenience role (21.3) — for some real users, it is not a faster alternative to typing but the only comfortable way to record a transaction, and this must inform its design priority (available prominently, not buried).

**Acceptance Criteria:** A manual walkthrough of the full Day-0 User Journey (Chapter 10) is completed successfully by a test participant using only icon recognition and voice entry, without reading any English-language text.

**Edge Cases:** Numeric input must support both local and international numeral systems/formats depending on region and user preference (Chapter 19 Localization).

**Future Considerations:** Pursue user research specifically with lower-literacy target users pre-launch to validate the icon-first core flows, beyond standard accessibility audit tooling.

---

## 19. Functional Requirements Overview

**Purpose:** Provide a single consolidated index of functional requirements before Chapter 21 details each feature individually.

At a system level, Galla must support: fast, minimal-field transaction creation with optional AI-assisted classification (natural language, voice, receipt OCR); a running, always-current cash position and party (customer/supplier) balance ledger; on-demand generation of standard financial reports (P&L, cash flow, balance summary) and tax/compliance documents from captured transaction data with no manual assembly; invoicing and inventory tracking scoped to small-business-adequate depth; role-based multi-user/staff access; full offline read/write with eventual cloud sync and conflict resolution; and a notification engine for payment-due and low-cash alerts.

**Research:** Consolidating this list up front lets engineering identify shared infrastructure early — e.g., the NL/voice/OCR entry pipelines (21.3, 21.4) and the Report generation engine (21.9) both depend on the same underlying Transaction store and must be built on a shared data model, not siloed per feature.

**Discussion:** This chapter is intentionally short; full functional requirements live inside each feature's own chapter in Section 21 per the required feature-spec template.

**Requirements:** See Chapter 21 (per-feature).

**Acceptance Criteria:** Every bullet in this overview is traceable to a fully detailed feature chapter in Section 21.

**Edge Cases:** N/A (index chapter).

**Future Considerations:** N/A.

---

## 20. Non-Functional Requirements

**Purpose:** Define system-wide quality attributes applying across all features.

- **Performance:** Cold app start to interactive Galla home screen under 1.5s on a mid-tier/budget device (see Chapter 28 for full targets) — budget-device performance is a first-class requirement given the target audience's typical device profile.
- **Reliability:** Core-loop actions (record transaction, view today's cash, view party balance) must have effectively zero data-loss rate even across app crashes, via write-ahead local persistence (Drift/SQLite) before any network sync attempt — financial data loss for this audience is a livelihood-level failure, not a minor bug.
- **Scalability:** Backend (FastAPI + Supabase/PostgreSQL) must support years of per-business transaction history without Ledger or Report generation latency degrading — indexed, paginated queries required from day one.
- **Security:** All data in transit via TLS 1.2+; at-rest encryption for all financial data (Chapter 26), which for this product is effectively all data, not a subset.
- **Maintainability:** Feature-first, Clean Architecture / MVVM structure (Chapter 29) so individual features can be developed, tested, and released independently.
- **Localization-readiness:** All user-facing strings, number formats, and currency symbols externalized and region-configurable from day one, given the explicit multi-region ambition (Chapter 19).
- **Battery/resource efficiency:** Background sync and notification scheduling must not measurably impact battery benchmarks, particularly important given target users' devices skew toward budget hardware with less battery/processing headroom.

**Research:** Budget-device performance and reliability are elevated above general best-practice targets specifically because this audience's device base skews lower-spec than a typical consumer productivity app's audience — a performance target validated only on flagship devices would misrepresent the real experience for a meaningful share of target users, directly analogous to (and even more pronounced than) the equivalent consideration in the companion "Today" app PRD.

**Discussion:** Data-loss reliability is treated with the same or greater severity than in a personal productivity app, because a lost transaction here isn't just an inconvenience — it can mean genuine, unrecoverable financial record loss for a livelihood-dependent business.

**Requirements:** See detailed, testable NFRs restated per-feature in Chapter 21 and system-wide in Chapter 28 (Performance).

**Acceptance Criteria:** NFRs above are validated via automated performance/battery test suites in CI (GitHub Actions) before each release, on representative budget-device profiles specifically, not only flagship devices.

**Edge Cases:** Very low-end devices with limited storage must be accounted for in local database size/retention planning (Chapter 25).

**Future Considerations:** Formal SLA definitions become relevant once a paid tier (Chapter 12) exists.

---

## 21. Feature Specifications

Each feature below follows the required template: Problem, Solution, Workflow, User Flow, Functional Requirements, Non-Functional Requirements, Acceptance Criteria, Failure States, Empty States, Success Metrics, Future Expansion.

### 21.1 Daily Galla (Cash Book)

**Problem:** Business owners need to know, at a glance, exactly how much cash they have and how today is going financially, without calculating it by hand or interpreting a dashboard (Chapter 5, invisible leakage).

**Solution:** A single, always-current home screen showing today's total money in, total money out, and net cash position, updated instantly with every transaction, presented the way an owner would mentally total their paper khata at day's end — but live and automatic.

**Workflow:** Every Transaction (21.2) writes directly to local storage (Drift); the Daily Galla view is a live, locally-computed aggregation of the current day's Transactions, recalculated on each write with no batch/nightly-job dependency (unlike the AI-generated Brief pattern in the companion "Today" app — this is a direct arithmetic aggregation, not an AI synthesis, and must be instant and fully reliable offline).

**User Flow:** App opens directly to Galla home → large, unambiguous "Cash Today" figure at the top → below it, total in / total out breakdown → below that, a compact scrollable list of today's individual transactions → tapping any transaction opens its detail; tapping "yesterday" or a date navigates to that day's equivalent view.

**Functional Requirements:** Must correctly carry forward an opening cash balance from the previous day (or a user-set starting balance) so "Cash Today" reflects true running cash, not just today's net movement in isolation; must support a manual starting-balance correction (with an audit-visible adjustment entry, never a silent overwrite) for when real cash counted doesn't match the calculated figure.

**Non-Functional Requirements:** Must render and update in under 100ms after any transaction write, entirely offline-capable, since this is the single most-viewed screen in the app (Chapter 13).

**Acceptance Criteria:** A user with zero prior data who records their first 3 transactions sees the Daily Galla figures update correctly and instantly after each one.

**Failure States:** N/A beyond standard sync-conflict handling (21.17) — this is a local-first, always-available computed view, not a feature that can meaningfully "fail" absent a data-corruption scenario.

**Empty States:** First-ever day (Day 0, no transactions yet): "Nothing recorded yet today — add your first entry" with a direct shortcut into Quick Entry.

**Success Metrics:** Daily Galla home-screen view frequency (should be the highest-frequency screen in the app, Chapter 13); manual starting-balance-correction frequency (a high rate may signal a data-trust or entry-accuracy issue worth investigating).

**Future Expansion:** Optional weekly/monthly rolling summary view directly from this screen (distinct from full Reports, 21.9) — deferred pending MVP usage data on whether users want this ambient, or prefer it only inside Reports.

---

### 21.2 Quick Entry (Income & Expense Capture)

**Problem:** Existing digital tools require deciding a category, account, or transaction type before saving, and that friction is the single biggest predictor of abandonment for this audience (Chapter 3 Mission research).

**Solution:** A single, always-one-tap-away entry surface (raised center tab, Chapter 15) requiring only two things to save: direction (money in / money out) and amount — every other field (category, party, note, photo) is optional and addable in the same flow without blocking save.

**Workflow:** User taps Entry → large "Money In" / "Money Out" toggle (defaulting to whichever direction was used most recently, reducing taps for repetitive entry patterns like a retail till) → numeric keypad for amount → optional row of quick-add chips (recent parties, common categories inferred from history) → save.

**User Flow:** Tap Entry → tap direction (or it's pre-selected) → enter amount → tap save (or optionally tap a party/category chip first) → sheet dismisses within under 5 seconds total, subtle confirmation, no forced review screen.

**Functional Requirements:** Support marking an entry as credit/udhaar (unpaid) at save time, linking it to a Party (21.5); support attaching a photo of a receipt/bill as a raw, offline-safe attachment even without OCR processing (21.4 enriches asynchronously); support quick repeat of the last entry (e.g., a recurring identical expense) via a one-tap "repeat last" shortcut.

**Non-Functional Requirements:** Entry-to-saved-locally latency under 200ms; entry must work with zero network connectivity with 100% reliability (Chapter 25).

**Acceptance Criteria:** A user can complete a basic entry (tap Entry → direction → amount → save) in under 5 seconds median, measured in usability testing, meeting the Chapter 3 mission goal directly.

**Failure States:** If any enrichment step fails (party auto-suggest, category inference), the raw amount/direction entry still saves successfully — enrichment is additive, never blocking.

**Empty States:** N/A (entry is an action surface, not a content list).

**Success Metrics:** Entries per active business per day (Chapter 13 target ≥3); median entry completion time.

**Future Expansion:** Widget/lock-screen quick-entry shortcut for the most common single action (e.g., "record a sale") to shrink the "open app" step further — candidate for Version 2.

---

### 21.3 Natural Language & Voice Entry

**Problem:** Even a two-field minimal form (direction + amount) is slower than how people naturally think and speak about a transaction ("sold rice for 500 to Hari, on credit"), and typing is a genuine barrier for lower-literacy or older users (Chapter 18).

**Solution:** An AI parsing layer accepting a single spoken or typed sentence and inferring direction, amount, optional party name, and optional category — reducing the entire entry to one natural utterance rather than a multi-field form.

**Workflow:** Raw text/voice transcript → sent to the classification endpoint (FastAPI, calling the Anthropic API) with a structured-output prompt requesting strict JSON → response mapped to a Transaction with each inferred field marked `ai_inferred: true` so the UI can visually distinguish AI-set fields until confirmed, mirroring the transparency pattern used for NL Input in the companion "Today" app.

**User Flow:** User taps the microphone/NL icon within Quick Entry → speaks or types a sentence → within 1–3 seconds, a pre-filled entry appears showing amount, direction, and any inferred party/category → user taps save (or corrects any field first) → saved.

**Functional Requirements:** Must correctly parse mixed-language and code-switched input (a common real-world pattern where numbers or business terms may be in a different language than the surrounding sentence, particularly relevant given the target regions, Chapter 19); must handle informal amount phrasing (e.g., regional shorthand for large numbers) correctly.

**Non-Functional Requirements:** ≥90% classification accuracy target for direction and amount extraction (the two mandatory fields); classification must never block the UI — always optimistic local save of at least the raw utterance, async-enrich.

**Acceptance Criteria:** A test suite of 100 representative natural-language entries (drawn from persona-realistic examples across supported languages) achieves ≥90% correct direction + amount extraction without manual correction.

**Failure States:** On parsing failure or low-confidence result, the raw utterance is saved as an unclassified note-like entry requiring manual completion — never guessed with false confidence on the two mandatory fields (amount, direction), consistent with the conservative-fallback principle established across both this and the companion "Today" app PRD.

**Empty States:** N/A.

**Success Metrics:** Classification accuracy; % of entries created via NL/voice vs. manual form (validates real-world adoption of this pathway, especially important for the accessibility case, Chapter 18).

**Future Expansion:** On-device lightweight classification model for instant offline parsing (currently offline NL entries save as unclassified pending reconnection) — candidate for Version 2 if offline usage data shows a meaningful gap.

---

### 21.4 Receipt & Bill Scanning (OCR)

**Problem:** Recording supplier purchase expenses by manually re-typing amounts from a paper bill is slow and error-prone, and many owners already receive/keep physical receipts they'd otherwise have to transcribe.

**Solution:** A camera-based capture flow that photographs a receipt or bill and uses OCR plus AI extraction to pre-fill a transaction (amount, and where legible, vendor name/date), letting the user confirm rather than manually type.

**Workflow:** Photo captured (or selected from gallery) → uploaded (when online) to an OCR + structured-extraction pipeline (FastAPI backend) → extracted fields returned and pre-filled into a draft Transaction, with the original photo retained as an attachment for future reference regardless of extraction success.

**Functional Requirements:** The original photo must always be saved locally immediately upon capture, independent of OCR success or connectivity — OCR is a convenience enrichment layer, never a precondition for the photo/expense being recorded; support batch-scanning multiple receipts in one session for owners catching up on a backlog.

**Non-Functional Requirements:** OCR extraction should complete within 5 seconds when online; must gracefully queue for later processing when offline, with the photo-only entry usable and editable in the meantime.

**Acceptance Criteria:** A test set of representative real-world receipt photos (varied lighting/quality) achieves reasonable amount-extraction accuracy sufficient to save the user manual entry more often than not; any extraction is presented as editable, never auto-saved without user confirmation.

**Failure States:** Illegible or failed OCR extraction results in a photo-attached, manually-completable draft transaction — never a dropped or lost capture.

**Empty States:** N/A (capture action, not a list).

**Success Metrics:** % of expense entries created via receipt scan; OCR extraction accuracy/correction rate.

**Future Expansion:** Automatic supplier/vendor recognition across repeated scans (building a vendor directory over time) — candidate for Version 2.

---

### 21.5 Party Ledger (Udhaar / Credit Tracking)

**Problem:** Regular customers who buy on credit, and suppliers the business owes, are currently tracked in memory or a fragile paper notebook, leading to real, recurring revenue loss and disputed balances (Chapter 5, credit blindness).

**Solution:** A dedicated running-balance ledger per Party (customer or supplier), automatically updated by any Transaction tagged with that Party, showing a clear, plain-language balance ("Hari owes you 2,400" / "You owe Ram Traders 1,200") rather than an abstract accounting figure.

**Workflow:** Parties are created inline at transaction time (first mention auto-creates a lightweight Party record) or explicitly in the Ledger tab; each linked Transaction updates the Party's running balance; a full transaction history per Party is always available for dispute resolution ("show me every entry with Hari").

**User Flow:** From Ledger tab → Parties list, sorted by largest outstanding balance by default (surfacing who most needs follow-up) → tap a Party → see balance, full history, and a one-tap "record payment received/made" shortcut that creates a new linked Transaction without re-entering the party name.

**Functional Requirements:** Support marking a balance as settled/written off (with a clear, distinct record, never silently deleting history); support sending a balance reminder directly to the party (21.11, 21.18) via SMS/WhatsApp share of a simple statement.

**Non-Functional Requirements:** Party balance recalculation must be instant and consistent even after offline entries sync (21.17) — no scenario should produce a temporarily incorrect displayed balance beyond the sync latency window.

**Acceptance Criteria:** Recording a credit sale to a new party name correctly creates the party and reflects the correct balance immediately, fully offline.

**Failure States:** Two offline devices recording different transactions for the same Party sync without conflict (balances are additive/append-only, not overwritten) — this is inherently lower conflict-risk than editable fields elsewhere in the app, and should be architected to exploit that (Chapter 20, 25).

**Empty States:** Empty Parties list: "Track who owes you and who you owe — add someone the next time you record a credit sale or purchase" with a direct shortcut.

**Success Metrics:** % of active businesses with at least one tracked Party; average number of Parties per active business; balance-reminder send rate.

**Future Expansion:** Party-level credit limits with a gentle warning when a customer's balance exceeds a set threshold — deferred to Version 2, must remain a non-blocking advisory, not a hard restriction.

---

### 21.6 Invoicing & Billing

**Problem:** Many small businesses, especially service providers (Persona 4, Bikash), currently send informal or no invoices at all, making income tracking and payment follow-up inconsistent (Chapter 5, institutional exclusion).

**Solution:** A simple, fast invoice/bill creation flow producing a clean, shareable document (PDF, shareable link, or direct WhatsApp share) from either a fresh entry or directly from existing transaction/party data — never requiring the user to design or format anything.

**Workflow:** User creates an invoice by selecting a Party (or entering a new one), adding one or more line items (description + amount, with an optional linked Inventory item, 21.7), and generating a formatted document from a single, pre-designed template; the invoice automatically creates a linked Transaction/Party-balance entry once marked sent or paid.

**Functional Requirements:** Support marking an invoice as paid/partially paid/unpaid, feeding directly into Party Ledger (21.5) balance; support a simple, sequential invoice numbering scheme (a common formal-business and tax requirement) generated automatically, never manually tracked by the user.

**Non-Functional Requirements:** Invoice PDF generation must complete in under 3 seconds and work fully offline (rendered locally), with sharing deferred until connectivity is available if needed.

**Acceptance Criteria:** A user can create and share a professional-looking invoice for a new customer in under 60 seconds from a cold start.

**Failure States:** If sharing fails (no connectivity for a link-based share), the generated PDF remains available locally for offline sharing methods (e.g., direct file share) or retried sending later.

**Empty States:** No invoices yet: "Send your first invoice — takes less than a minute" with a direct shortcut.

**Success Metrics:** Invoices created per active business per month; % of invoices marked paid within a reasonable follow-up window.

**Future Expansion:** Recurring invoice templates for regular clients — deferred to Version 2.

---

### 21.7 Inventory Lite

**Problem:** Businesses selling physical goods (Persona 1, Sita; Persona 3, Anita) want to know what's selling and roughly what stock they have, but full inventory-management software (multi-warehouse, batch tracking, complex costing methods) is far beyond their actual need and adds setup friction disproportionate to the value for a small operation.

**Solution:** A deliberately thin stock-count and cost-tracking layer — item name, current quantity, cost price, sale price — that automatically adjusts quantity when a linked sale Transaction or Invoice line item references it, surfacing simple low-stock alerts, without attempting full inventory-management depth.

**Workflow:** Items are created with minimal required fields (name, current quantity); linking a Transaction or Invoice line to an Inventory item automatically decrements quantity on a sale and increments on a recorded purchase, with manual stock-count correction always available (mirroring the cash-balance-correction pattern in 21.1).

**Functional Requirements:** Must support businesses that don't want to use Inventory at all — entirely optional, never a blocking step in Quick Entry or Invoicing; low-stock alerts (21.16) must be configurable per item (a simple, user-set reorder threshold), not automatically inferred.

**Non-Functional Requirements:** Inventory quantity calculations must remain consistent through offline/sync scenarios (21.17) using the same additive, append-only-adjustment pattern as Party Ledger (21.5) rather than absolute-value overwrites, to avoid sync conflicts.

**Acceptance Criteria:** Recording a sale linked to an Inventory item correctly decrements quantity and, when it crosses the configured threshold, surfaces a low-stock signal within the next Daily Galla view.

**Failure States:** Quantity going negative (oversell, e.g., from a data-entry error) is flagged visually as a discrepancy requiring review, never silently allowed to look like a normal state.

**Empty States:** No inventory items yet: "Track what you're selling — completely optional, add an item whenever you're ready" with a direct shortcut, framed as optional, not a required setup step.

**Success Metrics:** % of active businesses using Inventory at all (validates whether the "lite" scope is adequate or whether businesses need more depth); low-stock alert engagement rate.

**Future Expansion:** Basic barcode/SKU scanning for faster item lookup — deferred to Version 2, contingent on demand from the retail-heavy persona segment.

---

### 21.8 Bank & Cash Reconciliation

**Problem:** Businesses using a mix of cash and digital/bank payments need their recorded transactions to match their actual bank balance and physical cash count, but manual reconciliation is tedious and error-prone, and discrepancies (theft, error, forgotten entries) can go unnoticed for a long time without it.

**Solution:** A simple, periodic (owner-initiated, not forced) reconciliation flow where the user enters their actual counted cash and/or current bank balance, and the app shows the difference against calculated figures, with a guided flow to find likely causes (recent unrecorded transactions) rather than just flagging a raw discrepancy number.

**Workflow:** User initiates reconciliation from Business tab or a periodic (dismissible) prompt → enters actual cash counted and/or bank statement balance → app compares against calculated Daily Galla (21.1) running totals → any difference is shown with a suggested next step (review recent entries, check for a missed transaction) rather than a bare, unexplained number.

**Functional Requirements:** Must support partial reconciliation (cash-only, bank-only, or both) since not every business uses both; a reconciliation adjustment, once accepted, must be recorded as an explicit, visible adjustment entry (never a silent overwrite of history), consistent with the correction pattern in 21.1.

**Non-Functional Requirements:** Reconciliation comparison must be computed entirely from already-local data — fully functional offline, since bank balance is the only externally-sourced figure (manually entered by the user, not fetched via bank integration at MVP).

**Acceptance Criteria:** A user who deliberately introduces a known discrepancy (e.g., skips recording one transaction) sees the reconciliation flow correctly surface and quantify that gap.

**Failure States:** N/A beyond standard data-entry correction flows already covered.

**Empty States:** First-time use: brief explanation of what reconciliation is and why it helps, in plain language, before the entry fields.

**Success Metrics:** Reconciliation frequency per active business; average discrepancy size trend over time (should trend toward zero as entry habits mature, a proxy for data-quality improvement).

**Future Expansion:** Direct bank-feed integration (automatic balance import) for businesses with formal bank accounts — deferred to Version 2, contingent on regional banking API availability (Chapter 34 Open Questions).

---

### 21.9 Financial Reports

**Problem:** Businesses need standard financial reports (profit & loss, cash flow, balance summary) for external use (banks, investors, tax authorities) but have no way to produce them without hiring a bookkeeper or manually building one in a spreadsheet (Chapter 5, institutional exclusion).

**Solution:** One-tap generation of standard, professionally-formatted reports directly from already-captured Transaction data for any selected date range — never requiring the user to categorize, assemble, or format anything beyond what they already did at entry time, directly implementing the "reports are generated, never assembled" philosophy (Chapter 4).

**Workflow:** User selects a report type and date range (with smart presets: this week, this month, this year, custom) → report is computed entirely from local Transaction data (offline-capable) and rendered both as an in-app, readable summary and as an exportable, shareable PDF (21.18).

**Functional Requirements:** Must offer both a "simple" view (plain-language, matching Chapter 4's no-jargon philosophy — e.g., "Money In," "Money Out," "What's Left") and an optional "standard" view using conventional accounting terminology and structure (for the accountant/external-institution use case, Chapter 4 edge case) — both generated from the identical underlying data, never requiring separate data entry.

**Non-Functional Requirements:** Report generation for a full year of transaction history must complete in under 3 seconds on a mid-tier device, fully offline.

**Acceptance Criteria:** A P&L report generated for a date range with known, deliberately-seeded test data produces figures matching a manual hand-calculation for that same data.

**Failure States:** A report requested for a date range with zero transactions renders a clear, explicit "no activity in this period" report rather than a blank or broken output — still a valid, shareable state if needed.

**Empty States:** First visit to Reports with insufficient history: brief explanation that reports build up as transactions are recorded, with a shortcut to Quick Entry rather than a bare empty report.

**Success Metrics:** Report Generation Rate (Chapter 13, target ≥50% of active businesses monthly); External-Use Rate (validates the core "credible output" value proposition, Chapter 12 Goal #4).

**Future Expansion:** Comparative reports (this month vs. last month, year-over-year) — deferred to Version 2.

---

### 21.10 Tax & Compliance (VAT/GST-ready)

**Problem:** Small businesses in most regions have some tax obligation (VAT, GST, or local equivalent) but lack the tools to track taxable transactions correctly or generate the specific documents tax authorities require, and this is a significant driver of both compliance risk and (per Chapter 6/7) rejected access to formal credit.

**Solution:** A configurable tax module allowing the business to set applicable tax rate(s) once (region-appropriate defaults suggested at setup, never mandatory), automatically calculating and tracking tax on relevant transactions/invoices going forward, with dedicated report output formatted for the region's typical filing requirements.

**Workflow:** Tax settings configured in Business Profile (21.20) — optional, skippable at onboarding; once configured, Invoicing (21.6) and, optionally, Quick Entry (21.2) apply the set rate automatically to flagged taxable transactions; Reports (21.9) includes a dedicated tax-summary report aggregating collected/paid tax for a period.

**Functional Requirements:** Must support multiple tax rates/categories if a region or business requires it (e.g., different rates for different goods categories), while defaulting to a single simple rate for businesses that don't need that complexity — progressive disclosure per Chapter 16, principle #2.

**Non-Functional Requirements:** Tax calculation logic must be region-configurable at the architecture level (Chapter 29), not hardcoded to a single jurisdiction's rules, given the explicit multi-region ambition (Chapter 6, 19).

**Acceptance Criteria:** A business configuring a standard regional tax rate sees it correctly and automatically applied to a new invoice without additional manual calculation.

**Failure States:** A change to the configured tax rate must never retroactively alter historical transactions/reports — rate changes apply forward-only, with historical reports preserving the rate that was actually in effect at the time, a strict correctness requirement given the compliance stakes.

**Empty States:** Tax not configured: Reports simply omits the tax-summary section, with an optional, dismissible setup suggestion in Business Profile — never a blocking requirement (Chapter 4 philosophy: zero required setup).

**Success Metrics:** % of active businesses with tax configured; tax-report generation rate ahead of known regional filing periods (a strong signal of real compliance use).

**Future Expansion:** Direct e-filing integration with regional tax authority systems where APIs exist — deferred to Version 2/3, entirely dependent on regional regulatory infrastructure (Chapter 34 Open Questions).

---

### 21.11 Payment & Due Reminders

**Problem:** Owners forget to follow up on outstanding customer credit (udhaar) or upcoming supplier payments until it becomes a larger, harder-to-resolve balance, directly contributing to the revenue leakage described in Chapter 5.

**Solution:** Lightweight, configurable reminders tied to Party Ledger (21.5) balances — either time-based (e.g., "remind me about Hari's balance every 2 weeks") or threshold-based (e.g., "remind me if any customer balance exceeds X") — surfaced via the Notification Engine (21.16) and easily actioned (send a reminder to the party, record a payment) directly from the notification.

**Workflow:** Reminders are configured per-Party (optional, not required) or as a global default threshold in Business Profile (21.20); the Notification Engine evaluates candidates nightly and surfaces the highest-priority reminders within the daily notification budget (21.16).

**Functional Requirements:** Must support snoozing a reminder without dismissing the underlying balance (distinct actions — "remind me later" vs. "this is resolved"); must support one-tap sending of a plain-language balance reminder to the party (21.18) directly from the notification or Party detail screen.

**Non-Functional Requirements:** Reminder evaluation must run as part of the same efficient nightly batch process as other background computations (21.1, 21.9), not as a continuously-polling background service, for battery efficiency (Chapter 20).

**Acceptance Criteria:** A Party balance exceeding a configured threshold correctly triggers a reminder within the next evaluation cycle, verified in automated testing.

**Failure States:** Notification delivery failure must not prevent the reminder from being visible when the user next opens the Party Ledger — the notification is a convenience layer, the underlying balance/reminder state is always the source of truth (mirroring the same principle established for the companion "Today" app's Notification Engine, 21.19 of that PRD).

**Empty States:** No reminders configured: Party detail screen shows a simple, optional "remind me about this" toggle, off by default, never a nagging prompt to configure it.

**Success Metrics:** Reminder configuration rate; reminder-to-payment-recorded conversion rate (the strongest signal this feature reduces real revenue leakage, Chapter 5).

**Future Expansion:** Automated, scheduled reminder messages sent directly to the customer/supplier (not just to the owner) — deferred, requires careful UX/consent design to avoid feeling intrusive to the third party, evaluated for Version 2.

---

### 21.12 Staff Roles & Multi-User Access

**Problem:** Businesses with employees (Persona 2, Ramesh) need staff to record sales as they happen, but owners reasonably don't want every staff member to see full financial reports, historical data, or the ability to edit past entries.

**Solution:** A simple, role-based access system with a small number of clear roles (Owner — full access; Staff — can create new entries only, cannot view Reports or edit/delete past entries) rather than a granular, complex permissions matrix, consistent with the product's "avoid too many settings" design principle.

**Workflow:** Owner invites a staff member (via a simple code or link, no separate staff app-store account creation required beyond basic auth) and assigns the Staff role; staff members see a deliberately reduced interface — effectively just Quick Entry and today's own recorded entries, no access to Reports, Party balances beyond what's needed to record a transaction, or Business settings.

**Functional Requirements:** All entries created by a Staff-role user must be attributed (visibly, to the Owner) to that staff member for accountability, without requiring the staff member to see who else has access or broader business data; Owner must be able to revoke staff access instantly.

**Non-Functional Requirements:** Role enforcement must be validated server-side (not just hidden client-side UI), given the real financial-access-control stakes — a staff-role client must not be able to fetch Report or full-history data via direct API access even if UI navigation is restricted.

**Acceptance Criteria:** A staff-role test account, attempting to access Reports or historical data outside their permitted scope via any client path, is correctly denied at the API layer, verified in security testing.

**Failure States:** Revoked staff access must take effect immediately (next API call), not only on next app restart/token refresh cycle.

**Empty States:** No staff added yet: "Add staff so they can record sales without seeing your full reports" with a direct shortcut, framed as optional.

**Success Metrics:** % of active businesses using multi-user staff access; entries-per-staff-member (validates real delegated usage, not just a configured-but-unused feature).

**Future Expansion:** Additional intermediate roles (e.g., a "Manager" role with Report visibility but no settings access) — deferred to Version 2 pending demand signal from businesses larger than the typical MVP-target single-owner-plus-staff structure.

---

### 21.13 Multi-Branch Support

**Problem:** Businesses that grow beyond a single location (a second shop, a second workshop) need to track each location's finances both separately (for local decision-making) and together (for an overall business picture), which a single-ledger structure cannot support.

**Solution:** An optional Branch layer above the existing data model — each Transaction, Party, and Inventory item optionally belongs to a Branch, with the Daily Galla, Ledger, and Reports views each supporting a per-branch filter or a combined "all branches" view, without requiring single-branch businesses to ever interact with the concept at all.

**Functional Requirements:** Businesses that never add a second branch must see zero UI related to branches — this is a strictly progressive-disclosure feature (Chapter 16, principle #2), not a structural concept imposed on every business from Day 1; switching between branch views must be fast and clearly indicated (never ambiguous which branch's data is currently displayed).

**Non-Functional Requirements:** Adding Branch support to the data model must not require a breaking migration for existing single-branch businesses — the "no branch" state is the default and structurally equivalent to a single implicit branch, not a separate code path.

**Acceptance Criteria:** A single-branch business's existing data and workflows are completely unaffected by the existence of the Multi-Branch feature until they explicitly add a second branch.

**Failure States:** N/A beyond standard sync/reconciliation handling, applied per-branch.

**Empty States:** N/A (feature is invisible until the business opts in by adding a second branch).

**Success Metrics:** % of active businesses using more than one branch (a small, specific segment — not expected to be a majority, but valuable for the businesses that need it, per Persona 3, Anita's growth trajectory).

**Future Expansion:** Branch-level staff role scoping (a staff member who can only record entries for their assigned branch) — natural extension once core Multi-Branch and Staff Roles (21.12) are both validated; deferred to Version 2.

---

### 21.14 Business Health Score & AI Insights

**Problem:** Raw numbers (this month's profit, this month's expenses) don't tell an owner whether their business is actually doing better or worse, or what to pay attention to — the same "reduce thinking, not just reporting" gap identified in the companion "Today" app's AI Recommendations feature (21.12 of that PRD), applied here to business financial health.

**Solution:** A simple, narrative (not just numeric) monthly Business Health summary — e.g., "Your profit this month is up compared to last month, mainly because expenses were lower" — plus at most 1–2 short, actionable AI-generated insights (e.g., "You have 3 customers with balances over 30 days old — following up could recover this cash"), generated from existing transaction/party/inventory data.

**Workflow:** Generated as part of a monthly (not daily — deliberately lower-frequency than the companion "Today" app's daily Brief, since business-health trends are meaningfully assessed monthly, not daily) backend synthesis job, using the same underlying Report data (21.9) as input to the LLM synthesis call.

**Functional Requirements:** Must never present a numeric "score" alone without narrative context (avoiding the "dashboard the user must interpret" failure mode, Chapter 4 philosophy) — a numeric score, if shown at all, is a supporting visual, not the primary communication; insights must be dismissible and must not repeat a dismissed insight type within a cooldown period.

**Non-Functional Requirements:** Must degrade gracefully with limited data history (e.g., first month of use) — see Empty States.

**Acceptance Criteria:** A simulated business with a clear, seeded month-over-month profit decline produces a Health summary correctly identifying and explaining the decline in plain language.

**Failure States:** If LLM synthesis fails, the underlying numeric Reports (21.9) remain fully available — the narrative Health Score is an additive layer, never a blocking dependency for core reporting.

**Empty States:** First month of use with insufficient history for a month-over-month comparison: a simpler, single-month "here's how this month went" summary rather than a broken or misleading comparison.

**Success Metrics:** Health Score view rate; insight action rate (e.g., did the user follow up on a flagged overdue balance after seeing the insight).

**Future Expansion:** Peer/industry benchmarking (e.g., "similar small shops typically see X") — deferred, requires careful, privacy-respecting aggregate-data design (Chapter 27) before consideration, and is explicitly out of scope until a large enough anonymized dataset genuinely exists.

---

### 21.15 Search & Ledger History

**Problem:** Owners need to find a specific past transaction or party record (e.g., "that big payment from Hari in March") without scrolling through months of entries.

**Solution:** A search surface within the Ledger tab supporting search by party name, amount, date, or note text, with results presented in the same familiar transaction-list format as the main Ledger view.

**Workflow:** Query matches against locally-indexed Transaction and Party fields (offline-first, per Chapter 25); no semantic/AI search required for MVP given the structured, comparatively narrow nature of financial-record search compared to the companion "Today" app's freeform Memory Search (21.6 of that PRD) — a well-indexed exact/fuzzy match is sufficient and simpler to build reliably offline.

**Functional Requirements:** Support common query patterns: party name (partial match), amount (exact or range), date range, and free-text note search; results must be tappable directly into the transaction/party detail, never a dead-end preview.

**Non-Functional Requirements:** Search results returned in under 300ms for typical transaction-history sizes, fully offline.

**Acceptance Criteria:** Searching a partial party name correctly surfaces all matching transactions across the business's full history.

**Failure States:** No results found: explicit "nothing matched" state with a suggestion to check spelling or broaden the search, not a blank screen.

**Empty States:** Search screen before a query is entered: recent searches (once history exists) or simple guidance on what can be searched.

**Success Metrics:** Search usage frequency; search-to-successful-result rate.

**Future Expansion:** Semantic/fuzzy natural-language search (e.g., "that big rice order last month") mirroring the companion "Today" app's Memory Search approach — evaluated for Version 2 once real usage data shows structured search is insufficient for actual user query patterns.

---

### 21.16 Notification Engine

**Problem:** Owners need timely alerts (a low-cash warning, a payment-due reminder, a monthly Health Score ready) but excessive notifications from a financial app risk feeling alarming or intrusive rather than helpful, especially for an audience for whom financial anxiety is already a real, lived concern (Chapter 11).

**Solution:** A centralized, budget-aware notification engine (structurally similar to the companion "Today" app's Notification Engine, 21.19 of that PRD) capping total daily notifications and prioritizing by relevance, with a deliberately calm, non-alarmist tone even for genuinely important alerts like low cash.

**Workflow:** All feature-level triggers (payment-due reminders 21.11, low-stock alerts 21.7, monthly Health Score ready 21.14, reconciliation-discrepancy flags 21.8) register as candidates with the engine rather than sending directly; the engine selects and times the day's actual notification set based on user-configured quiet hours and a daily cap.

**Functional Requirements:** User-configurable quiet hours strictly enforced; full ability to disable categories individually (e.g., disable low-stock alerts, keep payment reminders) without an all-or-nothing toggle; low-cash and reconciliation-discrepancy alerts use calm, informative language ("Cash on hand is lower than usual" not "WARNING") consistent with Chapter 17's tonal guidance.

**Non-Functional Requirements:** Delivery via Firebase Cloud Messaging with retry/backoff; battery-efficient scheduled evaluation (Chapter 20), not continuous polling.

**Acceptance Criteria:** On a day with multiple theoretically eligible notification triggers, the user receives at most the configured daily cap, correctly prioritized, verified via simulated multi-trigger test scenarios.

**Failure States:** Delivery failure for any notification must not prevent the underlying alert condition (e.g., low stock, overdue balance) from being visible when the user next opens the relevant screen — notification is a convenience layer, not the source of truth.

**Empty States:** N/A (background system).

**Success Metrics:** Notification opt-out rate per category; reminder-to-action conversion rate (Chapter 21.11).

**Future Expansion:** Adaptive send-time optimization based on each business's actual typical open-time patterns — deferred to Version 2.

---

### 21.17 Offline Support & Cloud Sync

**Problem:** Target businesses (shops, market stalls, workshops) frequently operate with unreliable or no connectivity during business hours, and a financial record-keeping tool that fails offline is worse than the paper ledger it's meant to replace (Chapter 4, 12, 20).

**Solution:** A fully offline-first local persistence layer (Drift/SQLite on-device) as the single source of truth for all reads and writes, with a background sync process reconciling to Supabase/PostgreSQL whenever connectivity is available — no core-loop action (recording a transaction, viewing cash position, viewing a party balance) may ever block on network.

**Workflow:** Every write commits to local Drift storage synchronously before any network call is attempted; a background sync worker pushes an append-only change log to the backend and pulls remote changes (relevant for multi-device or multi-staff scenarios, 21.12), resolving conflicts using an append-only, additive strategy wherever the data model allows it (Party balances, Inventory quantities — see 21.5, 21.7) and a non-blocking manual-resolution card only for genuinely conflicting concurrent edits to the same field (e.g., two edits to the same transaction's amount).

**Functional Requirements:** All AI-dependent features (NL/voice classification, OCR extraction, Business Health Score) must have a defined, explicit offline-degraded behavior (documented per-feature above) rather than simply failing; core arithmetic (Daily Galla, Party balances, Reports) must never depend on AI/network availability at all, since these are the features carrying the highest trust stakes (Chapter 24).

**Non-Functional Requirements:** Sync must be incremental (change-log based), performant and battery-efficient as data history grows over years of business operation.

**Acceptance Criteria:** A full core-loop session (record 5 transactions across multiple parties, generate a report) executed in airplane mode, followed by reconnection, results in zero data loss and correct eventual server-side state, verified in automated integration tests.

**Failure States:** A sync conflict the engine cannot safely auto-resolve surfaces a simple "keep mine / keep other / merge" card, never silently discarding either version — given the financial stakes, this resolution card must show enough context (amount, date, party) for the owner to confidently choose correctly.

**Empty States:** N/A (infrastructure feature).

**Success Metrics:** Offline Session Success Rate (Chapter 13, target 100%); sync conflict rate and resolution-card engagement rate.

**Future Expansion:** Selective/partial sync for very large multi-year datasets on storage-constrained budget devices — deferred until real-world data volume warrants it.

---

### 21.18 Sharing & Export (PDF/Excel/WhatsApp)

**Problem:** Reports, invoices, and party balance statements are only useful if they can leave the app in a form the recipient (a bank, a customer, an accountant) can actually use — a screen the owner can only show in-person is insufficient for most real external-use cases (Chapter 12, Goal #4).

**Solution:** One-tap export of any Report, Invoice, or Party statement to PDF (for formal use — banks, tax) and direct sharing via WhatsApp or SMS (for informal use — sending a customer their balance, sending an invoice) given these are the dominant communication channels already used by the target audience.

**Workflow:** Export/share action available consistently from Reports (21.9), Invoicing (21.6), and Party detail (21.5) screens; PDF generation happens locally (offline-capable, per 21.6's non-functional requirement) and is handed to the platform's native share sheet, which already supports WhatsApp, SMS, email, and other installed apps without Galla needing custom integrations per channel.

**Functional Requirements:** Excel/CSV export additionally available for Reports specifically, supporting the accountant/bookkeeper use case (Chapter 4 edge case) where raw data manipulation is needed beyond a formatted PDF.

**Non-Functional Requirements:** Export generation must complete in under 3 seconds and function fully offline (the share step itself requires connectivity only for network-based channels like WhatsApp, not for generating the file).

**Acceptance Criteria:** A generated PDF report opens correctly and displays all figures accurately when opened outside the app (e.g., on a bank officer's computer), verified via cross-platform testing.

**Failure States:** If the native share sheet has no available network-based apps (offline), the generated file remains accessible via local file share/save, not lost or blocked.

**Empty States:** N/A (action, not a list).

**Success Metrics:** Export/share frequency per active business; channel breakdown (validates which formats/channels matter most to real usage, informing future prioritization).

**Future Expansion:** Direct email delivery with a custom Galla-branded template (rather than relying solely on the native share sheet) — deferred to Version 2.

---

### 21.19 Language, Currency & Localization

**Problem:** Target businesses operate across multiple regions and languages, and a tool available only in English (or only in one currency/number-format convention) would exclude a large share of the intended primary audience (Chapter 6, 9).

**Solution:** Full UI localization (starting with the primary target region's dominant local language(s) alongside English) and region-configurable currency symbol, number formatting (including local numbering conventions where they differ from international standards), and date format — set once during onboarding (with a sensible auto-detected default, never a blocking mandatory choice).

**Functional Requirements:** All user-facing strings externalized from Day 1 (Chapter 20) so adding a new language is a translation/content task, not an engineering one; number formatting must respect regional conventions correctly in both display and voice/NL input parsing (21.3), since misreading a number is a direct financial-accuracy risk, not just a cosmetic localization issue.

**Non-Functional Requirements:** Language switching must apply instantly across the full app without requiring reinstall or data loss.

**Acceptance Criteria:** A user switching the app's language mid-use sees all screens, including previously-entered transaction labels/categories where applicable, correctly localized without data corruption.

**Failure States:** An unsupported/untranslated string falls back to the base language (English) rather than displaying a broken placeholder key.

**Empty States:** N/A.

**Success Metrics:** Language distribution among active users (validates regional expansion prioritization); NL/voice entry accuracy broken out by language (Chapter 21.3 quality check per-locale).

**Future Expansion:** Additional regional languages and currencies added based on real user demand and regional expansion prioritization, sequenced in Version 2/3 roadmap discussions (Chapter 31, 32).

---

### 21.20 Settings & Business Profile

**Problem:** Owners need a place to configure business-level information (name, tax settings, starting balance, staff, branches) but this must remain minimal and rarely-visited, consistent with the product's "avoid too many settings" philosophy, not a sprawling configuration surface.

**Solution:** A single Business Profile screen consolidating business identity (name, logo for invoices, contact info), tax configuration (21.10), and links out to Staff (21.12) and Branches (21.13) management, plus standard app-level settings (language, currency, notifications, data export/deletion).

**Functional Requirements:** Full data export (all transactions, parties, inventory) available in a portable format (CSV/Excel), directly supporting the "no lock-in" philosophy established in Chapter 4's edge-case discussion — a business must always be able to leave with a clean copy of their own data; full account/data deletion available and clearly explained.

**Non-Functional Requirements:** Settings changes must take effect immediately without requiring an app restart.

**Acceptance Criteria:** A user can locate and complete full data export or full account deletion within 3 taps from the Business tab root, verified in usability testing.

**Failure States:** A failed export attempt must be retryable and must never partially delete data as a side effect of a failed export/deletion flow.

**Empty States:** N/A (utility screens).

**Success Metrics:** Settings visit frequency (should be low relative to core-loop screens); data export usage rate (a trust/transparency signal, mirroring the equivalent metric in the companion "Today" app PRD).

**Future Expansion:** Multi-business support under a single owner account (e.g., an owner running two unrelated businesses) — deferred, evaluated separately from Multi-Branch (21.13), which assumes branches of the *same* business.

---

## 22. AI Assistant System

**Purpose:** Define the AI's behavioral role across the whole product, covering tone, capability scope, and guardrails — distinct from any single AI feature (21.3, 21.4, 21.14).

**Goals:** The AI must consistently behave as a fast, careful clerk, never an autonomous financial decision-maker. Concretely: the AI infers and suggests (transaction classification, receipt extraction, health insights) but every inference is one tap from user override, and the AI never takes irreversible action (deleting a record, sending a message to a customer) without explicit confirmation. Given the financial stakes, the AI's guiding rule is stricter than a general productivity assistant's: **when uncertain, ask or leave blank — never guess with false confidence on a monetary figure.**

**Research:** Trust research on AI in financial contexts specifically shows users are far less tolerant of confident-but-wrong outputs on numeric/monetary fields than on softer, narrative content — a wrong guess at an amount is qualitatively more damaging to trust than a wrong guess at, say, a task category in a general planning app, directly justifying a stricter conservative-fallback standard here than even the equivalent principle in the companion "Today" app PRD.

**Discussion:** The AI's tone (Chapter 17) must remain calm and plain-spoken across every touchpoint — parsing confirmations, low-cash alerts, Health Score narratives — avoiding both alarmist language (which could cause real anxiety for a livelihood-dependent audience) and overly casual language (which could undermine the credibility needed for the "bank-ready" half of the product's value proposition, Chapter 2).

**Requirements:** All LLM calls for user-facing content must route through a shared system-prompt template enforcing tone consistency and the "never guess monetary figures with false confidence" rule as a hard constraint, not a soft preference.

**Acceptance Criteria:** A red-team style test suite of ambiguous/low-confidence inputs confirms the AI consistently defers to manual completion rather than guessing on amount/direction fields.

**Edge Cases:** Ambiguous or low-confidence AI inferences on non-monetary fields (party name spelling, category) may use best-effort inference with clear "AI-suggested" visual marking, since the cost of a wrong guess there is low and easily correctable, unlike monetary figures.

**Future Considerations:** Conversational (chat-style) financial Q&A ("how much did I spend on supplies last month?") as a natural-language layer over Reports — a plausible, well-justified Version 2 feature given the reporting-heavy domain, evaluated once core entry/reporting trust is well established.

---

## 23. Notification Strategy

**Purpose:** State the cross-feature strategic principles governing all notifications, complementing the mechanical spec in 21.16.

**Goals:** Notifications must feel like a helpful, calm assistant flagging something genuinely worth the owner's attention — never an alarming or nagging presence, especially given financial notifications carry inherently higher emotional weight than a general productivity app's reminders.

**Research:** For financial-management tools specifically, users report that alarmist notification language (e.g., aggressive "WARNING" framing for routine low-cash-flow days) erodes trust and increases anxiety without improving actual financial behavior, whereas calm, specific, actionable framing achieves the same informational goal without the trust cost — directly informing the tonal requirements in 21.16 and Chapter 17.

**Discussion:** The three primary notification categories (payment-due reminders, low-stock/low-cash alerts, monthly Health Score) map directly to genuinely high-value moments identified through the User Journey (Chapter 10) and Jobs To Be Done (Chapter 11) — this list should not expand without clear evidence that additional categories improve retention rather than eroding trust through over-notification.

**Requirements:** Every new feature proposed post-MVP that wants a notification trigger must register through the centralized budget-aware engine (21.16), never implement an independent, uncapped notification path.

**Acceptance Criteria:** Notification permission grant rate and retention rate are monitored together; if a new notification type correlates with retention decline, it is rolled back.

**Edge Cases:** Time-zone and regional-holiday awareness for reminder timing (e.g., not sending business notifications during locally-observed non-business hours or major holidays) should be considered in scheduling logic.

**Future Considerations:** Rich, actionable notifications (e.g., recording a payment directly from the notification shade) — evaluated for Version 2 once core notification-volume discipline is validated.

---

## 24. Trust & Data-Confidence Strategy

**Purpose:** Consolidate the cross-cutting principles that make Galla's numbers something an owner — and eventually a bank — can actually rely on, replacing the "Gamification Strategy" chapter from the companion "Today" app PRD with the domain-appropriate equivalent concern for a financial product: trust in accuracy, not motivation to engage.

**Goals:** Every number Galla shows must be traceable, correctable, and honest about its own confidence level. The product must never present an AI-inferred or estimated figure with the same visual authority as a manually-confirmed, verified figure.

**Research:** Financial-tool trust is built cumulatively through consistent correctness over time far more than through any single feature or interface polish — this is why the conservative-fallback principle (Chapter 22), the explicit adjustment-entry pattern (never silent overwrites, 21.1, 21.8), and the full audit-visible transaction history (21.15) are treated as core trust infrastructure, not secondary features.

**Discussion:** This is the domain-specific analog to the "no punishment" gamification discipline established in the companion "Today" app PRD — just as that product had to resist the temptation to add punitive engagement mechanics under growth pressure, this product must resist the temptation to smooth over data uncertainty (e.g., silently "rounding" an unclear OCR extraction, or hiding a sync-conflict rather than surfacing it) for a cleaner-looking UI, since doing so would directly undermine the core value proposition.

**Requirements:** Any proposed feature or UI simplification that would hide, silently resolve, or obscure a genuine data discrepancy or AI-uncertainty must pass explicit product and engineering review before implementation.

**Acceptance Criteria:** A full audit of all AI-inference-marking, adjustment-entry, and conflict-resolution UI (Chapters 21.1–21.20) confirms zero instances of silently-resolved discrepancies or unmarked AI-guessed monetary figures.

**Edge Cases:** N/A beyond what is covered in individual feature specs.

**Future Considerations:** A visible, optional "data confidence" indicator (e.g., "X% of your entries this month were AI-assisted vs. manually entered") could reinforce transparency further — candidate for Version 2, evaluated for whether it adds genuine trust value or unnecessary complexity.

---

## 25. Offline-First Strategy

**Purpose:** State the architectural philosophy behind 21.17 at a strategic level.

**Goals:** Local device storage (Drift/SQLite) is the single source of truth for the running app at any given moment; the cloud (Supabase/PostgreSQL) is a durable backup and cross-device/multi-staff sync mechanism, never a live dependency for core-loop functionality.

**Research:** This strategy responds directly to the real connectivity conditions of the target segment (Chapter 6, 9) — small shops, market stalls, and workshops frequently operate in low or intermittent connectivity, where a "requires internet" financial tool would fail at the exact moments transactions actually happen.

**Discussion:** Offline-first is architecturally demanding (conflict resolution, sync-state UI, idempotent event logging) but is treated as foundational, non-negotiable investment, exactly as in the companion "Today" app PRD's equivalent strategy — with the added consideration here that financial data conflicts carry higher real-world stakes than a missed task, further justifying the careful, additive-where-possible conflict-resolution design in 21.5, 21.7, and 21.17.

**Requirements:** No engineering ticket for a core-loop feature (transaction entry, Daily Galla view, Party balance view, Report generation) may be marked complete without an explicit offline-mode test pass.

**Acceptance Criteria:** Automated CI test suite includes an airplane-mode integration test path for every core-loop feature.

**Edge Cases:** AI-dependent enrichment (NL/voice classification, OCR, Business Health Score) is the one class of feature allowed genuine offline degradation, documented per-feature in Chapter 21.

**Future Considerations:** On-device small-model classification for NL/voice entry would narrow the offline-degradation gap further and should be evaluated as on-device model efficiency improves, mirroring the equivalent future consideration in the companion "Today" app PRD.

---

## 26. Security

**Purpose:** Define baseline security requirements protecting user data across the stack.

**Requirements:**
- All network traffic over TLS 1.2+; certificate pinning evaluated for mobile clients given the sensitivity of all data in this app (effectively 100% financial, unlike a general productivity app where only a subset of data is financial).
- At-rest encryption (AES-256 or platform-equivalent) applied to all business data by default, not as a subset-specific measure, given this product's data is uniformly financial in nature.
- Authentication via Supabase Auth (or equivalent) with mandatory support for biometric app-lock (Face ID/fingerprint/PIN) given every screen in the app shows sensitive financial information.
- Staff-role access tokens (21.12) scoped narrowly server-side, independently revocable and time-bounded, given the real-world scenario of staff turnover.
- Rate limiting and abuse protection on all backend (FastAPI) endpoints, particularly AI-classification, OCR, and report-generation endpoints.
- Regular dependency and container vulnerability scanning as part of the CI/CD pipeline (GitHub Actions + Docker).
- Audit log of all data modifications (edits, deletions, adjustment entries) retained and viewable by the Owner, given the explicit "no silent overwrites" trust principle (Chapter 24).

**Research:** Given this product holds the complete financial picture of a livelihood-dependent business — not a subset of personal data alongside other domains, as in a general productivity app — the security bar must be at least as high as a dedicated consumer fintech product, and a breach here has a categorically higher impact on the specific user than the equivalent risk profile discussed in the companion "Today" app PRD.

**Discussion:** Biometric app-lock and staff-scoped, revocable access are both elevated to required (not optional) MVP features specifically because of this uniformly-financial data profile.

**Acceptance Criteria:** Third-party security audit/penetration test completed before public launch, with all critical/high findings remediated pre-launch.

**Edge Cases:** Lost/stolen device — biometric lock plus remote data-wipe-on-account (via web-based account management, out of scope for this mobile-only PRD but noted as a required companion capability) mitigate exposure.

**Future Considerations:** Pursue relevant regional financial-data-handling compliance certifications as the product expands into markets with specific regulatory requirements.

---

## 27. Privacy

**Purpose:** Define the user-facing privacy commitments and controls, distinct from the technical security measures in Chapter 26.

**Requirements:**
- No advertising business model; business financial data is never sold, shared with data brokers, or used to target ads.
- Full user-facing transparency: an audit log (26) doubling as a "what's been recorded and changed" view the owner can always inspect.
- Staff-role users (21.12) have their own data-visibility scope clearly explained to them at invitation time — they should understand exactly what the Owner can see about their activity (their own entries, attributed) and what they cannot see (full business reports, other data).
- Clean, complete data export always available (21.20) with no lock-in — directly supporting the "graceful graduation" philosophy (Chapter 4 edge case) for businesses that eventually move to more sophisticated accounting software.
- Data retention and deletion: full account deletion must remove data from both local device and backend within a clearly communicated timeframe.
- Any future aggregate/benchmarking features (Chapter 21.14 Future Expansion) must use privacy-preserving aggregation with explicit opt-in, never exposing any individual business's data to another, even indirectly.

**Research:** Given the target audience's justified wariness of financial technology products (Chapter 8, SWOT Threats — trust/security failure risk), privacy transparency is treated as core trust-building infrastructure, directly parallel to but even higher-stakes than the equivalent treatment in the companion "Today" app PRD, since this product's entire dataset is financial rather than a mix of domains.

**Discussion:** The staff-visibility-scope transparency requirement is specific to this product's multi-user reality (21.12) and has no direct equivalent in the companion "Today" app PRD — it deserves particular design and legal attention given the employer/employee power dynamic involved.

**Acceptance Criteria:** A privacy-focused usability test confirms both Owner and Staff-role test users can correctly explain what data is visible to whom after reading the relevant onboarding/settings copy.

**Edge Cases:** Users in jurisdictions with specific data-protection regimes must have region-appropriate consent flows and data-subject-request handling — specific legal implementation deferred to legal counsel, out of this PRD's scope.

**Future Considerations:** Formal privacy policy and terms of service drafting (legal deliverable, out of PRD scope) must be reconciled against every commitment stated in this chapter before public launch.

---

## 28. Performance Requirements

**Purpose:** Set concrete, testable performance targets referenced by Chapter 20.

| Metric | Target |
|---|---|
| Cold app start → interactive Galla home screen | < 1.5s (budget/mid-tier device) |
| Quick Entry tap → numeric keypad ready | < 150ms |
| Entry submit → locally saved | < 200ms |
| Daily Galla summary update after entry | < 100ms |
| Report generation (1 year of data) | < 3s, fully offline |
| Invoice PDF generation | < 3s, fully offline |
| Search (offline, typical history size) | < 300ms |
| Nightly Health Score / reminder evaluation job | 99.9% of businesses processed before local morning hours |
| Crash-free session rate | ≥ 99.5% |

**Research:** These targets mirror the mobile-UX-perception research cited in the companion "Today" app PRD (sub-100ms as the threshold for "instantaneous" perception) but are applied with particular emphasis on budget-device performance, since this audience's device profile skews more toward lower-spec hardware than the general productivity-app audience — a target validated only on flagship devices would misrepresent real-world experience for a larger share of this specific user base.

**Discussion:** Report generation and Invoice PDF generation targets are set to fully offline-capable performance deliberately, not "under good network conditions," since these are exactly the moments (showing a report to a supplier or bank on the spot) where network unavailability would be most damaging to the product's core trust proposition (Chapter 2, 24).

**Requirements:** Performance budgets enforced via automated CI benchmarks on representative budget-device profiles, blocking merge on regression beyond defined thresholds.

**Acceptance Criteria:** All targets in the table above are met in pre-launch QA on both a flagship and a genuinely low-spec/budget reference device representative of the target markets.

**Edge Cases:** Very large datasets (multi-year, high-transaction-volume businesses like Ramesh's restaurant, Persona 2) must be included in performance test fixtures.

**Future Considerations:** Re-baseline targets as average device capability improves across target markets over the product's lifetime.

---

## 29. Technical Constraints & Architecture

**Purpose:** Document the committed technology stack and architectural pattern for engineering onboarding.

**Stack:** Flutter (cross-platform mobile client) with Riverpod for state management and GoRouter for navigation (Chapter 15); Drift for local SQLite-backed offline-first persistence (Chapter 20, 25); FastAPI backend serving AI classification, OCR, report-synthesis, and sync-reconciliation endpoints; Supabase (PostgreSQL + Auth) as the managed backend-as-a-service layer, with staff-role access control enforced at this layer (26); Docker for backend containerization; Firebase Cloud Messaging for push notification delivery (21.16); GitHub Actions for CI/CD (test, lint, performance benchmarking on budget-device profiles, build/release). *(This stack mirrors the companion "Today" app PRD's committed stack; assumed consistent for this PRD given shared team/infrastructure — flag in Chapter 34 Open Questions if this assumption is incorrect.)*

**Architecture pattern:** Clean Architecture with MVVM on the client, organized Feature-First (each feature in Chapter 21 is its own module with its own data/domain/presentation layers), for the same reasons established in the companion "Today" app PRD — the feature list here is similarly large enough that a layer-first structure would create significant merge contention as the team scales.

**Domain-specific architectural notes:**
- The **Transaction** object (Chapter 14) is the single most-written, most-critical data structure in the system and must be designed for append-only, audit-preserving writes from the outset — corrections happen via new adjustment entries, never in-place mutation of historical financial records, a stricter discipline than a general productivity app's data model typically requires.
- The **tax calculation module** (21.10) must be implemented as a pluggable, region-configurable rules engine, not hardcoded logic, given the explicit multi-region ambition (Chapter 6, 19).
- The **Report generation engine** (21.9) must be a pure, deterministic function of Transaction data for a given date range — critically, it must never depend on AI/LLM output for the numeric figures themselves (only the optional narrative Health Score, 21.14, uses AI) — ensuring reports remain fully explainable, reproducible, and auditable.

**Research:** The append-only, audit-preserving Transaction data model is a direct architectural implementation of the Trust & Data-Confidence Strategy (Chapter 24) — a financial record-keeping product that allows silent in-place edits to historical transactions cannot credibly claim to produce "bank-ready" records, since auditability is itself a core requirement of financial record credibility.

**Discussion:** Keeping numeric Report generation strictly deterministic and AI-independent (while allowing the separate narrative Health Score layer to use AI) is a deliberate, important architectural boundary — it ensures the product's core credibility claim never depends on AI reliability, only the "nice to have" insight layer does.

**Requirements:** Every new feature module must include: data layer (Drift schema + repository), domain layer (use-cases/business logic, framework-independent), presentation layer (Riverpod providers + widgets) — no feature may bypass this structure for expedience.

**Acceptance Criteria:** A new engineer can build and ship a small, isolated feature by touching only files within that feature's module folder, without required edits to unrelated feature modules.

**Edge Cases:** Shared cross-cutting concerns (Transaction object itself, Notification engine, Sync engine, Tax rules engine) are deliberately modeled as core/shared modules, not owned by any single feature.

**Future Considerations:** Evaluate a shared business-logic layer (e.g., via a shared package) if a desktop/web companion for report review is ever pursued (plausible for this product given the business/accountant-facing use case, more so than for a personal companion app).

---

## 30. MVP Definition

**Purpose:** Explicitly scope what ships first, enforcing the discipline argued for throughout this PRD against the full feature list's breadth.

**In scope for MVP:**
- Quick Entry (21.2) and Natural Language & Voice Entry (21.3) — the core value-creation loop.
- Daily Galla cash-book home view (21.1).
- Party Ledger / Udhaar tracking (21.5) — a top-tier differentiator versus generic expense trackers (Chapter 7) and directly addresses a named primary problem (Chapter 5, credit blindness).
- Basic Receipt Scanning (21.4) with photo-attachment always available even without OCR at initial release, OCR as a fast-follow within MVP if feasible, otherwise Version 2.
- Financial Reports (21.9) — simple view only at MVP; the "standard/accountant" view (21.9 functional requirement) may follow shortly after if not ready at initial launch.
- Search & Ledger History (21.15), structured (non-semantic) search only.
- Offline-first architecture and Cloud Sync (21.17) — foundational, not deferrable, exactly as in the companion "Today" app PRD's equivalent decision.
- Notification Engine (21.16) with payment-due reminders (21.11) and low-cash alerts only.
- Basic Settings, Business Profile, biometric app-lock, and core security/privacy commitments (26, 27).
- Sharing & Export (21.18) — PDF export and native share-sheet integration (WhatsApp/SMS) at minimum.

**Explicitly deferred (Version 2, Chapter 31):** Invoicing & Billing (21.6) as a full dedicated flow — MVP supports recording income transactions and simple statements, but not a polished, sequential-numbered invoice generator; Inventory Lite (21.7); Bank & Cash Reconciliation (21.8) as a guided flow — MVP supports manual starting-balance correction only; Tax & Compliance module (21.10) beyond a single simple configurable rate; Staff Roles & Multi-User Access (21.12); Multi-Branch Support (21.13); Business Health Score & AI Insights (21.14); full Excel/CSV export (21.18) — MVP ships PDF only; multi-language localization beyond the primary launch region's language plus English (21.19) — additional languages sequenced by regional launch priority.

**Research:** This scoping follows the same "prove the core synthesis loop before investing in deeper integrations" logic established in the companion "Today" app PRD's MVP Definition — here, the core loop is capture → classify → cash position → party balance → simple report, and every deferred item (invoicing polish, inventory, staff roles, tax depth) is a valuable but separable extension of that proven core, not a precondition for it.

**Discussion:** Party Ledger (21.5) is notably included in MVP (unlike, say, the companion "Today" app's deferral of its Finance feature's full depth to Version 2) because credit/udhaar tracking is not a "nice to have" extension for this product's target persona — it is one of the three named core problems (Chapter 5) and a primary differentiator versus every existing simple expense-tracker competitor (Chapter 7); shipping without it would fail to prove the product's central value proposition.

**Requirements:** Engineering roadmap and sprint planning must be organized around this MVP boundary; any scope addition beyond this list requires explicit product sign-off.

**Acceptance Criteria:** MVP is considered complete when a first-time business owner can complete the full Day-0-through-Day-30 User Journey (Chapter 10) using only in-scope features above, validated via structured usability testing with real target-persona participants before public launch.

**Edge Cases:** N/A (scoping chapter).

**Future Considerations:** Re-evaluate this boundary immediately after the first 4–6 weeks of MVP usage data (Chapter 13 metrics) before committing final Version 2 sequencing.

---

## 31. Version 2 Roadmap

**Purpose:** Sequence the features deferred in Chapter 30, prioritized by expected impact on the Chapter 13 success metrics.

**Priority order and rationale:**
1. **Full Invoicing & Billing (21.6)** — directly targets the service-provider/wholesale-buyer persona segment (Bikash, Anita) not fully served by MVP's simpler statement capability; moderate engineering cost, high expected impact on Report Generation Rate and External-Use Rate.
2. **Bank & Cash Reconciliation guided flow (21.8)** — builds directly on MVP's manual-correction pattern already in place; addresses a real, named trust concern (data accuracy) at moderate cost.
3. **Staff Roles & Multi-User Access (21.12)** — high expected impact for the food-service/retail-with-employees persona segment (Ramesh), but requires the added security/access-control engineering rigor (Chapter 26) to be done right, justifying sequencing after the reconciliation and invoicing work.
4. **Inventory Lite (21.7)** — valuable for retail/manufacturing personas (Sita, Anita) but lower urgency than credit-tracking or invoicing per the Chapter 9 persona research; sequenced once core-loop metrics from MVP validate strong retention to invest further engineering effort confidently.
5. **Tax & Compliance depth (21.10)** and **Multi-Branch Support (21.13)** — sequenced opportunistically based on regional launch priorities and MVP metric gaps.
6. **Business Health Score & AI Insights (21.14)** — deferred until enough usage data/history exists across active businesses to generate genuinely relevant month-over-month insights rather than generic filler, mirroring the equivalent reasoning for AI Recommendations in the companion "Today" app PRD.
7. **Full localization expansion (21.19)** — sequenced by regional go-to-market priority, a business/GTM decision more than a pure engineering-readiness one.

**Research:** This sequencing reflects the same "cheapest infrastructure reuse first, highest-impact-on-named-metrics next, highest-complexity/highest-security-stakes items given adequate lead time" logic used in the companion "Today" app PRD's Version 2 Roadmap, adapted to this product's specific persona and trust priorities.

**Discussion:** This roadmap is explicitly a hypothesis, not a commitment — Chapter 13's metrics from MVP launch should reorder this list before final sprint planning, particularly given real regional/regulatory factors (tax, banking integration availability) that may shift priority independent of pure product-impact reasoning.

**Requirements:** Each Version 2 item inherits its full feature spec already defined in Chapter 21 — no re-specification needed, only re-sequencing.

**Acceptance Criteria:** N/A (planning chapter).

**Edge Cases:** N/A.

**Future Considerations:** N/A.

---

## 32. Version 3 Vision

**Purpose:** Sketch the longer-horizon product direction beyond Version 2, extending the Vision (Chapter 2) toward a broader small-business financial ecosystem role.

**Direction:** Two plausible, complementary long-horizon expansions: (1) an **accountant/bookkeeper mode** — a dedicated interface for professionals serving multiple small-business clients through Galla, using standard accounting terminology and multi-client dashboards, directly extending the "accountant-facing export" edge case established in Chapter 4; and (2) **credit and financial-services access** — leveraging the credible, organized financial history Galla produces (Chapter 2's vision) to enable direct-in-app connections to lending or financial-services partners for qualifying businesses, turning the product's core trust proposition into a tangible financial-inclusion outcome for users, not just a record-keeping convenience.

**Research:** This direction is deferred to Version 3, not earlier, because both expansions depend on first proving, at meaningful scale, that Galla's records are genuinely trusted and used externally (Product Goal #4, Chapter 12; External-Use Rate metric, Chapter 13) — pursuing lending partnerships or a professional accountant product before that trust is established would risk both premature complexity and reputational risk if the underlying data quality isn't yet proven at scale.

**Discussion:** The financial-services-access direction must be designed carefully to preserve user trust and avoid any perception of predatory lending facilitation — any such partnership would require rigorous, transparent partner vetting and must remain entirely opt-in, never a default data-sharing arrangement, consistent with the Privacy commitments (Chapter 27).

**Requirements:** None yet defined at PRD level; full feature specification deferred to a future PRD revision once Version 2 metrics validate readiness to expand scope.

**Acceptance Criteria:** N/A.

**Edge Cases:** N/A.

**Future Considerations:** A desktop/web companion surface, explicitly out of scope for the mobile-first architecture described in Chapter 29, would likely be a prerequisite for a serious accountant-mode product given professionals' typical multi-client, larger-screen workflow expectations.

---

## 33. Risks

**Purpose:** Name the key risks threatening this PRD's success, cross-referencing earlier analysis.

| Risk | Source | Mitigation |
|---|---|---|
| Scope creep across a large, cross-functional feature list (cash book, ledger, invoicing, inventory, tax, reports) | Chapter 8 (Weaknesses) | Strict MVP boundary (Chapter 30) with product sign-off required for additions |
| A well-funded fintech/payments incumbent bundles a similar ledger feature, leveraging existing distribution and trust | Chapter 8 (Threats) | Differentiate via depth of the credit/udhaar ledger and report credibility; prioritize speed to meaningful market presence |
| Trust/security failure has outsized impact given 100% of app data is financial | Chapter 26, 27 | Security audit pre-launch; encryption; staff-scoped revocable access; audit-log transparency |
| AI-inferred monetary figures erode trust if confidently wrong | Chapter 13, 22, 24 | Strict conservative-fallback rule: never guess amount/direction with false confidence |
| Regulatory/tax-rule variance across regions adds engineering and compliance complexity outside product control | Chapter 6, 21.10 | Region-configurable, pluggable tax rules engine (Chapter 29) designed from the outset, not retrofitted |
| Low digital/financial literacy in parts of the target audience limits adoption regardless of UX quality | Chapter 9, 18 | Icon-first design, voice entry as first-class accessibility feature, plain-language copy throughout |
| Data-loss incident (even isolated) could set back trust across the entire target segment given justified pre-existing wariness of fintech products | Chapter 8 (Threats), 20 | Rigorous offline-first, write-ahead-persistence architecture (Chapter 25); zero-data-loss as a P0-severity engineering standard |

**Research:** This risk table synthesizes findings already established earlier in the document, deliberately avoiding new, undiscussed risk categories at this stage — every risk here should already feel familiar to a reader of the full document, mirroring the structure of the companion "Today" app PRD's equivalent chapter.

**Discussion:** The two highest-severity risks for this specific product are AI-confidence-on-monetary-figures and data-loss/trust-failure — both notably higher-stakes here than their nearest equivalents in the companion "Today" app PRD, given this product's uniformly financial, livelihood-critical data profile.

**Requirements:** Risk table reviewed at each major milestone (MVP launch, each Version 2 feature ship) and updated.

**Acceptance Criteria:** N/A.

**Edge Cases:** N/A.

**Future Considerations:** Add a formal risk-scoring (likelihood × impact) model once the team has enough operating history to calibrate it meaningfully.

---

## 34. Open Questions

**Purpose:** Surface unresolved decisions requiring stakeholder input before or during early development.

1. **Primary launch region and language(s)** — this PRD assumes a South Asia-adjacent primary market (given the product's "khata" framing and persona research, Chapter 2, 9) but does not resolve the specific initial launch country/language set; this materially affects tax-rule configuration (21.10) and localization sequencing (21.19) and should be resolved before detailed engineering begins on those modules.
2. **Bank-feed integration feasibility** (21.8 Future Expansion) — dependent entirely on regional banking API availability, which varies significantly by market and is outside this PRD's ability to resolve; requires dedicated regional research.
3. **Tax rule specifics per launch region** (21.10) — the exact VAT/GST rates, thresholds, and required document formats must be sourced from local regulatory/legal expertise, not assumed generically in this PRD.
4. **AI model selection and cost model** for classification, OCR, and report-synthesis pipelines (21.3, 21.4, 21.14) — this PRD assumes Anthropic API usage consistent with the companion "Today" app PRD's tech stack, but does not resolve specific model tier, per-transaction cost economics (particularly relevant given potentially high transaction volume per business, e.g., Persona 2 Ramesh's restaurant), or fallback-provider strategy.
5. **Final product name and trademark clearance** — "Galla" is a strong, culturally resonant working name but requires trademark and App Store availability clearance in each target launch region before being finalized.
6. **Pricing/monetization model** — this PRD scopes monetization only at the goal level (Chapter 12); the specific premium-tier feature boundary (e.g., is Multi-Branch or Staff Roles a paid tier feature) is unresolved and requires a dedicated pricing strategy exercise, informed by real regional willingness-to-pay research given this audience's typically tight margins.
7. **Technology stack assumption** — this PRD assumes the same Flutter/FastAPI/Supabase stack as the companion "Today" app PRD (Chapter 29) on the basis of shared team/infrastructure; this should be explicitly confirmed rather than silently inherited, particularly given this product's stricter data-integrity and audit-log requirements (Chapter 24, 29) which may warrant additional architectural review even within the same stack.

**Research:** These questions require either external regulatory/legal engagement, regional business-strategy decisions, or dedicated exercises (naming clearance, pricing research) outside a PRD's scope — flagging them explicitly here prevents them from being silently decided by default during implementation, consistent with the same discipline applied in the companion "Today" app PRD's Open Questions chapter.

**Discussion:** Question 1 (launch region) is the most foundational, since it cascades directly into Questions 2, 3, and 5 — resolving it early is a prerequisite for meaningfully de-risking the rest of this list.

**Requirements:** Each open question above should be assigned an owner and target resolution date before the relevant dependent feature enters active development.

**Acceptance Criteria:** N/A.

**Edge Cases:** N/A.

**Future Considerations:** Revisit this list at each major planning cycle; remove resolved items, add newly surfaced ones.

---

## 35. Appendix

### 35.1 Naming Candidate Notes
Working name "Galla" is deliberately regionally resonant (evoking the physical cash box/till of a traditional shop) and should be validated for meaning, connotation, and trademark/App Store availability across every target launch region before final commitment (Open Question 5, Chapter 34) — a name resonant in one region may carry unrelated or even negative connotations in another.

### 35.2 Glossary
- **Transaction** — the atomic unit of a recorded money-in or money-out event, see Chapter 14.
- **Galla (Daily Galla)** — the live, always-current daily cash summary view, see 21.1.
- **Udhaar** — informal credit/money owed by a customer, tracked via Party Ledger, see 21.5.
- **Party** — a customer or supplier record with a running balance, see 21.5.
- **Reconciliation** — the process of matching recorded figures against actual counted cash/bank balance, see 21.8.

### 35.3 Persona Quick-Reference
See Chapter 9 for full detail: Sita (kirana/general store owner), Ramesh (small restaurant owner with staff), Anita (small manufacturer/workshop owner with wholesale credit terms), Bikash (freelance service provider/contractor).

### 35.4 Design Review Checklist (Philosophy & Trust Gates)
A gating checklist (referenced in Chapters 4, 16, 24) to be applied to every new feature before implementation:
- Does this feature require accounting vocabulary or setup before it becomes useful? (Should be no.)
- Does every monetary figure shown have a clear, plain-language directional label (owed to/by, in/out)?
- Is every AI inference on a monetary field conservative (never guessed with false confidence) and transparently marked?
- Does every historical-data correction create a new, visible adjustment entry rather than a silent overwrite?
- Is there exactly one obvious primary action on every screen this feature introduces?
- Does every empty state teach the user what to do next, without accounting jargon?

### 35.5 AI Voice & Tone Style Guide (Reference)
All LLM-generated user-facing copy (parsing confirmations, Health Score narratives, low-cash/reminder alerts) should be reviewed against the tone established in Chapter 17 and Chapter 22: plain-spoken, calm, never alarmist, never jargon-heavy. A living style guide document (maintained outside this PRD) should collect approved and rejected copy examples over time, shared where relevant with the equivalent style guide maintained for the companion "Today" app product (Appendix 35.5 of that PRD) given overlapping team/tone standards.

---

*End of document. This PRD is a living artifact — Chapters 13 (Success Metrics), 30 (MVP Definition), and 34 (Open Questions) should be revisited at every major milestone.*
