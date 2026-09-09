-- ==============================================================================
-- GALLA SHARED DATABASE CONTRACT (MOBILE + WEB)
-- Project URL: https://ydnplzkvbsvaxoixxqqv.supabase.co
--
-- Both Flutter and the web app MUST:
--   1. Sign in with the same Supabase Auth account
--   2. Set business_id = auth.uid() on every row (businesses.id = auth.uid())
--   3. Generate UUIDs on the client, then upsert on id
--   4. Store money as *_minor integers (paisa / cents), never floats
--   5. Use UTC ISO-8601 timestamps and last-write-wins on updated_at
--   6. Soft-delete with deleted_at (do not hard-delete synced rows)
-- Device-only: app-lock PIN, demo flag, lastDirection. Do not sync those.
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Businesses / Stores (id matches auth.users.id)
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL DEFAULT 'My Store',
    currency TEXT NOT NULL DEFAULT 'NPR',
    tax_rate_pct NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    locale TEXT NOT NULL DEFAULT 'en',
    low_cash_threshold_minor BIGINT NOT NULL DEFAULT 0,
    notify_payment_due BOOLEAN NOT NULL DEFAULT TRUE,
    notify_low_cash BOOLEAN NOT NULL DEFAULT TRUE,
    notify_low_stock BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Parties (Customer & Supplier Khata)
CREATE TABLE IF NOT EXISTS public.parties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    balance_minor BIGINT NOT NULL DEFAULT 0,
    remind_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    remind_every_days INT NOT NULL DEFAULT 14,
    last_reminded_at TIMESTAMPTZ,
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 3. Branches
CREATE TABLE IF NOT EXISTS public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 4. Staff (PIN hashes stay on-device; not stored here)
CREATE TABLE IF NOT EXISTS public.staff_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'staff',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 5. Inventory Items
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID,
    name TEXT NOT NULL,
    sku TEXT,
    unit TEXT NOT NULL DEFAULT 'pcs',
    current_quantity NUMERIC(12, 3) NOT NULL DEFAULT 0.000,
    low_stock_threshold NUMERIC(12, 3) NOT NULL DEFAULT 5.000,
    cost_price_minor BIGINT NOT NULL DEFAULT 0,
    sale_price_minor BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 6. Transactions (Daily Galla Cash & Credit Ledger)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'txn_direction' AND n.nspname = 'public'
    ) THEN
        CREATE TYPE public.txn_direction AS ENUM ('money_in', 'money_out');
    END IF;
END $$;

ALTER TYPE public.txn_direction ADD VALUE IF NOT EXISTS 'money_in';
ALTER TYPE public.txn_direction ADD VALUE IF NOT EXISTS 'money_out';

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    party_id UUID REFERENCES public.parties(id) ON DELETE SET NULL,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE SET NULL,
    invoice_id UUID,
    branch_id UUID,
    staff_id UUID,
    staff_name TEXT,
    direction public.txn_direction NOT NULL,
    amount_minor BIGINT NOT NULL,
    category TEXT,
    note TEXT,
    is_credit BOOLEAN NOT NULL DEFAULT FALSE,
    is_adjustment BOOLEAN NOT NULL DEFAULT FALSE,
    is_write_off BOOLEAN NOT NULL DEFAULT FALSE,
    photo_url TEXT,
    nl_raw TEXT,
    ai_inferred BOOLEAN NOT NULL DEFAULT FALSE,
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 7. Invoices & Invoice Items
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'invoice_status' AND n.nspname = 'public'
    ) THEN
        CREATE TYPE public.invoice_status AS ENUM ('unpaid', 'partially_paid', 'paid', 'cancelled');
    END IF;
END $$;

ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'unpaid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'partially_paid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'paid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'cancelled';

CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    party_id UUID REFERENCES public.parties(id) ON DELETE SET NULL,
    party_name TEXT,
    invoice_number TEXT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE,
    subtotal_minor BIGINT NOT NULL,
    tax_rate_pct NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    tax_minor BIGINT NOT NULL DEFAULT 0,
    total_minor BIGINT NOT NULL,
    paid_amount_minor BIGINT NOT NULL DEFAULT 0,
    status public.invoice_status NOT NULL DEFAULT 'unpaid',
    notes TEXT,
    branch_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1.00,
    unit_price_minor BIGINT NOT NULL,
    total_minor BIGINT NOT NULL
);

-- 8. Cash Reconciliations
CREATE TABLE IF NOT EXISTS public.reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    occurred_at TIMESTAMPTZ NOT NULL,
    counted_cash_minor BIGINT NOT NULL,
    bank_balance_minor BIGINT,
    expected_cash_minor BIGINT NOT NULL,
    discrepancy_minor BIGINT NOT NULL,
    note TEXT,
    adjustment_txn_id UUID,
    branch_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- IDEMPOTENT COLUMN ADDS (existing projects created from an older schema)
-- ==============================================================================
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'en';
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS low_cash_threshold_minor BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS notify_payment_due BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS notify_low_cash BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS notify_low_stock BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.parties ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

ALTER TABLE public.inventory_items ADD COLUMN IF NOT EXISTS branch_id UUID;

ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS invoice_id UUID;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS branch_id UUID;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS staff_id UUID;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS staff_name TEXT;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS nl_raw TEXT;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS ai_inferred BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS party_name TEXT;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS branch_id UUID;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.reconciliations ADD COLUMN IF NOT EXISTS bank_balance_minor BIGINT;
ALTER TABLE public.reconciliations ADD COLUMN IF NOT EXISTS adjustment_txn_id UUID;
ALTER TABLE public.reconciliations ADD COLUMN IF NOT EXISTS branch_id UUID;
ALTER TABLE public.reconciliations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ==============================================================================
-- AUTOMATIC ONBOARDING TRIGGER (auth.users -> public.businesses)
-- Copies signup metadata business_name when present.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.businesses (id, email, name)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'business_name', ''), 'My Business')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- ROW LEVEL SECURITY
-- ==============================================================================
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reconciliations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own business" ON public.businesses;
CREATE POLICY "Users can manage their own business"
    ON public.businesses FOR ALL
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own parties" ON public.parties;
CREATE POLICY "Users can manage their own parties"
    ON public.parties FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own branches" ON public.branches;
CREATE POLICY "Users can manage their own branches"
    ON public.branches FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own staff" ON public.staff_members;
CREATE POLICY "Users can manage their own staff"
    ON public.staff_members FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own inventory" ON public.inventory_items;
CREATE POLICY "Users can manage their own inventory"
    ON public.inventory_items FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own transactions" ON public.transactions;
CREATE POLICY "Users can manage their own transactions"
    ON public.transactions FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own invoices" ON public.invoices;
CREATE POLICY "Users can manage their own invoices"
    ON public.invoices FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

DROP POLICY IF EXISTS "Users can manage their own invoice items" ON public.invoice_items;
CREATE POLICY "Users can manage their own invoice items"
    ON public.invoice_items FOR ALL
    USING (
        invoice_id IN (SELECT id FROM public.invoices WHERE business_id = auth.uid())
    )
    WITH CHECK (
        invoice_id IN (SELECT id FROM public.invoices WHERE business_id = auth.uid())
    );

DROP POLICY IF EXISTS "Users can manage their own reconciliations" ON public.reconciliations;
CREATE POLICY "Users can manage their own reconciliations"
    ON public.reconciliations FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- ==============================================================================
-- REALTIME
-- ==============================================================================
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'businesses',
        'parties',
        'branches',
        'staff_members',
        'inventory_items',
        'transactions',
        'invoices',
        'invoice_items',
        'reconciliations'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
              AND schemaname = 'public'
              AND tablename = t
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
        END IF;
    END LOOP;
END $$;
