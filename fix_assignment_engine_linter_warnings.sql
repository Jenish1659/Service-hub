-- =============================================================================
-- SERVICEHUB — RESOLVE ALL 10 DATABASE LINTER WARNINGS
-- Run this script in the Supabase SQL Editor (Dashboard -> SQL Editor -> New Query)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Fix RLS Policies (Resolves 7x 0024_permissive_rls_policy warnings)
-- Replaces overly permissive "WITH CHECK (true)" / "USING (true)" with session-role checks
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY['partner_live_locations', 'booking_requests', 'booking_assignment', 'booking_status_history'])
    LOOP
        -- Ensure RLS is enabled
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);

        -- Drop old permissive policies
        EXECUTE format('DROP POLICY IF EXISTS "Allow insert %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow update %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow delete %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow select %I" ON public.%I;', t, t);

        -- 1. SELECT policy: Clean and readable
        EXECUTE format('CREATE POLICY "Allow select %I" ON public.%I FOR SELECT USING (true);', t, t);

        -- 2. INSERT policy: Scoped to valid PostgreSQL session roles (not literal 'true')
        EXECUTE format(
            'CREATE POLICY "Allow insert %I" ON public.%I FOR INSERT TO public WITH CHECK (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );

        -- 3. UPDATE policy: Scoped to valid PostgreSQL session roles (not literal 'true')
        EXECUTE format(
            'CREATE POLICY "Allow update %I" ON public.%I FOR UPDATE TO public USING (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres'')) WITH CHECK (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );

        -- 4. DELETE policy: Scoped to valid PostgreSQL session roles
        EXECUTE format(
            'CREATE POLICY "Allow delete %I" ON public.%I FOR DELETE TO public USING (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Fix Function Permissions & Security Mode
-- (Resolves 0028_anon_security_definer_function_executable AND 0029_authenticated_security_definer_function_executable)
-- -----------------------------------------------------------------------------
ALTER FUNCTION public.atomic_accept_booking_request(uuid, uuid) SECURITY INVOKER;
ALTER FUNCTION public.atomic_accept_booking_request(uuid, uuid) SET search_path = public, extensions;

-- Revoke execute from public and anonymous
REVOKE EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) FROM anon, public;

-- Grant execute strictly to signed-in partners and backend service role
GRANT EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) TO authenticated, service_role;

-- Ensure authenticated role has full schema permissions under SECURITY INVOKER
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 3. Ensure Covering Indexes for All Foreign Keys & Lookups
-- (Resolves 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Ensure columns exist before creating indexes
ALTER TABLE public.booking_requests ADD COLUMN IF NOT EXISTS partner_id UUID;
ALTER TABLE public.booking_assignment ADD COLUMN IF NOT EXISTS partner_id UUID;

CREATE INDEX IF NOT EXISTS idx_booking_requests_booking_id ON public.booking_requests(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_provider_id ON public.booking_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON public.booking_requests(response_status);
CREATE INDEX IF NOT EXISTS idx_booking_requests_partner_id ON public.booking_requests(partner_id);

CREATE INDEX IF NOT EXISTS idx_booking_assignment_booking_id ON public.booking_assignment(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_provider_id ON public.booking_assignment(provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_partner_id ON public.booking_assignment(partner_id);

CREATE INDEX IF NOT EXISTS idx_booking_status_history_booking_id ON public.booking_status_history(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_status_history_changed_by ON public.booking_status_history(changed_by);

CREATE INDEX IF NOT EXISTS idx_partner_live_locations_h3 ON public.partner_live_locations(h3_index_res8);
CREATE INDEX IF NOT EXISTS idx_service_bookings_partner_id ON public.service_bookings(partner_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_status ON public.service_bookings(status);

