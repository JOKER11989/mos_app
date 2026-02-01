-- ============================================
-- Complete Supabase Database Setup for Mazadi App
-- ============================================
-- Run this in your Supabase SQL Editor to create all required tables

-- ============================================
-- 1. USERS TABLE (CamelCase)
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  address TEXT,
  region TEXT,
  "nearestPoint" TEXT,
  "imagePath" TEXT,
  "isAdmin" BOOLEAN DEFAULT FALSE,
  "isBlocked" BOOLEAN DEFAULT FALSE,
  password TEXT,
  "deviceId" TEXT,
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_isAdmin ON public.users("isAdmin");

-- ============================================
-- 2. PRODUCTS TABLE (CamelCase)
-- ============================================
CREATE TABLE IF NOT EXISTS public.products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price TEXT NOT NULL,
  "startingPrice" TEXT,
  "realPrice" TEXT,
  "timeLeft" TEXT DEFAULT '00h 00m 00s',
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  "endTime" TIMESTAMP WITH TIME ZONE,
  images TEXT[] NOT NULL DEFAULT '{}',
  "isDarkBg" BOOLEAN DEFAULT FALSE,
  description TEXT,
  views INTEGER DEFAULT 0,
  bids INTEGER DEFAULT 0,
  status TEXT DEFAULT 'جديد',
  "isLocalImage" BOOLEAN DEFAULT FALSE,
  "isOffer" BOOLEAN DEFAULT FALSE,
  "bannerImage" TEXT,
  category TEXT DEFAULT 'عام',
  "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_isOffer ON public.products("isOffer");
CREATE INDEX IF NOT EXISTS idx_products_endTime ON public.products("endTime");

-- ============================================
-- 3. BIDS TABLE (Mixed: CamelCase + INTEGER amount)
-- ============================================
CREATE TABLE IF NOT EXISTS public.bids (
  id TEXT PRIMARY KEY,
  "productId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "bidderName" TEXT NOT NULL,
  amount INTEGER NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  FOREIGN KEY ("productId") REFERENCES public.products(id) ON DELETE CASCADE,
  FOREIGN KEY ("userId") REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bids_productId ON public.bids("productId");
CREATE INDEX IF NOT EXISTS idx_bids_userId ON public.bids("userId");
CREATE INDEX IF NOT EXISTS idx_bids_timestamp ON public.bids(timestamp DESC);

-- ============================================
-- 4. FAVORITES TABLE (snake_case)
-- ============================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE,
  UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_product_id ON public.favorites(product_id);

-- ============================================
-- 5. NOTIFICATIONS TABLE (Mixed)
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type INTEGER NOT NULL,
  "productId" TEXT,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  "isRead" BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_isRead ON public.notifications("isRead");
CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON public.notifications(timestamp DESC);

-- ============================================
-- 6. PURCHASES TABLE (Mixed: snake_case FK + CamelCase product fields)
-- ============================================
CREATE TABLE IF NOT EXISTS public.purchases (
  id TEXT PRIMARY KEY, -- Stores Product ID
  user_id TEXT NOT NULL,
  
  -- Product Fields Copy
  name TEXT,
  price TEXT,
  "startingPrice" TEXT,
  "realPrice" TEXT,
  timestamp TIMESTAMP WITH TIME ZONE,
  "endTime" TIMESTAMP WITH TIME ZONE,
  images TEXT[],
  "isDarkBg" BOOLEAN,
  description TEXT,
  views INTEGER,
  bids INTEGER,
  status TEXT,
  "isLocalImage" BOOLEAN,
  "isOffer" BOOLEAN,
  "bannerImage" TEXT,
  category TEXT,
  
  "purchaseDate" TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
  UNIQUE (user_id, id)
);

CREATE INDEX IF NOT EXISTS idx_purchases_user_id ON public.purchases(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Public read access" ON public.users;
DROP POLICY IF EXISTS "Public insert access" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;
DROP POLICY IF EXISTS "Admins can update any user" ON public.users;

DROP POLICY IF EXISTS "Public read products" ON public.products;
DROP POLICY IF EXISTS "Admins can insert products" ON public.products;
DROP POLICY IF EXISTS "Admins can update products" ON public.products;
DROP POLICY IF EXISTS "Admins can delete products" ON public.products;

DROP POLICY IF EXISTS "Public read bids" ON public.bids;
DROP POLICY IF EXISTS "Users can insert bids" ON public.bids;

DROP POLICY IF EXISTS "Users can read own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can insert own favorites" ON public.favorites;
DROP POLICY IF EXISTS "Users can delete own favorites" ON public.favorites;

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

DROP POLICY IF EXISTS "Users can read own purchases" ON public.purchases;
DROP POLICY IF EXISTS "System can insert purchases" ON public.purchases;

-- USERS POLICIES
CREATE POLICY "Public read access" ON public.users FOR SELECT USING (true);
CREATE POLICY "Public insert access" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own data" ON public.users FOR UPDATE USING (id = current_setting('app.current_user_id', true));
CREATE POLICY "Admins can update any user" ON public.users FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = current_setting('app.current_user_id', true) AND "isAdmin" = true)
);

-- PRODUCTS POLICIES
CREATE POLICY "Public read products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Admins can insert products" ON public.products FOR INSERT WITH CHECK (true);
CREATE POLICY "Admins can update products" ON public.products FOR UPDATE USING (true);
CREATE POLICY "Admins can delete products" ON public.products FOR DELETE USING (true);

-- BIDS POLICIES
CREATE POLICY "Public read bids" ON public.bids FOR SELECT USING (true);
CREATE POLICY "Users can insert bids" ON public.bids FOR INSERT WITH CHECK (true);

-- FAVORITES POLICIES
CREATE POLICY "Users can read own favorites" ON public.favorites FOR SELECT USING (true);
CREATE POLICY "Users can insert own favorites" ON public.favorites FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete own favorites" ON public.favorites FOR DELETE USING (true);

-- NOTIFICATIONS POLICIES
CREATE POLICY "Users can read own notifications" ON public.notifications FOR SELECT USING (true);
CREATE POLICY "System can insert notifications" ON public.notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (true);
CREATE POLICY "Users can delete own notifications" ON public.notifications FOR DELETE USING (true);

-- PURCHASES POLICIES
CREATE POLICY "Users can read own purchases" ON public.purchases FOR SELECT USING (true);
CREATE POLICY "System can insert purchases" ON public.purchases FOR INSERT WITH CHECK (true);

-- ============================================
-- TRIGGERS
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."updatedAt" = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.users;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- Verification Queries
-- ============================================
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
