-- =============================================================================
-- SERVICEHUB ENTERPRISE MASTER DATABASE SCHEMA
-- PostgreSQL 15+ with PostGIS Extension (Supabase Cloud)
-- 16 Modular Domains | 70 Dedicated Tables | Realtime | Row Level Security (RLS)
-- =============================================================================

-- Clean Wipe of Previous Schema (Complete Reset)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Enable PostgreSQL Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- Set Default Search Path
SET search_path TO public, auth, extensions;

-- =============================================================================
-- MODULE 1: USER & ROLE MANAGEMENT
-- =============================================================================

-- 1. roles
CREATE TABLE IF NOT EXISTS public.roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT UNIQUE NOT NULL CHECK (role_name IN ('customer', 'service_provider', 'shopkeeper', 'delivery_agent', 'admin')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. permissions
CREATE TABLE IF NOT EXISTS public.permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name TEXT UNIQUE NOT NULL,
    module TEXT NOT NULL,
    description TEXT
);

-- 3. role_permissions
CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id UUID REFERENCES public.roles(role_id) ON DELETE CASCADE,
    permission_id UUID REFERENCES public.permissions(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- 4. users
CREATE TABLE IF NOT EXISTS public.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE, -- References auth.users(id) in Supabase Auth
    role_id UUID NOT NULL REFERENCES public.roles(role_id),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT UNIQUE NOT NULL,
    account_status TEXT NOT NULL CHECK (account_status IN ('ACTIVE', 'PENDING_VERIFICATION', 'SUSPENDED', 'DEACTIVATED')) DEFAULT 'ACTIVE',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. user_profiles
CREATE TABLE IF NOT EXISTS public.user_profiles (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT,
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other')),
    profile_photo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. user_addresses
CREATE TABLE IF NOT EXISTS public.user_addresses (
    address_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    address_type TEXT NOT NULL CHECK (address_type IN ('Home', 'Work', 'Other')) DEFAULT 'Home',
    house_no TEXT,
    building_name TEXT,
    street TEXT,
    area TEXT NOT NULL,
    landmark TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'Gujarat',
    pincode TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. user_devices
CREATE TABLE IF NOT EXISTS public.user_devices (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 2: PARTNER MANAGEMENT
-- =============================================================================

-- 8. partners
CREATE TABLE IF NOT EXISTS public.partners (
    partner_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    partner_code TEXT UNIQUE NOT NULL DEFAULT ('SHP' || FLOOR(100000 + RANDOM() * 900000)::TEXT),
    verification_status TEXT NOT NULL CHECK (verification_status IN ('PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'SUSPENDED')) DEFAULT 'PENDING',
    availability_status TEXT NOT NULL CHECK (availability_status IN ('ONLINE', 'OFFLINE', 'ON_JOB', 'BUSY')) DEFAULT 'ONLINE',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE
);

-- 9. service_provider_profiles
CREATE TABLE IF NOT EXISTS public.service_provider_profiles (
    provider_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID UNIQUE NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    experience_years INTEGER NOT NULL DEFAULT 1,
    about TEXT,
    rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    total_jobs INTEGER NOT NULL DEFAULT 0,
    service_radius_km DOUBLE PRECISION NOT NULL DEFAULT 10.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. shopkeeper_profiles
CREATE TABLE IF NOT EXISTS public.shopkeeper_profiles (
    shopkeeper_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID UNIQUE NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_type TEXT NOT NULL,
    business_experience INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. delivery_agent_profiles
CREATE TABLE IF NOT EXISTS public.delivery_agent_profiles (
    delivery_agent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID UNIQUE NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('Bike', 'Scooter', 'Electric Vehicle')),
    vehicle_number TEXT NOT NULL,
    driving_license_number TEXT NOT NULL,
    availability_status TEXT NOT NULL CHECK (availability_status IN ('ONLINE', 'OFFLINE', 'ON_DELIVERY')) DEFAULT 'ONLINE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. delivery_vehicles
CREATE TABLE IF NOT EXISTS public.delivery_vehicles (
    vehicle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_agent_id UUID NOT NULL REFERENCES public.delivery_agent_profiles(delivery_agent_id) ON DELETE CASCADE,
    vehicle_type TEXT NOT NULL,
    registration_number TEXT UNIQUE NOT NULL,
    model TEXT,
    insurance_status TEXT CHECK (insurance_status IN ('VALID', 'EXPIRED', 'PENDING')) DEFAULT 'VALID'
);

-- =============================================================================
-- MODULE 3: VERIFICATION & KYC
-- =============================================================================

-- 13. verification_requests
CREATE TABLE IF NOT EXISTS public.verification_requests (
    verification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    verification_type TEXT NOT NULL CHECK (verification_type IN ('AADHAAR', 'PAN', 'DRIVING_LICENSE', 'SHOP_LICENSE', 'POLICE_CLEARANCE')),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED')) DEFAULT 'PENDING',
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES public.users(user_id),
    remarks TEXT
);

-- 14. identity_documents
CREATE TABLE IF NOT EXISTS public.identity_documents (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_number TEXT NOT NULL,
    verification_status TEXT NOT NULL CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')) DEFAULT 'PENDING',
    verified_at TIMESTAMP WITH TIME ZONE
);

-- 15. document_files
CREATE TABLE IF NOT EXISTS public.document_files (
    file_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.identity_documents(document_id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. face_verifications
CREATE TABLE IF NOT EXISTS public.face_verifications (
    face_verification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    verification_id UUID REFERENCES public.verification_requests(verification_id) ON DELETE CASCADE,
    method TEXT NOT NULL DEFAULT 'AI_FACIAL_MATCH',
    match_status TEXT NOT NULL CHECK (match_status IN ('MATCHED', 'MISMATCH', 'PENDING')) DEFAULT 'PENDING',
    confidence_score DOUBLE PRECISION DEFAULT 0.98,
    verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 17. shop_inspections
CREATE TABLE IF NOT EXISTS public.shop_inspections (
    inspection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL,
    inspector_id UUID REFERENCES public.users(user_id),
    inspection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT NOT NULL CHECK (status IN ('PASSED', 'FAILED', 'PENDING')) DEFAULT 'PENDING',
    findings TEXT,
    remarks TEXT
);

-- 18. verification_history
CREATE TABLE IF NOT EXISTS public.verification_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_id UUID NOT NULL REFERENCES public.verification_requests(verification_id) ON DELETE CASCADE,
    old_status TEXT,
    new_status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(user_id),
    reason TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 4: SERVICE CATALOG
-- =============================================================================

-- 19. service_categories
CREATE TABLE IF NOT EXISTS public.service_categories (
    category_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE'
);

-- 20. services
CREATE TABLE IF NOT EXISTS public.services (
    service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id TEXT NOT NULL REFERENCES public.service_categories(category_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    image TEXT,
    base_price DOUBLE PRECISION NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE'
);

-- 21. service_variants
CREATE TABLE IF NOT EXISTS public.service_variants (
    variant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60
);

-- 22. service_addons
CREATE TABLE IF NOT EXISTS public.service_addons (
    addon_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE'
);

-- 23. service_requirements
CREATE TABLE IF NOT EXISTS public.service_requirements (
    requirement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    requirement_name TEXT NOT NULL,
    description TEXT,
    is_required BOOLEAN NOT NULL DEFAULT true
);

-- =============================================================================
-- MODULE 5: SERVICE PROVIDER DOMAIN
-- =============================================================================

-- 24. provider_services
CREATE TABLE IF NOT EXISTS public.provider_services (
    provider_service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    price DOUBLE PRECISION,
    is_available BOOLEAN NOT NULL DEFAULT true,
    UNIQUE(provider_id, service_id)
);

-- 25. provider_service_areas
CREATE TABLE IF NOT EXISTS public.provider_service_areas (
    area_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    city TEXT NOT NULL,
    area_name TEXT NOT NULL,
    radius_km DOUBLE PRECISION NOT NULL DEFAULT 10.0,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE'
);

-- 26. provider_availability
CREATE TABLE IF NOT EXISTS public.provider_availability (
    availability_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0: Sunday, 6: Saturday
    start_time TIME NOT NULL DEFAULT '08:00:00',
    end_time TIME NOT NULL DEFAULT '20:00:00',
    is_available BOOLEAN NOT NULL DEFAULT true
);

-- =============================================================================
-- MODULE 6: AC SERVICE (SPECIALIZED DOMAIN)
-- =============================================================================

-- 27. ac_service_types
CREATE TABLE IF NOT EXISTS public.ac_service_types (
    ac_service_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    base_price DOUBLE PRECISION NOT NULL,
    estimated_duration INTEGER NOT NULL DEFAULT 60
);

-- 28. ac_service_reports
CREATE TABLE IF NOT EXISTS public.ac_service_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL,
    ac_type TEXT NOT NULL CHECK (ac_type IN ('Split AC', 'Window AC', 'Cassette AC', 'Tower AC')),
    ac_model TEXT,
    issue_found TEXT,
    work_done TEXT,
    technician_notes TEXT,
    completion_status TEXT NOT NULL CHECK (completion_status IN ('COMPLETED', 'PARTS_PENDING', 'UNREPAIRABLE')) DEFAULT 'COMPLETED'
);

-- 29. ac_service_checklists
CREATE TABLE IF NOT EXISTS public.ac_service_checklists (
    checklist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_type_id UUID NOT NULL REFERENCES public.ac_service_types(ac_service_type_id) ON DELETE CASCADE,
    checklist_item TEXT NOT NULL,
    sequence_no INTEGER NOT NULL DEFAULT 1,
    is_required BOOLEAN NOT NULL DEFAULT true
);

-- 30. ac_service_photos
CREATE TABLE IF NOT EXISTS public.ac_service_photos (
    photo_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES public.ac_service_reports(report_id) ON DELETE CASCADE,
    photo_type TEXT NOT NULL CHECK (photo_type IN ('BEFORE_SERVICE', 'AFTER_SERVICE', 'DEFECTIVE_PART', 'INVOICE_RECEIPT')),
    file_id UUID NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 7: SERVICE BOOKING ENGINE
-- =============================================================================

-- 31. service_bookings
CREATE TABLE IF NOT EXISTS public.service_bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_code TEXT UNIQUE NOT NULL DEFAULT ('SHB' || FLOOR(10000000 + RANDOM() * 90000000)::TEXT),
    customer_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(service_id),
    address_id UUID NOT NULL REFERENCES public.user_addresses(address_id),
    booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    scheduled_time TEXT NOT NULL,
    problem_description TEXT,
    estimated_amount DOUBLE PRECISION NOT NULL,
    final_amount DOUBLE PRECISION,
    status TEXT NOT NULL CHECK (status IN (
        'PENDING',
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
    )) DEFAULT 'SEARCHING_PROVIDER',
    partner_id UUID REFERENCES public.partners(partner_id) ON DELETE SET NULL,
    service_status TEXT DEFAULT 'SEARCHING_PROVIDER',
    customer_latitude DOUBLE PRECISION,
    customer_longitude DOUBLE PRECISION,
    entrance_pin TEXT DEFAULT '7429',
    completion_otp TEXT DEFAULT '5892',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 32. booking_requests
CREATE TABLE IF NOT EXISTS public.booking_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.partners(partner_id) ON DELETE SET NULL,
    provider_id UUID REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    required_role TEXT DEFAULT 'service_provider',
    required_capability TEXT DEFAULT 'ac_service',
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '10 minutes'),
    response_at TIMESTAMP WITH TIME ZONE,
    response_status TEXT NOT NULL CHECK (response_status IN ('Pending', 'Accepted', 'Rejected', 'Expired')) DEFAULT 'Pending'
);

-- 33. booking_assignment
CREATE TABLE IF NOT EXISTS public.booking_assignment (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID UNIQUE NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    partner_id UUID REFERENCES public.partners(partner_id) ON DELETE SET NULL,
    provider_id UUID REFERENCES public.service_provider_profiles(provider_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assignment_method TEXT NOT NULL CHECK (assignment_method IN ('FIRST_ACCEPT', 'AUTO_DISPATCH', 'ADMIN_MANUAL')) DEFAULT 'FIRST_ACCEPT',
    status TEXT NOT NULL CHECK (status IN ('ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')) DEFAULT 'ASSIGNED'
);

-- 34. booking_status_history
CREATE TABLE IF NOT EXISTS public.booking_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(user_id),
    remarks TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 35. booking_cancellations
CREATE TABLE IF NOT EXISTS public.booking_cancellations (
    cancellation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    cancelled_by UUID NOT NULL REFERENCES public.users(user_id),
    reason TEXT NOT NULL,
    cancelled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 36. booking_location_logs
CREATE TABLE IF NOT EXISTS public.booking_location_logs (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.service_bookings(booking_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(user_id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 8: SHOPKEEPER & SHOP
-- =============================================================================

-- 37. shops
CREATE TABLE IF NOT EXISTS public.shops (
    shop_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopkeeper_id UUID NOT NULL REFERENCES public.shopkeeper_profiles(shopkeeper_id) ON DELETE CASCADE,
    shop_name TEXT NOT NULL,
    shop_type TEXT NOT NULL,
    address_id UUID REFERENCES public.user_addresses(address_id),
    verification_status TEXT NOT NULL CHECK (verification_status IN ('PENDING', 'VERIFIED', 'SUSPENDED')) DEFAULT 'PENDING',
    rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 38. shop_services
CREATE TABLE IF NOT EXISTS public.shop_services (
    shop_service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES public.shops(shop_id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES public.services(service_id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')) DEFAULT 'ACTIVE'
);

-- 39. shop_business_hours
CREATE TABLE IF NOT EXISTS public.shop_business_hours (
    hours_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES public.shops(shop_id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    opening_time TIME NOT NULL DEFAULT '09:00:00',
    closing_time TIME NOT NULL DEFAULT '21:00:00',
    is_open BOOLEAN NOT NULL DEFAULT true
);

-- 40. shop_images
CREATE TABLE IF NOT EXISTS public.shop_images (
    shop_image_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES public.shops(shop_id) ON DELETE CASCADE,
    file_id UUID NOT NULL,
    image_type TEXT NOT NULL CHECK (image_type IN ('STORE_FRONT', 'INTERIOR', 'BANNER', 'DOCUMENT'))
);

-- =============================================================================
-- MODULE 9: PRODUCTS & INVENTORY
-- =============================================================================

-- 41. product_categories
CREATE TABLE IF NOT EXISTS public.product_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID REFERENCES public.services(service_id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT
);

-- 42. products
CREATE TABLE IF NOT EXISTS public.products (
    product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES public.shops(shop_id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.product_categories(category_id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    description TEXT,
    sku TEXT UNIQUE,
    price DOUBLE PRECISION NOT NULL,
    discount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    tax_rate DOUBLE PRECISION NOT NULL DEFAULT 0.18,
    image TEXT,
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'OUT_OF_STOCK', 'DISCONTINUED')) DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 43. inventory
CREATE TABLE IF NOT EXISTS public.inventory (
    inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID UNIQUE NOT NULL REFERENCES public.products(product_id) ON DELETE CASCADE,
    current_stock INTEGER NOT NULL DEFAULT 0,
    reserved_stock INTEGER NOT NULL DEFAULT 0,
    low_stock_limit INTEGER NOT NULL DEFAULT 5,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 44. inventory_transactions
CREATE TABLE IF NOT EXISTS public.inventory_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(product_id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('STOCK_IN', 'ORDER_RESERVE', 'ORDER_FULFILL', 'RETURN', 'DAMAGE_WRITE_OFF')),
    quantity INTEGER NOT NULL,
    reference_id UUID,
    created_by UUID REFERENCES public.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 10: PRODUCT ORDERS
-- =============================================================================

-- 45. orders
CREATE TABLE IF NOT EXISTS public.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_code TEXT UNIQUE NOT NULL DEFAULT ('SHO' || FLOOR(10000000 + RANDOM() * 90000000)::TEXT),
    customer_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    shop_id UUID NOT NULL REFERENCES public.shops(shop_id),
    address_id UUID NOT NULL REFERENCES public.user_addresses(address_id),
    subtotal DOUBLE PRECISION NOT NULL,
    delivery_charge DOUBLE PRECISION NOT NULL DEFAULT 40.0,
    discount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    tax DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    total_amount DOUBLE PRECISION NOT NULL,
    payment_status TEXT NOT NULL CHECK (payment_status IN ('PENDING', 'PAID', 'REFUNDED', 'FAILED')) DEFAULT 'PENDING',
    order_status TEXT NOT NULL CHECK (order_status IN (
        'Placed',
        'Packing',
        'Ready for Pickup',
        'Out for Delivery',
        'Delivered',
        'Cancelled',
        'CANCELLED_BY_CUSTOMER',
        'CANCELLED_BY_PROVIDER'
    )) DEFAULT 'Placed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 46. order_items
CREATE TABLE IF NOT EXISTS public.order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DOUBLE PRECISION NOT NULL,
    subtotal DOUBLE PRECISION NOT NULL
);

-- 47. order_status_history
CREATE TABLE IF NOT EXISTS public.order_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    changed_by UUID REFERENCES public.users(user_id),
    remarks TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 48. order_cancellations
CREATE TABLE IF NOT EXISTS public.order_cancellations (
    cancellation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    cancelled_by UUID NOT NULL REFERENCES public.users(user_id),
    reason TEXT NOT NULL,
    cancelled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 11: DELIVERY
-- =============================================================================

-- 49. delivery_assignments
CREATE TABLE IF NOT EXISTS public.delivery_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID UNIQUE NOT NULL REFERENCES public.orders(order_id) ON DELETE CASCADE,
    delivery_agent_id UUID NOT NULL REFERENCES public.delivery_agent_profiles(delivery_agent_id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    picked_up_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL CHECK (status IN ('ASSIGNED', 'ACCEPTED', 'PICKED_UP', 'DELIVERED', 'FAILED', 'CANCELLED')) DEFAULT 'ASSIGNED'
);

-- 50. delivery_tracking
CREATE TABLE IF NOT EXISTS public.delivery_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.delivery_assignments(assignment_id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 51. delivery_status_history
CREATE TABLE IF NOT EXISTS public.delivery_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.delivery_assignments(assignment_id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    remarks TEXT
);

-- 52. delivery_failures
CREATE TABLE IF NOT EXISTS public.delivery_failures (
    failure_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID NOT NULL REFERENCES public.delivery_assignments(assignment_id) ON DELETE CASCADE,
    failure_type TEXT NOT NULL CHECK (failure_type IN ('CUSTOMER_UNAVAILABLE', 'INCORRECT_ADDRESS', 'REJECTED_BY_CUSTOMER', 'ACCIDENT_VEHICLE_ISSUE')),
    reason TEXT NOT NULL,
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolution TEXT
);

-- =============================================================================
-- MODULE 12: PAYMENT & FINANCE
-- =============================================================================

-- 53. payments
CREATE TABLE IF NOT EXISTS public.payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.users(user_id),
    booking_id UUID REFERENCES public.service_bookings(booking_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    transaction_id TEXT UNIQUE,
    amount DOUBLE PRECISION NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('CASH_ON_SERVICE', 'UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING', 'WALLET')) DEFAULT 'CASH_ON_SERVICE',
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')) DEFAULT 'PENDING',
    paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 54. payment_transactions
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES public.payments(payment_id) ON DELETE CASCADE,
    gateway_reference TEXT,
    gateway_status TEXT,
    response_code TEXT,
    response_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 55. refunds
CREATE TABLE IF NOT EXISTS public.refunds (
    refund_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES public.payments(payment_id) ON DELETE CASCADE,
    amount DOUBLE PRECISION NOT NULL,
    reason TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('REQUESTED', 'PROCESSING', 'COMPLETED', 'REJECTED')) DEFAULT 'REQUESTED',
    processed_at TIMESTAMP WITH TIME ZONE
);

-- 56. invoices
CREATE TABLE IF NOT EXISTS public.invoices (
    invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.service_bookings(booking_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    invoice_number TEXT UNIQUE NOT NULL DEFAULT ('INV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || FLOOR(1000 + RANDOM() * 9000)::TEXT),
    subtotal DOUBLE PRECISION NOT NULL,
    tax DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    total DOUBLE PRECISION NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 57. partner_earnings
CREATE TABLE IF NOT EXISTS public.partner_earnings (
    earning_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.service_bookings(booking_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    gross_amount DOUBLE PRECISION NOT NULL,
    platform_fee DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    net_amount DOUBLE PRECISION NOT NULL,
    earning_status TEXT NOT NULL CHECK (earning_status IN ('PENDING', 'AVAILABLE_FOR_PAYOUT', 'PAID_OUT')) DEFAULT 'AVAILABLE_FOR_PAYOUT',
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 58. payouts
CREATE TABLE IF NOT EXISTS public.payouts (
    payout_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_id UUID NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    amount DOUBLE PRECISION NOT NULL,
    payout_period TEXT NOT NULL, -- e.g. '2026-W34' or '2026-08'
    status TEXT NOT NULL CHECK (status IN ('INITIATED', 'PROCESSING', 'SETTLED', 'FAILED')) DEFAULT 'INITIATED',
    processed_at TIMESTAMP WITH TIME ZONE
);

-- 59. commission_rules
CREATE TABLE IF NOT EXISTS public.commission_rules (
    commission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partner_type TEXT NOT NULL CHECK (partner_type IN ('service_provider', 'shopkeeper', 'delivery_agent')),
    service_id UUID REFERENCES public.services(service_id) ON DELETE CASCADE,
    percentage DOUBLE PRECISION NOT NULL DEFAULT 10.0,
    fixed_amount DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    effective_to TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- MODULE 13: REVIEWS
-- =============================================================================

-- 60. reviews
CREATE TABLE IF NOT EXISTS public.reviews (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.service_bookings(booking_id) ON DELETE SET NULL,
    order_id UUID REFERENCES public.orders(order_id) ON DELETE SET NULL,
    rating DOUBLE PRECISION NOT NULL CHECK (rating BETWEEN 1.0 AND 5.0),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 61. review_replies
CREATE TABLE IF NOT EXISTS public.review_replies (
    reply_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.reviews(review_id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES public.partners(partner_id) ON DELETE CASCADE,
    reply_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 14: NOTIFICATIONS & SUPPORT
-- =============================================================================

-- 62. notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('BOOKING', 'ORDER', 'PAYMENT', 'PROMO', 'SECURITY', 'SYSTEM')),
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 63. notification_preferences
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    booking_notifications BOOLEAN NOT NULL DEFAULT true,
    order_notifications BOOLEAN NOT NULL DEFAULT true,
    payment_notifications BOOLEAN NOT NULL DEFAULT true,
    general_notifications BOOLEAN NOT NULL DEFAULT true
);

-- 64. support_tickets
CREATE TABLE IF NOT EXISTS public.support_tickets (
    ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')) DEFAULT 'MEDIUM',
    status TEXT NOT NULL CHECK (status IN ('OPEN', 'IN_PROGRESS', 'WAITING_FOR_USER', 'RESOLVED', 'CLOSED')) DEFAULT 'OPEN',
    assigned_admin UUID REFERENCES public.users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 65. support_messages
CREATE TABLE IF NOT EXISTS public.support_messages (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(ticket_id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 15: ADMIN
-- =============================================================================

-- 66. admin_profiles
CREATE TABLE IF NOT EXISTS public.admin_profiles (
    admin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    admin_level TEXT NOT NULL CHECK (admin_level IN ('SUPER_ADMIN', 'OPERATIONS_ADMIN', 'FINANCE_ADMIN', 'SUPPORT_AGENT')) DEFAULT 'OPERATIONS_ADMIN',
    status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'SUSPENDED')) DEFAULT 'ACTIVE'
);

-- 67. admin_actions
CREATE TABLE IF NOT EXISTS public.admin_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.admin_profiles(admin_id) ON DELETE CASCADE,
    module TEXT NOT NULL,
    action_type TEXT NOT NULL,
    target_id UUID,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 68. audit_logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    module TEXT NOT NULL,
    target_id UUID,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 69. system_settings
CREATE TABLE IF NOT EXISTS public.system_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- MODULE 16: FILE STORAGE
-- =============================================================================

-- 70. files
CREATE TABLE IF NOT EXISTS public.files (
    file_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uploaded_by UUID REFERENCES public.users(user_id) ON DELETE SET NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON public.users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON public.users(role_id);
CREATE INDEX IF NOT EXISTS idx_partners_user_id ON public.partners(user_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_customer_id ON public.service_bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_status ON public.service_bookings(status);
CREATE INDEX IF NOT EXISTS idx_booking_requests_provider_id ON public.booking_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_booking_requests_status ON public.booking_requests(response_status);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_booking_id ON public.booking_assignment(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_assignment_provider_id ON public.booking_assignment(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(order_status);
CREATE INDEX IF NOT EXISTS idx_delivery_assignments_agent ON public.delivery_assignments(delivery_agent_id);
CREATE INDEX IF NOT EXISTS idx_partner_earnings_partner ON public.partner_earnings(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_earnings_date ON public.partner_earnings(earned_at);

-- =============================================================================
-- STORED PROCEDURES & ATOMIC TRANSACTION LOGIC
-- =============================================================================

-- 1. Atomic Booking Accept Procedure (First-Accept-Wins Transaction)
CREATE OR REPLACE FUNCTION public.atomic_accept_booking_request(
    p_request_id UUID,
    p_partner_id UUID DEFAULT NULL,
    p_provider_id UUID DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_booking_id UUID;
    v_current_booking_status TEXT;
    v_actual_partner_id UUID;
    v_actual_provider_id UUID;
    v_req_partner_id UUID;
    v_req_provider_id UUID;
    v_result JSON;
BEGIN
    -- Get target booking id and recorded partner/provider IDs from request
    SELECT booking_id, partner_id, provider_id 
    INTO v_booking_id, v_req_partner_id, v_req_provider_id
    FROM public.booking_requests
    WHERE request_id = p_request_id;

    IF v_booking_id IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'Request record not found.');
    END IF;

    -- Resolve authoritative partner and provider IDs
    v_actual_partner_id := COALESCE(p_partner_id, v_req_partner_id);
    v_actual_provider_id := COALESCE(p_provider_id, v_req_provider_id);

    -- If provider_id still null but partner_id present, try lookup in service_provider_profiles
    IF v_actual_provider_id IS NULL AND v_actual_partner_id IS NOT NULL THEN
        SELECT provider_id INTO v_actual_provider_id 
        FROM public.service_provider_profiles 
        WHERE partner_id = v_actual_partner_id;
    END IF;

    -- Lock the booking row for update (Atomic First-Accept-Wins)
    SELECT status INTO v_current_booking_status
    FROM public.service_bookings
    WHERE booking_id = v_booking_id
    FOR UPDATE;

    -- Check if still available for assignment
    IF v_current_booking_status IN ('PENDING', 'SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS') THEN
        -- A. Update service_bookings status to ACCEPTED and assign partner_id
        UPDATE public.service_bookings
        SET status = 'ACCEPTED',
            service_status = 'ACCEPTED',
            partner_id = v_actual_partner_id,
            updated_at = NOW()
        WHERE booking_id = v_booking_id;

        -- B. Create assignment record
        INSERT INTO public.booking_assignment (
            booking_id,
            partner_id,
            provider_id,
            assignment_method,
            status
        ) VALUES (
            v_booking_id,
            v_actual_partner_id,
            v_actual_provider_id,
            'FIRST_ACCEPT',
            'ASSIGNED'
        ) ON CONFLICT (booking_id) DO UPDATE
        SET partner_id = EXCLUDED.partner_id,
            provider_id = EXCLUDED.provider_id,
            status = 'ASSIGNED',
            assigned_at = NOW();

        -- C. Update accepted request
        UPDATE public.booking_requests
        SET response_status = 'Accepted', response_at = NOW()
        WHERE request_id = p_request_id;

        -- D. Auto-expire/reject remaining competing requests
        UPDATE public.booking_requests
        SET response_status = 'Expired', response_at = NOW()
        WHERE booking_id = v_booking_id AND request_id != p_request_id;

        -- E. Log status history
        INSERT INTO public.booking_status_history (
            booking_id,
            status,
            remarks
        ) VALUES (
            v_booking_id,
            'ACCEPTED',
            'Partner accepted the service request'
        );

        v_result := json_build_object(
            'success', true,
            'message', 'Service booking accepted successfully!',
            'booking_id', v_booking_id,
            'status', 'ACCEPTED'
        );
    ELSE
        -- Already claimed by another provider
        UPDATE public.booking_requests
        SET response_status = 'Expired', response_at = NOW()
        WHERE request_id = p_request_id;

        v_result := json_build_object(
            'success', false,
            'message', 'Booking has already been accepted by another technician.',
            'status', v_current_booking_status
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Overload for backward compatibility with 2-parameter callers
CREATE OR REPLACE FUNCTION public.atomic_accept_booking_request(
    p_request_id UUID,
    p_provider_id UUID
)
RETURNS JSON AS $$
BEGIN
    RETURN public.atomic_accept_booking_request(p_request_id, p_provider_id, p_provider_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Dispatch Booking Request to Eligible Nearby Providers
CREATE OR REPLACE FUNCTION public.create_service_booking_and_dispatch(
    p_customer_id UUID,
    p_service_id UUID,
    p_address_id UUID,
    p_booking_date DATE,
    p_scheduled_time TEXT,
    p_problem_description TEXT,
    p_estimated_amount DOUBLE PRECISION
)
RETURNS JSON AS $$
DECLARE
    v_booking_id UUID;
    v_provider_record RECORD;
    v_dispatched_count INTEGER := 0;
BEGIN
    -- 1. Insert new booking
    INSERT INTO public.service_bookings (
        customer_id,
        service_id,
        address_id,
        booking_date,
        scheduled_time,
        problem_description,
        estimated_amount,
        final_amount,
        status
    ) VALUES (
        p_customer_id,
        p_service_id,
        p_address_id,
        p_booking_date,
        p_scheduled_time,
        p_problem_description,
        p_estimated_amount,
        p_estimated_amount,
        'SEARCHING_PROVIDER'
    ) RETURNING booking_id INTO v_booking_id;

    -- 2. Log initial history
    INSERT INTO public.booking_status_history (
        booking_id,
        status,
        changed_by,
        remarks
    ) VALUES (
        v_booking_id,
        'SEARCHING_PROVIDER',
        p_customer_id,
        'Booking created, searching nearby verified providers'
    );

    -- 3. Find active verified providers and dispatch booking_requests
    FOR v_provider_record IN
        SELECT sp.provider_id
        FROM public.service_provider_profiles sp
        JOIN public.partners p ON sp.partner_id = p.partner_id
        JOIN public.users u ON p.user_id = u.user_id
        WHERE p.verification_status = 'VERIFIED'
          AND p.availability_status = 'ONLINE'
          AND u.is_active = true
    LOOP
        INSERT INTO public.booking_requests (
            booking_id,
            provider_id,
            response_status
        ) VALUES (
            v_booking_id,
            v_provider_record.provider_id,
            'Pending'
        );
        v_dispatched_count := v_dispatched_count + 1;
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'dispatched_count', v_dispatched_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shopkeeper_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_agent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_assignment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Allow public read & write policies for ServiceHub unified APIs
CREATE POLICY "Public read roles" ON public.roles FOR SELECT USING (true);
CREATE POLICY "Public read permissions" ON public.permissions FOR SELECT USING (true);
CREATE POLICY "Public read role_permissions" ON public.role_permissions FOR SELECT USING (true);

CREATE POLICY "Public access users" ON public.users FOR ALL USING (true);
CREATE POLICY "Public access user_profiles" ON public.user_profiles FOR ALL USING (true);
CREATE POLICY "Public access user_addresses" ON public.user_addresses FOR ALL USING (true);
CREATE POLICY "Public access user_devices" ON public.user_devices FOR ALL USING (true);

CREATE POLICY "Public access partners" ON public.partners FOR ALL USING (true);
CREATE POLICY "Public access service_provider_profiles" ON public.service_provider_profiles FOR ALL USING (true);
CREATE POLICY "Public access shopkeeper_profiles" ON public.shopkeeper_profiles FOR ALL USING (true);
CREATE POLICY "Public access delivery_agent_profiles" ON public.delivery_agent_profiles FOR ALL USING (true);
CREATE POLICY "Public access delivery_vehicles" ON public.delivery_vehicles FOR ALL USING (true);

CREATE POLICY "Public access verification_requests" ON public.verification_requests FOR ALL USING (true);
CREATE POLICY "Public access identity_documents" ON public.identity_documents FOR ALL USING (true);
CREATE POLICY "Public access document_files" ON public.document_files FOR ALL USING (true);
CREATE POLICY "Public access face_verifications" ON public.face_verifications FOR ALL USING (true);
CREATE POLICY "Public access shop_inspections" ON public.shop_inspections FOR ALL USING (true);
CREATE POLICY "Public access verification_history" ON public.verification_history FOR ALL USING (true);

CREATE POLICY "Public access service_categories" ON public.service_categories FOR ALL USING (true);
CREATE POLICY "Public access services" ON public.services FOR ALL USING (true);
CREATE POLICY "Public access service_variants" ON public.service_variants FOR ALL USING (true);
CREATE POLICY "Public access service_addons" ON public.service_addons FOR ALL USING (true);
CREATE POLICY "Public access service_requirements" ON public.service_requirements FOR ALL USING (true);

CREATE POLICY "Public access provider_services" ON public.provider_services FOR ALL USING (true);
CREATE POLICY "Public access provider_service_areas" ON public.provider_service_areas FOR ALL USING (true);
CREATE POLICY "Public access provider_availability" ON public.provider_availability FOR ALL USING (true);

CREATE POLICY "Public access ac_service_types" ON public.ac_service_types FOR ALL USING (true);
CREATE POLICY "Public access ac_service_reports" ON public.ac_service_reports FOR ALL USING (true);
CREATE POLICY "Public access ac_service_checklists" ON public.ac_service_checklists FOR ALL USING (true);
CREATE POLICY "Public access ac_service_photos" ON public.ac_service_photos FOR ALL USING (true);

CREATE POLICY "Public access service_bookings" ON public.service_bookings FOR ALL USING (true);
CREATE POLICY "Public access booking_requests" ON public.booking_requests FOR ALL USING (true);
CREATE POLICY "Public access booking_assignment" ON public.booking_assignment FOR ALL USING (true);
CREATE POLICY "Public access booking_status_history" ON public.booking_status_history FOR ALL USING (true);
CREATE POLICY "Public access booking_cancellations" ON public.booking_cancellations FOR ALL USING (true);
CREATE POLICY "Public access booking_location_logs" ON public.booking_location_logs FOR ALL USING (true);

CREATE POLICY "Public access shops" ON public.shops FOR ALL USING (true);
CREATE POLICY "Public access shop_services" ON public.shop_services FOR ALL USING (true);
CREATE POLICY "Public access shop_business_hours" ON public.shop_business_hours FOR ALL USING (true);
CREATE POLICY "Public access shop_images" ON public.shop_images FOR ALL USING (true);

CREATE POLICY "Public access product_categories" ON public.product_categories FOR ALL USING (true);
CREATE POLICY "Public access products" ON public.products FOR ALL USING (true);
CREATE POLICY "Public access inventory" ON public.inventory FOR ALL USING (true);
CREATE POLICY "Public access inventory_transactions" ON public.inventory_transactions FOR ALL USING (true);

CREATE POLICY "Public access orders" ON public.orders FOR ALL USING (true);
CREATE POLICY "Public access order_items" ON public.order_items FOR ALL USING (true);
CREATE POLICY "Public access order_status_history" ON public.order_status_history FOR ALL USING (true);
CREATE POLICY "Public access order_cancellations" ON public.order_cancellations FOR ALL USING (true);

CREATE POLICY "Public access delivery_assignments" ON public.delivery_assignments FOR ALL USING (true);
CREATE POLICY "Public access delivery_tracking" ON public.delivery_tracking FOR ALL USING (true);
CREATE POLICY "Public access delivery_status_history" ON public.delivery_status_history FOR ALL USING (true);
CREATE POLICY "Public access delivery_failures" ON public.delivery_failures FOR ALL USING (true);

CREATE POLICY "Public access payments" ON public.payments FOR ALL USING (true);
CREATE POLICY "Public access payment_transactions" ON public.payment_transactions FOR ALL USING (true);
CREATE POLICY "Public access refunds" ON public.refunds FOR ALL USING (true);
CREATE POLICY "Public access invoices" ON public.invoices FOR ALL USING (true);
CREATE POLICY "Public access partner_earnings" ON public.partner_earnings FOR ALL USING (true);
CREATE POLICY "Public access payouts" ON public.payouts FOR ALL USING (true);
CREATE POLICY "Public access commission_rules" ON public.commission_rules FOR ALL USING (true);

CREATE POLICY "Public access reviews" ON public.reviews FOR ALL USING (true);
CREATE POLICY "Public access review_replies" ON public.review_replies FOR ALL USING (true);

CREATE POLICY "Public access notifications" ON public.notifications FOR ALL USING (true);
CREATE POLICY "Public access notification_preferences" ON public.notification_preferences FOR ALL USING (true);
CREATE POLICY "Public access support_tickets" ON public.support_tickets FOR ALL USING (true);
CREATE POLICY "Public access support_messages" ON public.support_messages FOR ALL USING (true);

CREATE POLICY "Public access admin_profiles" ON public.admin_profiles FOR ALL USING (true);
CREATE POLICY "Public access admin_actions" ON public.admin_actions FOR ALL USING (true);
CREATE POLICY "Public access audit_logs" ON public.audit_logs FOR ALL USING (true);
CREATE POLICY "Public access system_settings" ON public.system_settings FOR ALL USING (true);
CREATE POLICY "Public access files" ON public.files FOR ALL USING (true);

-- =============================================================================
-- INITIAL SEED DATA
-- =============================================================================

-- 1. Insert Core Roles
INSERT INTO public.roles (role_name, description) VALUES
('customer', 'End-user customer who books services and orders products'),
('service_provider', 'Skilled technician or professional providing services'),
('shopkeeper', 'Local store vendor selling products on the marketplace'),
('delivery_agent', 'Delivery personnel delivering orders to customers'),
('admin', 'System administrator with oversight and moderation powers')
ON CONFLICT (role_name) DO NOTHING;

-- 2. Insert Standard Service Categories
INSERT INTO public.service_categories (category_id, name, description, icon, status) VALUES
('ac_service', 'AC Service', 'Professional AC installation, deep jet cleaning, repair, and gas refilling', 'hvac', 'ACTIVE'),
('care_taker', 'Care Taker', 'Elderly care, patient care, babysitting, and domestic assistance', 'elderly', 'ACTIVE'),
('laundry', 'Laundry', 'Washing, dry cleaning, ironing, and garment care services', 'local_laundry_service', 'ACTIVE'),
('car_service', 'Car Service', 'Car washing, mechanical inspection, oil change, and doorstep detailing', 'directions_car', 'ACTIVE'),
('plumbing', 'Plumbing', 'Pipe repair, tap installation, leakage fix, and water motor setup', 'plumbing', 'ACTIVE'),
('cooking', 'Cooking', 'Professional domestic cooks, chefs, and catering services', 'restaurant', 'ACTIVE')
ON CONFLICT (category_id) DO NOTHING;

-- 3. Insert Master Services Catalog
INSERT INTO public.services (category_id, name, description, base_price, duration_minutes, status) VALUES
('ac_service', 'Split AC Deep Cleaning (Jet Wash)', 'Complete indoor and outdoor unit jet cleaning with anti-bacterial treatment', 499.0, 45, 'ACTIVE'),
('ac_service', 'AC Gas Refill (R32 / R410A / R22)', 'Complete vacuuming, leakage check, and 100% full gas recharge', 1499.0, 60, 'ACTIVE'),
('ac_service', 'AC Installation & Uninstallation', 'Professional standard split or window AC wall mounting and piping setup', 899.0, 90, 'ACTIVE'),
('ac_service', 'AC Complete Diagnostic & Repair', 'In-depth troubleshooting for cooling issues, PCB faults, and noise inspection', 299.0, 30, 'ACTIVE'),
('care_taker', 'Elderly Care Assistant', 'Dedicated compassionate assistance for elderly mobility, hygiene, and companionship', 399.0, 240, 'ACTIVE'),
('care_taker', 'Patient Caretaker', 'Post-surgery, bedridden or specialized home recovery nursing assistance', 499.0, 360, 'ACTIVE'),
('care_taker', 'Babysitter & Childcare', 'Attentive, certified in-home babysitting and infant care service', 349.0, 180, 'ACTIVE'),
('laundry', 'Wash & Fold Laundry', 'Everyday garment washing, fabric softening, drying, and neat folding', 99.0, 120, 'ACTIVE'),
('laundry', 'Dry Cleaning & Steam Ironing', 'Premium care for suits, blazers, delicate silks, and formal wear', 199.0, 1440, 'ACTIVE'),
('car_service', 'Periodic Standard Service', 'Engine oil replacement, oil filter change, air filter cleaning, 30-point inspection', 1499.0, 120, 'ACTIVE'),
('car_service', 'Full Foam Wash & Interior Detailing', 'Deep exterior foam pressure wash, interior vacuuming, and dashboard polish', 899.0, 90, 'ACTIVE'),
('car_service', 'AC Servicing & Gas Refill', 'Cabin air filter cleaning, evaporator coil disinfectant wash, refrigerant top-up', 1199.0, 60, 'ACTIVE'),
('plumbing', 'Tap & Pipe Leakage Repair', 'Fix leaking faucets, showerheads, mixer taps, and pipeline joints', 249.0, 45, 'ACTIVE'),
('plumbing', 'Toilet & Sanitaryware Installation', 'Western commode, flush tank, washbasin, and drainage line setup', 449.0, 90, 'ACTIVE'),
('plumbing', 'Water Tank & Motor Repair', 'Submersible pump diagnosis, water inlet repair, and overhead tank piping', 499.0, 60, 'ACTIVE'),
('cooking', 'Daily Domestic Home Cook (2 Meals)', 'Fresh home-style cooking for family according to your taste and dietary preferences', 399.0, 90, 'ACTIVE'),
('cooking', 'Special Event & Party Chef', 'Multi-course specialty dining prep for festive occasions and family gatherings', 999.0, 180, 'ACTIVE'),
('cooking', 'Jain & Diet Specific Meal Prep', 'Pure vegetarian preparation with strict adherence to Jain/Swaminarayan rules', 449.0, 90, 'ACTIVE')
ON CONFLICT DO NOTHING;

-- 4. Insert Default System Settings
INSERT INTO public.system_settings (setting_key, setting_value, description) VALUES
('platform_commission_service_percent', '15.0', 'Platform commission percentage on completed service bookings'),
('platform_commission_delivery_percent', '10.0', 'Platform commission percentage on delivery agent earnings'),
('service_radius_default_km', '10.0', 'Default service radius for provider dispatch in km'),
('support_emergency_helpline', '+91 1800 123 4567', '24x7 customer and partner emergency support phone')
ON CONFLICT (setting_key) DO NOTHING;

-- 5. Insert Primary System Administrator (admin@gmail.com / Admin@123)
DO $$
DECLARE
    v_admin_role_id UUID;
    v_admin_user_id UUID := '00000000-0000-0000-0000-000000000001'::UUID;
BEGIN
    SELECT role_id INTO v_admin_role_id FROM public.roles WHERE role_name = 'admin';

    IF v_admin_role_id IS NOT NULL THEN
        -- Insert Master Admin into users table
        INSERT INTO public.users (
            user_id,
            role_id,
            username,
            email,
            phone,
            account_status,
            is_active
        ) VALUES (
            v_admin_user_id,
            v_admin_role_id,
            'admin',
            'admin@gmail.com',
            '+91 99999 00000',
            'ACTIVE',
            true
        ) ON CONFLICT (email) DO NOTHING;

        -- Insert into user_profiles
        INSERT INTO public.user_profiles (
            user_id,
            first_name,
            last_name
        ) VALUES (
            v_admin_user_id,
            'System',
            'Administrator'
        ) ON CONFLICT (user_id) DO NOTHING;

        -- Insert into admin_profiles
        INSERT INTO public.admin_profiles (
            user_id,
            admin_level,
            status
        ) VALUES (
            v_admin_user_id,
            'SUPER_ADMIN',
            'ACTIVE'
        ) ON CONFLICT (user_id) DO NOTHING;
    END IF;
END $$;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) & ACCESS POLICIES
-- =============================================================================

-- Enable RLS on spatial_ref_sys (PostGIS internal table) & allow public read access
ALTER TABLE IF EXISTS public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
          AND tablename = 'spatial_ref_sys' 
          AND policyname = 'Public read spatial_ref_sys'
    ) THEN
        CREATE POLICY "Public read spatial_ref_sys" 
        ON public.spatial_ref_sys 
        FOR SELECT 
        USING (true);
    END IF;
END $$;

-- Enable RLS on all public tables & ensure standard public access policy exists
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', tbl.tablename);
        
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = tbl.tablename
        ) THEN
            EXECUTE format('CREATE POLICY "Public access %I" ON public.%I FOR ALL TO public USING (true) WITH CHECK (true);', tbl.tablename, tbl.tablename);
        END IF;
    END LOOP;
END $$;

-- =============================================================================
-- POSTGREST & SUPABASE ACCESS PERMISSIONS
-- Grants USAGE and ALL privileges on public schema to anon, authenticated, service_role
-- =============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- =============================================================================
-- MODULE 26: CUSTOMER WALLET & ATOMIC TRANSACTION LOGIC
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.customer_wallets (
    wallet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    balance NUMERIC(10, 2) NOT NULL DEFAULT 30.00 CHECK (balance >= 0),
    currency TEXT NOT NULL DEFAULT 'INR',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.customer_wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public access customer_wallets" ON public.customer_wallets FOR ALL TO public USING (true) WITH CHECK (true);

-- Atomic wallet deduction RPC with backend authoritative validation & double-spend protection
CREATE OR REPLACE FUNCTION public.apply_wallet_deduction_atomic(
    p_user_id UUID,
    p_requested_deduction NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_bal NUMERIC;
    v_actual_deduction NUMERIC;
BEGIN
    SELECT balance INTO v_current_bal
    FROM public.customer_wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        -- If no wallet row yet, create one with default ₹30 balance
        INSERT INTO public.customer_wallets (user_id, balance)
        VALUES (p_user_id, 30.00)
        RETURNING balance INTO v_current_bal;
    END IF;

    -- Authoritative backend calculation: min(requested, actual balance)
    v_actual_deduction := LEAST(GREATEST(p_requested_deduction, 0), v_current_bal);

    -- Atomic debit with double-spend protection
    IF v_actual_deduction > 0 THEN
        UPDATE public.customer_wallets
        SET balance = balance - v_actual_deduction,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    RETURN v_actual_deduction;
END;
$$;

-- =============================================================================
-- DISPATCH ENGINE & REDISPATCH ON PARTNER ONLINE
-- =============================================================================

CREATE OR REPLACE FUNCTION public.find_and_dispatch_eligible_partners(p_booking_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_booking RECORD;
    v_service RECORD;
    v_req_role TEXT;
    v_req_cap TEXT;
    v_candidate RECORD;
    v_dispatched_count INTEGER := 0;
BEGIN
    SELECT * INTO v_booking FROM public.service_bookings WHERE booking_id = p_booking_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Booking not found');
    END IF;

    SELECT * INTO v_service FROM public.services WHERE service_id = v_booking.service_id;
    v_req_cap := COALESCE(v_service.category_id, 'ac_service');

    IF v_req_cap = 'laundry' THEN
        v_req_role := 'shopkeeper';
    ELSE
        v_req_role := 'service_provider';
    END IF;

    UPDATE public.service_bookings 
    SET status = 'SEARCHING_PROVIDER', service_status = 'SEARCHING_PROVIDER', updated_at = NOW()
    WHERE booking_id = p_booking_id;

    IF v_req_role = 'service_provider' THEN
        FOR v_candidate IN
            SELECT p.partner_id, spp.provider_id, u.user_id,
                   COALESCE(pll.latitude, 22.4707) AS lat,
                   COALESCE(pll.longitude, 70.0577) AS lng
            FROM public.partners p
            JOIN public.users u ON u.user_id = p.user_id
            JOIN public.roles r ON r.role_id = u.role_id
            JOIN public.service_provider_profiles spp ON spp.partner_id = p.partner_id
            LEFT JOIN public.partner_live_locations pll ON pll.partner_id = p.partner_id
            WHERE r.role_name = 'service_provider'
              AND UPPER(p.verification_status) IN ('VERIFIED', 'APPROVED')
              AND UPPER(p.availability_status) IN ('ONLINE', 'AVAILABLE')
              AND u.is_active = true
              AND u.account_status = 'ACTIVE'
              AND (
                  EXISTS (
                      SELECT 1 FROM public.provider_services ps
                      JOIN public.services s ON s.service_id = ps.service_id
                      WHERE ps.provider_id = spp.provider_id
                        AND ps.is_available = true
                        AND (s.category_id = v_req_cap OR s.service_id = v_booking.service_id)
                  )
                  OR (v_req_cap = 'ac_service' AND (spp.about ILIKE '%AC%' OR spp.about ILIKE '%Air%'))
                  OR NOT EXISTS (SELECT 1 FROM public.provider_services ps_any WHERE ps_any.provider_id = spp.provider_id)
              )
              AND (
                  v_booking.customer_latitude IS NULL OR
                  (6371 * acos(
                      least(1.0, greatest(-1.0, 
                          cos(radians(v_booking.customer_latitude)) * cos(radians(COALESCE(pll.latitude, 22.4707))) *
                          cos(radians(COALESCE(pll.longitude, 70.0577)) - radians(v_booking.customer_longitude)) +
                          sin(radians(v_booking.customer_latitude)) * sin(radians(COALESCE(pll.latitude, 22.4707)))
                      ))
                  )) <= 15.0
              )
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_assignment ba
                  JOIN public.service_bookings sb ON sb.booking_id = ba.booking_id
                  WHERE (ba.provider_id = spp.provider_id OR ba.partner_id = p.partner_id)
                    AND ba.status IN ('ASSIGNED', 'IN_PROGRESS')
                    AND sb.status IN ('ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'SERVICE_STARTED')
                    AND sb.booking_date = v_booking.booking_date
                    AND (v_booking.scheduled_time IS NULL OR sb.scheduled_time = v_booking.scheduled_time)
              )
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_requests br
                  WHERE br.booking_id = p_booking_id AND (br.partner_id = p.partner_id OR br.provider_id = spp.provider_id)
              )
            LIMIT 15
        LOOP
            INSERT INTO public.booking_requests (
                booking_id,
                partner_id,
                provider_id,
                required_role,
                required_capability,
                response_status,
                sent_at,
                expires_at
            ) VALUES (
                p_booking_id,
                v_candidate.partner_id,
                v_candidate.provider_id,
                v_req_role,
                v_req_cap,
                'Pending',
                NOW(),
                NOW() + INTERVAL '10 minutes'
            );
            v_dispatched_count := v_dispatched_count + 1;
        END LOOP;

    ELSIF v_req_role = 'shopkeeper' THEN
        FOR v_candidate IN
            SELECT p.partner_id, skp.shopkeeper_id, u.user_id
            FROM public.partners p
            JOIN public.users u ON u.user_id = p.user_id
            JOIN public.roles r ON r.role_id = u.role_id
            JOIN public.shopkeeper_profiles skp ON skp.partner_id = p.partner_id
            JOIN public.shops sh ON sh.shopkeeper_id = skp.shopkeeper_id
            WHERE r.role_name = 'shopkeeper'
              AND UPPER(p.verification_status) IN ('VERIFIED', 'APPROVED')
              AND UPPER(p.availability_status) IN ('ONLINE', 'AVAILABLE')
              AND u.is_active = true
              AND (
                  sh.shop_type ILIKE '%LAUNDRY%' OR EXISTS (
                      SELECT 1 FROM public.shop_services ss
                      JOIN public.services s ON s.service_id = ss.service_id
                      WHERE ss.shop_id = sh.shop_id AND s.category_id = 'laundry'
                  )
              )
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_requests br
                  WHERE br.booking_id = p_booking_id AND br.partner_id = p.partner_id
              )
            LIMIT 15
        LOOP
            INSERT INTO public.booking_requests (
                booking_id,
                partner_id,
                required_role,
                required_capability,
                response_status,
                sent_at,
                expires_at
            ) VALUES (
                p_booking_id,
                v_candidate.partner_id,
                v_req_role,
                v_req_cap,
                'Pending',
                NOW(),
                NOW() + INTERVAL '10 minutes'
            );
            v_dispatched_count := v_dispatched_count + 1;
        END LOOP;
    END IF;

    IF v_dispatched_count > 0 THEN
        UPDATE public.service_bookings 
        SET status = 'OFFERED_TO_PROVIDERS', service_status = 'OFFERED_TO_PROVIDERS', updated_at = NOW()
        WHERE booking_id = p_booking_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'dispatched_count', v_dispatched_count,
        'required_role', v_req_role,
        'required_capability', v_req_cap
    );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.dispatch_pending_bookings_for_partner(p_partner_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_partner RECORD;
    v_role_name TEXT;
    v_provider_id UUID;
    v_shopkeeper_id UUID;
    v_booking RECORD;
    v_dispatched_count INTEGER := 0;
BEGIN
    SELECT p.*, r.role_name INTO v_partner
    FROM public.partners p
    JOIN public.users u ON u.user_id = p.user_id
    JOIN public.roles r ON r.role_id = u.role_id
    WHERE p.partner_id = p_partner_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Partner not found');
    END IF;

    IF UPPER(COALESCE(v_partner.availability_status, '')) NOT IN ('ONLINE', 'AVAILABLE') 
       OR UPPER(COALESCE(v_partner.verification_status, '')) NOT IN ('VERIFIED', 'APPROVED') THEN
        RETURN jsonb_build_object('success', true, 'dispatched_count', 0, 'reason', 'Partner not online or not verified');
    END IF;

    v_role_name := v_partner.role_name;

    IF v_role_name = 'service_provider' THEN
        SELECT provider_id INTO v_provider_id 
        FROM public.service_provider_profiles 
        WHERE partner_id = p_partner_id;

        FOR v_booking IN
            SELECT sb.booking_id, sb.service_id, COALESCE(s.category_id, 'ac_service') AS category_id
            FROM public.service_bookings sb
            JOIN public.services s ON s.service_id = sb.service_id
            WHERE sb.status IN ('SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING')
              AND sb.partner_id IS NULL
              AND s.category_id != 'laundry'
              AND (
                  EXISTS (
                      SELECT 1 FROM public.provider_services ps
                      WHERE ps.provider_id = v_provider_id
                        AND ps.is_available = true
                        AND (ps.service_id = sb.service_id OR EXISTS (
                            SELECT 1 FROM public.services s2 
                            WHERE s2.service_id = ps.service_id AND s2.category_id = s.category_id
                        ))
                  )
                  OR (s.category_id = 'ac_service' AND EXISTS (
                      SELECT 1 FROM public.service_provider_profiles spp 
                      WHERE spp.provider_id = v_provider_id AND (spp.about ILIKE '%AC%' OR spp.about ILIKE '%Air%'))
                  )
                  OR NOT EXISTS (SELECT 1 FROM public.provider_services ps_any WHERE ps_any.provider_id = v_provider_id)
              )
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_requests br
                  WHERE br.booking_id = sb.booking_id 
                    AND (br.partner_id = p_partner_id OR (v_provider_id IS NOT NULL AND br.provider_id = v_provider_id))
              )
            ORDER BY sb.created_at DESC
            LIMIT 15
        LOOP
            INSERT INTO public.booking_requests (
                booking_id,
                partner_id,
                provider_id,
                required_role,
                required_capability,
                response_status,
                sent_at,
                expires_at
            ) VALUES (
                v_booking.booking_id,
                p_partner_id,
                v_provider_id,
                'service_provider',
                v_booking.category_id,
                'Pending',
                NOW(),
                NOW() + INTERVAL '10 minutes'
            );

            UPDATE public.service_bookings 
            SET status = 'OFFERED_TO_PROVIDERS', service_status = 'OFFERED_TO_PROVIDERS', updated_at = NOW()
            WHERE booking_id = v_booking.booking_id AND status = 'SEARCHING_PROVIDER';

            v_dispatched_count := v_dispatched_count + 1;
        END LOOP;

    ELSIF v_role_name = 'shopkeeper' THEN
        SELECT shopkeeper_id INTO v_shopkeeper_id 
        FROM public.shopkeeper_profiles 
        WHERE partner_id = p_partner_id;

        FOR v_booking IN
            SELECT sb.booking_id, sb.service_id, s.category_id
            FROM public.service_bookings sb
            JOIN public.services s ON s.service_id = sb.service_id
            WHERE sb.status IN ('SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING')
              AND sb.partner_id IS NULL
              AND s.category_id = 'laundry'
              AND NOT EXISTS (
                  SELECT 1 FROM public.booking_requests br
                  WHERE br.booking_id = sb.booking_id AND br.partner_id = p_partner_id
              )
            ORDER BY sb.created_at DESC
            LIMIT 15
        LOOP
            INSERT INTO public.booking_requests (
                booking_id,
                partner_id,
                required_role,
                required_capability,
                response_status,
                sent_at,
                expires_at
            ) VALUES (
                v_booking.booking_id,
                p_partner_id,
                'shopkeeper',
                'laundry',
                'Pending',
                NOW(),
                NOW() + INTERVAL '10 minutes'
            );

            UPDATE public.service_bookings 
            SET status = 'OFFERED_TO_PROVIDERS', service_status = 'OFFERED_TO_PROVIDERS', updated_at = NOW()
            WHERE booking_id = v_booking.booking_id AND status = 'SEARCHING_PROVIDER';

            v_dispatched_count := v_dispatched_count + 1;
        END LOOP;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'partner_id', p_partner_id,
        'dispatched_count', v_dispatched_count
    );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION public.trig_partner_online_redispatch()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.availability_status IS NOT NULL 
       AND UPPER(NEW.availability_status) IN ('ONLINE', 'AVAILABLE') 
       AND (OLD.availability_status IS NULL OR UPPER(OLD.availability_status) NOT IN ('ONLINE', 'AVAILABLE')) THEN
        PERFORM public.dispatch_pending_bookings_for_partner(NEW.partner_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS tr_partner_online_redispatch ON public.partners;
CREATE TRIGGER tr_partner_online_redispatch
    AFTER UPDATE OF availability_status ON public.partners
    FOR EACH ROW
    EXECUTE FUNCTION public.trig_partner_online_redispatch();

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_bookings;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.booking_requests;
EXCEPTION WHEN others THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.partners;
EXCEPTION WHEN others THEN NULL;
END $$;

GRANT EXECUTE ON FUNCTION public.find_and_dispatch_eligible_partners(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.dispatch_pending_bookings_for_partner(UUID) TO authenticated, anon;


