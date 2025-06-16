/*
  # Insert Sample Data

  1. Store Categories
    - Food & Beverages
    - Stationery & Books
    - Electronics & Gadgets
    - Essentials

  2. Sample Vendors
    - Test vendors for development

  3. Sample Products
    - Products for testing the store functionality
*/

-- Insert store categories
INSERT INTO public.store_categories (name, description, icon, display_order, active) VALUES
  ('Food & Beverages', 'Meals, snacks, and drinks from campus food stalls', '🍔', 1, true),
  ('Xerox & Printing', 'Document printing, photocopying, and binding services', '🖨️', 2, true),
  ('Stationery', 'Notebooks, pens, and academic supplies', '📝', 3, true),
  ('Essentials', 'Daily necessities and personal care items', '🛍️', 4, true),
  ('Electronics', 'Gadgets, accessories, and tech supplies', '💻', 5, true)
ON CONFLICT DO NOTHING;

-- Insert sample vendors
INSERT INTO public.vendors (firebase_uid, business_name, category, description, status, approved_at) VALUES
  ('sample_vendor_001', 'Campus Cafe', 'Food & Beverages', 'Fresh food and beverages for students', 'approved', now()),
  ('sample_vendor_002', 'Quick Print Shop', 'Xerox & Printing', 'Fast printing and document services', 'approved', now()),
  ('sample_vendor_003', 'Campus Stationery', 'Stationery', 'Academic supplies and stationery items', 'approved', now())
ON CONFLICT (firebase_uid) DO NOTHING;

-- Insert sample products
WITH vendor_cafe AS (
  SELECT id FROM public.vendors WHERE business_name = 'Campus Cafe' LIMIT 1
),
vendor_print AS (
  SELECT id FROM public.vendors WHERE business_name = 'Quick Print Shop' LIMIT 1
),
vendor_stationery AS (
  SELECT id FROM public.vendors WHERE business_name = 'Campus Stationery' LIMIT 1
),
category_food AS (
  SELECT id FROM public.store_categories WHERE name = 'Food & Beverages' LIMIT 1
),
category_print AS (
  SELECT id FROM public.store_categories WHERE name = 'Xerox & Printing' LIMIT 1
),
category_stationery AS (
  SELECT id FROM public.store_categories WHERE name = 'Stationery' LIMIT 1
)
INSERT INTO public.products (vendor_id, category_id, name, description, price, discount_percentage, quantity, available_from, available_until, is_active)
SELECT * FROM (
  -- Food items
  SELECT vendor_cafe.id, category_food.id, 'Chicken Sandwich', 'Fresh grilled chicken sandwich with vegetables', 120.00, 10, 25, '08:00:00'::time, '20:00:00'::time, true
  FROM vendor_cafe, category_food
  UNION ALL
  SELECT vendor_cafe.id, category_food.id, 'Coffee', 'Hot freshly brewed coffee', 40.00, 0, 50, '07:00:00'::time, '22:00:00'::time, true
  FROM vendor_cafe, category_food
  UNION ALL
  SELECT vendor_cafe.id, category_food.id, 'Veg Burger', 'Delicious vegetarian burger with fresh ingredients', 80.00, 15, 30, '10:00:00'::time, '21:00:00'::time, true
  FROM vendor_cafe, category_food
  UNION ALL
  -- Printing services
  SELECT vendor_print.id, category_print.id, 'A4 Printout (B&W)', 'Black and white A4 size printout', 2.00, 0, 1000, '09:00:00'::time, '18:00:00'::time, true
  FROM vendor_print, category_print
  UNION ALL
  SELECT vendor_print.id, category_print.id, 'A4 Printout (Color)', 'Color A4 size printout', 8.00, 0, 500, '09:00:00'::time, '18:00:00'::time, true
  FROM vendor_print, category_print
  UNION ALL
  SELECT vendor_print.id, category_print.id, 'Spiral Binding', 'Spiral binding service for documents', 25.00, 0, 100, '09:00:00'::time, '17:00:00'::time, true
  FROM vendor_print, category_print
  UNION ALL
  -- Stationery items
  SELECT vendor_stationery.id, category_stationery.id, 'A4 Notebook', 'High quality A4 size notebook - 200 pages', 150.00, 5, 40, '09:00:00'::time, '19:00:00'::time, true
  FROM vendor_stationery, category_stationery
  UNION ALL
  SELECT vendor_stationery.id, category_stationery.id, 'Blue Pen Pack', 'Pack of 5 blue ballpoint pens', 50.00, 0, 60, '09:00:00'::time, '19:00:00'::time, true
  FROM vendor_stationery, category_stationery
  UNION ALL
  SELECT vendor_stationery.id, category_stationery.id, 'Highlighter Set', 'Set of 4 colored highlighters', 80.00, 20, 35, '09:00:00'::time, '19:00:00'::time, true
  FROM vendor_stationery, category_stationery
) AS sample_products
ON CONFLICT DO NOTHING;

-- Insert a sample club
INSERT INTO public.clubs (name, description, category, password, join_password, max_members) VALUES
  ('Tech Innovation Club', 'A club dedicated to exploring cutting-edge technologies, organizing hackathons, and fostering innovation among students.', 'Technology', 'admin123', 'mahesh', 30)
ON CONFLICT DO NOTHING;