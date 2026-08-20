-- =======================================================
-- SERVICEHUB MASTER DATABASE SCHEMA (SUPABASE POSTGRESQL + POSTGIS)
-- =======================================================

-- Enable PostGIS extension for hyperlocal geofencing
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. PROFILES TABLE (Holds roles: customer, partner, admin)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('customer', 'partner', 'admin')),
    name TEXT,
    phone TEXT,
    avatar_url TEXT,
    latitude DOUBLE PRECISION DEFAULT 12.9103,
    longitude DOUBLE PRECISION DEFAULT 77.6433,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to profiles" 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Allow users to update their own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. PROVIDERS TABLE (Detailed provider registration & verification state)
CREATE TABLE IF NOT EXISTS public.providers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_category TEXT NOT NULL,
    skills TEXT[] DEFAULT '{}',
    experience_years INTEGER DEFAULT 1,
    service_radius_km DOUBLE PRECISION DEFAULT 5.0,
    verification_status TEXT CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED')) DEFAULT 'PENDING',
    is_active BOOLEAN DEFAULT true,
    is_available BOOLEAN DEFAULT true,
    rating DOUBLE PRECISION DEFAULT 5.0,
    completed_jobs INTEGER DEFAULT 0,
    current_lat DOUBLE PRECISION DEFAULT 12.9103,
    current_lng DOUBLE PRECISION DEFAULT 77.6433,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on providers
ALTER TABLE public.providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to providers" 
    ON public.providers FOR SELECT USING (true);

CREATE POLICY "Allow providers to update their own record" 
    ON public.providers FOR UPDATE USING (auth.uid() = id);

-- 3. SERVICES CATALOG TABLE
CREATE TABLE IF NOT EXISTS public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on services
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to services" 
    ON public.services FOR SELECT USING (true);

CREATE POLICY "Allow admin only edits to services" 
    ON public.services FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 4. PRODUCTS CATALOG TABLE (With location coordinates for geofencing)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION NOT NULL,
    original_price DOUBLE PRECISION,
    discount TEXT,
    category TEXT NOT NULL,
    stock INTEGER DEFAULT 10,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to products" 
    ON public.products FOR SELECT USING (true);

CREATE POLICY "Allow seller to edit their own products" 
    ON public.products FOR ALL USING (auth.uid() = seller_id);

-- 5. BOOKINGS TABLE (Service bookings)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_code TEXT UNIQUE NOT NULL DEFAULT ('SHB' || FLOOR(10000000 + RANDOM() * 90000000)::TEXT),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    provider_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    service_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'ac_service',
    issue_description TEXT,
    photo_url TEXT,
    scheduled_date TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    payment_method TEXT DEFAULT 'Cash on Service',
    price DOUBLE PRECISION NOT NULL,
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
        'EXPIRED',
        'NO_PROVIDER_FOUND'
    )) DEFAULT 'SEARCHING_PROVIDER',
    entrance_pin TEXT DEFAULT '7429',
    completion_otp TEXT DEFAULT '5892',
    customer_lat DOUBLE PRECISION,
    customer_lng DOUBLE PRECISION,
    provider_lat DOUBLE PRECISION,
    provider_lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS on bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public select on bookings" ON public.bookings FOR SELECT USING (true);
CREATE POLICY "Allow public insert on bookings" ON public.bookings FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on bookings" ON public.bookings FOR UPDATE USING (true);

-- 6. BOOKING OFFERS TABLE (Multi-provider bidding / notification tracking)
CREATE TABLE IF NOT EXISTS public.booking_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES public.bookings(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED', 'ALREADY_ASSIGNED')) DEFAULT 'PENDING',
    distance_km DOUBLE PRECISION DEFAULT 2.3,
    estimated_earning DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS on booking_offers
ALTER TABLE public.booking_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public select on booking_offers" ON public.booking_offers FOR SELECT USING (true);
CREATE POLICY "Allow public insert on booking_offers" ON public.booking_offers FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on booking_offers" ON public.booking_offers FOR UPDATE USING (true);

-- 7. ORDERS TABLE (Product delivery orders)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    agent_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('Placed', 'Packing', 'Ready for Pickup', 'Out for Delivery', 'Delivered', 'Cancelled', 'CANCELLED_BY_CUSTOMER', 'CANCELLED_BY_PROVIDER')) DEFAULT 'Placed',
    items_summary TEXT,
    subtotal DOUBLE PRECISION NOT NULL,
    delivery_fee DOUBLE PRECISION NOT NULL,
    grand_total DOUBLE PRECISION NOT NULL,
    delivery_pin TEXT DEFAULT '2842',
    shipping_address TEXT,
    customer_lat DOUBLE PRECISION,
    customer_lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on orders" ON public.orders FOR SELECT USING (true);
CREATE POLICY "Allow public insert on orders" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on orders" ON public.orders FOR UPDATE USING (true);

-- 8. CUSTOMER LOCATIONS / SAVED ADDRESSES TABLE
CREATE TABLE IF NOT EXISTS public.customer_locations (
    id TEXT PRIMARY KEY,
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT NOT NULL,
    area TEXT,
    city TEXT,
    state TEXT,
    country TEXT DEFAULT 'India',
    postal_code TEXT,
    address_type TEXT DEFAULT 'home',
    is_for_someone_else BOOLEAN DEFAULT false,
    recipient_name TEXT,
    recipient_phone TEXT,
    house_number TEXT,
    landmark TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on customer_locations
ALTER TABLE public.customer_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on customer_locations" ON public.customer_locations FOR SELECT USING (true);
CREATE POLICY "Allow public insert on customer_locations" ON public.customer_locations FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on customer_locations" ON public.customer_locations FOR UPDATE USING (true);
CREATE POLICY "Allow public delete on customer_locations" ON public.customer_locations FOR DELETE USING (true);

-- 9. SUPPORT TICKETS TABLE
CREATE TABLE IF NOT EXISTS public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public select on tickets" ON public.tickets FOR SELECT USING (true);
CREATE POLICY "Allow public insert on tickets" ON public.tickets FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on tickets" ON public.tickets FOR UPDATE USING (true);

-- =======================================================
-- ATOMIC FIRST-ACCEPT-WINS BACKEND TRANSACTION LOGIC
-- =======================================================

-- Procedure: Atomic acceptance of a booking offer by a provider
CREATE OR REPLACE FUNCTION accept_booking_offer(
    p_booking_id UUID,
    p_provider_id UUID
)
RETURNS JSON AS $$
DECLARE
    v_current_status TEXT;
    v_result JSON;
BEGIN
    -- Perform row-level locking on the target booking record
    SELECT status INTO v_current_status
    FROM public.bookings
    WHERE id = p_booking_id
    FOR UPDATE;

    -- Verify if booking is still available for assignment
    IF v_current_status IN ('Pending', 'SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS') THEN
        -- 1. Assign provider and transition booking status to ACCEPTED
        UPDATE public.bookings
        SET 
            provider_id = p_provider_id,
            status = 'ACCEPTED',
            accepted_at = NOW()
        WHERE id = p_booking_id;

        -- 2. Mark winning provider's offer as ACCEPTED
        UPDATE public.booking_offers
        SET status = 'ACCEPTED', responded_at = NOW()
        WHERE booking_id = p_booking_id AND provider_id = p_provider_id;

        -- 3. Mark all other competing providers' offers as ALREADY_ASSIGNED
        UPDATE public.booking_offers
        SET status = 'ALREADY_ASSIGNED', responded_at = NOW()
        WHERE booking_id = p_booking_id AND provider_id != p_provider_id;

        v_result := json_build_object(
            'success', true,
            'message', 'Booking assigned successfully',
            'status', 'ACCEPTED'
        );
    ELSE
        -- Booking was already claimed by another provider
        UPDATE public.booking_offers
        SET status = 'ALREADY_ASSIGNED', responded_at = NOW()
        WHERE booking_id = p_booking_id AND provider_id = p_provider_id;

        v_result := json_build_object(
            'success', false,
            'message', 'Booking already accepted by another professional.',
            'status', v_current_status
        );
    END IF;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Procedure: Create booking request and dispatch to nearby verified providers
CREATE OR REPLACE FUNCTION create_booking_request(
    p_customer_id UUID,
    p_service_name TEXT,
    p_category TEXT,
    p_scheduled_date TEXT,
    p_scheduled_time TEXT,
    p_price DOUBLE PRECISION,
    p_customer_lat DOUBLE PRECISION,
    p_customer_lng DOUBLE PRECISION,
    p_notes TEXT DEFAULT ''
)
RETURNS JSON AS $$
DECLARE
    v_booking_id UUID;
    v_provider_record RECORD;
    v_offer_count INTEGER := 0;
BEGIN
    -- 1. Insert new booking with SEARCHING_PROVIDER status
    INSERT INTO public.bookings (
        customer_id,
        service_name,
        category,
        scheduled_date,
        scheduled_time,
        price,
        customer_lat,
        customer_lng,
        issue_description,
        status
    ) VALUES (
        p_customer_id,
        p_service_name,
        p_category,
        p_scheduled_date,
        p_scheduled_time,
        p_price,
        p_customer_lat,
        p_customer_lng,
        p_notes,
        'SEARCHING_PROVIDER'
    ) RETURNING id INTO v_booking_id;

    -- 2. Find eligible verified & active providers nearby and dispatch offers
    FOR v_provider_record IN
        SELECT id 
        FROM public.providers
        WHERE verification_status = 'VERIFIED'
          AND is_active = true
          AND is_available = true
    LOOP
        INSERT INTO public.booking_offers (
            booking_id,
            provider_id,
            distance_km,
            estimated_earning,
            status
        ) VALUES (
            v_booking_id,
            v_provider_record.id,
            2.3,
            p_price * 0.85,
            'PENDING'
        );
        v_offer_count := v_offer_count + 1;
    END LOOP;

    RETURN json_build_object(
        'success', true,
        'booking_id', v_booking_id,
        'offers_sent', v_offer_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create a public profile automatically when a user signs up via auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Seed data for testing products
INSERT INTO public.products (name, description, price, original_price, discount, category, latitude, longitude)
VALUES 
('AC Dust Filter (Universal)', 'Universal high performance AC filter', 349, 499, '30% OFF', 'AC', 12.9103, 77.6433),
('Pipe Repair Tape 5m', 'Waterproof heavy-duty repair tape', 89, 120, '26% OFF', 'Plumbing', 12.9110, 77.6420),
('Car Shampoo 500ml', 'Premium wax-infused car cleaner', 199, 299, '33% OFF', 'Car', 12.9090, 77.6450),
('3-Tier Tiffin Box', 'Stainless steel insulated lunch box', 449, 599, '25% OFF', 'Cooking', 12.9130, 77.6410)
ON CONFLICT DO NOTHING;
