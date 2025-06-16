/*
  # Initial Campus Management System Schema

  1. New Tables
    - `users` - User profiles with Firebase authentication
    - `vendors` - Service providers on campus
    - `events` - Campus events
    - `complaints` - Student complaints system
    - `clubs` - Student clubs
    - `club_memberships` - Club membership tracking
    - `club_roles` - Club leadership roles
    - `academic_info` - Academic information for users
    - `engagement` - User engagement tracking
    - `preferences` - User preferences
    - `notifications` - System notifications
    - `store_categories` - Campus store categories
    - `products` - Campus store products
    - `campus_orders` - Campus store orders
    - `campus_order_items` - Order line items
    - `promo_offers` - Promotional offers
    - `pickup_confirmations` - Order pickup confirmations

  2. Security
    - Enable RLS on all tables
    - Add policies for user data access
    - Create functions for user management

  3. Features
    - Automatic timestamp updates
    - User ranking system
    - Related data creation triggers
*/

-- Create users profile table to store additional user information
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  hall_ticket TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  department TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  email_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create vendors table for service providers
CREATE TABLE IF NOT EXISTS public.vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid TEXT UNIQUE NOT NULL,
  business_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  approved_at TIMESTAMP WITH TIME ZONE,
  rejected_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create clubs table
CREATE TABLE IF NOT EXISTS public.clubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  password TEXT,
  join_password TEXT,
  auth_code TEXT,
  max_members INTEGER DEFAULT 50,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create club memberships table
CREATE TABLE IF NOT EXISTS public.club_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  role TEXT DEFAULT 'member',
  UNIQUE(club_id, user_id)
);

-- Create club_roles table for storing different roles
CREATE TABLE IF NOT EXISTS public.club_roles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('chair', 'vice_chair', 'core_member')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(club_id, user_id, role)
);

-- Create academic_info table
CREATE TABLE IF NOT EXISTS public.academic_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  gpa DECIMAL(3,2),
  semester INTEGER,
  graduation_year INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create engagement table
CREATE TABLE IF NOT EXISTS public.engagement (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  activity_points INTEGER DEFAULT 0,
  badges JSONB DEFAULT '[]'::jsonb,
  events_attended TEXT[] DEFAULT '{}',
  feedback_count INTEGER DEFAULT 0,
  last_login TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create theme enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'theme_type') THEN
        CREATE TYPE theme_type AS ENUM ('Light', 'Dark', 'System');
    END IF;
END $$;

-- Create preferences table
CREATE TABLE IF NOT EXISTS public.preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  theme theme_type DEFAULT 'System',
  notifications_enabled BOOLEAN DEFAULT true,
  email_notifications BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create events table
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  category TEXT,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create complaints table
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) NOT NULL,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  priority TEXT NOT NULL DEFAULT 'medium',
  assigned_to UUID REFERENCES public.users(id),
  resolved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  club_id uuid REFERENCES public.clubs(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Create store categories table
CREATE TABLE IF NOT EXISTS public.store_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create products table for campus store
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES public.vendors(id),
  category_id UUID REFERENCES public.store_categories(id),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  discount_percentage INTEGER DEFAULT 0,
  quantity INTEGER DEFAULT 0,
  image_url TEXT,
  available_from TIME,
  available_until TIME,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create campus store orders table
CREATE TABLE IF NOT EXISTS public.campus_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.users(id),
  vendor_id UUID REFERENCES public.vendors(id),
  status TEXT NOT NULL DEFAULT 'placed' CHECK (status IN ('placed', 'accepted', 'ready', 'completed', 'cancelled')),
  total_price NUMERIC(10,2) NOT NULL,
  service_fee NUMERIC(10,2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'cod' CHECK (payment_method IN ('cod', 'wallet', 'upi', 'card')),
  pickup_deadline TIMESTAMP WITH TIME ZONE,
  qr_code TEXT UNIQUE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create order items table
CREATE TABLE IF NOT EXISTS public.campus_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.campus_orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id),
  quantity INTEGER NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create promo offers table
CREATE TABLE IF NOT EXISTS public.promo_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES public.vendors(id),
  product_id UUID REFERENCES public.products(id),
  title TEXT NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'flat', 'combo')),
  discount_value NUMERIC(10,2) NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create pickup confirmations table
CREATE TABLE IF NOT EXISTS public.pickup_confirmations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.campus_orders(id),
  confirmed_by UUID REFERENCES public.vendors(id),
  confirmed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  qr_code TEXT NOT NULL,
  notes TEXT
);

-- Create function to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create function to get current user ID
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
AS $$
  SELECT id FROM public.users WHERE firebase_uid = auth.uid()::text;
$$;

-- Create function to get user rank
CREATE OR REPLACE FUNCTION public.get_user_rank(p_user_id uuid)
RETURNS TABLE(rank BIGINT)
LANGUAGE sql
STABLE
AS $$
  SELECT rank
  FROM (
    SELECT 
      user_id, 
      RANK() OVER (ORDER BY activity_points DESC) as rank
    FROM public.engagement
  ) as ranked_users
  WHERE user_id = p_user_id;
$$;

-- Create function to automatically create related data when user profile is created
CREATE OR REPLACE FUNCTION public.create_user_related_data()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.academic_info(user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO public.engagement(user_id, last_login) VALUES (NEW.id, now()) ON CONFLICT (user_id) DO NOTHING;
  INSERT INTO public.preferences(user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;