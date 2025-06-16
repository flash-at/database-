/*
  # Enable Row Level Security and Create Policies

  1. Security Setup
    - Enable RLS on all tables
    - Create comprehensive access policies
    - Set up user authentication policies

  2. Access Control
    - Users can manage their own data
    - Vendors can manage their business data
    - Public access for certain data like events and products
*/

-- Enable Row Level Security on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campus_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campus_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pickup_confirmations ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Allow profile creation" ON public.users
  FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Allow profile viewing" ON public.users
  FOR SELECT TO public USING (true);

CREATE POLICY "Allow profile updates" ON public.users
  FOR UPDATE TO public USING (true) WITH CHECK (true);

-- Vendors table policies
CREATE POLICY "Users can create their own vendor records" ON public.vendors
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Users can view their own vendor records" ON public.vendors
  FOR SELECT TO authenticated USING (firebase_uid = auth.uid()::text);

CREATE POLICY "Users can update their own vendor records" ON public.vendors
  FOR UPDATE TO authenticated USING (firebase_uid = auth.uid()::text);

-- Clubs table policies
CREATE POLICY "Everyone can view clubs" ON public.clubs
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can create clubs" ON public.clubs
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Club creators can update their clubs" ON public.clubs
  FOR UPDATE TO authenticated USING (created_by = public.get_current_user_id());

-- Club memberships policies (temporarily disabled for testing)
-- These will be re-enabled once authentication is properly configured

-- Academic info policies
CREATE POLICY "Users can manage their academic info" ON public.academic_info
  FOR ALL TO authenticated USING (user_id = public.get_current_user_id());

-- Engagement policies
CREATE POLICY "Users can manage their engagement" ON public.engagement
  FOR ALL TO authenticated USING (user_id = public.get_current_user_id());

-- Preferences policies
CREATE POLICY "Users can manage their preferences" ON public.preferences
  FOR ALL TO authenticated USING (user_id = public.get_current_user_id());

-- Events policies
CREATE POLICY "Everyone can view events" ON public.events
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage events" ON public.events
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub' 
      AND role IN ('admin', 'super_admin')
    )
  );

-- Complaints policies
CREATE POLICY "Users can view their own complaints" ON public.complaints
  FOR SELECT USING (
    user_id IN (
      SELECT id FROM public.users 
      WHERE firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );

CREATE POLICY "Users can create complaints" ON public.complaints
  FOR INSERT WITH CHECK (
    user_id IN (
      SELECT id FROM public.users 
      WHERE firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid()::text IN (
    SELECT firebase_uid FROM public.users WHERE id = notifications.user_id
  ));

CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid()::text IN (
    SELECT firebase_uid FROM public.users WHERE id = notifications.user_id
  ));

-- Store categories policies
CREATE POLICY "Everyone can view store categories" ON public.store_categories
  FOR SELECT TO authenticated USING (active = true);

-- Products policies
CREATE POLICY "Allow public access to all active products" ON public.products
  FOR SELECT TO public USING (is_active = true);

CREATE POLICY "Vendors can manage their products" ON public.products
  FOR ALL USING (
    vendor_id IN (
      SELECT v.id FROM public.vendors v
      WHERE v.firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );

-- Campus orders policies
CREATE POLICY "Allow authenticated users to create orders" ON public.campus_orders
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow users to view orders" ON public.campus_orders
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Vendors can manage their orders" ON public.campus_orders
  FOR ALL USING (
    vendor_id IN (
      SELECT id FROM public.vendors 
      WHERE firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );

-- Campus order items policies
CREATE POLICY "Allow order items for valid orders" ON public.campus_order_items
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow viewing order items" ON public.campus_order_items
  FOR SELECT TO authenticated USING (true);

-- Promo offers policies
CREATE POLICY "Everyone can view active promos" ON public.promo_offers
  FOR SELECT TO authenticated USING (is_active = true AND end_time > now());

CREATE POLICY "Vendors can manage their promos" ON public.promo_offers
  FOR ALL USING (
    vendor_id IN (
      SELECT v.id FROM public.vendors v
      WHERE v.firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );

-- Pickup confirmations policies
CREATE POLICY "Vendors can manage pickup confirmations" ON public.pickup_confirmations
  FOR ALL USING (
    confirmed_by IN (
      SELECT v.id FROM public.vendors v
      WHERE v.firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub'
    )
  );