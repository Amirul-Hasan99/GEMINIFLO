import '../../../../core/database/neon_database_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

class CatalogNeonDataSource {
  final NeonDatabaseService _neonDb;

  CatalogNeonDataSource(this._neonDb);

  Future<List<ProductCategory>> getCategories() async {
    final conn = await _neonDb.getConnection();
    final result = await conn.execute('''
      SELECT c.id, c.name, COUNT(p.id) as product_count
      FROM categories c
      LEFT JOIN products p ON c.id = p.category_id
      GROUP BY c.id, c.name
      ORDER BY c.name ASC;
    ''');

    return result.map((row) {
      return ProductCategory(
        id: row[0].toString(),
        name: row[1].toString(),
        productCount: (row[2] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    int page = 1,
    int perPage = 20,
  }) async {
    final conn = await _neonDb.getConnection();
    String query = '''
      SELECT id, name, category_id, category_name, description, price, dimension, stock, image_urls, is_available
      FROM products
      WHERE 1=1
    ''';

    if (categoryId != null && categoryId.isNotEmpty) {
      query += " AND category_id = '$categoryId'";
    }

    if (search != null && search.isNotEmpty) {
      final sanitized = search.replaceAll("'", "''");
      query += " AND (name ILIKE '%$sanitized%' OR description ILIKE '%$sanitized%')";
    }

    query += ' ORDER BY created_at DESC LIMIT $perPage OFFSET ${(page - 1) * perPage};';

    final result = await conn.execute(query);

    return result.map((row) {
      final id = row[0].toString();
      final name = row[1].toString();
      final catId = row[2]?.toString() ?? '';
      final catName = row[3]?.toString() ?? '';
      final desc = row[4]?.toString();
      final price = (row[5] as num?)?.toDouble() ?? 0.0;
      final dim = row[6]?.toString() ?? '2.0m x 1.5m';
      final stock = (row[7] as num?)?.toInt() ?? 1;
      final rawImages = row[8];
      final List<String> images = [];
      if (rawImages is List) {
        images.addAll(rawImages.map((e) => e.toString()));
      }
      final isAvailable = row[9] as bool? ?? true;

      return Product(
        id: id,
        name: name,
        sku: 'GF-${id.toUpperCase()}',
        categoryId: catId,
        categoryName: catName,
        description: desc,
        pricePerDay: price,
        dimensions: dim,
        stockTotal: stock,
        stockAvailable: isAvailable ? stock : 0,
        isActive: isAvailable,
        isFeatured: true,
        availabilityStatus: !isAvailable
            ? 'unavailable'
            : stock <= 2
                ? 'limited'
                : 'available',
        imageUrls: images,
      );
    }).toList();
  }

  Future<Product?> getProductById(String id) async {
    final conn = await _neonDb.getConnection();
    final result = await conn.execute('''
      SELECT id, name, category_id, category_name, description, price, dimension, stock, image_urls, is_available
      FROM products
      WHERE id = '$id'
      LIMIT 1;
    ''');

    if (result.isEmpty) return null;
    final row = result.first;
    final rawImages = row[8];
    final List<String> images = [];
    if (rawImages is List) {
      images.addAll(rawImages.map((e) => e.toString()));
    }

    return Product(
      id: row[0].toString(),
      name: row[1].toString(),
      sku: 'GF-${row[0].toString().toUpperCase()}',
      categoryId: row[2]?.toString() ?? '',
      categoryName: row[3]?.toString() ?? '',
      description: row[4]?.toString(),
      pricePerDay: (row[5] as num?)?.toDouble() ?? 0.0,
      dimensions: row[6]?.toString() ?? '2.0m x 1.5m',
      stockTotal: (row[7] as num?)?.toInt() ?? 1,
      stockAvailable: (row[7] as num?)?.toInt() ?? 1,
      isActive: row[9] as bool? ?? true,
      imageUrls: images,
    );
  }
}
