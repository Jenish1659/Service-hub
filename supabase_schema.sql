-- ServiceHub Supabase Database Schema
-- Phase 2: Database Design & RLS Policies
-- Target: Supabase (PostgreSQL with PostGIS and Realtime)

-- =========================================================================
-- 1. EXTENSIONS & SCHEMA SETUP
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- Crucial for 5km geofencing and GPS radius checks

-- =========================================================================
-- 2. CUSTOM TYPES AND ENUMS
-- =========================================================================
CREATE TYPE user_role AS ENUM ('customer', 'partner', 'admin');
CREATE TYPE partner_role AS ENUM ('shopkeeper', 'service_provider');
CREATE TYPE booking_status AS ENUM ('created', 'accepted', 'en_route', 'active', 'completed', 'cancelled');
CREATE TYPE order_status AS ENUM ('placed', 'accepted', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

-- =========================================================================
-- 3. CORE PLATFORM TABLES
-- =========================================================================

-- Central profiles table linked to Supabase Auth
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    phone_number TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'customer',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Customer Profiles
CREATE TABLE public.customers (
    id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    avatar_url TEXT,
    default_address TEXT,
    default_lat DECIMAL(9,6),
    default_lon DECIMAL(9,6),
    rating DECIMAL(2,1) DEFAULT 5.0,
    total_bookings INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Partner / Business Profiles (Shopkeepers & Service Providers)
CREATE TABLE public.partners (
    id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    business_name TEXT NOT NULL,
    partner_type partner_role NOT NULL,
    logo_url TEXT,
    address TEXT,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    is_online BOOLEAN DEFAULT false NOT NULL,
    kyc_verified BOOLEAN DEFAULT false NOT NULL,
    rating DECIMAL(3,2) DEFAULT 5.00,
    total_jobs INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Delivery Agent Profiles
CREATE TABLE public.delivery_agents (
    id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    vehicle_number TEXT NOT NULL,
    vehicle_type TEXT NOT NULL, -- bike, cycle, etc.
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    is_online BOOLEAN DEFAULT false NOT NULL,
    kyc_verified BOOLEAN DEFAULT false NOT NULL,
    rating DECIMAL(3,2) DEFAULT 5.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 4. SERVICES & INVENTORY TABLES
-- =========================================================================

-- Service Categories (e.g. Hardware Services, Plumbing, Cooking, Laundry, Car Service)
CREATE TABLE public.service_categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL
);

-- Product Categories (e.g. Supplies, Tools, Spare Parts)
CREATE TABLE public.product_categories (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL
);

-- Services offered by Service Providers
CREATE TABLE public.services (
    id BIGSERIAL PRIMARY KEY,
    provider_id UUID REFERENCES public.partners(id) ON DELETE CASCADE NOT NULL,
    category_id BIGINT REFERENCES public.service_categories(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    visiting_charge DECIMAL(10,2) NOT NULL,
    price_range_min DECIMAL(10,2) NOT NULL,
    price_range_max DECIMAL(10,2) NOT NULL,
    is_available BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Products offered by Shopkeepers
CREATE TABLE public.products (
    id BIGSERIAL PRIMARY KEY,
    shop_id UUID REFERENCES public.partners(id) ON DELETE CASCADE NOT NULL,
    category_id BIGINT REFERENCES public.product_categories(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    compare_at_price DECIMAL(10,2), -- Strikethrough price
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 5. TRANSACTIONAL TABLES (BOOKINGS & ORDERS)
-- =========================================================================

-- Service Bookings
CREATE TABLE public.bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) NOT NULL,
    provider_id UUID REFERENCES public.partners(id) NOT NULL,
    service_id BIGINT REFERENCES public.services(id) NOT NULL,
    status booking_status NOT NULL DEFAULT 'created',
    scheduled_date DATE NOT NULL,
    scheduled_time_slot TEXT NOT NULL,
    description_issue TEXT,
    photo_urls TEXT[] DEFAULT '{}',
    visiting_charge DECIMAL(10,2) NOT NULL,
    estimated_total DECIMAL(10,2) NOT NULL,
    final_total DECIMAL(10,2),
    completion_otp TEXT NOT NULL, -- Secure OTP sent to customer
    customer_lat DECIMAL(9,6) NOT NULL,
    customer_lon DECIMAL(9,6) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Product Orders
CREATE TABLE public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) NOT NULL,
    shop_id UUID REFERENCES public.partners(id) NOT NULL,
    delivery_agent_id UUID REFERENCES public.delivery_agents(id),
    status order_status NOT NULL DEFAULT 'placed',
    subtotal DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    customer_lat DECIMAL(9,6) NOT NULL,
    customer_lon DECIMAL(9,6) NOT NULL,
    pickup_pin VARCHAR(4) NOT NULL,      -- Unlocks at <= 5m from shop
    delivery_pin VARCHAR(4) NOT NULL,    -- Unlocks at <= 5m from customer
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Product Order Items
CREATE TABLE public.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
    product_id BIGINT REFERENCES public.products(id) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_per_item DECIMAL(10,2) NOT NULL
);

-- Payments Ledger
CREATE TABLE public.payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID REFERENCES public.orders(id),
    booking_id UUID REFERENCES public.bookings(id),
    payment_method TEXT NOT NULL, -- cash_on_delivery, online
    payment_status payment_status NOT NULL DEFAULT 'pending',
    transaction_id TEXT,
    amount DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT one_target CHECK (
        (order_id IS NOT NULL AND booking_id IS NULL) OR 
        (booking_id IS NOT NULL AND order_id IS NULL)
    )
);

-- =========================================================================
-- 6. DISPUTES, REVIEWS, & REALTIME CHATS
-- =========================================================================

-- Reviews & Ratings
CREATE TABLE public.reviews (
    id BIGSERIAL PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) NOT NULL,
    provider_id UUID REFERENCES public.partners(id),
    product_id BIGINT REFERENCES public.products(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT one_subject CHECK (
        (provider_id IS NOT NULL AND product_id IS NULL) OR 
        (product_id IS NOT NULL AND provider_id IS NULL)
    )
);

-- Chat Channels (Direct user-to-user and customer-to-admin chats)
CREATE TABLE public.chats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES public.bookings(id),
    order_id UUID REFERENCES public.orders(id),
    sender_id UUID REFERENCES public.users(id) NOT NULL,
    receiver_id UUID REFERENCES public.users(id) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Support Tickets / Complaints
CREATE TABLE public.complaints (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    booking_id UUID REFERENCES public.bookings(id),
    order_id UUID REFERENCES public.orders(id),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open' NOT NULL, -- open, investigating, resolved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Earnings Ledger (Commission calculation)
CREATE TABLE public.earnings (
    id BIGSERIAL PRIMARY KEY,
    partner_id UUID REFERENCES public.partners(id) ON DELETE CASCADE,
    agent_id UUID REFERENCES public.delivery_agents(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES public.bookings(id),
    order_id UUID REFERENCES public.orders(id),
    gross_amount DECIMAL(10,2) NOT NULL,
    commission_deducted DECIMAL(10,2) NOT NULL,
    net_payout DECIMAL(10,2) NOT NULL,
    is_settled BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT one_recipient CHECK (
        (partner_id IS NOT NULL AND agent_id IS NULL) OR 
        (agent_id IS NOT NULL AND partner_id IS NULL)
    )
);

-- Global System Configurations (Commissions, Service fees)
CREATE TABLE public.commissions (
    id SERIAL PRIMARY KEY,
    service_commission_rate DECIMAL(4,2) DEFAULT 10.00 NOT NULL, -- e.g., 10%
    product_commission_rate DECIMAL(4,2) DEFAULT 8.00 NOT NULL,   -- e.g., 8%
    base_delivery_fee DECIMAL(10,2) DEFAULT 30.00 NOT NULL,
    platform_fee DECIMAL(10,2) DEFAULT 5.00 NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 7. SECURITY & RLS POLICIES
-- =========================================================================

-- Enable RLS on all public tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.earnings ENABLE ROW LEVEL SECURITY;

-- 7.1 Users Policies
CREATE POLICY "Allow public read access to users" ON public.users 
    FOR SELECT USING (true);
CREATE POLICY "Allow users to update their own data" ON public.users 
    FOR UPDATE USING (auth.uid() = id);

-- 7.2 Customer Policies
CREATE POLICY "Allow public read access to customer profiles" ON public.customers 
    FOR SELECT USING (true);
CREATE POLICY "Allow customers to manage their own profile" ON public.customers 
    FOR ALL USING (auth.uid() = id);

-- 7.3 Partner Policies
CREATE POLICY "Allow public read access to partner profiles" ON public.partners 
    FOR SELECT USING (true);
CREATE POLICY "Allow partners to manage their own profile" ON public.partners 
    FOR ALL USING (auth.uid() = id);

-- 7.4 Delivery Agent Policies
CREATE POLICY "Allow public read access to active agents" ON public.delivery_agents 
    FOR SELECT USING (true);
CREATE POLICY "Allow agents to update their coordinates/status" ON public.delivery_agents 
    FOR ALL USING (auth.uid() = id);

-- 7.5 Services & Products Policies (All can read, only partner owners can manage)
CREATE POLICY "Allow anyone to read services" ON public.services FOR SELECT USING (true);
CREATE POLICY "Allow partners to edit their own services" ON public.services 
    FOR ALL USING (auth.uid() = provider_id);

CREATE POLICY "Allow anyone to read products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Allow partners to edit their own products" ON public.products 
    FOR ALL USING (auth.uid() = shop_id);

-- 7.6 Bookings Policies
CREATE POLICY "Customers see their own bookings" ON public.bookings 
    FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Partners see their assigned bookings" ON public.bookings 
    FOR SELECT USING (auth.uid() = provider_id);
CREATE POLICY "Customers can create bookings" ON public.bookings 
    FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Parties to booking can update booking state" ON public.bookings 
    FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- 7.7 Orders & Order Items Policies
CREATE POLICY "Customers see their own orders" ON public.orders 
    FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Shops see orders placed with them" ON public.orders 
    FOR SELECT USING (auth.uid() = shop_id);
CREATE POLICY "Delivery agents see orders assigned to them" ON public.orders 
    FOR SELECT USING (auth.uid() = delivery_agent_id OR status = 'ready_for_pickup');
CREATE POLICY "Customers can place orders" ON public.orders 
    FOR INSERT WITH CHECK (auth.uid() = customer_id);
CREATE POLICY "Parties to order can update order" ON public.orders 
    FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = shop_id OR auth.uid() = delivery_agent_id);

CREATE POLICY "Access order items via order ownership" ON public.order_items 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE public.orders.id = order_items.order_id AND (
                orders.customer_id = auth.uid() OR 
                orders.shop_id = auth.uid() OR 
                orders.delivery_agent_id = auth.uid()
            )
        )
    );

-- 7.8 Chat Policies (Access only if sender or receiver)
CREATE POLICY "Users can access their own chat threads" ON public.chats 
    FOR ALL USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- =========================================================================
-- 8. DATABASE TRIGGERS & BUSINESS LOGIC FUNCTIONS
-- =========================================================================

-- Trigger to sync auth.users with public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, phone_number, full_name, role)
    VALUES (
        new.id, 
        new.phone, 
        COALESCE(new.raw_user_meta_data->>'full_name', 'User'), 
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'customer'::user_role)
    );

    -- Sync profile table based on user role
    IF COALESCE(new.raw_user_meta_data->>'role', 'customer') = 'customer' THEN
        INSERT INTO public.customers (id) VALUES (new.id);
    ELSIF COALESCE(new.raw_user_meta_data->>'role', 'customer') = 'partner' THEN
        INSERT INTO public.partners (id, business_name, partner_type) 
        VALUES (
            new.id, 
            COALESCE(new.raw_user_meta_data->>'business_name', 'Business Profile'),
            COALESCE((new.raw_user_meta_data->>'partner_type')::partner_role, 'service_provider'::partner_role)
        );
    ELSIF COALESCE(new.raw_user_meta_data->>'role', 'customer') = 'delivery_agent' THEN
        INSERT INTO public.delivery_agents (id, vehicle_number, vehicle_type) 
        VALUES (
            new.id, 
            COALESCE(new.raw_user_meta_data->>'vehicle_number', 'PENDING'),
            COALESCE(new.raw_user_meta_data->>'vehicle_type', 'bike')
        );
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Geofencing Check: Distance calculation helper using PostGIS
CREATE OR REPLACE FUNCTION public.check_geofence(
    shop_lat DECIMAL(9,6), 
    shop_lon DECIMAL(9,6), 
    cust_lat DECIMAL(9,6), 
    cust_lon DECIMAL(9,6),
    max_distance_meters FLOAT DEFAULT 5000.0 -- Default strict 5 km radius
)
RETURNS BOOLEAN AS $$
DECLARE
    distance FLOAT;
BEGIN
    distance := ST_Distance(
        ST_SetSRID(ST_MakePoint(shop_lon, shop_lat), 4326)::geography,
        ST_SetSRID(ST_MakePoint(cust_lon, cust_lat), 4326)::geography
    );
    RETURN distance <= max_distance_meters;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PIN Validation: Decrypts/Checks Delivery PIN only when distance <= 5m
CREATE OR REPLACE FUNCTION public.verify_delivery_location_pin(
    target_order_id UUID,
    agent_lat DECIMAL(9,6),
    agent_lon DECIMAL(9,6),
    input_pin VARCHAR(4),
    is_pickup_step BOOLEAN -- true if verifying at shop, false if verifying at customer
)
RETURNS BOOLEAN AS $$
DECLARE
    dest_lat DECIMAL(9,6);
    dest_lon DECIMAL(9,6);
    correct_pin VARCHAR(4);
    distance FLOAT;
BEGIN
    -- 1. Fetch correct coordinates and PIN depending on verification step
    IF is_pickup_step THEN
        SELECT p.latitude, p.longitude, o.pickup_pin INTO dest_lat, dest_lon, correct_pin
        FROM public.orders o
        JOIN public.partners p ON o.shop_id = p.id
        WHERE o.id = target_order_id;
    ELSE
        SELECT o.customer_lat, o.customer_lon, o.delivery_pin INTO dest_lat, dest_lon, correct_pin
        FROM public.orders o
        WHERE o.id = target_order_id;
    END IF;

    -- 2. Verify GPS proximity (must be <= 5 meters)
    distance := ST_Distance(
        ST_SetSRID(ST_MakePoint(agent_lon, agent_lat), 4326)::geography,
        ST_SetSRID(ST_MakePoint(dest_lon, dest_lat), 4326)::geography
    );

    IF distance > 5.0 THEN
        RAISE EXCEPTION 'Verification failed: Delivery Agent must be within 5 meters of target location. Current distance: % meters', ROUND(distance::numeric, 2);
    END IF;

    -- 3. Match PIN code
    RETURN input_pin = correct_pin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =========================================================================
-- 9. OPTIMIZATION INDEXES
-- =========================================================================
CREATE INDEX idx_users_phone ON public.users(phone_number);
CREATE INDEX idx_services_provider ON public.services(provider_id);
CREATE INDEX idx_products_shop ON public.products(shop_id);
CREATE INDEX idx_bookings_customer ON public.bookings(customer_id);
CREATE INDEX idx_bookings_provider ON public.bookings(provider_id);
CREATE INDEX idx_orders_customer ON public.orders(customer_id);
CREATE INDEX idx_orders_shop ON public.orders(shop_id);
CREATE INDEX idx_orders_agent ON public.orders(delivery_agent_id);
CREATE INDEX idx_chats_sender_receiver ON public.chats(sender_id, receiver_id);
