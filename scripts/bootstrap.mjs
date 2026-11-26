import { Pool } from '@neondatabase/serverless';
import { createHmac, randomBytes } from 'node:crypto';

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL belum diatur.');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const id = (prefix) => `${prefix}-${randomBytes(32).toString('base64url').slice(0, 20)}`;
const hashPassword = (password, salt) => {
  const hmac = (data) => createHmac('sha256', password).update(data).digest();
  let block = hmac(Buffer.concat([Buffer.from(salt), Buffer.from([0, 0, 0, 1])]));
  const derived = Buffer.from(block);
  for (let round = 1; round < 60000; round++) {
    block = hmac(block);
    for (let i = 0; i < derived.length; i++) derived[i] ^= block[i];
  }
  return derived.toString('base64url');
};

const statements = [
  `CREATE TABLE IF NOT EXISTS categories(id VARCHAR(50) PRIMARY KEY,name VARCHAR(100) NOT NULL,slug VARCHAR(100) UNIQUE NOT NULL,description TEXT,icon VARCHAR(50),created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS products(id VARCHAR(50) PRIMARY KEY,sku VARCHAR(50),category_id VARCHAR(50) REFERENCES categories(id) ON DELETE SET NULL,category_name VARCHAR(100),name VARCHAR(150) NOT NULL,description TEXT,price NUMERIC(15,2) NOT NULL,original_price NUMERIC(15,2),dimension VARCHAR(50),flower_type VARCHAR(100),stock INT DEFAULT 5,stock_available INT DEFAULT 1,rating NUMERIC(3,2) DEFAULT 5,review_count INT DEFAULT 0,image_urls TEXT[] DEFAULT '{}',is_available BOOLEAN DEFAULT TRUE,is_active BOOLEAN DEFAULT TRUE,is_featured BOOLEAN DEFAULT FALSE,availability_status VARCHAR(30) DEFAULT 'available',created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS users(id VARCHAR(50) PRIMARY KEY,name VARCHAR(150) NOT NULL,username VARCHAR(50),email VARCHAR(150) UNIQUE NOT NULL,phone VARCHAR(30),role VARCHAR(20) NOT NULL DEFAULT 'user',avatar_url TEXT,google_uid VARCHAR(128) UNIQUE,password_salt VARCHAR(100),password_hash VARCHAR(100),created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS auth_sessions(token_hash VARCHAR(64) PRIMARY KEY,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,expires_at TIMESTAMPTZ NOT NULL,created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS bookings(id VARCHAR(50) PRIMARY KEY,booking_code VARCHAR(30) UNIQUE NOT NULL,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,product_id VARCHAR(50) REFERENCES products(id) ON DELETE SET NULL,product_name VARCHAR(150) NOT NULL,start_date TIMESTAMPTZ NOT NULL,end_date TIMESTAMPTZ NOT NULL,customer_name VARCHAR(150) NOT NULL,customer_phone VARCHAR(30) NOT NULL,event_address TEXT NOT NULL,event_message TEXT NOT NULL,notes TEXT,with_delivery BOOLEAN NOT NULL DEFAULT TRUE,with_installation BOOLEAN NOT NULL DEFAULT TRUE,subtotal NUMERIC(15,2) NOT NULL DEFAULT 0,delivery_fee NUMERIC(15,2) NOT NULL DEFAULT 0,installation_fee NUMERIC(15,2) NOT NULL DEFAULT 0,total_amount NUMERIC(15,2) NOT NULL,booking_status VARCHAR(30) NOT NULL DEFAULT 'pending_payment',payment_deadline TIMESTAMPTZ,returned_at TIMESTAMPTZ,created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS reviews(id VARCHAR(50) PRIMARY KEY,booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,rating INT NOT NULL CHECK(rating BETWEEN 1 AND 5),comment TEXT,admin_response TEXT,created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS addresses(id VARCHAR(50) PRIMARY KEY,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,label VARCHAR(50) NOT NULL,recipient_name VARCHAR(100) NOT NULL,phone VARCHAR(30) NOT NULL,address_line TEXT NOT NULL,city VARCHAR(100) NOT NULL DEFAULT '',postal_code VARCHAR(20),is_primary BOOLEAN NOT NULL DEFAULT FALSE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS favorites(user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,product_id VARCHAR(50) NOT NULL REFERENCES products(id) ON DELETE CASCADE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),PRIMARY KEY(user_id,product_id))`,
  `CREATE TABLE IF NOT EXISTS payment_methods(id VARCHAR(50) PRIMARY KEY,type VARCHAR(30) NOT NULL,name VARCHAR(100) NOT NULL,account_number VARCHAR(100),account_name VARCHAR(150),bank_code VARCHAR(50),logo_url TEXT,is_active BOOLEAN NOT NULL DEFAULT TRUE,created_at TIMESTAMPTZ DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS payments(id VARCHAR(50) PRIMARY KEY,booking_id VARCHAR(50) NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,amount NUMERIC(15,2) NOT NULL,payment_method VARCHAR(50) NOT NULL,proof_url TEXT,status VARCHAR(30) NOT NULL DEFAULT 'pending',rejection_reason TEXT,verified_at TIMESTAMPTZ,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS notifications(id VARCHAR(50) PRIMARY KEY,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,title VARCHAR(150) NOT NULL,message TEXT NOT NULL,type VARCHAR(50) NOT NULL,booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE SET NULL,booking_code VARCHAR(50),is_read BOOLEAN NOT NULL DEFAULT FALSE,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
  `CREATE TABLE IF NOT EXISTS password_reset_tokens(token_hash VARCHAR(64) PRIMARY KEY,user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,expires_at TIMESTAMPTZ NOT NULL,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW())`,
];

try {
  for (const statement of statements) await pool.query(statement);
  for (const [column, type] of [
    ['username', 'VARCHAR(50)'], ['phone', 'VARCHAR(30)'], ['role', "VARCHAR(20) DEFAULT 'user'"],
    ['avatar_url', 'TEXT'], ['password_salt', 'VARCHAR(100)'], ['password_hash', 'VARCHAR(100)'],
  ]) await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${column} ${type}`);
  await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS google_uid VARCHAR(128)`);
  await pool.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_uid ON users(google_uid)`);
  for (const [column, type] of [
    ['sku', 'VARCHAR(50)'], ['stock_available', 'INT DEFAULT 1'], ['is_active', 'BOOLEAN DEFAULT TRUE'],
    ['is_featured', 'BOOLEAN DEFAULT FALSE'], ["availability_status", "VARCHAR(30) DEFAULT 'available'"],
  ]) await pool.query(`ALTER TABLE products ADD COLUMN IF NOT EXISTS ${column} ${type}`);
  for (const [column, type] of [
    ['subtotal', 'NUMERIC(15,2) NOT NULL DEFAULT 0'], ['delivery_fee', 'NUMERIC(15,2) NOT NULL DEFAULT 0'],
    ['installation_fee', 'NUMERIC(15,2) NOT NULL DEFAULT 0'], ['payment_deadline', 'TIMESTAMPTZ'], ['returned_at', 'TIMESTAMPTZ'],
  ]) await pool.query(`ALTER TABLE bookings ADD COLUMN IF NOT EXISTS ${column} ${type}`);
  await pool.query(`ALTER TABLE reviews ADD COLUMN IF NOT EXISTS admin_response TEXT`);
  await pool.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_booking_unique ON reviews(booking_id)`);
  await pool.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(LOWER(username))`);
  await pool.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_ci ON users(LOWER(email))`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id)`);
  await pool.query(`CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status)`);
  const duplicatePayments = await pool.query(`SELECT COUNT(*)::int AS groups FROM (SELECT booking_id FROM payments GROUP BY booking_id HAVING COUNT(*)>1) d`);
  if (duplicatePayments.rows[0].groups > 0) throw new Error('Ada booking dengan lebih dari satu pembayaran; duplikasi perlu ditinjau sebelum indeks unik dibuat.');
  await pool.query(`CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_booking_unique ON payments(booking_id)`);
  const categories = ['Pernikahan', 'Grand Opening', 'Ulang Tahun', 'Duka Cita', 'Wisuda', 'Promosi', 'Papan Bunga'];
  for (let i = 0; i < categories.length; i++) {
    const name = categories[i], categoryId = String(i + 1);
    await pool.query(`INSERT INTO categories(id,name,slug,description,icon) VALUES($1,$2,$3,$4,'local_florist') ON CONFLICT(slug) DO NOTHING`, [categoryId,name,name.toLowerCase().replaceAll(' ','-'),'Kategori produk papan bunga GEMINIFLO']);
  }
  const catalog = [['Landscape VI',110000],['Thumbelina V2',150000],['Kubah Pink',80000],['Standing Black',150000],['Maroon',150000],['Potret V2',150000],['Pink I',140000],['Pink White',150000],['Blue',140000],['Pink Fanta',150000],['Standing Ungu',150000],['Convex Mirror',155000],['Bulat Pink V2',80000],['Blue White',85000],['Bulat Maroon',85000]];
  for (let i=0;i<catalog.length;i++) {
    const n=i+1,[name,price]=catalog[i],pid=`GF-PB-${String(n).padStart(3,'0')}`;
    await pool.query(`INSERT INTO products(id,sku,category_id,category_name,name,description,price,dimension,stock,stock_available,image_urls,is_available,is_active,is_featured,availability_status) VALUES($1,$1,'7','Papan Bunga',$2,$3,$4,'Sesuai model foto',1,1,$5,TRUE,TRUE,$6,'available') ON CONFLICT(id) DO NOTHING`,[pid,name,`Model ${name} sesuai foto katalog.`,price,[`assets/images/products/geminiflo_${n}.jpg`],n<=3]);
  }
  await pool.query(`DELETE FROM users WHERE LOWER(email) IN ('geminiflo@user.com','user@geminiflo.com','admin@geminiflo.com')`);
  await pool.query(`UPDATE users SET role='user' WHERE role='admin' AND LOWER(email)<>'geminiflo@admin.com'`);
  const salt=randomBytes(32).toString('base64url'),passwordHashValue=hashPassword('admin000',salt);
  const existing=(await pool.query(`SELECT id FROM users WHERE LOWER(email)='geminiflo@admin.com'`)).rows[0];
  if(existing) await pool.query(`UPDATE users SET role='admin',password_salt=$1,password_hash=$2 WHERE id=$3`,[salt,passwordHashValue,existing.id]);
  else await pool.query(`INSERT INTO users(id,name,username,email,role,password_salt,password_hash) VALUES($1,'Admin GEMINIFLO','geminiflo.admin','geminiflo@admin.com','admin',$2,$3)`,[id('ADM'),salt,passwordHashValue]);
  console.log('Neon schema siap; katalog dan akun admin GEMINIFLO disinkronkan.');
} finally { await pool.end(); }
