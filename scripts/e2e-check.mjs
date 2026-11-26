const base = (process.env.E2E_API_BASE_URL ?? 'https://geminiflo-api.vercel.app/api').replace(/\/$/, '');
const tag = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
const email = `e2e-${tag}@example.com`;
const password = `E2e-${tag}-Password`;
const created = { userId: null, productId: `E2E-${tag}`, paymentMethodId: null, bookingIds: [] };
let adminToken;
let userToken;
let checks = 0;

async function request(method, path, token, data, expectedStatus) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(data ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(data ? { body: JSON.stringify(data) } : {}),
  });
  const text = await response.text();
  let result;
  try { result = text ? JSON.parse(text) : null; } catch { result = text; }
  const expected = expectedStatus ?? (response.ok ? response.status : 200);
  if (response.status !== expected) {
    throw new Error(`${method} ${path}: expected ${expected}, got ${response.status}: ${typeof result === 'string' ? result : JSON.stringify(result)}`);
  }
  if (!response.ok) throw new Error(`${method} ${path}: ${JSON.stringify(result)}`);
  return result;
}
function assert(condition, message) { if (!condition) throw new Error(message); checks++; }

async function cleanup() {
  if (!adminToken) return;
  for (const bookingId of created.bookingIds) {
    try { await request('DELETE', `/admin/bookings/${encodeURIComponent(bookingId)}`, adminToken); } catch {}
  }
  if (created.paymentMethodId) {
    try { await request('DELETE', `/admin/payment-methods/${encodeURIComponent(created.paymentMethodId)}`, adminToken); } catch {}
  }
  try { await request('DELETE', `/admin/products/${encodeURIComponent(created.productId)}`, adminToken); } catch {}
  if (created.userId) {
    try { await request('DELETE', `/admin/customers/${encodeURIComponent(created.userId)}`, adminToken); } catch {}
  }
}

try {
  const adminLogin = await request('POST', '/login', null, { email: 'geminiflo@admin.com', password: 'admin000' });
  adminToken = adminLogin.data.token;
  assert(adminLogin.data.user.email === 'geminiflo@admin.com' && adminLogin.data.user.role === 'admin', 'Akun admin tidak terautentikasi dengan benar.');

  const catalog = await request('GET', '/products');
  assert(Array.isArray(catalog.products) && catalog.products.length > 0, 'Katalog Neon kosong.');

  const productPayload = {
    id: created.productId, sku: created.productId, category_id: '7', category_name: 'Papan Bunga',
    name: 'Produk uji E2E', description: 'Akan dihapus setelah pengujian.', price: 123456,
    dimension: 'E2E', stock: 1, stock_available: 1, image_urls: [], is_active: true,
    is_featured: false, availability_status: 'available',
  };
  const newProduct = await request('POST', '/admin/products', adminToken, productPayload, 201);
  assert(newProduct.product.id === created.productId, 'Tambah produk gagal.');
  const loadedProduct = await request('GET', `/admin/products/${encodeURIComponent(created.productId)}`, adminToken);
  assert(loadedProduct.product.name === productPayload.name, 'Baca produk gagal.');
  await request('PUT', `/admin/products/${encodeURIComponent(created.productId)}`, adminToken, { ...productPayload, name: 'Produk uji E2E diperbarui', price: 123457 });
  await request('DELETE', `/admin/products/${encodeURIComponent(created.productId)}`, adminToken);
  const publicProductsAfterDelete = await request('GET', '/products');
  assert(!publicProductsAfterDelete.products.some((p) => p.id === created.productId), 'Hapus produk gagal.');

  const registered = await request('POST', '/register', null, {
    name: 'Pengguna Uji E2E', username: `e2e_${tag.replaceAll('-', '_')}`.slice(0, 30), email, phone: '081234567890',
    avatar: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j0ioAAAAASUVORK5CYII=', password, password_confirmation: password,
  }, 201);
  created.userId = registered.data.user.id;
  userToken = registered.data.token;
  assert(registered.data.user.phone === '081234567890' && registered.data.user.avatar?.startsWith('data:image/png;base64,'), 'Telepon/foto tidak tersimpan saat daftar.');
  const profile = await request('GET', '/profile', userToken);
  assert(profile.data.phone === '081234567890' && profile.data.avatar === registered.data.user.avatar, 'Data profil tidak sinkron.');
  await request('PUT', '/profile', userToken, {
    name: 'Pengguna Uji E2E Diperbarui', phone: '081234567891',
    avatar: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j0ioAAAAASUVORK5CYII=',
  });
  const editedProfile = await request('GET', '/profile', userToken);
  assert(editedProfile.data.name === 'Pengguna Uji E2E Diperbarui' && editedProfile.data.phone === '081234567891', 'Edit profil tidak tersimpan.');
  const userLogin = await request('POST', '/login', null, { email, password });
  assert(userLogin.data.user.id === created.userId, 'Login pengguna baru gagal.');

  const favBefore = await request('GET', '/favorites', userToken);
  const favoriteId = catalog.products[0].id;
  await request('POST', `/favorites/${encodeURIComponent(favoriteId)}`, userToken);
  const favAdded = await request('GET', '/favorites', userToken);
  assert(favAdded.products.some((p) => p.id === favoriteId), 'Tambah favorit gagal.');
  await request('POST', `/favorites/${encodeURIComponent(favoriteId)}`, userToken);
  const favRemoved = await request('GET', '/favorites', userToken);
  assert(favRemoved.products.length === (favBefore.products?.length ?? 0), 'Hapus favorit gagal.');

  const address = await request('POST', '/addresses', userToken, {
    label: 'Alamat E2E', recipient_name: 'Pengguna Uji E2E', phone: '081234567890',
    address_line: 'Alamat pengujian sementara', city: 'Kota Uji', postal_code: '12345', is_primary: true,
  }, 201);
  const addressId = address.data.id;
  const addressList = await request('GET', '/addresses', userToken);
  assert(addressList.data.addresses.some((a) => a.id === addressId), 'Tambah/baca alamat gagal.');
  await request('PUT', `/addresses/${encodeURIComponent(addressId)}`, userToken, {
    label: 'Alamat E2E Edit', recipient_name: 'Pengguna Uji E2E', phone: '081234567890',
    address_line: 'Alamat pengujian diperbarui', city: 'Kota Uji', postal_code: '54321', is_primary: false,
  });
  await request('PUT', `/addresses/${encodeURIComponent(addressId)}/primary`, userToken);
  const addressUpdated = await request('GET', '/addresses', userToken);
  assert(addressUpdated.data.addresses.find((a) => a.id === addressId)?.isPrimary === true, 'Edit/alamat utama gagal.');
  await request('DELETE', `/addresses/${encodeURIComponent(addressId)}`, userToken);

  const method = await request('POST', '/admin/payment-methods', adminToken, {
    type: 'bank_transfer', name: 'Metode uji E2E', account_number: '0000000000', account_name: 'GEMINIFLO E2E', is_active: true,
  });
  created.paymentMethodId = method.data.id;
  await request('PUT', `/admin/payment-methods/${encodeURIComponent(created.paymentMethodId)}`, adminToken, {
    type: 'bank_transfer', name: 'Metode uji E2E Edit', account_number: '0000000001', account_name: 'GEMINIFLO E2E', is_active: true,
  });
  const methodList = await request('GET', '/admin/payment-methods', adminToken);
  assert(methodList.data.methods.some((m) => m.id === created.paymentMethodId), 'Tambah/edit metode pembayaran gagal.');

  const now = Date.now();
  const makeBooking = async (offset) => {
    const start = new Date(now + offset * 86400000), end = new Date(now + (offset + 1) * 86400000);
    const createdBooking = await request('POST', '/bookings', userToken, {
      product_id: catalog.products[0].id, start_date: start.toISOString(), end_date: end.toISOString(),
      customer_name: 'Pengguna Uji E2E', customer_phone: '081234567890',
      event_address: 'Alamat event pengujian', event_message: 'Papan bunga uji', notes: 'e2e-cleanup',
      with_delivery: true, with_installation: true,
    }, 201);
    const booking = createdBooking.data.booking;
    created.bookingIds.push(booking.id);
    return booking;
  };
  const booking = await makeBooking(3);
  const userBookings = await request('GET', '/bookings', userToken);
  assert(userBookings.data.bookings.some((b) => b.id === booking.id && b.customerId === created.userId), 'Booking user tidak tercatat/terhubung ke akun.');
  const adminBookings = await request('GET', '/admin/bookings', adminToken);
  assert(adminBookings.data.bookings.some((b) => b.id === booking.id && b.customerEmail === email), 'Booking user tidak tampil di panel admin.');
  const customerWhileBookingExists = await request('GET', '/admin/customers', adminToken);
  assert(customerWhileBookingExists.data.customers.find((c) => c.id === created.userId)?.totalBookings === 1, 'Ringkasan pelanggan tidak membaca booking Neon.');
  const bookingDetail = await request('GET', `/bookings/${encodeURIComponent(booking.id)}`, userToken);
  assert(bookingDetail.data.booking.bookingCode === booking.bookingCode, 'Detail booking gagal.');
  await request('PUT', `/bookings/${encodeURIComponent(booking.id)}`, userToken, {
    product_id: catalog.products[0].id, start_date: new Date(now + 4 * 86400000).toISOString(),
    end_date: new Date(now + 5 * 86400000).toISOString(), customer_name: 'Pengguna Uji E2E Edit',
    customer_phone: '081234567890', event_address: 'Alamat event pengujian edit',
    event_message: 'Papan bunga uji edit', with_delivery: true, with_installation: true,
  });
  await request('PUT', `/admin/bookings/${encodeURIComponent(booking.id)}/status`, adminToken, { status: 'processing' });
  const statusCheck = await request('GET', `/bookings/${encodeURIComponent(booking.id)}`, userToken);
  assert(statusCheck.data.booking.status === 'processing', 'Ubah status booking admin gagal.');
  await request('PUT', `/admin/bookings/${encodeURIComponent(booking.id)}/status`, adminToken, { status: 'pending_payment' });

  const chosen = await request('POST', `/bookings/${encodeURIComponent(booking.id)}/payment`, userToken, { payment_method: created.paymentMethodId });
  const paymentId = chosen.data.payment.id;
  const proof = await request('POST', `/payments/${encodeURIComponent(paymentId)}/proof`, userToken, {
    proof: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j0ioAAAAASUVORK5CYII=',
  });
  assert(proof.data.payment.status === 'waiting_verification', 'Unggah bukti pembayaran gagal.');
  const paymentQueue = await request('GET', '/admin/payments', adminToken);
  assert(paymentQueue.data.payments.some((p) => p.id === paymentId), 'Bukti pembayaran tidak masuk panel admin.');
  await request('PUT', `/admin/payments/${encodeURIComponent(paymentId)}/verify`, adminToken, { approve: false, reason: 'Uji alur penolakan.' });
  const rejectedBooking = await request('GET', `/bookings/${encodeURIComponent(booking.id)}`, userToken);
  assert(rejectedBooking.data.booking.status === 'pending_payment', 'Penolakan pembayaran gagal memperbarui booking.');
  await request('POST', `/payments/${encodeURIComponent(paymentId)}/proof`, userToken, {
    proof: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j0ioAAAAASUVORK5CYII=',
  });
  await request('PUT', `/admin/payments/${encodeURIComponent(paymentId)}/verify`, adminToken, { approve: true });
  const confirmedBooking = await request('GET', `/bookings/${encodeURIComponent(booking.id)}`, userToken);
  assert(confirmedBooking.data.booking.status === 'confirmed', 'Verifikasi pembayaran gagal memperbarui booking.');
  const paymentDetail = await request('GET', `/admin/payments/${encodeURIComponent(paymentId)}`, adminToken);
  assert(paymentDetail.data.payment.status === 'verified', 'Detail pembayaran admin tidak sesuai.');
  const notices = await request('GET', '/notifications', userToken);
  assert(notices.data.notifications.length >= 2, 'Notifikasi alur verifikasi tidak tercatat.');
  if (notices.data.notifications[0]) await request('PUT', `/notifications/${encodeURIComponent(notices.data.notifications[0].id)}`, userToken);
  await request('PUT', '/notifications/read-all', userToken);
  const readNotices = await request('GET', '/notifications', userToken);
  assert(readNotices.data.notifications.every((n) => n.isRead), 'Tandai semua notifikasi dibaca gagal.');
  await request('DELETE', '/notifications/clear', userToken);
  assert((await request('GET', '/notifications', userToken)).data.notifications.length === 0, 'Hapus notifikasi gagal.');
  await request('DELETE', `/admin/payments/${encodeURIComponent(paymentId)}`, adminToken);
  await request('DELETE', `/admin/bookings/${encodeURIComponent(booking.id)}`, adminToken);

  const cancelBooking = await makeBooking(6);
  await request('POST', `/bookings/${encodeURIComponent(cancelBooking.id)}/cancel`, userToken, { reason: 'Uji pembatalan.' });
  const cancelled = await request('GET', `/bookings/${encodeURIComponent(cancelBooking.id)}`, userToken);
  assert(cancelled.data.booking.status === 'cancelled', 'Pembatalan booking gagal.');
  const deleteBooking = await makeBooking(9);
  await request('DELETE', `/admin/bookings/${encodeURIComponent(deleteBooking.id)}`, adminToken);
  const afterAdminDelete = await request('GET', '/admin/bookings', adminToken);
  assert(!afterAdminDelete.data.bookings.some((b) => b.id === deleteBooking.id), 'Hapus booking admin gagal.');
  await request('DELETE', `/bookings/${encodeURIComponent(cancelBooking.id)}`, userToken);

  const customers = await request('GET', '/admin/customers', adminToken);
  const tempCustomer = customers.data.customers.find((c) => c.id === created.userId);
  assert(tempCustomer?.email === email, 'Pelanggan sementara tidak muncul di panel admin.');
  await request('DELETE', `/admin/customers/${encodeURIComponent(created.userId)}`, adminToken);
  created.userId = null;
  const customersAfterDelete = await request('GET', '/admin/customers', adminToken);
  assert(!customersAfterDelete.data.customers.some((c) => c.email === email), 'Hapus pelanggan admin gagal.');
  await request('DELETE', `/admin/payment-methods/${encodeURIComponent(created.paymentMethodId)}`, adminToken);
  created.paymentMethodId = null;

  console.log(`PASS: ${checks} pemeriksaan API-to-Neon lulus. Data pengguna, produk, alamat, metode pembayaran, booking, pembayaran, dan notifikasi sementara sudah dibersihkan.`);
} catch (error) {
  console.error(`FAIL after ${checks} assertions:`, error instanceof Error ? error.message : error);
  process.exitCode = 1;
} finally {
  await cleanup();
}
