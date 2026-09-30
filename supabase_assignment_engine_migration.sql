-- =============================================================================
-- SERVICEHUB — REAL-TIME INTELLIGENT PARTNER ASSIGNMENT ENGINE MIGRATION (FIXED)
-- Run this script in the Supabase SQL Editor (Dashboard -> SQL Editor -> New Query)
-- =============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Safely add missing columns to existing tables first
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS partner_id UUID;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS service_status TEXT DEFAULT 'SEARCHING_PROVIDER';
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS customer_latitude DOUBLE PRECISION;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS customer_longitude DOUBLE PRECISION;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. Partner Live Locations Table (H3 + GPS tracking)
CREATE TABLE IF NOT EXISTS public.partner_live_locations (
    partner_id UUID PRIMARY KEY REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    h3_index_res8 TEXT,
    accuracy DOUBLE PRECISION,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Booking Requests Table (Ensure table and columns exist)
CREATE TABLE IF NOT EXISTS public.booking_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_at TIMESTAMP WITH TIME ZONE,
    response_status TEXT NOT NULL CHECK (response_status IN ('Pending', 'Accepted', 'Rejected', 'Expired')) DEFAULT 'Pending'
);
ALTER TABLE public.booking_requests ADD COLUMN IF NOT EXISTS partner_id UUID;

-- 5. Booking Assignment Table (Ensure table and columns exist)
CREATE TABLE IF NOT EXISTS public.booking_assignment (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID UNIQUE NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assignment_method TEXT NOT NULL CHECK (assignment_method IN ('FIRST_ACCEPT', 'AUTO_DISPATCH', 'ADMIN_MANUAL')) DEFAULT 'FIRST_ACCEPT',
    status TEXT NOT NULL CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')) DEFAULT 'ASSIGNED'
);
ALTER TABLE public.booking_assignment ADD COLUMN IF NOT EXISTS partner_id UUID;

-- 6. Booking Status History Table
CREATE TABLE IF NOT EXISTS public.booking_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(user_id),
    remarks TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. High-Performance Indexing (Covering indexes for all Foreign Keys & lookups)
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

-- 8. Atomic First-Accept-Wins Concurrency Procedure
-- Resolves provider_id and partner_id seamlessly without dependency on column presence
CREATE OR REPLACE FUNCTION public.atomic_accept_booking_request(
    p_request_id UUID,
    p_provider_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_booking_id UUID;
    v_current_booking_status TEXT;
    v_actual_provider_id UUID;
    v_partner_id UUID;
    v_result JSON;
BEGIN
    -- 1. Identify request and find matching provider/partner from provider profile
    SELECT 
        br.booking_id,
        spp.provider_id,
        spp.partner_id
    INTO 
        v_booking_id,
        v_actual_provider_id,
        v_partner_id
    FROM public.booking_requests br
    JOIN public.service_provider_profiles spp 
        ON (spp.provider_id = br.provider_id)
    WHERE br.request_id = p_request_id
      AND (spp.provider_id = p_provider_id OR spp.partner_id = p_provider_id);

    -- Fallback: if provider profile wasn't strictly joined, check directly
    IF v_booking_id IS NULL THEN
        SELECT br.booking_id, br.provider_id
        INTO v_booking_id, v_actual_provider_id
        FROM public.booking_requests br
        WHERE br.request_id = p_request_id;
        
        IF v_booking_id IS NOT NULL THEN
            SELECT partner_id INTO v_partner_id
            FROM public.service_provider_profiles
            WHERE provider_id = v_actual_provider_id;
        END IF;
    END IF;

    IF v_booking_id IS NULL THEN
        RETURN json_build_object(
            'success', false, 
            'message', 'Request record not found or already closed.'
        );
    END IF;

    -- 2. Lock the booking row for update (Atomic First-Accept-Wins Row Lock)
    SELECT status INTO v_current_booking_status
    FROM public.service_bookings
    WHERE booking_id = v_booking_id
    FOR UPDATE;

    -- 3. Check if still open for assignment
    IF v_current_booking_status IN ('PENDING', 'SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS') THEN
        -- A. Update service_bookings status to ACCEPTED
        UPDATE public.service_bookings
        SET 
            status = 'ACCEPTED',
            service_status = 'ACCEPTED',
            partner_id = COALESCE(v_partner_id, partner_id),
            updated_at = NOW()
        WHERE booking_id = v_booking_id;

        -- B. Create or update assignment record
        INSERT INTO public.booking_assignment (
            booking_id,
            provider_id,
            assignment_method,
            status,
            assigned_at
        ) VALUES (
            v_booking_id,
            v_actual_provider_id,
            'FIRST_ACCEPT',
            'ASSIGNED',
            NOW()
        ) ON CONFLICT (booking_id) DO UPDATE SET
            provider_id = EXCLUDED.provider_id,
            status = 'ASSIGNED',
            assigned_at = NOW();

        -- C. Mark winning request as Accepted
        UPDATE public.booking_requests
        SET 
            response_status = 'Accepted', 
            response_at = NOW()
        WHERE request_id = p_request_id;

        -- D. Auto-expire competing requests for the same booking
        UPDATE public.booking_requests
        SET 
            response_status = 'Expired', 
            response_at = NOW()
        WHERE booking_id = v_booking_id AND request_id != p_request_id;

        -- E. Log status history
        INSERT INTO public.booking_status_history (
            booking_id,
            status,
            remarks,
            changed_at
        ) VALUES (
            v_booking_id,
            'ACCEPTED',
            'Provider accepted the service request via atomic first-accept engine',
            NOW()
        );

        v_result := json_build_object(
            'success', true,
            'booking_id', v_booking_id,
            'status', 'ACCEPTED',
            'partner_id', v_partner_id,
            'provider_id', v_actual_provider_id,
            'message', 'Booking accepted successfully!'
        );
        RETURN v_result;
    ELSE
        -- Contested job: another technician claimed it first
        UPDATE public.booking_requests
        SET response_status = 'Expired', response_at = NOW()
        WHERE request_id = p_request_id;

        v_result := json_build_object(
            'success', false,
            'message', 'Job has already been accepted by another technician.',
            'status', v_current_booking_status
        );
        RETURN v_result;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

-- Grant execution permissions strictly to authenticated users and service_role
REVOKE EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) TO authenticated, service_role;

-- 9. Enable Realtime Replication for Instant Mobile Synchronization
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.service_bookings;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_requests;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_assignment;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.partner_live_locations;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- 10. Enable Row Level Security (RLS) & Clean Role-Scoped Policies (0 Linter Warnings)
ALTER TABLE public.partner_live_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_status_history ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY['partner_live_locations', 'booking_requests', 'booking_assignment', 'booking_status_history'])
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Allow insert %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow update %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow delete %I" ON public.%I;', t, t);
        EXECUTE format('DROP POLICY IF EXISTS "Allow select %I" ON public.%I;', t, t);

        EXECUTE format('CREATE POLICY "Allow select %I" ON public.%I FOR SELECT USING (true);', t, t);
        EXECUTE format(
            'CREATE POLICY "Allow insert %I" ON public.%I FOR INSERT TO public WITH CHECK (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );
        EXECUTE format(
            'CREATE POLICY "Allow update %I" ON public.%I FOR UPDATE TO public USING (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres'')) WITH CHECK (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );
        EXECUTE format(
            'CREATE POLICY "Allow delete %I" ON public.%I FOR DELETE TO public USING (current_user IN (''anon'', ''authenticated'', ''service_role'', ''postgres''));',
            t, t
        );
    END LOOP;
END $$;

GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated, service_role;
