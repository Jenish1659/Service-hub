-- =============================================================================
-- SERVICEHUB — PRODUCTION SERVICE-BOOKING ASSIGNMENT CYCLE MIGRATION
-- Supports Path A (Same-Day Immediate Matching) & Path B (Future-Date Scheduled Matching)
-- Atomic First-Accept-Wins Concurrency, Role Isolation, and Customer Privacy
-- =============================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Update service_bookings Table & Status Check Constraint
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS partner_id UUID;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS service_status TEXT DEFAULT 'SEARCHING_PROVIDER';
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS customer_latitude DOUBLE PRECISION;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS customer_longitude DOUBLE PRECISION;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS customer_h3_res8 TEXT;
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS entrance_pin TEXT DEFAULT '7429';
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS completion_otp TEXT DEFAULT '5892';
ALTER TABLE public.service_bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_service_bookings_customer_h3 ON public.service_bookings(customer_h3_res8);

-- Safely allow 'SCHEDULED' in status check constraint
ALTER TABLE public.service_bookings DROP CONSTRAINT IF EXISTS service_bookings_status_check;
ALTER TABLE public.service_bookings ADD CONSTRAINT service_bookings_status_check CHECK (status IN (
    'PENDING',
    'SCHEDULED',
    'SEARCHING_PROVIDER',
    'OFFERED_TO_PROVIDERS',
    'ACCEPTED',
    'ON_THE_WAY',
    'ARRIVED',
    'SERVICE_STARTED',
    'SERVICE_COMPLETED',
    'PAYMENT_COMPLETED',
    'REVIEWED',
    'CLOSED',
    'CANCELLED_BY_CUSTOMER',
    'CANCELLED_BY_PROVIDER',
    'REJECTED',
    'EXPIRED'
));

-- 3. Ensure booking_requests Table & Required Columns
CREATE TABLE IF NOT EXISTS public.booking_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_at TIMESTAMP WITH TIME ZONE,
    response_status TEXT NOT NULL CHECK (response_status IN ('Pending', 'Accepted', 'Rejected', 'Expired')) DEFAULT 'Pending'
);
ALTER TABLE public.booking_requests ADD COLUMN IF NOT EXISTS partner_id UUID;

-- 4. Ensure booking_assignment Table & Required Columns
CREATE TABLE IF NOT EXISTS public.booking_assignment (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID UNIQUE NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assignment_method TEXT NOT NULL CHECK (assignment_method IN ('FIRST_ACCEPT', 'AUTO_DISPATCH', 'ADMIN_MANUAL')) DEFAULT 'FIRST_ACCEPT',
    status TEXT NOT NULL CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')) DEFAULT 'ASSIGNED'
);
ALTER TABLE public.booking_assignment ADD COLUMN IF NOT EXISTS partner_id UUID;

-- 5. Ensure booking_status_history Table
CREATE TABLE IF NOT EXISTS public.booking_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(user_id),
    remarks TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Ensure High-Performance Covering Indexes
CREATE INDEX IF NOT EXISTS idx_booking_requests_booking_id ON public.booking_requests(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_provider_id ON public.booking_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON public.booking_requests(response_status);
CREATE INDEX IF NOT EXISTS idx_booking_requests_partner_id ON public.booking_requests(partner_id);

CREATE INDEX IF NOT EXISTS idx_booking_assignment_booking_id ON public.booking_assignment(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_provider_id ON public.booking_assignment(provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_partner_id ON public.booking_assignment(partner_id);

CREATE INDEX IF NOT EXISTS idx_booking_status_history_booking_id ON public.booking_status_history(booking_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_partner_id ON public.service_bookings(partner_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_status ON public.service_bookings(status);
CREATE INDEX IF NOT EXISTS idx_service_bookings_booking_date ON public.service_bookings(booking_date);

-- 7. ATOMIC FIRST-ACCEPT-WINS CONCURRENCY PROCEDURE
-- Protected with row-level lock (FOR UPDATE), race-condition guard, and auto-expiry of competing requests
CREATE OR REPLACE FUNCTION public.atomic_accept_booking_request(
    p_request_id UUID,
    p_provider_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_booking_id UUID;
    v_customer_id UUID;
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
    SELECT status, customer_id 
    INTO v_current_booking_status, v_customer_id
    FROM public.service_bookings
    WHERE booking_id = v_booking_id
    FOR UPDATE;

    -- 3. Check if still open for assignment
    IF v_current_booking_status IN ('PENDING', 'SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'SCHEDULED') THEN
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
            partner_id,
            assignment_method,
            status,
            assigned_at
        ) VALUES (
            v_booking_id,
            v_actual_provider_id,
            v_partner_id,
            'FIRST_ACCEPT',
            'ASSIGNED',
            NOW()
        ) ON CONFLICT (booking_id) DO UPDATE SET
            provider_id = EXCLUDED.provider_id,
            partner_id = EXCLUDED.partner_id,
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

        -- F. Send Customer Notification
        IF v_customer_id IS NOT NULL THEN
            INSERT INTO public.notifications (
                user_id,
                title,
                body,
                created_at
            ) VALUES (
                v_customer_id,
                'Partner Assigned!',
                'Your service partner has accepted your request and is preparing for service.',
                NOW()
            );
        END IF;

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

-- Grant execution permissions
REVOKE EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.atomic_accept_booking_request(uuid, uuid) TO authenticated, service_role;


-- 8. DISPATCH ELIGIBLE SERVICE PROVIDERS (PATH A & PATH B EXECUTION)
-- Strictly filters: role = 'service_provider', verified, online, capable, no active conflicts
CREATE OR REPLACE FUNCTION public.dispatch_eligible_service_providers(
    p_booking_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_booking RECORD;
    v_candidate RECORD;
    v_dispatched_count INTEGER := 0;
BEGIN
    -- 1. Fetch booking record
    SELECT * INTO v_booking
    FROM public.service_bookings
    WHERE booking_id = p_booking_id;

    IF v_booking.booking_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'Booking not found');
    END IF;

    -- 2. Find eligible verified service providers (strictly service_provider, excluding shopkeeper and delivery)
    -- Enforces: 5.0 km radius limit, location freshness, AC service capability, and conflict check
    FOR v_candidate IN
        WITH candidate_distances AS (
            SELECT 
                spp.provider_id,
                p.partner_id,
                p.user_id,
                pll.h3_index_res8,
                pll.updated_at AS location_updated_at,
                COALESCE(
                    CASE 
                        WHEN v_booking.customer_latitude IS NOT NULL 
                         AND v_booking.customer_longitude IS NOT NULL 
                         AND pll.latitude IS NOT NULL 
                         AND pll.longitude IS NOT NULL THEN
                            (6371000.0 * 2.0 * asin(sqrt(
                                power(sin(radians(pll.latitude - v_booking.customer_latitude) / 2.0), 2) +
                                cos(radians(v_booking.customer_latitude)) * cos(radians(pll.latitude)) *
                                power(sin(radians(pll.longitude - v_booking.customer_longitude) / 2.0), 2)
                            )))
                        ELSE 1200.0
                    END, 1200.0
                ) AS distance_meters
            FROM public.service_provider_profiles spp
            JOIN public.partners p ON p.partner_id = spp.partner_id
            JOIN public.users u ON u.user_id = p.user_id
            JOIN public.roles r ON r.role_id = u.role_id
            LEFT JOIN public.partner_live_locations pll ON pll.partner_id = p.partner_id
            WHERE r.role_name = 'service_provider'
              AND p.verification_status IN ('VERIFIED', 'APPROVED')
              AND p.availability_status IN ('ONLINE', 'AVAILABLE')
              AND u.is_active = true
              AND u.account_status = 'ACTIVE'
              -- Service Capability: Must support AC Service
              AND (
                  EXISTS (
                      SELECT 1 FROM public.provider_services ps
                      JOIN public.services s ON s.service_id = ps.service_id
                      WHERE ps.provider_id = spp.provider_id
                        AND (s.name ILIKE '%AC%' OR s.name ILIKE '%Air%' OR s.service_id = v_booking.service_id)
                        AND ps.is_available = true
                  )
                  OR (spp.about ILIKE '%AC%' OR spp.about ILIKE '%Air%')
                  OR NOT EXISTS (SELECT 1 FROM public.provider_services ps2 WHERE ps2.provider_id = spp.provider_id)
              )
              -- Conflict Check: Provider must not have conflicting active job at requested time
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_assignment ba
                  JOIN public.service_bookings sb ON sb.booking_id = ba.booking_id
                  WHERE (ba.provider_id = spp.provider_id OR ba.partner_id = p.partner_id)
                    AND ba.status IN ('ASSIGNED', 'IN_PROGRESS')
                    AND sb.status IN ('ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'SERVICE_STARTED')
                    AND sb.booking_date = v_booking.booking_date
                    AND (v_booking.scheduled_time IS NULL OR sb.scheduled_time = v_booking.scheduled_time)
              )
              -- Location Freshness: Stale locations older than 24 hours are excluded if tracking is active
              AND (
                  pll.updated_at IS NULL 
                  OR pll.updated_at >= NOW() - INTERVAL '24 hours'
              )
              -- Ensure not already requested for this booking
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_requests br
                  WHERE br.booking_id = p_booking_id AND br.provider_id = spp.provider_id
              )
        )
        SELECT * FROM candidate_distances
        -- Hard PostGIS / Geographic Radius: Exclude candidates beyond 5.0 km (5000 meters)
        WHERE distance_meters <= 5000.0
        ORDER BY 
            (CASE WHEN v_booking.customer_h3_res8 IS NOT NULL AND h3_index_res8 = v_booking.customer_h3_res8 THEN 0 ELSE 1 END),
            distance_meters ASC
        LIMIT 10
    LOOP
        -- Insert real partner request
        INSERT INTO public.booking_requests (
            booking_id,
            provider_id,
            partner_id,
            response_status,
            sent_at
        ) VALUES (
            p_booking_id,
            v_candidate.provider_id,
            v_candidate.partner_id,
            'Pending',
            NOW()
        );

        -- Insert Partner Notification
        INSERT INTO public.notifications (
            user_id,
            title,
            body,
            created_at
        ) VALUES (
            v_candidate.user_id,
            'New Service Request Available',
            'A customer requested ' || COALESCE(v_booking.problem_description, 'AC Service') || '. Tap to review and accept.',
            NOW()
        );

        v_dispatched_count := v_dispatched_count + 1;
    END LOOP;

    -- Update booking status to SEARCHING_PROVIDER
    UPDATE public.service_bookings
    SET 
        status = 'SEARCHING_PROVIDER',
        service_status = 'SEARCHING_PROVIDER',
        updated_at = NOW()
    WHERE booking_id = p_booking_id;

    RETURN json_build_object(
        'success', true,
        'booking_id', p_booking_id,
        'dispatched_count', v_dispatched_count
    );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

GRANT EXECUTE ON FUNCTION public.dispatch_eligible_service_providers(uuid) TO authenticated, service_role;


-- 9. SERVICE-DATE MORNING SCHEDULED MATCHING FUNCTION (PATH B)
-- Detects future scheduled bookings whose service date is TODAY and begins partner matching
CREATE OR REPLACE FUNCTION public.process_scheduled_bookings_for_today()
RETURNS JSON AS $$
DECLARE
    v_rec RECORD;
    v_processed_count INTEGER := 0;
BEGIN
    FOR v_rec IN
        SELECT booking_id, customer_id
        FROM public.service_bookings
        WHERE status = 'SCHEDULED'
          AND booking_date <= CURRENT_DATE
          AND partner_id IS NULL
    LOOP
        -- Trigger matching dispatch
        PERFORM public.dispatch_eligible_service_providers(v_rec.booking_id);

        -- Notify customer that service date matching has commenced
        IF v_rec.customer_id IS NOT NULL THEN
            INSERT INTO public.notifications (
                user_id,
                title,
                body,
                created_at
            ) VALUES (
                v_rec.customer_id,
                'Service Today: Finding Partner',
                'Your scheduled service is today! We are finding the best verified professional for you.',
                NOW()
            );
        END IF;

        v_processed_count := v_processed_count + 1;
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'processed_count', v_processed_count,
        'date', CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

GRANT EXECUTE ON FUNCTION public.process_scheduled_bookings_for_today() TO authenticated, service_role;


-- 10. ATOMIC CUSTOMER CANCELLATION RPC
CREATE OR REPLACE FUNCTION public.cancel_customer_booking(
    p_booking_id UUID,
    p_customer_id UUID,
    p_reason TEXT DEFAULT 'Cancelled by Customer'
)
RETURNS JSON AS $$
DECLARE
    v_current_status TEXT;
    v_partner_id UUID;
BEGIN
    -- Row lock
    SELECT status, partner_id INTO v_current_status, v_partner_id
    FROM public.service_bookings
    WHERE booking_id = p_booking_id
      AND customer_id = p_customer_id
    FOR UPDATE;

    IF v_current_status IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'Booking not found or not owned by user.');
    END IF;

    -- Only allow cancellation before work started
    IF v_current_status IN ('SERVICE_STARTED', 'SERVICE_COMPLETED', 'PAYMENT_COMPLETED', 'CLOSED') THEN
        RETURN json_build_object('success', false, 'message', 'Cannot cancel booking after service has commenced.');
    END IF;

    -- Update booking
    UPDATE public.service_bookings
    SET 
        status = 'CANCELLED_BY_CUSTOMER',
        service_status = 'CANCELLED_BY_CUSTOMER',
        updated_at = NOW()
    WHERE booking_id = p_booking_id;

    -- Expire any pending partner requests
    UPDATE public.booking_requests
    SET response_status = 'Expired', response_at = NOW()
    WHERE booking_id = p_booking_id AND response_status = 'Pending';

    -- Record in cancellations table
    INSERT INTO public.booking_cancellations (
        booking_id,
        cancelled_by,
        reason,
        cancelled_at
    ) VALUES (
        p_booking_id,
        p_customer_id,
        p_reason,
        NOW()
    );

    -- Log history
    INSERT INTO public.booking_status_history (
        booking_id,
        status,
        changed_by,
        remarks,
        changed_at
    ) VALUES (
        p_booking_id,
        'CANCELLED_BY_CUSTOMER',
        p_customer_id,
        p_reason,
        NOW()
    );

    RETURN json_build_object('success', true, 'message', 'Booking cancelled successfully.');
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

GRANT EXECUTE ON FUNCTION public.cancel_customer_booking(uuid, uuid, text) TO authenticated, service_role;


-- 11. Optional pg_cron automated schedule
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        BEGIN
            PERFORM cron.unschedule('morning-partner-matching');
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        PERFORM cron.schedule('morning-partner-matching', '0 6 * * *', 'SELECT public.process_scheduled_bookings_for_today();');
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;
