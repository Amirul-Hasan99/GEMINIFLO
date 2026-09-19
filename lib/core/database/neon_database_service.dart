import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgres/postgres.dart';

class NeonConfig {
  static const String connectionString =
      'postgresql://neondb_owner:npg_An3OriHysUC0@ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech/GEMINIFLO?sslmode=require&channel_binding=require';

  static const String host =
      'ep-snowy-haze-at8e3hc2-pooler.c-9.us-east-1.aws.neon.tech';
  static const int port = 5432;
  static const String database = 'GEMINIFLO';
  static const String username = 'neondb_owner';
  static const String password = 'npg_An3OriHysUC0';
}

/// Service to interact directly with Neon PostgreSQL Database
class NeonDatabaseService {
  Connection? _connection;
  bool _isConnecting = false;

  Endpoint get _endpoint => Endpoint(
        host: NeonConfig.host,
        port: NeonConfig.port,
        database: NeonConfig.database,
        username: NeonConfig.username,
        password: NeonConfig.password,
      );

  /// Ensure an active, open connection to Neon DB
  Future<Connection> getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    if (_isConnecting) {
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_connection != null && _connection!.isOpen) {
        return _connection!;
      }
    }

    _isConnecting = true;
    try {
      developer.log('Connecting to Neon PostgreSQL: ${NeonConfig.host}...',
          name: 'NeonDB');
      _connection = await Connection.open(
        _endpoint,
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(seconds: 15),
          queryTimeout: Duration(seconds: 30),
        ),
      );
      developer.log('Connected to Neon PostgreSQL successfully.',
          name: 'NeonDB');
      return _connection!;
    } catch (e, stack) {
      developer.log('Failed to connect to Neon PostgreSQL: $e',
          error: e, stackTrace: stack, name: 'NeonDB');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Execute an SQL query and return results
  Future<Result> query(String sql, [List<dynamic>? parameters]) async {
    final conn = await getConnection();
    if (parameters != null && parameters.isNotEmpty) {
      return await conn.execute(Sql.named(sql),
          parameters: parameters as dynamic);
    } else {
      return await conn.execute(sql);
    }
  }

  /// Initialize database schema in Neon DB (tables: users, categories, products, bookings, payments, reviews)
  Future<void> initializeSchema() async {
    final conn = await getConnection();
    developer.log('Initializing Neon DB Schema...', name: 'NeonDB');

    final statements = [
      // Categories Table
      '''CREATE TABLE IF NOT EXISTS categories (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        slug VARCHAR(100) UNIQUE NOT NULL,
        description TEXT,
        icon VARCHAR(50),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',

      // Products (Papan Bunga) Table
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
        image_urls TEXT[],
        is_available BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',

      // Users Table
      '''CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(50) PRIMARY KEY,
        name VARCHAR(150) NOT NULL,
        email VARCHAR(150) UNIQUE NOT NULL,
        phone VARCHAR(30),
        role VARCHAR(20) DEFAULT 'customer',
        avatar_url TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',

      // Bookings Table
      '''CREATE TABLE IF NOT EXISTS bookings (
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
        booking_status VARCHAR(30) DEFAULT 'pending',
        payment_status VARCHAR(30) DEFAULT 'unpaid',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',

      // Payments Table
      '''CREATE TABLE IF NOT EXISTS payments (
        id VARCHAR(50) PRIMARY KEY,
        booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,
        user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        amount NUMERIC(15, 2) NOT NULL,
        payment_method VARCHAR(50) NOT NULL,
        proof_url TEXT,
        status VARCHAR(30) DEFAULT 'pending',
        rejection_reason TEXT,
        verified_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',

      // Reviews Table
      '''CREATE TABLE IF NOT EXISTS reviews (
        id VARCHAR(50) PRIMARY KEY,
        booking_id VARCHAR(50) REFERENCES bookings(id) ON DELETE CASCADE,
        product_id VARCHAR(50) REFERENCES products(id) ON DELETE CASCADE,
        user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
        rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )''',
    ];

    for (final stmt in statements) {
      await conn.execute(stmt);
    }

    // Seed default categories if empty
    final existingCategories =
        await conn.execute('SELECT COUNT(*) FROM categories;');
    final count = existingCategories.first[0] as int;
    if (count == 0) {
      await seedInitialData(conn);
    }

    developer.log('Neon DB Schema initialized and verified.', name: 'NeonDB');
  }

  /// Seed initial categories and products into Neon DB
  Future<void> seedInitialData(Connection conn) async {
    developer.log('Seeding initial data into Neon DB...', name: 'NeonDB');

    final categoryInserts = [
      "INSERT INTO categories (id, name, slug, description, icon) VALUES ('cat-1', 'Pernikahan', 'pernikahan', 'Papan bunga ucapan selamat bahagia dan wedding ceremonial', 'favorite')",
      "INSERT INTO categories (id, name, slug, description, icon) VALUES ('cat-2', 'Duka Cita', 'duka-cita', 'Papan bunga ungkapan bela sungkawa dan simpati mendalam', 'sentiment_dissatisfied')",
      "INSERT INTO categories (id, name, slug, description, icon) VALUES ('cat-3', 'Grand Opening', 'grand-opening', 'Papan ucapan selamat & sukses peresmian kantor / toko', 'store')",
      "INSERT INTO categories (id, name, slug, description, icon) VALUES ('cat-4', 'Wisuda', 'wisuda', 'Papan bunga ucapan selamat wisuda dan kelulusan', 'school')",
    ];

    for (final c in categoryInserts) {
      await conn.execute(c);
    }

    final productInserts = [
      "INSERT INTO products (id, category_id, category_name, name, description, price, original_price, dimension, flower_type, stock, rating, review_count, image_urls, is_available) VALUES ('p-1', 'cat-1', 'Pernikahan', 'Royal Magnolia Wedding Board', 'Papan bunga pernikahan eksklusif ukuran jumbo dengan rangkaian bunga segar premium, perpaduan mawar merah, lily putih, dan baby breath.', 750000, 850000, '2.5m x 1.8m', 'Bunga Segar & Suyok Premium', 4, 4.9, 28, ARRAY['https://images.unsplash.com/photo-1519228498877-380d321eb103?w=800'], true)",
      "INSERT INTO products (id, category_id, category_name, name, description, price, original_price, dimension, flower_type, stock, rating, review_count, image_urls, is_available) VALUES ('p-2', 'cat-1', 'Pernikahan', 'Elegance Blush Pink Floral', 'Desain manis bernuansa soft pink dan peach, sangat cocok untuk tema pernikahan modern romantis.', 550000, 600000, '2.0m x 1.5m', 'Mawar Pastel & Chrysanthemum', 5, 4.8, 19, ARRAY['https://images.unsplash.com/photo-1561181286-d3fee7d55364?w=800'], true)",
      "INSERT INTO products (id, category_id, category_name, name, description, price, original_price, dimension, flower_type, stock, rating, review_count, image_urls, is_available) VALUES ('p-3', 'cat-2', 'Duka Cita', 'Serenity White Condolence', 'Papan bunga duka cita elegan dengan dominasi warna putih salju dan kuning lembut melambangkan kedamaian abadi.', 500000, 500000, '2.0m x 1.5m', 'Aster, Lily Putih & Krisan', 6, 5.0, 14, ARRAY['https://images.unsplash.com/photo-1533616688419-b7a585564566?w=800'], true)",
      "INSERT INTO products (id, category_id, category_name, name, description, price, original_price, dimension, flower_type, stock, rating, review_count, image_urls, is_available) VALUES ('p-4', 'cat-3', 'Grand Opening', 'Prosperity Golden Ribbon', 'Papan bunga ucapan selamat & sukses grand opening dengan warna merah emas menyala pertanda keberuntungan.', 650000, 700000, '2.2m x 1.6m', 'Gerbera Merah, Sedap Malam & Suyok', 3, 4.9, 32, ARRAY['https://images.unsplash.com/photo-1508615039623-a25605d2b022?w=800'], true)",
      "INSERT INTO products (id, category_id, category_name, name, description, price, original_price, dimension, flower_type, stock, rating, review_count, image_urls, is_available) VALUES ('p-5', 'cat-4', 'Wisuda', 'Achievement Blue Velvet', 'Papan bunga wisuda bernuansa biru navy elegan dan kuning cerah untuk perayaan kelulusan berkesan.', 450000, 500000, '1.8m x 1.2m', 'Krisan & Mawar Kuning', 8, 4.7, 22, ARRAY['https://images.unsplash.com/photo-1526047932273-341f2a7631f9?w=800'], true)",
    ];

    for (final p in productInserts) {
      await conn.execute(p);
    }
  }

  /// Close connection
  Future<void> close() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }
  }
}

/// Riverpod Provider for NeonDatabaseService
final neonDatabaseServiceProvider = Provider<NeonDatabaseService>((ref) {
  final service = NeonDatabaseService();
  ref.onDispose(() {
    service.close();
  });
  return service;
});
