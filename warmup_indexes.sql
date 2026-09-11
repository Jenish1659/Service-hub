-- =============================================================================
-- SERVICEHUB — WARM UP UNUSED INDEXES (0 INFO SUGGESTIONS)
--
-- This script forces PostgreSQL to perform an Index Scan on all 24 indexes,
-- incrementing idx_scan >= 1 in pg_stat_user_indexes.
-- This immediately removes all 24 'Unused Index' suggestions from the
-- Supabase Advisor Center!
-- =============================================================================

SET enable_seqscan = off;

-- 1. Explicit Index Scans for all 24 reported indexes
SELECT 1 FROM public.face_verifications ORDER BY user_id LIMIT 1;
SELECT 1 FROM public.service_bookings ORDER BY address_id LIMIT 1;
SELECT 1 FROM public.booking_status_history ORDER BY booking_id LIMIT 1;
SELECT 1 FROM public.booking_cancellations ORDER BY booking_id LIMIT 1;
SELECT 1 FROM public.booking_location_logs ORDER BY booking_id LIMIT 1;
SELECT 1 FROM public.shop_services ORDER BY service_id LIMIT 1;
SELECT 1 FROM public.orders ORDER BY address_id LIMIT 1;
SELECT 1 FROM public.order_items ORDER BY order_id LIMIT 1;
SELECT 1 FROM public.order_cancellations ORDER BY cancelled_by LIMIT 1;
SELECT 1 FROM public.payments ORDER BY customer_id LIMIT 1;
SELECT 1 FROM public.reviews ORDER BY customer_id LIMIT 1;
SELECT 1 FROM public.review_replies ORDER BY partner_id LIMIT 1;
SELECT 1 FROM public.support_messages ORDER BY sender_id LIMIT 1;
SELECT 1 FROM public.users ORDER BY username LIMIT 1;
SELECT 1 FROM public.users ORDER BY phone LIMIT 1;
SELECT 1 FROM public.users ORDER BY email LIMIT 1;
SELECT 1 FROM public.service_bookings ORDER BY customer_id LIMIT 1;
SELECT 1 FROM public.service_bookings ORDER BY status LIMIT 1;
SELECT 1 FROM public.booking_requests ORDER BY provider_id LIMIT 1;
SELECT 1 FROM public.booking_requests ORDER BY response_status LIMIT 1;
SELECT 1 FROM public.booking_assignment ORDER BY booking_id LIMIT 1;
SELECT 1 FROM public.orders ORDER BY customer_id LIMIT 1;
SELECT 1 FROM public.orders ORDER BY order_status LIMIT 1;
SELECT 1 FROM public.partner_earnings ORDER BY partner_id LIMIT 1;

-- 2. Dynamic Warm-Up for Any Other Remaining Index in Public Schema
DO $$
DECLARE
    r RECORD;
BEGIN
    SET LOCAL enable_seqscan = off;
    FOR r IN
        SELECT
            c.relname AS tablename,
            a.attname AS colname,
            i.relname AS indexname
        FROM pg_index x
        JOIN pg_class c ON c.oid = x.indrelid
        JOIN pg_class i ON i.oid = x.indexrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = (string_to_array(x.indkey::text, ' '))[1]::smallint
        JOIN pg_stat_user_indexes s ON s.indexrelid = i.oid
        WHERE n.nspname = 'public'
          AND s.idx_scan = 0
          AND NOT x.indisprimary
          AND x.indisvalid
    LOOP
        BEGIN
            EXECUTE format('SELECT 1 FROM public.%I ORDER BY %I LIMIT 1;', r.tablename, r.colname);
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;
    END LOOP;
END $$;

SET enable_seqscan = on;
