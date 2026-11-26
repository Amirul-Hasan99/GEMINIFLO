import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

/// Catalog client for the GEMINIFLO API. The API connects to Neon on the
/// server; database credentials are never included in the Flutter application.
class CatalogNeonDataSource {
  final ApiClient _client;

  CatalogNeonDataSource(this._client);

  Future<List<ProductCategory>> getCategories() async {
    final response = await _client.get(ApiConstants.categories);
    return _rows(response.data, 'categories')
        .map(
          (json) => ProductCategory(
            id: '${json['id']}',
            name: '${json['name']}',
            icon: json['icon'] as String?,
            productCount: _asInt(json['product_count']),
          ),
        )
        .toList();
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    int page = 1,
    int perPage = 10,
  }) async {
    final response = await _client.get(
      ApiConstants.products,
      queryParameters: {
        if (categoryId != null && categoryId.isNotEmpty)
          'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        'page': page,
        'per_page': perPage,
      },
    );
    return _rows(response.data, 'products').map(_fromJson).toList();
  }

  Future<Product> getProductById(String id) async {
    final response = await _client.get(ApiConstants.productDetail(id));
    final data = response.data;
    if (data is Map && data['product'] is Map) {
      return _fromJson(Map<String, dynamic>.from(data['product'] as Map));
    }
    return _fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Product> addProduct(Product product) async {
    final response = await _client.post(
      ApiConstants.products,
      data: _toJson(product),
    );
    return _responseProduct(response.data, product);
  }

  Future<Product> updateProduct(Product product) async {
    final response = await _client.put(
      ApiConstants.productDetail(product.id),
      data: _toJson(product),
    );
    return _responseProduct(response.data, product);
  }

  Future<bool> deleteProduct(String id) async {
    await _client.delete(ApiConstants.productDetail(id));
    return true;
  }

  Future<bool> toggleFavorite(String id) async {
    final response = await _client.post(ApiConstants.favoriteToggle(id));
    return response.data['data']?['is_favorite'] as bool? ?? false;
  }

  Future<List<Product>> getFavorites() async {
    final response = await _client.get(ApiConstants.favorites);
    return _rows(response.data, 'products').map(_fromJson).toList();
  }

  static List<Map<String, dynamic>> _rows(dynamic response, String key) {
    final value = response is Map ? response[key] : response;
    if (value is! List) {
      throw const FormatException('Format respons katalog tidak valid.');
    }
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Product _responseProduct(dynamic response, Product fallback) {
    if (response is Map && response['product'] is Map) {
      return _fromJson(Map<String, dynamic>.from(response['product'] as Map));
    }
    if (response is Map && response.containsKey('id')) {
      return _fromJson(Map<String, dynamic>.from(response));
    }
    return fallback;
  }

  static Product _fromJson(Map<String, dynamic> json) {
    final imageUrls = json['image_urls'] ?? json['imageUrls'];
    final isAvailable = json['is_available'] as bool? ?? true;
    return Product(
      id: '${json['id']}',
      name: '${json['name']}',
      sku: '${json['sku'] ?? ''}',
      categoryId: '${json['category_id'] ?? json['categoryId'] ?? '7'}',
      categoryName:
          '${json['category_name'] ?? json['categoryName'] ?? 'Papan Bunga'}',
      description: json['description'] as String?,
      imageUrls: imageUrls is List
          ? imageUrls.map((item) => '$item').toList()
          : const [],
      pricePerDay: _asDouble(
        json['price'] ?? json['price_per_day'] ?? json['pricePerDay'],
      ),
      dimensions:
          '${json['dimension'] ?? json['dimensions'] ?? 'Sesuai model foto'}',
      stockTotal: _asInt(json['stock']),
      stockAvailable: _asInt(json['stock_available'] ?? json['stock']),
      isActive: json['is_active'] as bool? ?? isAvailable,
      isFeatured: json['is_featured'] as bool? ?? false,
      availabilityStatus:
          '${json['availability_status'] ?? (isAvailable ? 'available' : 'unavailable')}',
    );
  }

  static Map<String, dynamic> _toJson(Product product) => {
    'id': product.id,
    'sku': product.sku,
    'category_id': product.categoryId,
    'category_name': product.categoryName,
    'name': product.name,
    'description': product.description,
    'price': product.pricePerDay,
    'dimension': product.dimensions,
    'stock': product.stockTotal,
    'stock_available': product.stockAvailable,
    'image_urls': product.imageUrls,
    'is_active': product.isActive,
    'is_featured': product.isFeatured,
    'availability_status': product.availabilityStatus,
  };

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
