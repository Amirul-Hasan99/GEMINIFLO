-- ==============================================================================
-- GEMINIFLO - FLORAL BOARD (PAPAN BUNGA) BOOKING & RENTAL DATABASE SCHEMA
-- Target DB: Neon Serverless PostgreSQL
-- Database URI: postgresql://neondb_owner:npg_An3OriHysUC0@ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech/GEMINIFLO?sslmode=require&channel_binding=require
-- ==============================================================================

-- 1. Categories
CREATE TABLE IF NOT EXISTS categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Products (Papan Bunga)
CREATE TABLE IF NOT EXISTS products (
  id VARCHAR(50) PRIMARY KEY,
  category_id VARCHAR(50) REFERENCES categories(id) ON DELETE SET NULL,
  category_name VARCHAR(100),
  name VARCHAR(150) NOT NULL,
  description TEXT,
  price NUMERIC(15, 2) NOT NULL,
  original_price NUMERIC(15, 2),
  dimension VARCHAR(50),
  flower_type VARCHAR(100),
  stock INT DEFAULT 5,
  rating NUMERIC(3, 2) DEFAULT 5.0,
  review_count INT DEFAULT 0,
  image_urls TEXT[],
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Users
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  phone VARCHAR(30),
  role VARCHAR(20) DEFAULT 'customer', -- 'customer', 'admin'
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bookings (Two-Status Engine: Booking Status vs Payment Status)
CREATE TABLE IF NOT EXISTS bookings (
  id VARCHAR(50) PRIMARY KEY,
  booking_code VARCHAR(30) UNIQUE NOT NULL,
  user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
  product_id VARCHAR(50) REFERENCES products(id) ON DELETE SET NULL,
  product_name VARCHAR(150),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  customer_name VARCHAR(150) NOT NULL,
  customer_phone VARCHAR(30) NOT NULL,
  event_address TEXT NOT NULL,
  event_message TEXT NOT NULL,
  notes TEXT,
  with_delivery BOOLEAN DEFAULT true,
  with_installation BOOLEAN DEFAULT true,
  total_amount NUMERIC(15, 2) NOT NULL,
  booking_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'confirmed', 'delivered', 'completed', 'cancelled'
  payment_status VARCHAR(30) DEFAULT 'unpaid',  -- 'unpaid', 'verifying', 'paid', 'rejected', 'refunded'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Payments (Verification & Proof of Transfer)
CREATE TABLE IF NOT EXISTS payments (
  id VARCHAR(50) PRIMARY KEY,
  booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,
  user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(15, 2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL, -- 'bca_transfer', 'mandiri_transfer', 'dana', 'gopay', 'qris'
  proof_url TEXT,
  status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'verified', 'rejected'
  rejection_reason TEXT,
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Customer Saved Addresses
CREATE TABLE IF NOT EXISTS addresses (
  id VARCHAR(50) PRIMARY KEY,
  user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
  label VARCHAR(50) NOT NULL,
  recipient_name VARCHAR(100) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  address_line TEXT NOT NULL,
  city VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20),
  is_primary BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Reviews & Ratings
CREATE TABLE IF NOT EXISTS reviews (
  id VARCHAR(50) PRIMARY KEY,
  booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,
  product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,
  user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Default Indices for High-Speed Querying
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
