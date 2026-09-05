# Galla Web Application: Complete Architecture & Design System Specification

This document provides the complete blueprint, theme constraints, design tokens, layout hierarchy, and component specifications needed to build the web version of **Galla**.

---

## 1. Design System & Theme Constraints

Galla's visual identity is built on **trust, clarity, and merchant familiarity**. It avoids generic SaaS templates and embraces a warm, editorial, and tactile aesthetic inspired by traditional merchant ledgers (*khata*) elevated with modern typography and structured data.

### 1.1 Color Tokens

| Token Name | Hex Code | HSL / RGBA Equivalent | Semantic Role |
|---|---|---|---|
| **Canvas** | `#F7F4EF` | `hsl(38, 33%, 95%)` | Main application background (warm cream) |
| **Surface** | `#FFFFFF` | `rgb(255, 255, 255)` | Primary card and table background |
| **Surface Alt** | `#F3EEE6` | `hsl(38, 30%, 93%)` | Table headers, secondary containers |
| **Surface Elevated** | `#FAF8F4` | `hsl(40, 33%, 97%)` | Hover states, interactive panels |
| **Line (Border)** | `#EAE4DA` | `hsl(37, 26%, 89%)` | Primary container borders and table dividers |
| **Line Soft** | `#F0EBE2` | `hsl(38, 31%, 91%)` | Subtle inner dividers |
| **Ink** | `#181818` | `rgb(24, 24, 24)` | Primary text and large numbers |
| **Ink Secondary** | `#3D3D3D` | `rgb(61, 61, 61)` | Secondary content and table cells |
| **Muted** | `#787878` | `rgb(120, 120, 120)` | Captions, metadata, column headers |
| **Faint** | `#AEA696` | `hsl(39, 14%, 64%)` | Placeholders, disabled states |
| **Brand (Forest)** | `#1A3B2E` | `hsl(156, 39%, 17%)` | Primary brand green, navigation sidebar |
| **Brand Mid** | `#2D5A40` | `hsl(145, 33%, 26%)` | Primary buttons, interactive highlights |
| **Brand Soft** | `#E6F0EA` | `hsl(144, 28%, 92%)` | Brand badges, active sidebar item background |
| **Money In** | `#1B7A3E` | `hsl(142, 64%, 29%)` | Sales, cash collected, credit payments |
| **Money In Soft** | `#EAF5ED` | `hsl(137, 39%, 94%)` | Positive transaction badges |
| **Money Out** | `#C0392B` | `hsl(6, 63%, 46%)` | Expenses, supplier payments, destructive actions |
| **Money Out Soft** | `#FDEBEA` | `hsl(4, 82%, 96%)` | Expense badges, alert chips |
| **Udhaar (Amber)** | `#B45309` | `hsl(26, 90%, 37%)` | Customer receivables, pending credit balance |
| **Udhaar Soft** | `#FEF3E2` | `hsl(37, 95%, 94%)` | Udhaar warning pills and reminders |
| **Gold** | `#B8962E` | `hsl(45, 60%, 45%)` | Accent highlights, health score, demo badges |
| **Gold Soft** | `#FDF8EB` | `hsl(44, 88%, 96%)` | Special callout cards |
| **Blue** | `#1D4ED8` | `hsl(221, 83%, 48%)` | System info, invoice links, bank indicators |
| **Blue Soft** | `#EFF4FF` | `hsl(221, 100%, 97%)` | Informational chips |

#### Hero Surface Gradient
```css
background: linear-gradient(135deg, #244837 0%, #163326 100%);
```

---

### 1.2 Typography System

Galla uses Google Fonts **Outfit** across all desktop and mobile interfaces. Outfit delivers clean geometric numbers with warm grotesque letters.

- **Primary Font Family:** `'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif`
- **Tabular Numerals:** Always apply `font-variant-numeric: tabular-nums` to financial amounts and ledger tables to guarantee perfect digit alignment.

| Role | Font Size | Weight | Line Height | Letter Spacing | CSS Usage |
|---|---|---|---|---|---|
| **Display Hero** | `38px` (2.375rem) | `800` (Extrabold) | `1.0` | `-1.2px` | Main cash balance |
| **Total Lg** | `32px` (2.0rem) | `800` | `1.1` | `-1.0px` | Section totals / Drawer balance |
| **Total Md** | `28px` (1.75rem) | `800` | `1.15` | `-0.8px` | Statement net balance |
| **Number Xl** | `24px` (1.5rem) | `800` | `1.2` | `-0.5px` | KPI card figures |
| **Number Lg** | `20px` (1.25rem) | `800` | `1.2` | `-0.3px` | Invoice totals, modal headers |
| **Number Md** | `18px` (1.125rem) | `800` | `1.25` | `-0.3px` | Table amount cells |
| **Screen Title** | `22px` (1.375rem) | `800` | `1.25` | `0` | Top header page titles |
| **Card Title** | `16px` (1.0rem) | `700` (Bold) | `1.3` | `0` | Widget and section headings |
| **Subtitle** | `14px` (0.875rem) | `700` | `1.35` | `0` | Secondary section headers |
| **Body Strong** | `13px` (0.8125rem) | `600` (Semibold) | `1.4` | `0` | Table row primary text, buttons |
| **Body** | `13px` (0.8125rem) | `400` (Regular) | `1.45` | `0` | General text, descriptions |
| **Label Strong**| `11px` (0.6875rem) | `700` | `1.3` | `0.2px` | Table headers, badges |
| **Label / Meta**| `12px` (0.75rem) | `600` | `1.3` | `0` | Form labels, secondary tags |
| **Caption** | `12px` (0.75rem) | `400` | `1.4` | `0` | Helper text, hints |
| **Caption Sm** | `11px` (0.6875rem) | `400` | `1.4` | `0` | Footnotes, timestamps |
| **Badge** | `10px` (0.625rem) | `700` | `1.0` | `0.5px` | Status tags (PAID, UNPAID) |

---

### 1.3 Spacing, Radii & Shadows

#### Spacing Scale (8pt Grid)
```css
--space-xs: 4px;
--space-sm: 8px;
--space-md: 12px;
--space-base: 16px;
--space-lg: 20px;
--space-xl: 24px;
--space-xxl: 32px;
--space-xxxl: 40px;
--space-huge: 48px;
```

#### Border Radii
```css
--radius-sm: 8px;       /* Tags, chips, inner controls */
--radius-md: 12px;      /* Buttons, form inputs */
--radius-lg: 16px;      /* Standard cards, data tables */
--radius-xl: 20px;      /* Modal dialogs, hero containers */
--radius-pill: 9999px;  /* Pill buttons, search inputs */
```

#### Elevation / Box Shadows
```css
--shadow-card: 0 1px 2px rgba(26, 59, 46, 0.02), 0 3px 10px rgba(26, 59, 46, 0.04);
--shadow-elevated: 0 8px 24px rgba(26, 59, 46, 0.08);
--shadow-modal: 0 20px 40px rgba(26, 59, 46, 0.15);
```

---

### 1.4 Ready-to-Use CSS Variables (`tokens.css`)

```css
:root {
  /* Color Palette */
  --galla-canvas: #F7F4EF;
  --galla-surface: #FFFFFF;
  --galla-surface-alt: #F3EEE6;
  --galla-surface-elevated: #FAF8F4;
  --galla-line: #EAE4DA;
  --galla-line-soft: #F0EBE2;
  
  --galla-ink: #181818;
  --galla-ink-secondary: #3D3D3D;
  --galla-muted: #787878;
  --galla-faint: #AEA696;

  --galla-brand: #1A3B2E;
  --galla-brand-mid: #2D5A40;
  --galla-brand-soft: #E6F0EA;

  --galla-money-in: #1B7A3E;
  --galla-money-in-soft: #EAF5ED;
  --galla-money-out: #C0392B;
  --galla-money-out-soft: #FDEBEA;
  --galla-udhaar: #B45309;
  --galla-udhaar-soft: #FEF3E2;

  --galla-gold: #B8962E;
  --galla-gold-soft: #FDF8EB;
  --galla-blue: #1D4ED8;
  --galla-blue-soft: #EFF4FF;

  /* Typography */
  --font-family-base: 'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

  /* Radii */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 20px;
  --radius-pill: 9999px;

  /* Shadows */
  --shadow-card: 0 1px 2px rgba(26, 59, 46, 0.02), 0 3px 10px rgba(26, 59, 46, 0.04);
  --shadow-elevated: 0 8px 24px rgba(26, 59, 46, 0.08);
  --shadow-modal: 0 20px 40px rgba(26, 59, 46, 0.15);
}

body {
  background-color: var(--galla-canvas);
  color: var(--galla-ink);
  font-family: var(--font-family-base);
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}
```

---

## 2. Web Layout Architecture & Grid

### 2.1 Viewport Breakpoints
- **Mobile (< 768px):** Mobile app layout or mobile web drawer.
- **Tablet (768px – 1023px):** Collapsed sidebar rail (icon-only, 72px width).
- **Desktop (1024px – 1439px):** Standard 240px expanded sidebar, 1-2 column layouts.
- **Large Desktop (≥ 1440px):** Full 260px sidebar, 3-4 column dashboard KPI grids, max content width of `1600px`.

### 2.2 Web App Shell Structure

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│  SIDEBAR (240px)   │  TOP NAV BAR (Height: 64px)                                       │
│                    │  [Search Bar ⌘K]   [Branch]   [+ Add Entry]   [Account Profile ▾] │
├────────────────────┼───────────────────────────────────────────────────────────────────┤
│  GALLA [Logo]      │  MAIN CONTENT CONTAINER (max-width: 1500px, padding: 24px)        │
│                    │                                                                   │
│  • Pulse (Home)    │  ┌─────────────────────────┐  ┌────────────────────────────────┐  │
│  • Khata (Ledger)  │  │ Cash Hero Balance Card  │  │ KPI Strip (Sales/Exp/Udhaar)   │  │
│  • Stock (Items)   │  └─────────────────────────┘  └────────────────────────────────┘  │
│  • Invoices        │                                                                   │
│  • Analytics       │  ┌─────────────────────────────────────────────────────────────┐  │
│  • Reports         │  │ Data Table / Ledger View / Split-Screen Editor              │  │
│                    │  │                                                             │  │
│  ────────────────  │  │                                                             │  │
│  ⚙ Settings        │  └─────────────────────────────────────────────────────────────┘  │
│  ⇄ Switch Account  │                                                                   │
│  ➜ Sign Out        │                                                                   │
└────────────────────┴───────────────────────────────────────────────────────────────────┘
```

---

## 3. Core Page Specifications & Web Adaptations

### 3.1 Pulse (Dashboard & Cash Book)
- **Top Summary Grid:**
  - **Cash-in-Hand Card:** Forest green gradient background with large display text (`38px`), showing real physical drawer cash with quick "Count Till / Reconcile" button.
  - **Sales Today:** Inflow total with green badge (`+18.4% vs yesterday`).
  - **Expenses Today:** Outflow total with red badge.
  - **To Collect (Udhaar):** Amber outstanding receivable sum with "View 8 debtors" link.
- **Charts Row:**
  - **Cash Pulse (Line Chart):** Inflow vs. Outflow vs. Net trend.
  - **Expense Category Distribution (Donut Chart):** Breakdown of top 5 categories.
- **Recent Activity Table:**
  - Columns: `Time`, `Type` (Sale/Expense/Udhaar), `Party Name`, `Category`, `Amount`, `Actions`.
  - Row click opens transaction detail drawer without leaving the page.

---

### 3.2 Khata (Customer & Supplier Ledger)
- **Desktop Split-Pane Layout:**
  - **Left Pane (350px):**
    - Search input + Filter tabs (`All`, `To Collect (Customers)`, `To Pay (Suppliers)`).
    - Contact list cards displaying running balance in Green (they owe you) or Red (you owe them).
  - **Right Pane (Expanded):**
    - Party Statement Header: Contact name, phone, WhatsApp reminder shortcut, net balance.
    - Two large primary action buttons:
      - **`+ Give Udhaar (Credit Sale)`** (Amber button)
      - **`+ Receive Payment (Cash In)`** (Forest green button)
    - Chronological statement table showing running balance after every entry.
    - PDF / Print statement button.

---

### 3.3 Stock (Inventory Lite)
- **No SKU Required:** Per merchant specification, product lookup is strictly by **Item Name**.
- **Data Table Layout:**
  - Columns: `Item Name`, `Current Stock`, `Unit`, `Cost Price`, `Sale Price`, `Total Valuation`, `Status`, `Actions`.
  - Low stock warning chips (`< 5 pcs remaining`).
- **Add / Edit Item Modal Requirements:**
  - **Item Name Input** (required).
  - **Unit Selection:** Dropdown with defaults:
    `pcs`, `kg`, `gm`, `ltr`, `ml`, `packet`, `box`, `bottle`, `dozen`, `bag`, `can`, `meter`, plus `Custom...`.
    - When `Custom...` is selected, an inline text box appears allowing manual entry (e.g., `bundle`, `tin`, `roll`).
  - **Quantity & Alert Level** inputs.
  - **Cost Price & Sale Price** inputs.

---

### 3.4 Invoicing & Billing
- **Split-Screen Invoicing Studio:**
  - **Left 50% (Editor Form):**
    - Invoice Number (auto-incremented), Date, Customer selector.
    - Dynamic line-item rows: Item dropdown (auto-fills unit price from inventory), Quantity, Subtotal.
    - Tax rate toggle (% VAT/GST).
  - **Right 50% (Live Thermal / A4 Preview):**
    - Real-time SVG/HTML invoice preview as items are typed.
    - Direct Print button (`Ctrl + P`) compatible with standard 80mm POS thermal receipt printers and A4 sheets.

---

### 3.5 Reports & Analytics
- **Date-Range Controls:** Quick chips (`Today`, `7 Days`, `30 Days`, `This Month`, `Custom Range`).
- **P&L Summary Table:**
  - Revenue, Cost of Goods, Gross Profit, Operating Expenses, Net Cash.
- **Export Toolbar:**
  - **Download CSV** (Excel ready).
  - **Export PDF** (Devanagari font capable).

---

### 3.6 Settings & Account Session
- **Business Profile:** Store name, currency (`NPR`, `INR`, `USD`), tax defaults.
- **Account & Session Card:**
  - Active login email or demo mode status.
  - **Switch Account** button: returns to sign-in modal/page.
  - **Sign Out** button: terminates Supabase session, clears cache, redirects to `/login`.

---

## 4. Desktop Productivity & Keyboard Shortcuts

Web users expect fast keyboard workflows:

| Shortcut | Action | Scope |
|---|---|---|
| **`N`** or **`Ctrl + N`** | Open "Quick Add Entry" modal | Global |
| **`Ctrl + K`** or **`/`** | Focus global search | Global |
| **`Esc`** | Close current modal, drawer, or clear search | Global |
| **`Ctrl + P`** | Print current invoice or ledger statement | Invoices / Khata |
| **`Enter`** (in numeric fields) | Submit entry and open next row | Quick Entry |

---

## 5. Supabase Web Integration Contract

The web application connects to the exact same backend configured for mobile:

- **Project URL:** `https://ydnplzkvbsvaxoixxqqv.supabase.co`
- **Client Library:** `@supabase/supabase-js` (or `supabase_flutter` if using Flutter Web).

### 5.1 Environment Variables
```env
NEXT_PUBLIC_SUPABASE_URL=https://ydnplzkvbsvaxoixxqqv.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlkbnBsemt2YnN2YXhvaXh4cXF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1NzM5ODcsImV4cCI6MjEwNDE0OTk4N30.yhhN64squfl5-VAC-bJqUglB6M74os3205fatKCA0YU
```

### 5.2 Common Database Queries (PostgreSQL)

```typescript
// 1. Fetch Today's Transactions
const { data: todayTxns } = await supabase
  .from('transactions')
  .select('*')
  .gte('occurred_at', new Date().toISOString().split('T')[0])
  .order('occurred_at', { ascending: false });

// 2. Fetch Parties with Running Balances
const { data: parties } = await supabase
  .from('parties')
  .select('*')
  .order('name', { ascending: true });

// 3. Realtime Subscription (Syncs when Mobile records an entry)
supabase
  .channel('web_live_sync')
  .on('postgres_changes', { event: '*', schema: 'public', table: 'transactions' }, (payload) => {
    refreshLedger();
  })
  .subscribe();
```
