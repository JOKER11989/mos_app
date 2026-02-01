-- ============================================
-- Supabase Database Setup for Mazadi App
-- ============================================
-- This script creates the users table and sets up Row Level Security (RLS) policies
-- Run this in your Supabase SQL Editor

-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  address TEXT,
  region TEXT,
  nearest_point TEXT,
  image_path TEXT,
  is_admin BOOLEAN DEFAULT FALSE,
  is_blocked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create index on phone for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON public.users(is_admin);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
DROP POLICY IF EXISTS "Admins can update any user" ON public.users;

-- Policy: Anyone can view all users (needed for login/registration)
CREATE POLICY "Users can view all users"
  ON public.users
  FOR SELECT
  USING (true);

-- Policy: Anyone can insert new users (for registration)
CREATE POLICY "Users can insert their own data"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Policy: Users can update their own data
CREATE POLICY "Users can update their own data"
  ON public.users
  FOR UPDATE
  USING (id = current_setting('app.current_user_id', true))
  WITH CHECK (id = current_setting('app.current_user_id', true));

-- Policy: Admins can update any user
CREATE POLICY "Admins can update any user"
  ON public.users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = current_setting('app.current_user_id', true)
      AND is_admin = true
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS set_updated_at ON public.users;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================
-- Optional: Insert default admin user
-- ============================================
-- Uncomment the following lines if you want to create a default admin user
-- Make sure to change the phone number to your actual admin phone

-- INSERT INTO public.users (id, name, phone, is_admin, is_blocked)
-- VALUES ('admin_1', 'Admin', '7711131188', true, false)
-- ON CONFLICT (phone) DO UPDATE SET is_admin = true;

-- ============================================
-- Verification Queries
-- ============================================
-- Run these to verify the setup:

-- Check if table exists and view structure
-- SELECT * FROM information_schema.columns WHERE table_name = 'users';

-- View all policies
-- SELECT * FROM pg_policies WHERE tablename = 'users';

-- Count users
-- SELECT COUNT(*) FROM public.users;
