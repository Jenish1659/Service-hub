-- =============================================================================
-- SERVICEHUB — CLEAN PURGE OF ALL DUMMY, TEST & LOGIN DATA
--
-- This script safely removes:
-- 1. All test bookings, verification requests, orders, and payments.
-- 2. All dummy/test customer, partner, delivery, and shopkeeper records.
-- 3. All test users from auth.users and public.users (except official Admin).
--
-- PRESERVES:
-- 1. All database tables, schema structures, and foreign keys.
-- 2. System reference data: roles, service categories, and services.
-- 3. Official Admin account: admin@gmail.com (Password: Admin@123).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STEP 1: Truncate All Transactional and Operational Tables
-- -----------------------------------------------------------------------------
TRUNCATE TABLE
    public.verification_requests,
    public.face_verifications,
    public.document_files,
    public.identity_documents,
    public.verification_history,
    public.service_provider_profiles,
    public.shopkeeper_profiles,
    public.delivery_vehicles,
    public.delivery_assignments,
    public.delivery_tracking,
    public.delivery_status_history,
    public.delivery_failures,
    public.partners,
    public.service_bookings,
    public.booking_requests,
    public.booking_assignment,
    public.booking_status_history,
    public.booking_cancellations,
    public.booking_location_logs,
    public.ac_service_reports,
    public.ac_service_photos,
    public.order_items,
    public.orders,
    public.order_status_history,
    public.order_cancellations,
    public.payments,
    public.payment_transactions,
    public.payouts,
    public.refunds,
    public.invoices,
    public.partner_earnings,
    public.reviews,
    public.review_replies,
    public.support_messages,
    public.support_tickets,
    public.notifications,
    public.notification_preferences,
    public.audit_logs,
    public.admin_actions,
    public.user_addresses,
    public.user_devices,
    public.user_profiles
CASCADE;

-- -----------------------------------------------------------------------------
-- STEP 2: Delete Non-Admin Users from Public and Auth Tables
-- -----------------------------------------------------------------------------
DELETE FROM public.users WHERE email != 'admin@gmail.com';

DO $$
BEGIN
    DELETE FROM auth.users WHERE email != 'admin@gmail.com';
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- -----------------------------------------------------------------------------
-- STEP 3: Ensure Official Admin Exists (admin@gmail.com / Admin@123)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_admin_role_id UUID;
    v_admin_auth_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 1. Fetch or create admin role
    SELECT role_id INTO v_admin_role_id FROM public.roles WHERE role_name = 'admin' LIMIT 1;
    IF v_admin_role_id IS NULL THEN
        INSERT INTO public.roles (role_name, description)
        VALUES ('admin', 'System Administrator with full access')
        RETURNING role_id INTO v_admin_role_id;
    END IF;

    -- 2. Check if admin exists in auth.users, or create it with password 'Admin@123'
    SELECT id INTO v_admin_auth_id FROM auth.users WHERE email = 'admin@gmail.com' LIMIT 1;
    IF v_admin_auth_id IS NULL THEN
        v_admin_auth_id := gen_random_uuid();
        INSERT INTO auth.users (
            id,
            instance_id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at
        ) VALUES (
            v_admin_auth_id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'admin@gmail.com',
            crypt('Admin@123', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}',
            '{"role":"admin","name":"Super Admin"}',
            NOW(),
            NOW()
        );
    ELSE
        -- Update password to Admin@123
        UPDATE auth.users
        SET encrypted_password = crypt('Admin@123', gen_salt('bf')),
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            updated_at = NOW()
        WHERE id = v_admin_auth_id;
    END IF;

    -- 3. Ensure admin exists in public.users
    SELECT user_id INTO v_admin_user_id FROM public.users WHERE email = 'admin@gmail.com' LIMIT 1;
    IF v_admin_user_id IS NULL THEN
        INSERT INTO public.users (
            auth_id,
            role_id,
            username,
            email,
            phone,
            account_status,
            is_active,
            created_at
        ) VALUES (
            v_admin_auth_id,
            v_admin_role_id,
            'admin',
            'admin@gmail.com',
            '+919999999999',
            'ACTIVE',
            true,
            NOW()
        )
        RETURNING user_id INTO v_admin_user_id;
    ELSE
        UPDATE public.users
        SET auth_id = v_admin_auth_id,
            role_id = v_admin_role_id,
            account_status = 'ACTIVE',
            is_active = true
        WHERE user_id = v_admin_user_id;
    END IF;

    -- 4. Ensure admin profile exists
    INSERT INTO public.user_profiles (user_id, first_name, last_name, profile_photo)
    VALUES (v_admin_user_id, 'System', 'Admin', 'https://api.dicebear.com/7.x/bottts/svg?seed=admin')
    ON CONFLICT (user_id) DO UPDATE
    SET first_name = 'System', last_name = 'Admin';

END $$;

-- -----------------------------------------------------------------------------
-- VERIFICATION: Show Remaining Records
-- -----------------------------------------------------------------------------
SELECT 'users' AS table_name, count(*) AS remaining_records FROM public.users
UNION ALL
SELECT 'verification_requests', count(*) FROM public.verification_requests
UNION ALL
SELECT 'partners', count(*) FROM public.partners
UNION ALL
SELECT 'service_bookings', count(*) FROM public.service_bookings
UNION ALL
SELECT 'orders', count(*) FROM public.orders;
