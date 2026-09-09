# TASK: Integrate Galla-Web with Supabase Backend & Mobile Sync Contract

We need to update our Next.js web application (`Galla-Web`) so it perfectly synchronizes in real time with the Galla mobile (Flutter) app via our shared Supabase backend (`https://ydnplzkvbsvaxoixxqqv.supabase.co`).

---

### 1. Database Schema & RLS Contract Rules

1. **`businesses` Table Primary Key:**
   - In Supabase, the table primary key is `id UUID PRIMARY KEY REFERENCES auth.users(id)`.
   - **Never query `.eq('user_id', user.id)`**. Always query `.eq('id', user.id)`.

2. **Mandatory `business_id` Foreign Key:**
   - Every insert/upsert across `transactions`, `parties`, `inventory_items`, and `invoices` MUST include `business_id: user.id`.
   - Failing to provide `business_id` causes Supabase Row Level Security (RLS) check `WITH CHECK (business_id = auth.uid())` to fail.

3. **Client-side UUIDs:**
   - Always generate a UUID on the client using `crypto.randomUUID()` when inserting new records so mobile and web can idempotently upsert.

4. **Amounts in Minor Units (Paisa / Cents):**
   - All amounts are stored as integers in `amount_minor`, `balance_minor`, `cost_price_minor`, etc.
   - 1 Rupee = 100 Paisa. Always convert user-entered amounts using `Math.round(amount * 100)`. Never write floats to `*_minor` columns.

5. **Postgres Enum `txn_direction`:**
   - Allowed values are strictly `'money_in'` and `'money_out'`. Never send `'in'` or `'out'`.

6. **Soft Deletions:**
   - Mobile uses an append-only SQLite database. Never call `.delete()` on synced tables.
   - Mark deletions with `deleted_at: new Date().toISOString()`.

---

### 2. Required Changes in `lib/queries.ts`

Update or replace the relevant methods in `lib/queries.ts`:

```typescript
import { createClient } from '@/lib/supabase/client';

// 1. Fetch Business Profile
export async function getBusiness(userId: string) {
  if (isDemoMode()) return getDemoStore().business;

  const supabase = createClient();
  const { data, error } = await supabase
    .from('businesses')
    .select('*')
    .eq('id', userId) // MUST be 'id', NOT 'user_id'
    .maybeSingle();

  if (error) {
    console.error('getBusiness error:', error);
    return getDemoStore().business;
  }
  return data;
}

// 2. Add / Record Transaction
export async function addTransaction(
  userId: string,
  txn: {
    direction: 'money_in' | 'money_out';
    amountMinor: number;
    partyId?: string | null;
    inventoryItemId?: string | null;
    invoiceId?: string | null;
    category?: string | null;
    note?: string | null;
    isCredit?: boolean;
    occurredAt?: string;
  }
) {
  if (isDemoMode()) {
    return addDemoTransaction(txn);
  }

  const supabase = createClient();
  const now = new Date().toISOString();
  const id = crypto.randomUUID();

  const { data, error } = await supabase
    .from('transactions')
    .insert({
      id,
      business_id: userId,
      direction: txn.direction,
      amount_minor: txn.amountMinor,
      party_id: txn.partyId || null,
      inventory_item_id: txn.inventoryItemId || null,
      invoice_id: txn.invoiceId || null,
      category: txn.category || null,
      note: txn.note || null,
      is_credit: txn.isCredit ?? false,
      is_adjustment: false,
      is_write_off: false,
      occurred_at: txn.occurredAt || now,
      created_at: now,
      updated_at: now,
      deleted_at: null,
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

// 3. Khata Credit/Debit Transaction & Balance Synchronization
export async function addKhataTransaction(
  userId: string,
  params: {
    partyId: string;
    direction: 'money_in' | 'money_out';
    amountMinor: number;
    isCredit: boolean;
    note?: string;
  }
) {
  if (isDemoMode()) {
    return addDemoKhataTransaction(params);
  }

  const supabase = createClient();

  // 1. Record the ledger transaction
  await addTransaction(userId, {
    direction: params.direction,
    amountMinor: params.amountMinor,
    partyId: params.partyId,
    isCredit: params.isCredit,
    note: params.note,
  });

  // 2. Compute Party balance delta matching Mobile logic:
  //    - Credit sale to customer (money_in, isCredit=true): debtor owes you (+amount)
  //    - Customer cash repayment (money_in, isCredit=false): reduces receivable (-amount)
  //    - Credit purchase from supplier (money_out, isCredit=true): you owe supplier (-amount)
  //    - Supplier payment made (money_out, isCredit=false): reduces payable (+amount)
  let delta = 0;
  if (params.isCredit) {
    delta = params.direction === 'money_in' ? params.amountMinor : -params.amountMinor;
  } else {
    delta = params.direction === 'money_in' ? -params.amountMinor : params.amountMinor;
  }

  // 3. Fetch current party balance and apply delta
  const { data: party, error: partyErr } = await supabase
    .from('parties')
    .select('balance_minor')
    .eq('id', params.partyId)
    .single();

  if (!partyErr && party) {
    const newBalance = (party.balance_minor || 0) + delta;
    await supabase
      .from('parties')
      .update({
        balance_minor: newBalance,
        updated_at: new Date().toISOString(),
      })
      .eq('id', params.partyId);
  }
}

// 4. Soft Delete for any record
export async function softDeleteRecord(
  table: 'transactions' | 'parties' | 'inventory_items' | 'invoices',
  id: string
) {
  if (isDemoMode()) return;

  const supabase = createClient();
  const { error } = await supabase
    .from(table)
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id);

  if (error) throw error;
}
```

---

### 3. Add Realtime Two-Way Live Sync

Create `components/realtime-sync.tsx` to subscribe to Postgres changes and revalidate Next.js pages when the mobile app creates or edits records:

```typescript
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { createBrowserClient } from '@supabase/ssr';

export function RealtimeSync({ userId }: { userId: string | null | undefined }) {
  const router = useRouter();

  useEffect(() => {
    if (!userId) return;

    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    );

    const channel = supabase
      .channel(`galla_web_live_sync_${userId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'transactions',
          filter: `business_id=eq.${userId}`,
        },
        () => router.refresh()
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'parties',
          filter: `business_id=eq.${userId}`,
        },
        () => router.refresh()
      )
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'inventory_items',
          filter: `business_id=eq.${userId}`,
        },
        () => router.refresh()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId, router]);

  return null;
}
```

Mount `<RealtimeSync userId={user?.id} />` in your root dashboard layout (`app/(dashboard)/layout.tsx` or `app/layout.tsx`).

---

### 4. Verification Checklist

1. Run `npm run lint` and `npm run build` to verify there are no TypeScript or query errors.
2. Sign in on web with the same Supabase account as the mobile app.
3. Record a transaction on mobile → verify the web dashboard updates in real time without refreshing.
4. Add a contact or transaction on web → verify it shows up on mobile on the next sync cycle.
