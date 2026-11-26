import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';

const _productFields = '''
  id, sku, category_id, category_name, name, description, price,
  dimension, stock, stock_available, image_urls, is_available,
  is_active, is_featured, availability_status
''';
const _reservedStock =
    '''(SELECT COUNT(*)::int FROM bookings b WHERE b.product_id=products.id
  AND b.returned_at IS NULL AND b.start_date<=NOW() AND b.end_date>NOW()
  AND (b.booking_status IN ('confirmed','processing','ready','completed')
  OR (b.booking_status='pending_payment' AND b.payment_deadline>NOW())))''';

Future<void> main(List<String> args) async {
  final databaseUrl = Platform.environment['NEON_DATABASE_URL'];
  if (databaseUrl == null || databaseUrl.isEmpty) {
    stderr.writeln(
      'NEON_DATABASE_URL belum diatur. Isi variabel lingkungan backend.',
    );
    exitCode = 64;
    return;
  }

  final host = _option(args, '--host') ?? '0.0.0.0';
  final port = int.tryParse(_option(args, '--port') ?? '8000') ?? 8000;
  final pool = Pool.withUrl(databaseUrl);

  try {
    await _prepareDatabase(pool);
    await _seedAdminFromEnvironment(pool);
  } catch (_) {
    stderr.writeln(
      'Koneksi atau migrasi Neon gagal. Periksa URL dan izin database.',
    );
    await pool.close();
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(host, port);
  stdout.writeln('GEMINIFLO API berjalan di http://$host:$port');
  await for (final request in server) {
    unawaited(_handle(request, pool));
  }
}

String? _option(List<String> args, String option) {
  final index = args.indexOf(option);
  return index >= 0 && index + 1 < args.length ? args[index + 1] : null;
}

Future<void> _prepareDatabase(Pool pool) async {
  const statements = [
    '''CREATE TABLE IF NOT EXISTS categories (
      id VARCHAR(50) PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      slug VARCHAR(100) UNIQUE NOT NULL,
      description TEXT,
      icon VARCHAR(50),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS products (
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
      image_urls TEXT[] DEFAULT '{}',
      is_available BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    'ALTER TABLE products ADD COLUMN IF NOT EXISTS sku VARCHAR(50)',
    'ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_available INT DEFAULT 1',
    'ALTER TABLE products ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true',
    'ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false',
    "ALTER TABLE products ADD COLUMN IF NOT EXISTS availability_status VARCHAR(30) DEFAULT 'available'",
  ];
  for (final sql in statements) {
    await pool.execute(sql);
  }

  const bookingAndAccountSchema = [
    '''CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(50) PRIMARY KEY,
      name VARCHAR(150) NOT NULL,
      username VARCHAR(50) UNIQUE,
      email VARCHAR(150) UNIQUE NOT NULL,
      phone VARCHAR(30),
      role VARCHAR(20) NOT NULL DEFAULT 'user',
      avatar_url TEXT,
      google_uid VARCHAR(128) UNIQUE,
      password_salt VARCHAR(100),
      password_hash VARCHAR(100),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50)',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(30)',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT \'user\'',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS google_uid VARCHAR(128)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_google_uid ON users(google_uid)',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_salt VARCHAR(100)',
    'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(100)',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(LOWER(username))',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_ci ON users(LOWER(email))',
    '''CREATE TABLE IF NOT EXISTS auth_sessions (
      token_hash VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS bookings (
      id VARCHAR(50) PRIMARY KEY,
      booking_code VARCHAR(30) UNIQUE NOT NULL,
      user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      product_id VARCHAR(50) REFERENCES products(id) ON DELETE SET NULL,
      product_name VARCHAR(150) NOT NULL,
      start_date TIMESTAMP WITH TIME ZONE NOT NULL,
      end_date TIMESTAMP WITH TIME ZONE NOT NULL,
      customer_name VARCHAR(150) NOT NULL,
      customer_phone VARCHAR(30) NOT NULL,
      event_address TEXT NOT NULL,
      event_message TEXT NOT NULL,
      notes TEXT,
      with_delivery BOOLEAN NOT NULL DEFAULT true,
      with_installation BOOLEAN NOT NULL DEFAULT true,
      subtotal NUMERIC(15, 2) NOT NULL DEFAULT 0,
      delivery_fee NUMERIC(15, 2) NOT NULL DEFAULT 0,
      installation_fee NUMERIC(15, 2) NOT NULL DEFAULT 0,
      total_amount NUMERIC(15, 2) NOT NULL,
      booking_status VARCHAR(30) NOT NULL DEFAULT 'pending_payment',
      payment_deadline TIMESTAMP WITH TIME ZONE,
      returned_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS subtotal NUMERIC(15, 2) NOT NULL DEFAULT 0',
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC(15, 2) NOT NULL DEFAULT 0',
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS installation_fee NUMERIC(15, 2) NOT NULL DEFAULT 0',
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS payment_deadline TIMESTAMP WITH TIME ZONE',
    'ALTER TABLE bookings ADD COLUMN IF NOT EXISTS returned_at TIMESTAMP WITH TIME ZONE',
    "ALTER TABLE bookings ALTER COLUMN booking_status SET DEFAULT 'pending_payment'",
    'CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id)',
    'CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(booking_status)',
    '''CREATE TABLE IF NOT EXISTS addresses (
      id VARCHAR(50) PRIMARY KEY, user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      label VARCHAR(50) NOT NULL, recipient_name VARCHAR(100) NOT NULL,
      phone VARCHAR(30) NOT NULL, address_line TEXT NOT NULL, city VARCHAR(100) NOT NULL DEFAULT '',
      postal_code VARCHAR(20), is_primary BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS favorites (
      user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      product_id VARCHAR(50) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, product_id)
    )''',
    '''CREATE TABLE IF NOT EXISTS payment_methods (
      id VARCHAR(50) PRIMARY KEY, type VARCHAR(30) NOT NULL, name VARCHAR(100) NOT NULL,
      account_number VARCHAR(100), account_name VARCHAR(150), bank_code VARCHAR(50),
      logo_url TEXT, is_active BOOLEAN NOT NULL DEFAULT true, created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS payments (
      id VARCHAR(50) PRIMARY KEY, booking_id VARCHAR(50) NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
      user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      amount NUMERIC(15,2) NOT NULL, payment_method VARCHAR(50) NOT NULL,
      proof_url TEXT, status VARCHAR(30) NOT NULL DEFAULT 'pending', rejection_reason TEXT,
      verified_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS notifications (
      id VARCHAR(50) PRIMARY KEY, user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(150) NOT NULL, message TEXT NOT NULL, type VARCHAR(50) NOT NULL,
      booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE SET NULL,
      booking_code VARCHAR(50), is_read BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS password_reset_tokens (
      token_hash VARCHAR(64) PRIMARY KEY, user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      expires_at TIMESTAMPTZ NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE IF NOT EXISTS reviews (
      id VARCHAR(50) PRIMARY KEY,
      booking_id VARCHAR(50) UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
      product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,
      user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
      rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
      comment TEXT,
      admin_response TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )''',
    'ALTER TABLE reviews ADD COLUMN IF NOT EXISTS admin_response TEXT',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_reviews_booking_unique ON reviews(booking_id)',
  ];
  for (final sql in bookingAndAccountSchema) {
    await pool.execute(sql);
  }
  await pool.execute(
    "DELETE FROM users WHERE LOWER(email) IN ('geminiflo@user.com', 'user@geminiflo.com', 'admin@geminiflo.com')",
  );
  await pool.execute(
    "UPDATE users SET role = 'user' WHERE role = 'admin' AND LOWER(email) <> 'geminiflo@admin.com'",
  );

  const categoryNames = [
    'Pernikahan',
    'Grand Opening',
    'Ulang Tahun',
    'Duka Cita',
    'Wisuda',
    'Promosi',
    'Papan Bunga',
  ];
  for (var index = 0; index < categoryNames.length; index++) {
    final name = categoryNames[index];
    final id = '${index + 1}';
    await pool.execute(
      Sql.named('''INSERT INTO categories (id, name, slug, description, icon)
        VALUES (@id, @name, @slug, @description, @icon)
        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name,
          slug = EXCLUDED.slug, description = EXCLUDED.description'''),
      parameters: {
        'id': id,
        'name': name,
        'slug': name.toLowerCase().replaceAll(' ', '-'),
        'description': 'Kategori produk papan bunga GEMINIFLO',
        'icon': 'local_florist',
      },
    );
  }

  const seed = [
    ('Landscape VI', 110000),
    ('Thumbelina V2', 150000),
    ('Kubah Pink', 80000),
    ('Standing Black', 150000),
    ('Maroon', 150000),
    ('Potret V2', 150000),
    ('Pink I', 140000),
    ('Pink White', 150000),
    ('Blue', 140000),
    ('Pink Fanta', 150000),
    ('Standing Ungu', 150000),
    ('Convex Mirror', 155000),
    ('Bulat Pink V2', 80000),
    ('Blue White', 85000),
    ('Bulat Maroon', 85000),
  ];
  for (var index = 0; index < seed.length; index++) {
    final number = index + 1;
    final name = seed[index].$1;
    await pool.execute(
      Sql.named('''INSERT INTO products
        (id, sku, category_id, category_name, name, description, price,
         dimension, stock, stock_available, image_urls, is_available,
         is_active, is_featured, availability_status)
        VALUES (@id, @sku, '7', 'Papan Bunga', @name, @description, @price,
         'Sesuai model foto', 1, 1, @images, true, true, @featured, 'available')
        ON CONFLICT (id) DO NOTHING'''),
      parameters: {
        'id': 'GF-PB-${number.toString().padLeft(3, '0')}',
        'sku': 'GF-PB-${number.toString().padLeft(3, '0')}',
        'name': name,
        'description':
            'Model $name sesuai foto katalog. Tulisan pada papan dapat disesuaikan dengan kebutuhan pemesan.',
        'price': seed[index].$2,
        'images': ['assets/images/products/geminiflo_$number.jpg'],
        'featured': number <= 3,
      },
    );
  }
}

Future<void> _handle(HttpRequest request, Pool pool) async {
  request.response.headers
    ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
    ..set(
      HttpHeaders.accessControlAllowMethodsHeader,
      'GET, POST, PUT, DELETE, OPTIONS',
    )
    ..set(
      HttpHeaders.accessControlAllowHeadersHeader,
      'Content-Type, Authorization',
    );

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }
  if (request.uri.path == '/health') {
    await _respond(request, HttpStatus.ok, {'status': 'ok'});
    return;
  }

  try {
    final segments = request.uri.pathSegments;
    if (segments.length < 2 || segments.first != 'api') {
      await _respond(request, HttpStatus.notFound, {
        'error': 'Rute tidak ditemukan.',
      });
      return;
    }
    await _expirePendingBookings(pool);
    if (segments[1] == 'register' || segments[1] == 'login') {
      await _auth(request, pool, segments[1]);
      return;
    }
    if (segments[1] == 'google-login') {
      await _googleLogin(request, pool);
      return;
    }
    if (segments[1] == 'logout') {
      if (request.method != 'POST') {
        await _apiFailure(
          request,
          HttpStatus.methodNotAllowed,
          'Metode tidak didukung.',
        );
        return;
      }
      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      if (authorization != null && authorization.startsWith('Bearer ')) {
        final token = authorization.substring(7).trim();
        if (token.isNotEmpty) {
          await pool.execute(
            Sql.named('DELETE FROM auth_sessions WHERE token_hash = @hash'),
            parameters: {'hash': sha256.convert(utf8.encode(token)).toString()},
          );
        }
      }
      await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
      return;
    }
    if (segments[1] == 'forgot-password' || segments[1] == 'reset-password') {
      await _passwordReset(request, pool, segments[1]);
      return;
    }
    if (segments[1] == 'payment-methods' && request.method == 'GET') {
      await _paymentMethods(request, pool);
      return;
    }
    if (segments[1] == 'payments') {
      final user = await _authenticatedUser(request, pool);
      if (user == null) {
        await _apiFailure(
          request,
          HttpStatus.unauthorized,
          'Sesi masuk tidak valid.',
        );
        return;
      }
      await _paymentProof(request, pool, segments, user);
      return;
    }
    if (segments[1] == 'profile') {
      final user = await _authenticatedUser(request, pool);
      if (user == null) {
        await _apiFailure(
          request,
          HttpStatus.unauthorized,
          'Sesi masuk tidak valid. Silakan masuk kembali.',
        );
        return;
      }
      await _profile(request, pool, user, segments);
      return;
    }
    if (segments[1] == 'addresses' ||
        segments[1] == 'favorites' ||
        segments[1] == 'notifications') {
      final user = await _authenticatedUser(request, pool);
      if (user == null) {
        await _apiFailure(
          request,
          HttpStatus.unauthorized,
          'Sesi masuk tidak valid. Silakan masuk kembali.',
        );
        return;
      }
      if (segments[1] == 'addresses')
        await _addresses(request, pool, segments, user);
      if (segments[1] == 'favorites')
        await _favorites(request, pool, segments, user);
      if (segments[1] == 'notifications')
        await _notifications(request, pool, segments, user);
      return;
    }
    if (segments[1] == 'bookings') {
      final user = await _authenticatedUser(request, pool);
      if (user == null) {
        await _apiFailure(
          request,
          HttpStatus.unauthorized,
          'Sesi masuk tidak valid. Silakan masuk kembali.',
        );
        return;
      }
      await _bookings(request, pool, segments, user);
      return;
    }
    if (segments[1] == 'admin' &&
        segments.length >= 3 &&
        segments[2] == 'bookings') {
      final user = await _authenticatedUser(request, pool);
      if (user == null) {
        await _apiFailure(
          request,
          HttpStatus.unauthorized,
          'Sesi masuk tidak valid. Silakan masuk kembali.',
        );
        return;
      }
      if (user['role'] != 'admin') {
        await _apiFailure(request, HttpStatus.forbidden, 'Akses khusus admin.');
        return;
      }
      await _adminBookings(request, pool, segments, user);
      return;
    }
    if (segments[1] == 'admin' &&
        segments.length >= 3 &&
        segments[2] == 'reviews') {
      final user = await _authenticatedUser(request, pool);
      if (user == null || user['role'] != 'admin') {
        await _apiFailure(
          request,
          user == null ? HttpStatus.unauthorized : HttpStatus.forbidden,
          'Akses admin diperlukan.',
        );
        return;
      }
      final rows = await pool.execute(
        '''SELECT r.*,u.name AS customer_name,p.name AS product_name
        FROM reviews r JOIN users u ON u.id=r.user_id LEFT JOIN products p ON p.id=r.product_id
        ORDER BY r.created_at DESC LIMIT 200''',
      );
      await _respond(request, HttpStatus.ok, {
        'success': true,
        'data': {'reviews': rows.map(_reviewJson).toList()},
      });
      return;
    }
    if (segments[1] == 'admin' &&
        segments.length >= 3 &&
        segments[2] == 'payments') {
      final user = await _authenticatedUser(request, pool);
      if (user == null || user['role'] != 'admin') {
        await _apiFailure(
          request,
          user == null ? HttpStatus.unauthorized : HttpStatus.forbidden,
          'Akses admin diperlukan.',
        );
        return;
      }
      await _adminPayments(request, pool, segments);
      return;
    }
    if (segments[1] == 'admin' &&
        segments.length >= 3 &&
        segments[2] == 'customers') {
      final user = await _authenticatedUser(request, pool);
      if (user == null || user['role'] != 'admin') {
        await _apiFailure(
          request,
          user == null ? HttpStatus.unauthorized : HttpStatus.forbidden,
          'Akses admin diperlukan.',
        );
        return;
      }
      await _adminCustomers(request, pool, segments);
      return;
    }
    if (segments[1] == 'admin' &&
        segments.length >= 3 &&
        segments[2] == 'payment-methods') {
      final user = await _authenticatedUser(request, pool);
      if (user == null || user['role'] != 'admin') {
        await _apiFailure(
          request,
          user == null ? HttpStatus.unauthorized : HttpStatus.forbidden,
          'Akses admin diperlukan.',
        );
        return;
      }
      await _adminPaymentMethods(request, pool, segments);
      return;
    }
    if (segments[1] == 'categories' && request.method == 'GET') {
      final result = await pool.execute('''
        SELECT c.id, c.name, c.icon, COUNT(p.id)::int AS product_count
        FROM categories c LEFT JOIN products p ON p.category_id = c.id AND p.is_active = true
        GROUP BY c.id ORDER BY c.id
      ''');
      await _respond(request, HttpStatus.ok, {
        'categories': result.map(_rowJson).toList(),
      });
      return;
    }
    if (segments[1] == 'products') {
      await _products(request, pool, segments);
      return;
    }
    await _respond(request, HttpStatus.notFound, {
      'error': 'Rute tidak ditemukan.',
    });
  } catch (error) {
    final status = error is FormatException
        ? HttpStatus.badRequest
        : error is StateError
        ? HttpStatus.notFound
        : HttpStatus.internalServerError;
    await _respond(request, status, {
      'error': error is FormatException || error is StateError
          ? error.toString()
          : 'Permintaan ke basis data gagal.',
    });
  }
}

Future<void> _expirePendingBookings(Pool pool) async {
  final expired = await pool.execute("""
    UPDATE bookings SET booking_status='expired'
    WHERE booking_status='pending_payment' AND payment_deadline<=NOW()
    RETURNING id,user_id,booking_code
  """);
  for (final row in expired) {
    final booking = row.toColumnMap();
    await pool.execute(
      Sql.named(
        '''INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code)
      VALUES(@id,@user,'Batas pembayaran terlewati',@message,'orderStatusChanged',@booking,@code)''',
      ),
      parameters: {
        'id': 'NTF-${_randomToken().substring(0, 20)}',
        'user': booking['user_id'],
        'message':
            'Booking ${booking['booking_code']} kedaluwarsa; stok telah tersedia kembali.',
        'booking': booking['id'],
        'code': booking['booking_code'],
      },
    );
  }
}

Future<void> _auth(HttpRequest request, Pool pool, String action) async {
  if (request.method != 'POST') {
    await _apiFailure(
      request,
      HttpStatus.methodNotAllowed,
      'Metode tidak didukung.',
    );
    return;
  }
  final body = await _readBody(request);
  if (action == 'register') {
    final name = _requiredString(body, 'name');
    final username = _requiredString(body, 'username').toLowerCase();
    final email = _requiredString(body, 'email').toLowerCase();
    if (email == 'geminiflo@admin.com') {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Email admin hanya digunakan untuk akun admin.',
      );
      return;
    }
    final phone = _requiredString(body, 'phone');
    final password = _requiredString(body, 'password');
    if (password != body['password_confirmation']) {
      await _apiFailure(
        request,
        HttpStatus.badRequest,
        'Konfirmasi kata sandi tidak sama.',
      );
      return;
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9._]{2,29}$').hasMatch(username) ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ||
        password.length < 6) {
      await _apiFailure(
        request,
        HttpStatus.badRequest,
        'Data registrasi tidak valid.',
      );
      return;
    }
    final duplicate = await pool.execute(
      Sql.named(
        'SELECT id FROM users WHERE LOWER(email) = @email OR LOWER(username) = @username',
      ),
      parameters: {'email': email, 'username': username},
    );
    if (duplicate.isNotEmpty) {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Email atau username sudah terdaftar.',
      );
      return;
    }
    final salt = _randomToken();
    final userId = 'USR-${_randomToken().substring(0, 20)}';
    final inserted = await pool.execute(
      Sql.named('''INSERT INTO users
        (id, name, username, email, phone, role, avatar_url, password_salt, password_hash)
        VALUES (@id, @name, @username, @email, @phone, 'user', @avatar, @salt, @hash)
        RETURNING id, name, username, email, phone, role, avatar_url'''),
      parameters: {
        'id': userId,
        'name': name,
        'username': username,
        'email': email,
        'phone': phone,
        'avatar': body['avatar']?.toString(),
        'salt': salt,
        'hash': _passwordHash(password, salt),
      },
    );
    await _respondAuthSuccess(request, pool, inserted.first);
    return;
  }

  final identifier = _requiredString(body, 'email').toLowerCase();
  final password = _requiredString(body, 'password');
  final rows = await pool.execute(
    Sql.named('''SELECT id, name, username, email, phone, role, avatar_url,
        password_salt, password_hash FROM users
        WHERE LOWER(email) = @identifier OR LOWER(username) = @identifier'''),
    parameters: {'identifier': identifier},
  );
  if (rows.isEmpty) {
    await _apiFailure(
      request,
      HttpStatus.unauthorized,
      'Username/email atau kata sandi salah.',
    );
    return;
  }
  final row = rows.first;
  final values = row.toColumnMap();
  final salt = values['password_salt']?.toString() ?? '';
  final expected = values['password_hash']?.toString() ?? '';
  if (salt.isEmpty ||
      !_constantTimeEquals(_passwordHash(password, salt), expected)) {
    await _apiFailure(
      request,
      HttpStatus.unauthorized,
      'Username/email atau kata sandi salah.',
    );
    return;
  }
  await _respondAuthSuccess(request, pool, row);
}

Future<void> _respondAuthSuccess(
  HttpRequest request,
  Pool pool,
  ResultRow row,
) async {
  final user = _userJson(row);
  final token = _randomToken();
  await pool.execute(
    Sql.named('''INSERT INTO auth_sessions (token_hash, user_id, expires_at)
        VALUES (@hash, @user_id, @expires)'''),
    parameters: {
      'hash': sha256.convert(utf8.encode(token)).toString(),
      'user_id': user['id'],
      'expires': DateTime.now().toUtc().add(const Duration(days: 30)),
    },
  );
  await _respond(request, HttpStatus.ok, {
    'success': true,
    'message': 'Berhasil masuk.',
    'data': {'user': user, 'token': token},
  });
}

Future<void> _googleLogin(HttpRequest request, Pool pool) async {
  if (request.method != 'POST') {
    await _apiFailure(
      request,
      HttpStatus.methodNotAllowed,
      'Metode tidak didukung.',
    );
    return;
  }
  final body = await _readBody(request);
  final idToken = body['id_token']?.toString() ?? '';
  if (idToken.isEmpty)
    throw const FormatException('Token Google wajib dikirim.');
  final apiKey = Platform.environment['FIREBASE_WEB_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    await _apiFailure(
      request,
      HttpStatus.serviceUnavailable,
      'Firebase Web API key belum diatur pada backend lokal.',
    );
    return;
  }
  final client = HttpClient();
  Map<String, dynamic> claims;
  try {
    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:lookup',
      {'key': apiKey},
    );
    final firebaseRequest = await client.postUrl(uri);
    firebaseRequest.headers.contentType = ContentType.json;
    firebaseRequest.write(jsonEncode({'idToken': idToken}));
    final response = await firebaseRequest.close();
    final decoded = jsonDecode(await response.transform(utf8.decoder).join());
    if (response.statusCode != HttpStatus.ok ||
        decoded is! Map<String, dynamic> ||
        decoded['users'] is! List ||
        (decoded['users'] as List).isEmpty) {
      await _apiFailure(
        request,
        HttpStatus.unauthorized,
        'Token Firebase tidak valid.',
      );
      return;
    }
    claims = Map<String, dynamic>.from((decoded['users'] as List).first as Map);
  } finally {
    client.close();
  }
  final email = claims['email']?.toString().toLowerCase() ?? '';
  if (claims['emailVerified'] != true ||
      email.isEmpty ||
      claims['localId'] == null) {
    await _apiFailure(
      request,
      HttpStatus.unauthorized,
      'Sesi Google tidak valid atau email belum diverifikasi.',
    );
    return;
  }
  final matches = await pool.execute(
    Sql.named(
      '''SELECT id,name,username,email,phone,role,avatar_url FROM users
    WHERE google_uid=@uid OR LOWER(email)=@email ORDER BY CASE WHEN google_uid=@uid THEN 0 ELSE 1 END LIMIT 1''',
    ),
    parameters: {'uid': claims['localId'], 'email': email},
  );
  ResultRow user;
  if (matches.isNotEmpty) {
    user = matches.first;
    final values = user.toColumnMap();
    if (values['role'] == 'admin') {
      await _apiFailure(
        request,
        HttpStatus.forbidden,
        'Akun admin harus masuk menggunakan username dan password admin.',
      );
      return;
    }
    await pool.execute(
      Sql.named(
        'UPDATE users SET google_uid=@uid,avatar_url=COALESCE(avatar_url,@avatar) WHERE id=@id',
      ),
      parameters: {
        'uid': claims['localId'],
        'avatar': claims['photoUrl'],
        'id': values['id'],
      },
    );
  } else {
    final name = claims['displayName']?.toString() ?? email.split('@').first;
    final rawHandle = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '');
    final handle = rawHandle.isEmpty ? 'customer' : rawHandle;
    final uid = claims['localId'].toString();
    final username =
        '${handle.substring(0, min(handle.length, 18))}.${uid.substring(uid.length - 6)}';
    final inserted = await pool.execute(
      Sql.named(
        '''INSERT INTO users(id,name,username,email,role,avatar_url,google_uid)
      VALUES(@id,@name,@username,@email,'user',@avatar,@uid)
      RETURNING id,name,username,email,phone,role,avatar_url''',
      ),
      parameters: {
        'id': 'USR-${_randomToken().substring(0, 20)}',
        'name': name,
        'username': username,
        'email': email,
        'avatar': claims['photoUrl'],
        'uid': uid,
      },
    );
    user = inserted.first;
  }
  await _respondAuthSuccess(request, pool, user);
}

Future<Map<String, dynamic>?> _authenticatedUser(
  HttpRequest request,
  Pool pool,
) async {
  final authorization = request.headers.value(HttpHeaders.authorizationHeader);
  if (authorization == null || !authorization.startsWith('Bearer ')) {
    return null;
  }
  final token = authorization.substring(7).trim();
  if (token.isEmpty) return null;
  final rows = await pool.execute(
    Sql.named(
      '''SELECT u.id, u.name, u.username, u.email, u.phone, u.role, u.avatar_url
      FROM auth_sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = @hash AND s.expires_at > CURRENT_TIMESTAMP''',
    ),
    parameters: {'hash': sha256.convert(utf8.encode(token)).toString()},
  );
  return rows.isEmpty ? null : _userJson(rows.first);
}

Future<void> _profile(
  HttpRequest request,
  Pool pool,
  Map<String, dynamic> user,
  List<String> segments,
) async {
  if (segments.length == 3 && segments[2] == 'change-password') {
    if (request.method != 'POST') {
      await _apiFailure(
        request,
        HttpStatus.methodNotAllowed,
        'Metode tidak didukung.',
      );
      return;
    }
    final body = await _readBody(request);
    final current = _requiredString(body, 'current_password');
    final next = _requiredString(body, 'password');
    if (next.length < 8 || next != body['password_confirmation']) {
      await _apiFailure(
        request,
        HttpStatus.badRequest,
        'Kata sandi baru minimal 8 karakter dan konfirmasinya harus sama.',
      );
      return;
    }
    final rows = await pool.execute(
      Sql.named('SELECT password_salt,password_hash FROM users WHERE id=@id'),
      parameters: {'id': user['id']},
    );
    final values = rows.first.toColumnMap();
    final salt = '${values['password_salt'] ?? ''}';
    if (!_constantTimeEquals(
      _passwordHash(current, salt),
      '${values['password_hash'] ?? ''}',
    )) {
      await _apiFailure(
        request,
        HttpStatus.unauthorized,
        'Kata sandi lama tidak sesuai.',
      );
      return;
    }
    final nextSalt = _randomToken();
    await pool.execute(
      Sql.named(
        'UPDATE users SET password_salt=@salt,password_hash=@hash WHERE id=@id',
      ),
      parameters: {
        'id': user['id'],
        'salt': nextSalt,
        'hash': _passwordHash(next, nextSalt),
      },
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  if (request.method == 'GET') {
    await _respond(request, HttpStatus.ok, {'success': true, 'data': user});
    return;
  }
  if (request.method != 'PUT') {
    await _apiFailure(
      request,
      HttpStatus.methodNotAllowed,
      'Metode tidak didukung.',
    );
    return;
  }
  final body = await _readBody(request);
  final rows = await pool.execute(
    Sql.named('''UPDATE users SET name = @name, phone = @phone,
      avatar_url = COALESCE(@avatar, avatar_url)
      WHERE id = @id
      RETURNING id, name, username, email, phone, role, avatar_url'''),
    parameters: {
      'id': user['id'],
      'name': body['name']?.toString() ?? user['name'],
      'phone': body['phone']?.toString() ?? user['phone'],
      'avatar': body['avatar']?.toString(),
    },
  );
  await _respond(request, HttpStatus.ok, {
    'success': true,
    'message': 'Profil diperbarui.',
    'data': _userJson(rows.first),
  });
}

Map<String, dynamic> _userJson(ResultRow row) {
  final values = row.toColumnMap();
  return {
    'id': '${values['id']}',
    'name': '${values['name'] ?? ''}',
    'username': values['username']?.toString(),
    'email': '${values['email'] ?? ''}',
    'phone': values['phone']?.toString(),
    'role': '${values['role'] ?? 'user'}',
    'avatar': values['avatar_url']?.toString(),
  };
}

Future<void> _seedAdminFromEnvironment(Pool pool) async {
  final requestedEmail = Platform.environment['ADMIN_EMAIL']
      ?.trim()
      .toLowerCase();
  if (requestedEmail != null &&
      requestedEmail.isNotEmpty &&
      requestedEmail != 'geminiflo@admin.com') {
    stderr.writeln(
      'ADMIN_EMAIL harus geminiflo@admin.com; akun admin lain tidak dibuat.',
    );
  }
  const email = 'geminiflo@admin.com';
  const password = 'admin000';
  final existing = await pool.execute(
    Sql.named('SELECT id FROM users WHERE LOWER(email) = @email'),
    parameters: {'email': email},
  );
  if (existing.isNotEmpty) {
    final salt = _randomToken();
    await pool.execute(
      Sql.named(
        "UPDATE users SET role = 'admin', password_salt = @salt, password_hash = @hash WHERE id = @id",
      ),
      parameters: {
        'id': existing.first.toColumnMap()['id'],
        'salt': salt,
        'hash': _passwordHash(password, salt),
      },
    );
    return;
  }
  final salt = _randomToken();
  await pool.execute(
    Sql.named('''INSERT INTO users
      (id, name, username, email, phone, role, password_salt, password_hash)
      VALUES (@id, @name, @username, @email, @phone, 'admin', @salt, @hash)'''),
    parameters: {
      'id': 'ADM-${_randomToken().substring(0, 20)}',
      'name': Platform.environment['ADMIN_NAME'] ?? 'Admin GEMINIFLO',
      'username': Platform.environment['ADMIN_USERNAME'] ?? 'geminiflo.admin',
      'email': email,
      'phone': Platform.environment['ADMIN_PHONE'],
      'salt': salt,
      'hash': _passwordHash(password, salt),
    },
  );
}

String _randomToken() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

String _passwordHash(String password, String salt) {
  final hmac = Hmac(sha256, utf8.encode(password));
  var block = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
  final derived = List<int>.from(block);
  for (var round = 1; round < 60000; round++) {
    block = hmac.convert(block).bytes;
    for (var index = 0; index < derived.length; index++) {
      derived[index] ^= block[index];
    }
  }
  return base64UrlEncode(derived).replaceAll('=', '');
}

bool _constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}

String _requiredString(Map<String, dynamic> body, String field) {
  final value = body[field]?.toString().trim() ?? '';
  if (value.isEmpty) throw FormatException('Kolom $field wajib diisi.');
  return value;
}

Future<void> _apiFailure(
  HttpRequest request,
  int status,
  String message,
) async {
  await _respond(request, status, {
    'success': false,
    'message': message,
    'data': null,
  });
}

const _bookingSelect = '''
  SELECT b.*, u.username AS customer_username, u.email AS customer_email,
    p.image_urls[1] AS product_image_url
  FROM bookings b
  JOIN users u ON u.id = b.user_id
  LEFT JOIN products p ON p.id = b.product_id
''';

Future<void> _bookings(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  final isAdmin = user['role'] == 'admin';
  if (segments.length == 4 && segments[3] == 'review') {
    final bookingId = segments[2];
    final bookings = await pool.execute(
      Sql.named(
        'SELECT id,user_id,product_id,booking_status FROM bookings WHERE id=@id AND user_id=@uid',
      ),
      parameters: {'id': bookingId, 'uid': user['id']},
    );
    if (bookings.isEmpty) throw StateError('Booking tidak ditemukan.');
    final booking = bookings.first.toColumnMap();
    if (request.method == 'GET') {
      final rows = await pool.execute(
        Sql.named(
          'SELECT * FROM reviews WHERE booking_id=@id AND user_id=@uid',
        ),
        parameters: {'id': bookingId, 'uid': user['id']},
      );
      await _respond(request, HttpStatus.ok, {
        'success': true,
        'data': {'review': rows.isEmpty ? null : _reviewJson(rows.first)},
      });
      return;
    }
    if (request.method == 'POST') {
      if (booking['booking_status'] != 'completed') {
        await _apiFailure(
          request,
          HttpStatus.conflict,
          'Ulasan dapat dikirim setelah booking selesai.',
        );
        return;
      }
      final body = await _readBody(request);
      final rating = int.tryParse('${body['rating']}');
      final comment = body['comment']?.toString().trim() ?? '';
      if (rating == null || rating < 1 || rating > 5 || comment.length > 2000)
        throw const FormatException(
          'Rating harus 1-5 dan ulasan maksimal 2000 karakter.',
        );
      final rows = await pool.execute(
        Sql.named(
          '''INSERT INTO reviews(id,booking_id,product_id,user_id,rating,comment)
        VALUES(@id,@booking,@product,@user,@rating,@comment) ON CONFLICT(booking_id) DO NOTHING RETURNING *''',
        ),
        parameters: {
          'id': 'REV-${_randomToken().substring(0, 20)}',
          'booking': bookingId,
          'product': booking['product_id'],
          'user': user['id'],
          'rating': rating,
          'comment': comment,
        },
      );
      if (rows.isEmpty) {
        await _apiFailure(
          request,
          HttpStatus.conflict,
          'Booking ini sudah memiliki ulasan.',
        );
        return;
      }
      await pool.execute(
        Sql.named(
          '''UPDATE products SET rating=(SELECT AVG(rating)::numeric(3,2) FROM reviews WHERE product_id=@product),
        review_count=(SELECT COUNT(*)::int FROM reviews WHERE product_id=@product) WHERE id=@product''',
        ),
        parameters: {'product': booking['product_id']},
      );
      await _respond(request, HttpStatus.created, {
        'success': true,
        'data': {'review': _reviewJson(rows.first)},
      });
      return;
    }
  }
  if (segments.length == 4 && segments[3] == 'payment') {
    await _userPayment(request, pool, segments[2], user);
    return;
  }
  if (segments.length == 2 && request.method == 'GET') {
    final parameters = <String, dynamic>{};
    final conditions = <String>[];
    if (!isAdmin) {
      conditions.add('b.user_id = @user_id');
      parameters['user_id'] = user['id'];
    }
    final status = request.uri.queryParameters['status'];
    if (status != null && status.isNotEmpty) {
      conditions.add('b.booking_status = @status');
      parameters['status'] = _bookingStatus(status);
    }
    final rows = await pool.execute(
      Sql.named('''$_bookingSelect
        ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
        ORDER BY b.created_at DESC'''),
      parameters: parameters,
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'bookings': rows.map(_bookingJson).toList()},
    });
    return;
  }

  if (segments.length == 2 && request.method == 'POST') {
    if (isAdmin) {
      await _apiFailure(
        request,
        HttpStatus.forbidden,
        'Admin tidak dapat membuat booking pelanggan.',
      );
      return;
    }
    final body = await _readBody(request);
    final productId = _requiredString(body, 'product_id');
    final startDate = _requiredDate(body, 'start_date');
    final endDate = _requiredDate(body, 'end_date');
    if (!endDate.isAfter(startDate)) {
      throw const FormatException(
        'Tanggal selesai harus setelah tanggal mulai.',
      );
    }
    final products = await pool.execute(
      Sql.named('''SELECT id, name, price, image_urls, stock, stock_available FROM products
        WHERE id = @id AND is_active = true AND is_available = true'''),
      parameters: {'id': productId},
    );
    if (products.isEmpty) throw StateError('Produk tidak tersedia.');
    final product = products.first.toColumnMap();
    final occupied = await pool.execute(
      Sql.named('''SELECT COUNT(*)::int AS count FROM bookings
      WHERE product_id=@product AND returned_at IS NULL AND start_date<@end AND end_date>@start
      AND (booking_status IN ('confirmed','processing','ready','completed') OR
      (booking_status='pending_payment' AND payment_deadline>NOW()))'''),
      parameters: {'product': productId, 'start': startDate, 'end': endDate},
    );
    final capacity = min(
      (product['stock'] as num?)?.toInt() ?? 1,
      (product['stock_available'] as num?)?.toInt() ?? 1,
    );
    if ((occupied.first.toColumnMap()['count'] as num).toInt() >= capacity) {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Papan bunga sudah dipesan pada tanggal tersebut.',
      );
      return;
    }
    final subtotal = (product['price'] as num).toDouble();
    final customerName = body['customer_name']?.toString().trim();
    final customerPhone = body['customer_phone']?.toString().trim();
    final address = body['event_address']?.toString().trim() ?? '';
    final message = body['event_message']?.toString().trim() ?? '';
    if (customerName == null ||
        customerName.isEmpty ||
        customerPhone == null ||
        customerPhone.isEmpty ||
        address.isEmpty ||
        message.isEmpty) {
      throw const FormatException(
        'Nama, telepon, alamat acara, dan pesan wajib diisi.',
      );
    }
    final now = DateTime.now().toUtc();
    final bookingId = 'BKG-${_randomToken().substring(0, 20)}';
    final bookingCode =
        'GF-${now.year}-${_randomToken().substring(0, 7).toUpperCase()}';
    final rows = await pool.execute(
      Sql.named('''INSERT INTO bookings
        (id, booking_code, user_id, product_id, product_name, start_date,
         end_date, customer_name, customer_phone, event_address, event_message,
         notes, with_delivery, with_installation, subtotal, delivery_fee,
         installation_fee, total_amount, booking_status, payment_deadline)
        VALUES (@id, @code, @user_id, @product_id, @product_name, @start,
         @end, @customer_name, @customer_phone, @address, @message, @notes,
         @delivery, @installation, @subtotal, 0, 0, @total, 'pending_payment',
         @deadline)
        RETURNING *'''),
      parameters: {
        'id': bookingId,
        'code': bookingCode,
        'user_id': user['id'],
        'product_id': productId,
        'product_name': product['name'],
        'start': startDate,
        'end': endDate,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'address': address,
        'message': message,
        'notes': body['notes']?.toString(),
        'delivery': body['with_delivery'] as bool? ?? true,
        'installation': body['with_installation'] as bool? ?? true,
        'subtotal': subtotal,
        'total': subtotal,
        'deadline': now.add(const Duration(hours: 24)),
      },
    );
    final fullBooking = await _findBooking(pool, bookingId);
    await _respond(request, HttpStatus.created, {
      'success': true,
      'message': 'Booking berhasil dibuat.',
      'data': {'booking': _bookingJson(fullBooking ?? rows.first)},
    });
    return;
  }

  if (segments.length == 3 && request.method == 'GET') {
    final row = await _findBooking(pool, segments[2]);
    if (row == null ||
        (!isAdmin && row.toColumnMap()['user_id'] != user['id'])) {
      throw StateError('Booking tidak ditemukan.');
    }
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'booking': _bookingJson(row)},
    });
    return;
  }

  if (segments.length == 3 && request.method == 'PUT') {
    final id = segments[2];
    final existing = await _findBooking(pool, id);
    if (existing == null) throw StateError('Booking tidak ditemukan.');
    final old = existing.toColumnMap();
    if (!isAdmin && old['user_id'] != user['id']) {
      throw StateError('Booking tidak ditemukan.');
    }
    if (!isAdmin && old['booking_status'] != 'pending_payment') {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Booking yang sudah diproses tidak dapat diubah.',
      );
      return;
    }
    final body = await _readBody(request);
    final productId = body['product_id']?.toString() ?? '${old['product_id']}';
    final productRows = await pool.execute(
      Sql.named(
        'SELECT id, name, price FROM products WHERE id = @id AND is_active = true',
      ),
      parameters: {'id': productId},
    );
    if (productRows.isEmpty) throw StateError('Produk tidak ditemukan.');
    final product = productRows.first.toColumnMap();
    final startDate = _optionalDate(
      body['start_date'],
      old['start_date'] as DateTime,
    );
    final endDate = _optionalDate(
      body['end_date'],
      old['end_date'] as DateTime,
    );
    if (!endDate.isAfter(startDate)) {
      throw const FormatException(
        'Tanggal selesai harus setelah tanggal mulai.',
      );
    }
    final subtotal = (product['price'] as num).toDouble();
    final updatedRows = await pool.execute(
      Sql.named('''UPDATE bookings SET product_id = @product_id,
        product_name = @product_name, start_date = @start, end_date = @end,
        customer_name = @customer_name, customer_phone = @customer_phone,
        event_address = @address, event_message = @message, notes = @notes,
        with_delivery = @delivery, with_installation = @installation,
        subtotal = @subtotal, total_amount = @subtotal
        WHERE id = @id RETURNING *'''),
      parameters: {
        'id': id,
        'product_id': productId,
        'product_name': product['name'],
        'start': startDate,
        'end': endDate,
        'customer_name':
            body['customer_name']?.toString() ?? old['customer_name'],
        'customer_phone':
            body['customer_phone']?.toString() ?? old['customer_phone'],
        'address': body['event_address']?.toString() ?? old['event_address'],
        'message': body['event_message']?.toString() ?? old['event_message'],
        'notes': body['notes']?.toString(),
        'delivery': body['with_delivery'] as bool? ?? old['with_delivery'],
        'installation':
            body['with_installation'] as bool? ?? old['with_installation'],
        'subtotal': subtotal,
      },
    );
    final row = await _findBooking(pool, id) ?? updatedRows.first;
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'booking': _bookingJson(row)},
    });
    return;
  }

  if (segments.length == 4 &&
      segments[3] == 'cancel' &&
      request.method == 'POST') {
    final id = segments[2];
    final existing = await _findBooking(pool, id);
    if (existing == null) throw StateError('Booking tidak ditemukan.');
    final old = existing.toColumnMap();
    if (old['user_id'] != user['id'] && !isAdmin) {
      throw StateError('Booking tidak ditemukan.');
    }
    if (!['pending_payment', 'confirmed'].contains(old['booking_status'])) {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Booking ini tidak dapat dibatalkan.',
      );
      return;
    }
    final body = await _readBody(request);
    await pool.execute(
      Sql.named('''UPDATE bookings SET booking_status = 'cancelled',
        notes = COALESCE(@reason, notes) WHERE id = @id'''),
      parameters: {'id': id, 'reason': body['reason']?.toString()},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'cancelled': true},
    });
    return;
  }

  if (segments.length == 3 && request.method == 'DELETE') {
    if (!isAdmin) {
      await _apiFailure(
        request,
        HttpStatus.forbidden,
        'Hanya admin yang dapat menghapus riwayat booking.',
      );
      return;
    }
    final deleted = await pool.execute(
      Sql.named('''DELETE FROM bookings WHERE id = @id
        AND booking_status IN ('completed', 'cancelled', 'expired')'''),
      parameters: {'id': segments[2]},
    );
    if (deleted.affectedRows == 0) {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Hanya riwayat booking selesai, batal, atau kedaluwarsa yang dapat dihapus.',
      );
      return;
    }
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'deleted': true},
    });
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode booking tidak didukung.',
  );
}

Future<void> _adminBookings(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  if (segments.length == 5 &&
      segments[4] == 'return' &&
      request.method == 'POST') {
    final rows = await pool.execute(
      Sql.named(
        '''UPDATE bookings SET returned_at=NOW(),booking_status='completed'
      WHERE id=@id AND booking_status IN ('ready','completed') AND returned_at IS NULL
      RETURNING id,booking_code,user_id''',
      ),
      parameters: {'id': segments[3]},
    );
    if (rows.isEmpty) {
      await _apiFailure(
        request,
        HttpStatus.conflict,
        'Booking harus siap atau selesai dan belum pernah dikembalikan.',
      );
      return;
    }
    final booking = rows.first.toColumnMap();
    await pool.execute(
      Sql.named('''INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code)
      VALUES(@id,@uid,@title,@message,'orderStatusChanged',@booking,@code)'''),
      parameters: {
        'id': 'NTF-${_randomToken().substring(0, 20)}',
        'uid': booking['user_id'],
        'title': 'Papan bunga telah dikembalikan',
        'message':
            'Pengembalian booking ${booking['booking_code']} telah dicatat.',
        'booking': booking['id'],
        'code': booking['booking_code'],
      },
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'returned_at': DateTime.now().toUtc().toIso8601String()},
    });
    return;
  }
  if (segments.length == 3 && request.method == 'GET') {
    await _bookings(request, pool, const ['api', 'bookings'], user);
    return;
  }
  if (segments.length == 5 &&
      segments[4] == 'status' &&
      request.method == 'PUT') {
    final body = await _readBody(request);
    final status = _bookingStatus(_requiredString(body, 'status'));
    final result = await pool.execute(
      Sql.named(
        'UPDATE bookings SET booking_status = @status WHERE id = @id RETURNING id,booking_code,user_id',
      ),
      parameters: {'id': segments[3], 'status': status},
    );
    if (result.isEmpty) throw StateError('Booking tidak ditemukan.');
    final booking = result.first.toColumnMap();
    await pool.execute(
      Sql.named(
        '''INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code)
      VALUES(@id,@uid,'Status booking diperbarui',@message,'orderStatusChanged',@booking,@code)''',
      ),
      parameters: {
        'id': 'NTF-${_randomToken().substring(0, 20)}',
        'uid': booking['user_id'],
        'message': 'Booking ${booking['booking_code']} kini berstatus $status.',
        'booking': booking['id'],
        'code': booking['booking_code'],
      },
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'updated': true},
    });
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode admin booking tidak didukung.',
  );
}

Future<ResultRow?> _findBooking(Pool pool, String id) async {
  final rows = await pool.execute(
    Sql.named('$_bookingSelect WHERE b.id = @id'),
    parameters: {'id': id},
  );
  return rows.isEmpty ? null : rows.first;
}

Map<String, dynamic> _bookingJson(ResultRow row) {
  final values = row.toColumnMap();
  final imageUrls = values['image_urls'];
  return {
    'id': '${values['id']}',
    'bookingCode': '${values['booking_code']}',
    'productId': values['product_id']?.toString() ?? '',
    'productName': '${values['product_name'] ?? ''}',
    'productImageUrl':
        values['product_image_url'] ??
        (imageUrls is List && imageUrls.isNotEmpty ? imageUrls.first : null),
    'customerId': '${values['user_id']}',
    'customerName': '${values['customer_name']}',
    'customerUsername': values['customer_username']?.toString(),
    'customerEmail': values['customer_email']?.toString(),
    'customerPhone': '${values['customer_phone']}',
    'eventAddress': '${values['event_address']}',
    'eventMessage': '${values['event_message']}',
    'notes': values['notes']?.toString(),
    'startDate': (values['start_date'] as DateTime).toIso8601String(),
    'endDate': (values['end_date'] as DateTime).toIso8601String(),
    'withDelivery': values['with_delivery'] as bool? ?? true,
    'withInstallation': values['with_installation'] as bool? ?? true,
    'subtotal': (values['subtotal'] as num?)?.toDouble() ?? 0,
    'deliveryFee': (values['delivery_fee'] as num?)?.toDouble() ?? 0,
    'installationFee': (values['installation_fee'] as num?)?.toDouble() ?? 0,
    'total': (values['total_amount'] as num).toDouble(),
    'status': values['booking_status']?.toString() ?? 'pending_payment',
    'createdAt': (values['created_at'] as DateTime).toIso8601String(),
    'paymentDeadline': (values['payment_deadline'] as DateTime?)
        ?.toIso8601String(),
    'returnedAt': (values['returned_at'] as DateTime?)?.toIso8601String(),
  };
}

String _bookingStatus(String status) {
  const allowed = {
    'pending_payment',
    'confirmed',
    'processing',
    'ready',
    'completed',
    'cancelled',
    'expired',
  };
  final normalized = status.toLowerCase();
  if (!allowed.contains(normalized)) {
    throw const FormatException('Status booking tidak valid.');
  }
  return normalized;
}

DateTime _requiredDate(Map<String, dynamic> body, String field) {
  final value = body[field]?.toString();
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Tanggal $field tidak valid.');
  return parsed.toUtc();
}

DateTime _optionalDate(dynamic value, DateTime fallback) =>
    value == null ? fallback : DateTime.tryParse('$value')?.toUtc() ?? fallback;

Future<void> _passwordReset(
  HttpRequest request,
  Pool pool,
  String action,
) async {
  if (request.method != 'POST') {
    await _apiFailure(
      request,
      HttpStatus.methodNotAllowed,
      'Metode tidak didukung.',
    );
    return;
  }
  final body = await _readBody(request);
  if (action == 'reset-password') {
    final email = _requiredString(body, 'email').toLowerCase();
    final token = _requiredString(body, 'token');
    final password = _requiredString(body, 'password');
    if (password.length < 8 || password != body['password_confirmation']) {
      await _apiFailure(
        request,
        HttpStatus.badRequest,
        'Kata sandi minimal 8 karakter dan konfirmasinya harus sama.',
      );
      return;
    }
    final matches = await pool.execute(
      Sql.named('''
      SELECT u.id FROM password_reset_tokens t JOIN users u ON u.id=t.user_id
      WHERE u.email=@email AND t.token_hash=@hash AND t.expires_at>CURRENT_TIMESTAMP
    '''),
      parameters: {
        'email': email,
        'hash': sha256.convert(utf8.encode(token)).toString(),
      },
    );
    if (matches.isEmpty) {
      await _apiFailure(
        request,
        HttpStatus.badRequest,
        'Tautan reset tidak valid atau sudah kedaluwarsa.',
      );
      return;
    }
    final userId = matches.first.toColumnMap()['id'];
    final salt = _randomToken();
    await pool.execute(
      Sql.named(
        'UPDATE users SET password_salt=@salt,password_hash=@hash WHERE id=@id',
      ),
      parameters: {
        'salt': salt,
        'hash': _passwordHash(password, salt),
        'id': userId,
      },
    );
    await pool.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE user_id=@id'),
      parameters: {'id': userId},
    );
    await pool.execute(
      Sql.named('DELETE FROM auth_sessions WHERE user_id=@id'),
      parameters: {'id': userId},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'message': 'Kata sandi berhasil diperbarui.',
      'data': null,
    });
    return;
  }

  final email = _requiredString(body, 'email').toLowerCase();
  final resendKey = Platform.environment['RESEND_API_KEY'];
  final from = Platform.environment['MAIL_FROM'];
  if (resendKey == null || resendKey.isEmpty || from == null || from.isEmpty) {
    await _apiFailure(
      request,
      HttpStatus.serviceUnavailable,
      'Layanan email reset belum dikonfigurasi pada backend.',
    );
    return;
  }
  final users = await pool.execute(
    Sql.named('SELECT id,name FROM users WHERE email=@email'),
    parameters: {'email': email},
  );
  if (users.isNotEmpty) {
    final row = users.first.toColumnMap();
    final token = _randomToken();
    final hash = sha256.convert(utf8.encode(token)).toString();
    await pool.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE user_id=@id'),
      parameters: {'id': row['id']},
    );
    await pool.execute(
      Sql.named(
        'INSERT INTO password_reset_tokens(token_hash,user_id,expires_at) VALUES(@hash,@id,@expires)',
      ),
      parameters: {
        'hash': hash,
        'id': row['id'],
        'expires': DateTime.now().toUtc().add(const Duration(minutes: 30)),
      },
    );
    final base =
        Platform.environment['APP_RESET_URL'] ?? 'geminiflo://reset-password';
    final link = Uri.parse(base)
        .replace(queryParameters: {'email': email, 'token': token});
    final http = HttpClient();
    try {
      final req = await http.postUrl(Uri.https('api.resend.com', '/emails'));
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $resendKey')
        ..contentType = ContentType.json;
      req.write(
        jsonEncode({
          'from': from,
          'to': [email],
          'subject': 'Reset kata sandi GEMINIFLO',
          'html':
              '<p>Halo ${htmlEscape.convert('${row['name']}')},</p><p>Gunakan tautan berikut untuk mengatur kata sandi baru. Tautan berlaku 30 menit.</p><p><a href="$link">Reset Kata Sandi</a></p><p>Jika Anda tidak meminta reset, abaikan email ini.</p>',
        }),
      );
      final res = await req.close();
      await res.drain<void>();
      if (res.statusCode < 200 || res.statusCode >= 300)
        throw StateError('Penyedia email menolak pengiriman.');
    } catch (_) {
      await pool.execute(
        Sql.named('DELETE FROM password_reset_tokens WHERE user_id=@id'),
        parameters: {'id': row['id']},
      );
      rethrow;
    } finally {
      http.close(force: true);
    }
  }
  await _respond(request, HttpStatus.ok, {
    'success': true,
    'message': 'Jika alamat terdaftar, email reset telah dikirim.',
    'data': null,
  });
}

Future<void> _paymentMethods(HttpRequest request, Pool pool) async {
  final rows = await pool.execute(
    '''SELECT id,type,name,account_number,account_name,
    bank_code,logo_url,is_active FROM payment_methods WHERE is_active=true ORDER BY name''',
  );
  await _respond(request, HttpStatus.ok, {
    'methods': rows.map((row) {
      final v = row.toColumnMap();
      return {
        'id': v['id'],
        'type': v['type'],
        'name': v['name'],
        'accountNumber': v['account_number'],
        'accountName': v['account_name'],
        'bankCode': v['bank_code'],
        'logoUrl': v['logo_url'],
        'isActive': v['is_active'],
      };
    }).toList(),
  });
}

Future<void> _adminPaymentMethods(
  HttpRequest request,
  Pool pool,
  List<String> segments,
) async {
  final id = segments.length > 3 ? segments[3] : null;
  if (id == null && request.method == 'GET') {
    final rows = await pool.execute(
      'SELECT id,type,name,account_number,account_name,bank_code,logo_url,is_active FROM payment_methods ORDER BY name',
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {
        'methods': rows.map((r) {
          final v = r.toColumnMap();
          return {
            'id': v['id'],
            'type': v['type'],
            'name': v['name'],
            'accountNumber': v['account_number'],
            'accountName': v['account_name'],
            'bankCode': v['bank_code'],
            'logoUrl': v['logo_url'],
            'isActive': v['is_active'],
          };
        }).toList(),
      },
    });
    return;
  }
  if ((id == null && request.method == 'POST') ||
      (id != null && request.method == 'PUT')) {
    final b = await _readBody(request);
    final newId = id ?? 'PM-${_randomToken().substring(0, 18)}';
    final args = {
      'id': newId,
      'type': _requiredString(b, 'type'),
      'name': _requiredString(b, 'name'),
      'number': b['account_number']?.toString(),
      'account': b['account_name']?.toString(),
      'bank': b['bank_code']?.toString(),
      'logo': b['logo_url']?.toString(),
      'active': b['is_active'] as bool? ?? true,
    };
    await pool.execute(
      Sql.named(
        id == null
            ? '''INSERT INTO payment_methods(id,type,name,account_number,account_name,bank_code,logo_url,is_active) VALUES(@id,@type,@name,@number,@account,@bank,@logo,@active)'''
            : '''UPDATE payment_methods SET type=@type,name=@name,account_number=@number,account_name=@account,bank_code=@bank,logo_url=@logo,is_active=@active WHERE id=@id''',
      ),
      parameters: args,
    );
    await _respond(request, id == null ? HttpStatus.created : HttpStatus.ok, {
      'success': true,
      'data': {'id': newId},
    });
    return;
  }
  if (id != null && request.method == 'DELETE') {
    await pool.execute(
      Sql.named('DELETE FROM payment_methods WHERE id=@id'),
      parameters: {'id': id},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode rekening pembayaran tidak didukung.',
  );
}

Future<void> _addresses(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  final id = segments.length > 2 ? segments[2] : null;
  if (id == null && request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named(
        'SELECT * FROM addresses WHERE user_id=@uid ORDER BY is_primary DESC,created_at DESC',
      ),
      parameters: {'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'addresses': rows.map(_addressJson).toList()},
    });
    return;
  }
  if (id != null &&
      segments.length == 4 &&
      segments[3] == 'primary' &&
      request.method == 'PUT') {
    await pool.execute(
      Sql.named('UPDATE addresses SET is_primary=(id=@id) WHERE user_id=@uid'),
      parameters: {'id': id, 'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  if ((id == null && request.method == 'POST') ||
      (id != null && request.method == 'PUT')) {
    final body = await _readBody(request);
    final isNew = id == null;
    final addressId = id ?? 'ADR-${_randomToken().substring(0, 18)}';
    final params = {
      'id': addressId,
      'uid': user['id'],
      'label': _requiredString(body, 'label'),
      'name': _requiredString(body, 'recipient_name'),
      'phone': _requiredString(body, 'phone'),
      'address': _requiredString(body, 'address_line'),
      'city': body['city']?.toString() ?? '',
      'postal': body['postal_code']?.toString(),
      'primary': body['is_primary'] as bool? ?? false,
    };
    if (params['primary'] == true)
      await pool.execute(
        Sql.named('UPDATE addresses SET is_primary=false WHERE user_id=@uid'),
        parameters: {'uid': user['id']},
      );
    final sql = isNew
        ? '''INSERT INTO addresses(id,user_id,label,recipient_name,phone,address_line,city,postal_code,is_primary)
      VALUES(@id,@uid,@label,@name,@phone,@address,@city,@postal,@primary)'''
        : '''UPDATE addresses SET label=@label,recipient_name=@name,phone=@phone,address_line=@address,city=@city,postal_code=@postal,is_primary=@primary WHERE id=@id AND user_id=@uid''';
    final result = await pool.execute(Sql.named(sql), parameters: params);
    if (!isNew && result.affectedRows == 0)
      throw StateError('Alamat tidak ditemukan.');
    final rows = await pool.execute(
      Sql.named('SELECT * FROM addresses WHERE id=@id AND user_id=@uid'),
      parameters: {'id': addressId, 'uid': user['id']},
    );
    await _respond(request, isNew ? HttpStatus.created : HttpStatus.ok, {
      'success': true,
      'data': {'address': _addressJson(rows.first)},
    });
    return;
  }
  if (id != null && segments.length == 3 && request.method == 'DELETE') {
    await pool.execute(
      Sql.named('DELETE FROM addresses WHERE id=@id AND user_id=@uid'),
      parameters: {'id': id, 'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode alamat tidak didukung.',
  );
}

Map<String, dynamic> _addressJson(ResultRow row) {
  final v = row.toColumnMap();
  return {
    'id': v['id'],
    'label': v['label'],
    'recipientName': v['recipient_name'],
    'phone': v['phone'],
    'addressDetail': v['address_line'],
    'city': v['city'],
    'postalCode': v['postal_code'],
    'isPrimary': v['is_primary'],
  };
}

Future<void> _adminCustomers(
  HttpRequest request,
  Pool pool,
  List<String> segments,
) async {
  if (segments.length == 3 && request.method == 'GET') {
    final rows = await pool.execute(
      '''SELECT u.id,u.name,u.email,u.phone,u.created_at,
      COUNT(b.id)::int total_bookings,COALESCE(SUM(b.total_amount) FILTER (WHERE b.booking_status<>'cancelled'),0) total_spent
      FROM users u LEFT JOIN bookings b ON b.user_id=u.id WHERE u.role='user' GROUP BY u.id ORDER BY u.created_at DESC''',
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {
        'customers': rows.map((r) {
          final v = r.toColumnMap();
          return {
            'id': v['id'],
            'name': v['name'],
            'email': v['email'],
            'phone': v['phone'],
            'totalBookings': v['total_bookings'],
            'totalSpent': v['total_spent'],
            'joinDate': (v['created_at'] as DateTime).toIso8601String(),
          };
        }).toList(),
      },
    });
    return;
  }
  if (segments.length == 4 && request.method == 'DELETE') {
    final result = await pool.execute(
      Sql.named("DELETE FROM users WHERE id=@id AND role='user'"),
      parameters: {'id': segments[3]},
    );
    if (result.affectedRows == 0)
      throw StateError('Pelanggan tidak ditemukan.');
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode pelanggan tidak didukung.',
  );
}

const _paymentSelect =
    '''SELECT p.*,b.booking_code,b.total_amount,b.payment_deadline,b.customer_name,b.product_name,u.email AS customer_email FROM payments p JOIN bookings b ON b.id=p.booking_id JOIN users u ON u.id=p.user_id''';
Map<String, dynamic> _paymentJson(ResultRow row) {
  final v = row.toColumnMap();
  return {
    'id': v['id'],
    'bookingId': v['booking_id'],
    'bookingCode': v['booking_code'],
    'amount': (v['amount'] as num).toDouble(),
    'status': v['status'] == 'pending' ? 'waiting_verification' : v['status'],
    'proofImageUrl': v['proof_url'],
    'paidAt': (v['created_at'] as DateTime).toIso8601String(),
    'verifiedAt': (v['verified_at'] as DateTime?)?.toIso8601String(),
    'rejectionReason': v['rejection_reason'],
    'deadline':
        ((v['payment_deadline'] as DateTime?) ??
                DateTime.now().toUtc().add(const Duration(days: 1)))
            .toIso8601String(),
    'paymentMethod': v['payment_method'],
    'customerEmail': v['customer_email'],
    'customerName': v['customer_name'],
    'productName': v['product_name'],
  };
}

Future<void> _userPayment(
  HttpRequest request,
  Pool pool,
  String bookingId,
  Map<String, dynamic> user,
) async {
  final booking = await pool.execute(
    Sql.named(
      '''SELECT b.* FROM bookings b WHERE b.id=@id AND (@admin OR b.user_id=@uid)''',
    ),
    parameters: {
      'id': bookingId,
      'uid': user['id'],
      'admin': user['role'] == 'admin',
    },
  );
  if (booking.isEmpty) throw StateError('Booking tidak ditemukan.');
  if (request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named('$_paymentSelect WHERE p.booking_id=@id'),
      parameters: {'id': bookingId},
    );
    if (rows.isNotEmpty) {
      await _respond(request, HttpStatus.ok, {
        'success': true,
        'data': {'payment': _paymentJson(rows.first)},
      });
      return;
    }
    final b = booking.first.toColumnMap();
    final deadline =
        b['payment_deadline'] as DateTime? ??
        DateTime.now().toUtc().add(const Duration(days: 1));
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {
        'payment': {
          'id': bookingId,
          'bookingId': bookingId,
          'bookingCode': b['booking_code'],
          'amount': (b['total_amount'] as num).toDouble(),
          'status': 'unpaid',
          'deadline': deadline.toIso8601String(),
          'proofImageUrl': null,
        },
      },
    });
    return;
  }
  if (request.method == 'POST') {
    final body = await _readBody(request);
    final methodId = _requiredString(body, 'payment_method');
    final methods = await pool.execute(
      Sql.named(
        'SELECT id FROM payment_methods WHERE id=@id AND is_active=true',
      ),
      parameters: {'id': methodId},
    );
    if (methods.isEmpty) throw StateError('Metode pembayaran tidak tersedia.');
    final b = booking.first.toColumnMap();
    final id = 'PAY-${_randomToken().substring(0, 18)}';
    await pool.execute(
      Sql.named('''INSERT INTO payments(id,booking_id,user_id,amount,payment_method,status)
      VALUES(@id,@bid,@uid,@amount,@method,'unpaid') ON CONFLICT(booking_id) DO UPDATE SET
      payment_method=EXCLUDED.payment_method,amount=EXCLUDED.amount,status='unpaid',proof_url=NULL,rejection_reason=NULL
      WHERE payments.status IN ('rejected','unpaid')'''),
      parameters: {
        'id': id,
        'bid': bookingId,
        'uid': user['id'],
        'amount': b['total_amount'],
        'method': methodId,
      },
    );
    final rows = await pool.execute(
      Sql.named('$_paymentSelect WHERE p.booking_id=@id'),
      parameters: {'id': bookingId},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'payment': _paymentJson(rows.first)},
    });
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode transaksi tidak didukung.',
  );
}

Future<void> _paymentProof(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  if (segments.length != 4 ||
      segments[3] != 'proof' ||
      request.method != 'POST') {
    await _apiFailure(
      request,
      HttpStatus.methodNotAllowed,
      'Metode bukti pembayaran tidak didukung.',
    );
    return;
  }
  final body = await _readBody(request);
  final proof = _requiredString(body, 'proof');
  if (!proof.startsWith('data:image/') || proof.length > 8 * 1024 * 1024)
    throw const FormatException('Bukti harus berupa gambar maksimal 6 MB.');
  final id = segments[2];
  final rows = await pool.execute(
    Sql.named(
      '''UPDATE payments SET proof_url=@proof,status='pending',created_at=CURRENT_TIMESTAMP
    WHERE (id=@id OR booking_id=@id) AND user_id=@uid AND status IN ('pending','rejected') RETURNING booking_id''',
    ),
    parameters: {'id': id, 'uid': user['id'], 'proof': proof},
  );
  if (rows.isEmpty)
    throw StateError('Pembayaran tidak ditemukan atau sudah diverifikasi.');
  await pool.execute(
    Sql.named(
      "UPDATE bookings SET booking_status='pending_payment' WHERE id=@id",
    ),
    parameters: {'id': rows.first.toColumnMap()['booking_id']},
  );
  final payment = await pool.execute(
    Sql.named('$_paymentSelect WHERE p.booking_id=@id'),
    parameters: {'id': rows.first.toColumnMap()['booking_id']},
  );
  await _respond(request, HttpStatus.ok, {
    'success': true,
    'data': {'payment': _paymentJson(payment.first)},
  });
}

Future<void> _adminPayments(
  HttpRequest request,
  Pool pool,
  List<String> segments,
) async {
  if (segments.length == 3 && request.method == 'GET') {
    final rows = await pool.execute(
      '$_paymentSelect WHERE p.proof_url IS NOT NULL ORDER BY p.created_at DESC',
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'payments': rows.map(_paymentJson).toList()},
    });
    return;
  }
  if (segments.length == 5 &&
      segments[4] == 'verify' &&
      request.method == 'PUT') {
    final body = await _readBody(request);
    final approve = body['approve'] as bool? ?? true;
    final status = approve ? 'verified' : 'rejected';
    final rows = await pool.execute(
      Sql.named(
        '''UPDATE payments SET status=@status,rejection_reason=@reason,verified_at=CASE WHEN @approve THEN CURRENT_TIMESTAMP ELSE NULL END WHERE id=@id RETURNING booking_id,user_id''',
      ),
      parameters: {
        'id': segments[3],
        'status': status,
        'reason': body['reason'],
        'approve': approve,
      },
    );
    if (rows.isEmpty) throw StateError('Transaksi tidak ditemukan.');
    await pool.execute(
      Sql.named("UPDATE bookings SET booking_status=@status WHERE id=@id"),
      parameters: {
        'id': rows.first.toColumnMap()['booking_id'],
        'status': approve ? 'confirmed' : 'pending_payment',
      },
    );
    final booking = await _findBooking(
      pool,
      '${rows.first.toColumnMap()['booking_id']}',
    );
    if (booking != null) {
      final b = booking.toColumnMap();
      final nId = 'NTF-${_randomToken().substring(0, 18)}';
      await pool.execute(
        Sql.named(
          '''INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code) VALUES(@id,@uid,@title,@message,@type,@bid,@code)''',
        ),
        parameters: {
          'id': nId,
          'uid': rows.first.toColumnMap()['user_id'],
          'title': approve ? 'Pembayaran Dikonfirmasi' : 'Pembayaran Ditolak',
          'message': approve
              ? 'Pembayaran booking ${b['booking_code']} telah diverifikasi.'
              : 'Bukti pembayaran booking ${b['booking_code']} ditolak. ${body['reason'] ?? ''}',
          'type': approve ? 'paymentVerified' : 'paymentRejected',
          'bid': b['id'],
          'code': b['booking_code'],
        },
      );
    }
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  if (segments.length == 4 && request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named('$_paymentSelect WHERE p.id=@id OR p.booking_id=@id'),
      parameters: {'id': segments[3]},
    );
    if (rows.isEmpty) throw StateError('Transaksi tidak ditemukan.');
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'payment': _paymentJson(rows.first)},
    });
    return;
  }
  if (segments.length == 4 && request.method == 'DELETE') {
    await pool.execute(
      Sql.named('DELETE FROM payments WHERE id=@id OR booking_id=@id'),
      parameters: {'id': segments[3]},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode admin pembayaran tidak didukung.',
  );
}

Future<void> _favorites(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  if (segments.length == 2 && request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named(
        '''SELECT $_productFields FROM products p JOIN favorites f ON f.product_id=p.id WHERE f.user_id=@uid ORDER BY f.created_at DESC''',
      ),
      parameters: {'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {
      'products': rows.map(_rowJson).toList(),
    });
    return;
  }
  if (segments.length == 3 && request.method == 'POST') {
    final productId = segments[2];
    final exists = await pool.execute(
      Sql.named(
        'SELECT 1 FROM favorites WHERE user_id=@uid AND product_id=@pid',
      ),
      parameters: {'uid': user['id'], 'pid': productId},
    );
    if (exists.isEmpty)
      await pool.execute(
        Sql.named(
          'INSERT INTO favorites(user_id,product_id) VALUES(@uid,@pid) ON CONFLICT DO NOTHING',
        ),
        parameters: {'uid': user['id'], 'pid': productId},
      );
    else
      await pool.execute(
        Sql.named(
          'DELETE FROM favorites WHERE user_id=@uid AND product_id=@pid',
        ),
        parameters: {'uid': user['id'], 'pid': productId},
      );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'is_favorite': exists.isEmpty},
    });
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode favorit tidak didukung.',
  );
}

Future<void> _notifications(
  HttpRequest request,
  Pool pool,
  List<String> segments,
  Map<String, dynamic> user,
) async {
  if (segments.length == 2 && request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named(
        'SELECT * FROM notifications WHERE user_id=@uid ORDER BY created_at DESC',
      ),
      parameters: {'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {
        'notifications': rows.map((r) {
          final v = r.toColumnMap();
          return {
            'id': v['id'],
            'title': v['title'],
            'message': v['message'],
            'type': v['type'],
            'bookingId': v['booking_id'],
            'bookingCode': v['booking_code'],
            'isRead': v['is_read'],
            'createdAt': (v['created_at'] as DateTime).toIso8601String(),
          };
        }).toList(),
      },
    });
    return;
  }
  if (segments.length == 2 && request.method == 'POST') {
    final b = await _readBody(request);
    final id = 'NTF-${_randomToken().substring(0, 18)}';
    await pool.execute(
      Sql.named(
        '''INSERT INTO notifications(id,user_id,title,message,type,booking_id,booking_code) VALUES(@id,@uid,@title,@message,@type,@bid,@code)''',
      ),
      parameters: {
        'id': id,
        'uid': user['id'],
        'title': _requiredString(b, 'title'),
        'message': _requiredString(b, 'message'),
        'type': _requiredString(b, 'type'),
        'bid': b['booking_id'],
        'code': b['booking_code'],
      },
    );
    await _respond(request, HttpStatus.created, {
      'success': true,
      'data': {'id': id},
    });
    return;
  }
  if (segments.length == 3 &&
      segments[2] == 'read-all' &&
      request.method == 'PUT') {
    await pool.execute(
      Sql.named('UPDATE notifications SET is_read=true WHERE user_id=@uid'),
      parameters: {'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  if (segments.length == 3 && request.method == 'PUT') {
    await pool.execute(
      Sql.named(
        'UPDATE notifications SET is_read=true WHERE id=@id AND user_id=@uid',
      ),
      parameters: {'id': segments[2], 'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  if (segments.length == 3 &&
      segments[2] == 'clear' &&
      request.method == 'DELETE') {
    await pool.execute(
      Sql.named('DELETE FROM notifications WHERE user_id=@uid'),
      parameters: {'uid': user['id']},
    );
    await _respond(request, HttpStatus.ok, {'success': true, 'data': null});
    return;
  }
  await _apiFailure(
    request,
    HttpStatus.methodNotAllowed,
    'Metode notifikasi tidak didukung.',
  );
}

Future<void> _products(
  HttpRequest request,
  Pool pool,
  List<String> segments,
) async {
  if (segments.length == 4 &&
      segments[3] == 'availability' &&
      request.method == 'GET') {
    final productId = segments[2];
    final start = _requiredDate(request.uri.queryParameters['start_date']);
    final end = _requiredDate(request.uri.queryParameters['end_date']);
    final rows = await pool.execute(
      Sql.named('''SELECT p.stock,p.stock_available,COUNT(b.id)::int AS occupied
      FROM products p LEFT JOIN bookings b ON b.product_id=p.id AND b.returned_at IS NULL
      AND b.start_date<@end AND b.end_date>@start
      AND (@exclude::text IS NULL OR b.id<>@exclude)
      AND (b.booking_status IN ('confirmed','processing','ready','completed') OR
      (b.booking_status='pending_payment' AND b.payment_deadline>NOW()))
      WHERE p.id=@id AND p.is_active AND p.is_available GROUP BY p.id'''),
      parameters: {
        'id': productId,
        'start': start,
        'end': end,
        'exclude': request.uri.queryParameters['exclude_booking_id'],
      },
    );
    if (rows.isEmpty) throw StateError('Produk tidak ditemukan.');
    final values = rows.first.toColumnMap();
    final capacity = min(
      (values['stock'] as num?)?.toInt() ?? 1,
      (values['stock_available'] as num?)?.toInt() ?? 1,
    );
    final available = max(0, capacity - (values['occupied'] as num).toInt());
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'available': available, 'is_available': available > 0},
    });
    return;
  }
  if (segments.length == 4 &&
      segments[3] == 'reviews' &&
      request.method == 'GET') {
    final rows = await pool.execute(
      Sql.named('''SELECT r.*,u.name AS customer_name,p.name AS product_name
      FROM reviews r JOIN users u ON u.id=r.user_id LEFT JOIN products p ON p.id=r.product_id
      WHERE r.product_id=@id ORDER BY r.created_at DESC LIMIT 100'''),
      parameters: {'id': segments[2]},
    );
    await _respond(request, HttpStatus.ok, {
      'success': true,
      'data': {'reviews': rows.map(_reviewJson).toList()},
    });
    return;
  }
  if (request.method != 'GET') {
    final user = await _authenticatedUser(request, pool);
    if (user == null || user['role'] != 'admin') {
      await _apiFailure(
        request,
        user == null ? HttpStatus.unauthorized : HttpStatus.forbidden,
        'Hanya admin yang dapat mengelola produk.',
      );
      return;
    }
  }
  if (segments.length == 2 && request.method == 'GET') {
    final query = request.uri.queryParameters;
    final where = <String>['is_active = true', 'is_available = true'];
    final params = <String, dynamic>{};
    if (query['category_id']?.isNotEmpty ?? false) {
      where.add('category_id = @category');
      params['category'] = query['category_id'];
    }
    if (query['search']?.isNotEmpty ?? false) {
      where.add(
        '(name ILIKE @search OR sku ILIKE @search OR category_name ILIKE @search)',
      );
      params['search'] = '%${query['search']}%';
    }
    final ordering = switch (query['sort_by']) {
      'price_asc' => 'price ASC',
      'price_desc' => 'price DESC',
      _ => 'created_at DESC, id ASC',
    };
    final result = await pool.execute(
      Sql.named(
        'SELECT $_productFields, GREATEST(0, LEAST(COALESCE(stock,stock_available),stock_available)-$_reservedStock)::int AS computed_stock_available FROM products WHERE ${where.join(' AND ')} ORDER BY $ordering',
      ),
      parameters: params,
    );
    await _respond(request, HttpStatus.ok, {
      'products': result.map(_catalogJson).toList(),
    });
    return;
  }

  if (segments.length == 3 && request.method == 'GET') {
    final result = await pool.execute(
      Sql.named(
        'SELECT $_productFields, GREATEST(0, LEAST(COALESCE(stock,stock_available),stock_available)-$_reservedStock)::int AS computed_stock_available FROM products WHERE id = @id AND is_active = true',
      ),
      parameters: {'id': segments[2]},
    );
    if (result.isEmpty) throw StateError('Produk tidak ditemukan.');
    await _respond(request, HttpStatus.ok, {
      'product': _catalogJson(result.first),
    });
    return;
  }

  if (segments.length == 2 && request.method == 'POST') {
    final body = await _readBody(request);
    final row = await pool.execute(
      Sql.named('''INSERT INTO products
        (id, sku, category_id, category_name, name, description, price, dimension,
         stock, stock_available, image_urls, is_available, is_active, is_featured,
         availability_status)
        VALUES (@id, @sku, @category_id, @category_name, @name, @description, @price,
         @dimension, @stock, @stock_available, @image_urls, @is_active, @is_active,
         @is_featured, @availability_status)
        RETURNING $_productFields'''),
      parameters: _productParameters(body),
    );
    await _respond(request, HttpStatus.created, {
      'product': _rowJson(row.first),
    });
    return;
  }

  if (segments.length == 3 && request.method == 'PUT') {
    final body = await _readBody(request);
    body['id'] = segments[2];
    final row = await pool.execute(
      Sql.named('''UPDATE products SET sku = @sku, category_id = @category_id,
        category_name = @category_name, name = @name, description = @description,
        price = @price, dimension = @dimension, stock = @stock,
        stock_available = @stock_available, image_urls = @image_urls,
        is_available = @is_active, is_active = @is_active,
        is_featured = @is_featured, availability_status = @availability_status
        WHERE id = @id RETURNING $_productFields'''),
      parameters: _productParameters(body),
    );
    if (row.isEmpty) throw StateError('Produk tidak ditemukan.');
    await _respond(request, HttpStatus.ok, {'product': _rowJson(row.first)});
    return;
  }

  if (segments.length == 3 && request.method == 'DELETE') {
    final result = await pool.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': segments[2]},
    );
    if (result.affectedRows == 0) throw StateError('Produk tidak ditemukan.');
    await _respond(request, HttpStatus.ok, {'deleted': true});
    return;
  }
  await _respond(request, HttpStatus.methodNotAllowed, {
    'error': 'Metode tidak didukung.',
  });
}

Map<String, dynamic> _productParameters(Map<String, dynamic> body) {
  for (final field in [
    'id',
    'sku',
    'category_id',
    'category_name',
    'name',
    'price',
  ]) {
    if (body[field] == null || '${body[field]}'.trim().isEmpty) {
      throw FormatException('Kolom $field wajib diisi.');
    }
  }
  final price = num.tryParse('${body['price']}');
  if (price == null || price <= 0) {
    throw const FormatException('Tarif harus lebih dari nol.');
  }
  return {
    'id': '${body['id']}',
    'sku': '${body['sku']}',
    'category_id': '${body['category_id']}',
    'category_name': '${body['category_name']}',
    'name': '${body['name']}',
    'description': body['description']?.toString() ?? '',
    'price': price,
    'dimension': body['dimension']?.toString() ?? 'Sesuai model foto',
    'stock': int.tryParse('${body['stock']}') ?? 1,
    'stock_available': int.tryParse('${body['stock_available']}') ?? 1,
    'image_urls': (body['image_urls'] as List<dynamic>? ?? const [])
        .map((item) => '$item')
        .toList(),
    'is_active': body['is_active'] as bool? ?? true,
    'is_featured': body['is_featured'] as bool? ?? false,
    'availability_status':
        body['availability_status']?.toString() ?? 'available',
  };
}

Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
  final text = await utf8.decoder.bind(request).join();
  final decoded = jsonDecode(text);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Isi permintaan harus berupa objek JSON.');
  }
  return decoded;
}

Map<String, dynamic> _rowJson(ResultRow row) {
  final result = Map<String, dynamic>.from(row.toColumnMap());
  for (final entry in result.entries.toList()) {
    if (entry.value is DateTime) {
      result[entry.key] = (entry.value as DateTime).toIso8601String();
    }
  }
  for (final field in ['price', 'original_price', 'rating']) {
    final value = result[field];
    if (value is num) result[field] = value.toDouble();
    if (value != null && value is! num) {
      result[field] = double.tryParse('$value');
    }
  }
  return result;
}

Map<String, dynamic> _catalogJson(ResultRow row) {
  final result = _rowJson(row);
  final total = (result['stock'] as num?)?.toInt() ?? 0;
  final available =
      (result.remove('computed_stock_available') as num?)?.toInt() ??
      (result['stock_available'] as num?)?.toInt() ??
      0;
  result['stock_available'] = available;
  result['availability_status'] = available <= 0
      ? 'unavailable'
      : available < total
      ? 'limited'
      : 'available';
  return result;
}

Map<String, dynamic> _reviewJson(ResultRow row) {
  final result = _rowJson(row);
  result['rating'] = (result['rating'] as num?)?.toInt() ?? 0;
  return result;
}

Future<void> _respond(HttpRequest request, int status, Object body) async {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}
