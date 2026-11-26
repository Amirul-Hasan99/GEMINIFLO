import { createHash, createPublicKey, randomUUID, verify } from 'node:crypto';

const tokenId = () => `NTF-${randomUUID()}`;
const userId = () => `USR-${randomUUID()}`;
const sessionToken = () => randomUUID() + randomUUID();
export const firebaseProjectId = 'geminiflo-3d7f0';

export class FirebaseTokenError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'FirebaseTokenError';
  }
}

export async function expirePendingBookings(sql: any) {
  const { rows } = await sql.query(`UPDATE bookings SET booking_status='expired' WHERE booking_status='pending_payment' AND payment_deadline<=NOW() RETURNING id,user_id,booking_code`);
  for (const booking of rows) {
    await sql.query('INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code) VALUES($1,$2,$3,$4,$5,$6,$7)', [tokenId(), booking.user_id, 'Batas pembayaran terlewati', `Booking ${booking.booking_code} kedaluwarsa; stok telah tersedia kembali.`, 'orderStatusChanged', booking.id, booking.booking_code]);
  }
}

export async function firebaseClaims(rawToken: string) {
  const parts = rawToken.split('.');
  if (parts.length !== 3) throw new FirebaseTokenError('Token Firebase tidak valid.');
  const decode = (part: string) => JSON.parse(Buffer.from(part, 'base64url').toString());
  let header: any;
  let claims: any;
  try {
    header = decode(parts[0]);
    claims = decode(parts[1]);
  } catch {
    throw new FirebaseTokenError('Token Firebase tidak valid.');
  }
  if (header.alg !== 'RS256' || !header.kid) throw new FirebaseTokenError('Token Firebase tidak valid.');
  const certs = await firebaseSigningCertificates();
  const certificate = certs[header.kid];
  const signature = Uint8Array.from(Buffer.from(parts[2], 'base64url'));
  if (!certificate || !verify('RSA-SHA256', new TextEncoder().encode(`${parts[0]}.${parts[1]}`), createPublicKey(certificate), signature)) {
    throw new FirebaseTokenError('Token Firebase tidak dapat diverifikasi.');
  }
  const now = Math.floor(Date.now() / 1000);
  if (claims.aud !== firebaseProjectId || claims.iss !== `https://securetoken.google.com/${firebaseProjectId}`) {
    throw new FirebaseTokenError('Token berasal dari proyek Firebase yang berbeda dengan GEMINIFLO.');
  }
  if (
    typeof claims.sub !== 'string' || !claims.sub ||
    typeof claims.exp !== 'number' || typeof claims.iat !== 'number' ||
    typeof claims.auth_time !== 'number' ||
    claims.exp <= now || claims.iat > now || claims.auth_time > now
  ) {
    throw new FirebaseTokenError('Token Firebase tidak valid atau sudah kedaluwarsa. Silakan login kembali.');
  }
  if (!claims.email || claims.email_verified !== true) throw new FirebaseTokenError('Akun Google harus memiliki email terverifikasi.');
  return claims;
}

let certificateCache: { expiresAt: number; values: Record<string, string> } | undefined;
async function firebaseSigningCertificates() {
  if (certificateCache && certificateCache.expiresAt > Date.now()) return certificateCache.values;
  const response = await fetch('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
  if (!response.ok) throw new Error('Sertifikat Firebase tidak dapat diakses.');
  const maxAge = Number(response.headers.get('cache-control')?.match(/max-age=(\d+)/)?.[1] ?? 1800);
  certificateCache = { values: await response.json(), expiresAt: Date.now() + maxAge * 1000 };
  return certificateCache.values;
}

export async function firebaseLogin(req: any, res: any, sql: any) {
  if (req.method !== 'POST') return res.status(405).json({ success: false, message: 'Metode tidak didukung.' });
  const rawToken = String(req.body?.id_token ?? '').trim();
  if (!rawToken) return res.status(400).json({ success: false, message: 'Token Google wajib dikirim.' });
  const claims = await firebaseClaims(rawToken);
  const email = String(claims.email).toLowerCase();
  const existing = await sql.query('SELECT id,name,username,email,phone,role,avatar_url FROM users WHERE google_uid=$1 OR LOWER(email)=$2 ORDER BY CASE WHEN google_uid=$1 THEN 0 ELSE 1 END LIMIT 1', [claims.sub, email]);
  let user = existing.rows[0];
  if (user) {
    if (user.role === 'admin') {
      return res.status(403).json({ success: false, message: 'Akun admin harus masuk menggunakan username dan password admin.' });
    }
    await sql.query('UPDATE users SET google_uid=$1, avatar_url=COALESCE(avatar_url,$2), name=CASE WHEN name IS NULL OR name=\'\' THEN $3 ELSE name END WHERE id=$4', [claims.sub, claims.picture ?? null, claims.name ?? email.split('@')[0], user.id]);
  } else {
    const id = userId();
    const base = String(claims.name ?? email.split('@')[0]).toLowerCase().replace(/[^a-z0-9._]/g, '').slice(0, 22) || 'pelanggan';
    const username = `${base}.${claims.sub.slice(-6)}`;
    const inserted = await sql.query('INSERT INTO users(id,name,username,email,role,avatar_url,google_uid) VALUES($1,$2,$3,$4,\'user\',$5,$6) RETURNING id,name,username,email,phone,role,avatar_url', [id, claims.name ?? email.split('@')[0], username, email, claims.picture ?? null, claims.sub]);
    user = inserted.rows[0];
  }
  const session = sessionToken();
  const hash = createHash('sha256').update(session).digest('hex');
  await sql.query('INSERT INTO auth_sessions(token_hash,user_id,expires_at) VALUES($1,$2,NOW()+INTERVAL \'30 days\')', [hash, user.id]);
  return res.status(200).json({ success: true, message: 'Berhasil masuk.', data: { user: { id: user.id, name: user.name, username: user.username, email: user.email, phone: user.phone, role: user.role, avatar: user.avatar_url }, token: session } });
}

export async function productAvailability(req: any, res: any, sql: any, productId: string) {
  const start = new Date(String(req.query.start_date ?? ''));
  const end = new Date(String(req.query.end_date ?? ''));
  if (!Number.isFinite(start.valueOf()) || !Number.isFinite(end.valueOf()) || end <= start) return res.status(400).json({ success: false, message: 'Rentang tanggal tidak valid.' });
  const excludeId = String(req.query.exclude_booking_id ?? '') || null;
  const result = await sql.query(`SELECT p.stock,p.stock_available,GREATEST(0,LEAST(COALESCE(p.stock,p.stock_available),p.stock_available)-COUNT(b.id)::int) AS available FROM products p LEFT JOIN bookings b ON b.product_id=p.id AND b.returned_at IS NULL AND b.start_date < $3 AND b.end_date > $2 AND ($4::text IS NULL OR b.id<>$4) AND (b.booking_status IN ('confirmed','processing','ready','completed') OR (b.booking_status='pending_payment' AND b.payment_deadline>NOW())) WHERE p.id=$1 AND p.is_active AND p.is_available GROUP BY p.id`, [productId, start, end, excludeId]);
  if (!result.rows[0]) return res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
  const available = Number(result.rows[0].available);
  return res.status(200).json({ success: true, data: { available, is_available: available > 0 } });
}

export async function catalogProducts(req: any, res: any, sql: any, adminView = false, productId?: string) {
  const filters: string[] = [];
  const args: unknown[] = [];
  if (!adminView) filters.push('p.is_active=true AND p.is_available=true');
  if (productId) { args.push(productId); filters.push(`p.id=$${args.length}`); }
  if (req.query.category_id) { args.push(req.query.category_id); filters.push(`p.category_id=$${args.length}`); }
  if (req.query.search) { args.push(`%${req.query.search}%`); filters.push(`(p.name ILIKE $${args.length} OR p.sku ILIKE $${args.length} OR p.category_name ILIKE $${args.length})`); }
  const order = req.query.sort_by === 'price_asc' ? 'p.price ASC' : req.query.sort_by === 'price_desc' ? 'p.price DESC' : 'p.created_at DESC,p.id ASC';
  const expression = `(SELECT COUNT(*)::int FROM bookings b WHERE b.product_id=p.id AND b.returned_at IS NULL AND b.start_date<=NOW() AND b.end_date>NOW() AND (b.booking_status IN ('confirmed','processing','ready','completed') OR (b.booking_status='pending_payment' AND b.payment_deadline>NOW())))`;
  const where = filters.length ? `WHERE ${filters.join(' AND ')}` : '';
  const result = await sql.query(`SELECT p.*,GREATEST(0,LEAST(COALESCE(p.stock,p.stock_available),p.stock_available)-${expression})::int AS stock_available,CASE WHEN GREATEST(0,LEAST(COALESCE(p.stock,p.stock_available),p.stock_available)-${expression})<=0 THEN 'unavailable' WHEN GREATEST(0,LEAST(COALESCE(p.stock,p.stock_available),p.stock_available)-${expression})<COALESCE(p.stock,p.stock_available) THEN 'limited' ELSE 'available' END AS availability_status FROM products p ${where} ORDER BY ${order}`, args);
  if (productId) return result.rows[0] ? res.status(200).json({ product: result.rows[0] }) : res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
  return res.status(200).json({ products: result.rows });
}

export async function bookingReview(req: any, res: any, sql: any, bookingId: string, user: any) {
  if (req.method === 'GET') {
    const existing = await sql.query('SELECT id,booking_id,product_id,rating,comment,created_at FROM reviews WHERE booking_id=$1 AND user_id=$2', [bookingId, user.id]);
    return res.status(200).json({ success: true, data: { review: existing.rows[0] ?? null } });
  }
  if (req.method !== 'POST') return res.status(405).json({ success: false, message: 'Metode ulasan tidak didukung.' });
  const booking = await sql.query('SELECT id,user_id,product_id,booking_code,booking_status FROM bookings WHERE id=$1 AND user_id=$2', [bookingId, user.id]);
  if (!booking.rows[0]) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan.' });
  if (booking.rows[0].booking_status !== 'completed') return res.status(409).json({ success: false, message: 'Ulasan dapat dikirim setelah booking selesai.' });
  const rating = Number(req.body?.rating);
  const comment = String(req.body?.comment ?? '').trim();
  if (!Number.isInteger(rating) || rating < 1 || rating > 5 || comment.length > 2000) return res.status(400).json({ success: false, message: 'Rating harus 1-5 dan ulasan maksimal 2000 karakter.' });
  const id = `REV-${randomUUID()}`;
  const inserted = await sql.query('INSERT INTO reviews(id,booking_id,product_id,user_id,rating,comment) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(booking_id) DO NOTHING RETURNING id,booking_id,product_id,user_id,rating,comment,created_at', [id, bookingId, booking.rows[0].product_id, user.id, rating, comment]);
  if (!inserted.rows[0]) return res.status(409).json({ success: false, message: 'Booking ini sudah memiliki ulasan.' });
  await sql.query('UPDATE products SET rating=(SELECT AVG(rating)::numeric(3,2) FROM reviews WHERE product_id=$1), review_count=(SELECT COUNT(*)::int FROM reviews WHERE product_id=$1) WHERE id=$1', [booking.rows[0].product_id]);
  return res.status(201).json({ success: true, data: { review: inserted.rows[0] } });
}

export async function listReviews(req: any, res: any, sql: any, productId?: string) {
  const args = productId ? [productId] : [];
  const where = productId ? 'WHERE r.product_id=$1' : '';
  const result = await sql.query(`SELECT r.id,r.booking_id,r.product_id,r.rating,r.comment,r.created_at,u.name AS customer_name,p.name AS product_name FROM reviews r JOIN users u ON u.id=r.user_id LEFT JOIN products p ON p.id=r.product_id ${where} ORDER BY r.created_at DESC LIMIT 200`, args);
  return res.status(200).json({ success: true, data: { reviews: result.rows } });
}

export async function markBookingReturned(res: any, sql: any, bookingId: string) {
  const result = await sql.query(`UPDATE bookings SET returned_at=NOW(),booking_status='completed' WHERE id=$1 AND booking_status IN ('ready','completed') AND returned_at IS NULL RETURNING id,booking_code,user_id`, [bookingId]);
  if (!result.rows[0]) return res.status(409).json({ success: false, message: 'Booking harus siap atau selesai dan belum pernah dikembalikan.' });
  const booking = result.rows[0];
  await sql.query('INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code) VALUES($1,$2,$3,$4,$5,$6,$7)', [tokenId(), booking.user_id, 'Papan bunga telah dikembalikan', `Pengembalian booking ${booking.booking_code} telah dicatat.`, 'orderStatusChanged', booking.id, booking.booking_code]);
  return res.status(200).json({ success: true, data: { returned_at: new Date().toISOString() } });
}

export async function changeBookingStatus(sql: any, bookingId: string, status: string) {
  const result = await sql.query('UPDATE bookings SET booking_status=$1 WHERE id=$2 RETURNING id,booking_code,user_id,booking_status', [status, bookingId]);
  if (!result.rows[0]) return null;
  const booking = result.rows[0];
  await sql.query('INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code) VALUES($1,$2,$3,$4,$5,$6,$7)', [tokenId(), booking.user_id, 'Status booking diperbarui', `Booking ${booking.booking_code} kini berstatus ${booking.booking_status}.`, 'orderStatusChanged', booking.id, booking.booking_code]);
  return booking;
}

export async function createBooking(req: any, res: any, sql: any, user: any) {
  if (user.role === 'admin') return res.status(403).json({ success: false, message: 'Admin tidak dapat membuat booking pelanggan.' });
  const d = req.body ?? {};
  const productId = String(d.product_id ?? '').trim();
  const start = new Date(String(d.start_date ?? ''));
  const end = new Date(String(d.end_date ?? ''));
  if (!productId || !Number.isFinite(start.valueOf()) || !Number.isFinite(end.valueOf()) || end <= start) return res.status(400).json({ success: false, message: 'Produk dan rentang tanggal booking wajib valid.' });
  const client = await sql.connect();
  try {
    await client.query('BEGIN ISOLATION LEVEL SERIALIZABLE');
    const product = (await client.query('SELECT id,name,price,stock,stock_available FROM products WHERE id=$1 AND is_active AND is_available FOR UPDATE', [productId])).rows[0];
    if (!product) { await client.query('ROLLBACK'); return res.status(404).json({ success: false, message: 'Produk tidak tersedia.' }); }
    const active = (await client.query(`SELECT COUNT(*)::int AS count FROM bookings WHERE product_id=$1 AND returned_at IS NULL AND start_date<$3 AND end_date>$2 AND (booking_status IN ('confirmed','processing','ready','completed') OR (booking_status='pending_payment' AND payment_deadline>NOW()))`, [productId, start, end])).rows[0];
    const capacity = Math.max(0, Math.min(Number(product.stock ?? product.stock_available), Number(product.stock_available ?? product.stock)));
    if (Number(active.count) >= capacity) { await client.query('ROLLBACK'); return res.status(409).json({ success: false, message: 'Papan bunga sudah dipesan pada tanggal tersebut.' }); }
    const bookingId = `BKG-${randomUUID()}`;
    const year = new Date().getFullYear();
    const bookingCode = `GF-${year}-${randomUUID().slice(0, 7).toUpperCase()}`;
    const amount = Number(product.price);
    const customerName = String(d.customer_name ?? user.name ?? '').trim();
    const customerPhone = String(d.customer_phone ?? user.phone ?? '').trim();
    const address = String(d.event_address ?? '').trim();
    const message = String(d.event_message ?? '').trim();
    if (!customerName || !customerPhone || !address || !message) { await client.query('ROLLBACK'); return res.status(400).json({ success: false, message: 'Nama, telepon, alamat acara, dan pesan wajib diisi.' }); }
    await client.query(`INSERT INTO bookings(id,booking_code,user_id,product_id,product_name,start_date,end_date,customer_name,customer_phone,event_address,event_message,notes,with_delivery,with_installation,subtotal,total_amount,booking_status,payment_deadline) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$15,'pending_payment',NOW()+INTERVAL '24 hours')`, [bookingId, bookingCode, user.id, productId, product.name, start, end, customerName, customerPhone, address, message, d.notes ?? null, d.with_delivery !== false, d.with_installation !== false, amount]);
    const booking = (await client.query(`${'SELECT b.*,u.username AS customer_username,u.email AS customer_email,p.image_urls[1] AS product_image_url FROM bookings b JOIN users u ON u.id=b.user_id LEFT JOIN products p ON p.id=b.product_id'} WHERE b.id=$1`, [bookingId])).rows[0];
    await client.query('COMMIT');
    return res.status(201).json({ success: true, message: 'Booking berhasil dibuat.', data: { booking: booking ? { id: booking.id, bookingCode: booking.booking_code, customerId: booking.user_id, user_id: booking.user_id, productId: booking.product_id, productName: booking.product_name, productImageUrl: booking.product_image_url, startDate: booking.start_date, endDate: booking.end_date, customerName: booking.customer_name, customerPhone: booking.customer_phone, customerEmail: booking.customer_email, customerUsername: booking.customer_username, eventAddress: booking.event_address, eventMessage: booking.event_message, notes: booking.notes, withDelivery: booking.with_delivery, withInstallation: booking.with_installation, subtotal: Number(booking.subtotal), deliveryFee: Number(booking.delivery_fee), installationFee: Number(booking.installation_fee), total: Number(booking.total_amount), bookingStatus: booking.booking_status, status: booking.booking_status, paymentDeadline: booking.payment_deadline, returnedAt: booking.returned_at, createdAt: booking.created_at } : null } });
  } catch (error) {
    try { await client.query('ROLLBACK'); } catch { /* transaction may already be closed */ }
    throw error;
  } finally { client.release(); }
}
