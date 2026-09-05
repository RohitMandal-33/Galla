-- ==============================================================================
-- GALLA SUPABASE / POSTGRESQL SCHEMA (IDEMPOTENT MIGRATION)
-- Project URL: https://ydnplzkvbsvaxoixxqqv.supabase.co
-- Compatible with Flutter Mobile & Web frontends
-- Safe to re-run multiple times without errors (ERROR 42710 prevention)
-- ==============================================================================

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Businesses / Stores Table
-- id matches auth.users.id 1-to-1 so each signed up account owns their business
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL DEFAULT 'My Store',
    currency TEXT NOT NULL DEFAULT 'NPR',
    tax_rate_pct NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Parties (Customer & Supplier Khata)
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
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Inventory Items
CREATE TABLE IF NOT EXISTS public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
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

-- 5. Transactions (Daily Galla Cash & Credit Ledger)
-- Idempotent Enum: txn_direction
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

-- Ensure enum values exist if type was created previously
ALTER TYPE public.txn_direction ADD VALUE IF NOT EXISTS 'money_in';
ALTER TYPE public.txn_direction ADD VALUE IF NOT EXISTS 'money_out';

CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    party_id UUID REFERENCES public.parties(id) ON DELETE SET NULL,
    inventory_item_id UUID REFERENCES public.inventory_items(id) ON DELETE SET NULL,
    direction public.txn_direction NOT NULL,
    amount_minor BIGINT NOT NULL,
    category TEXT,
    note TEXT,
    is_credit BOOLEAN NOT NULL DEFAULT FALSE,
    is_adjustment BOOLEAN NOT NULL DEFAULT FALSE,
    is_write_off BOOLEAN NOT NULL DEFAULT FALSE,
    photo_url TEXT,
    invoice_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- 6. Invoices & Invoice Items
-- Idempotent Enum: invoice_status
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

-- Ensure enum values exist if type was created previously
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'unpaid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'partially_paid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'paid';
ALTER TYPE public.invoice_status ADD VALUE IF NOT EXISTS 'cancelled';

CREATE TABLE IF NOT EXISTS public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    party_id UUID REFERENCES public.parties(id) ON DELETE SET NULL,
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

-- 7. Cash Reconciliations
CREATE TABLE IF NOT EXISTS public.reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    occurred_at TIMESTAMPTZ NOT NULL,
    counted_cash_minor BIGINT NOT NULL,
    expected_cash_minor BIGINT NOT NULL,
    discrepancy_minor BIGINT NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- AUTOMATIC ONBOARDING TRIGGER (auth.users -> public.businesses)
-- When a user signs up on mobile or web, their business profile is created
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.businesses (id, email, name)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'business_name', 'My Business')
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
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Ensures each account can ONLY read and write their own business data
-- ==============================================================================
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reconciliations ENABLE ROW LEVEL SECURITY;

-- Businesses
DROP POLICY IF EXISTS "Users can manage their own business" ON public.businesses;
CREATE POLICY "Users can manage their own business"
    ON public.businesses FOR ALL
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Parties
DROP POLICY IF EXISTS "Users can manage their own parties" ON public.parties;
CREATE POLICY "Users can manage their own parties"
    ON public.parties FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- Inventory Items
DROP POLICY IF EXISTS "Users can manage their own inventory" ON public.inventory_items;
CREATE POLICY "Users can manage their own inventory"
    ON public.inventory_items FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- Transactions
DROP POLICY IF EXISTS "Users can manage their own transactions" ON public.transactions;
CREATE POLICY "Users can manage their own transactions"
    ON public.transactions FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- Invoices
DROP POLICY IF EXISTS "Users can manage their own invoices" ON public.invoices;
CREATE POLICY "Users can manage their own invoices"
    ON public.invoices FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- Invoice Items
DROP POLICY IF EXISTS "Users can manage their own invoice items" ON public.invoice_items;
CREATE POLICY "Users can manage their own invoice items"
    ON public.invoice_items FOR ALL
    USING (
        invoice_id IN (SELECT id FROM public.invoices WHERE business_id = auth.uid())
    )
    WITH CHECK (
        invoice_id IN (SELECT id FROM public.invoices WHERE business_id = auth.uid())
    );

-- Reconciliations
DROP POLICY IF EXISTS "Users can manage their own reconciliations" ON public.reconciliations;
CREATE POLICY "Users can manage their own reconciliations"
    ON public.reconciliations FOR ALL
    USING (business_id = auth.uid())
    WITH CHECK (business_id = auth.uid());

-- ==============================================================================
-- REALTIME SUBSCRIPTIONS
-- Idempotent check before adding tables to publication
-- ==============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'transactions'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'parties'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.parties;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'inventory_items'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.inventory_items;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'invoices'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.invoices;
    END IF;
END $$;
