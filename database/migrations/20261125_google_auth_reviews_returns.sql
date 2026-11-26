ALTER TABLE users
  ADD COLUMN IF NOT EXISTS google_uid VARCHAR(128);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_uid
  ON users(google_uid);

ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS returned_at TIMESTAMP WITH TIME ZONE;

CREATE TABLE IF NOT EXISTS reviews (
  id VARCHAR(50) PRIMARY KEY,
  booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,
  product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,
  user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  admin_response TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS admin_response TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_booking_unique
  ON reviews(booking_id);
