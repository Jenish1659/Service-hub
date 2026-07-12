-- =======================================================
-- SERVICEHUB DATABASE SCHEMA (SUPABASE POSTGRESQL + POSTGIS)
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
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to profiles" 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Allow users to update their own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. SERVICES CATALOG TABLE
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

-- 3. PRODUCTS CATALOG TABLE (With location coordinates for geofencing)
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

-- 4. BOOKINGS TABLE (Service bookings)
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    provider_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    service_name TEXT NOT NULL,
    issue_description TEXT,
    photo_url TEXT,
    scheduled_date TEXT NOT NULL,
    scheduled_time TEXT NOT NULL,
    payment_method TEXT DEFAULT 'Cash on Service',
    price DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Pending', 'Confirmed', 'En Route', 'Started', 'Completed')) DEFAULT 'Pending',
    entrance_pin TEXT DEFAULT '7429',
    completion_otp TEXT DEFAULT '5892',
    customer_lat DOUBLE PRECISION,
    customer_lng DOUBLE PRECISION,
    provider_lat DOUBLE PRECISION,
    provider_lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can view their own bookings" 
    ON public.bookings FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Providers can view assigned bookings" 
    ON public.bookings FOR SELECT USING (auth.uid() = provider_id);

CREATE POLICY "Customers can insert bookings" 
    ON public.bookings FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Users can update their booking status" 
    ON public.bookings FOR UPDATE USING (
        auth.uid() = customer_id OR auth.uid() = provider_id
    );

-- 5. ORDERS TABLE (Product delivery orders)
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    agent_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('Placed', 'Packing', 'Ready for Pickup', 'Out for Delivery', 'Delivered')) DEFAULT 'Placed',
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

CREATE POLICY "Customers can view their own orders" 
    ON public.orders FOR SELECT USING (auth.uid() = customer_id);

CREATE POLICY "Agents can view assigned orders" 
    ON public.orders FOR SELECT USING (auth.uid() = agent_id);

CREATE POLICY "Customers can place orders" 
    ON public.orders FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Users can update order status" 
    ON public.orders FOR UPDATE USING (
        auth.uid() = customer_id OR auth.uid() = agent_id
    );

-- =======================================================
-- HYPERLOCAL GEOGRAPHIC QUERY FUNCTIONS (POSTGIS)
-- =======================================================

-- Function: Get products within range (default 5000 meters / 5 km)
CREATE OR REPLACE FUNCTION get_products_in_range(
    customer_lat DOUBLE PRECISION, 
    customer_lng DOUBLE PRECISION, 
    range_meters DOUBLE PRECISION DEFAULT 5000.0
)
RETURNS SETOF public.products AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.products
    WHERE ST_DWithin(
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography,
        ST_SetSRID(ST_MakePoint(customer_lng, customer_lat), 4326)::geography,
        range_meters
    );
END;
$$ LANGUAGE plpgsql;

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
('3-Tier Tiffin Box', 'Stainless steel insulated lunch box', 449, 599, '25% OFF', 'Cooking', 12.9130, 77.6410);
