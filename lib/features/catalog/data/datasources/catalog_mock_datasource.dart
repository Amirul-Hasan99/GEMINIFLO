import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

class CatalogMockDataSource {
  static const String _storageKey = 'geminiflo.catalog.products.v1';

  static const List<ProductCategory> _categories = [
    const ProductCategory(id: '1', name: 'Pernikahan', productCount: 8),
    const ProductCategory(id: '2', name: 'Grand Opening', productCount: 12),
    const ProductCategory(id: '3', name: 'Ulang Tahun', productCount: 6),
    const ProductCategory(id: '4', name: 'Duka Cita', productCount: 4),
    const ProductCategory(id: '5', name: 'Wisuda', productCount: 5),
    const ProductCategory(id: '6', name: 'Promosi', productCount: 7),
    const ProductCategory(id: '7', name: 'Papan Bunga', productCount: 15),
  ];

  static Product _board(int number, String name, int price) => Product(
    id: number.toString(),
    name: name,
    sku: 'GF-PB-${number.toString().padLeft(3, '0')}',
    categoryId: '7',
    categoryName: 'Papan Bunga',
    description:
        'Model $name sesuai foto katalog. Tulisan pada papan dapat disesuaikan dengan kebutuhan pemesan.',
    imageUrls: ['assets/images/products/geminiflo_$number.jpg'],
    pricePerDay: price.toDouble(),
    dimensions: 'Sesuai model foto',
    stockTotal: 1,
    stockAvailable: 1,
    isActive: true,
    isFeatured: number <= 3,
    availabilityStatus: 'available',
  );

  static final List<Product> _seedProducts = [
    _board(1, 'Landscape VI', 110000),
    _board(2, 'Thumbelina V2', 150000),
    _board(3, 'Kubah Pink', 80000),
    _board(4, 'Standing Black', 150000),
    _board(5, 'Maroon', 150000),
    _board(6, 'Potret V2', 150000),
    _board(7, 'Pink I', 140000),
    _board(8, 'Pink White', 150000),
    _board(9, 'Blue', 140000),
    _board(10, 'Pink Fanta', 150000),
    _board(11, 'Standing Ungu', 150000),
    _board(12, 'Convex Mirror', 155000),
    _board(13, 'Bulat Pink V2', 80000),
    _board(14, 'Blue White', 85000),
    _board(15, 'Bulat Maroon', 85000),
  ];

  final List<Product> _products = [];
  final Set<String> _favorites = {};
  Future<void>? _loadFuture;

  Future<void> _ensureLoaded() async {
    _loadFuture ??= _loadSavedProducts();
    await _loadFuture;
  }

  Future<void> _loadSavedProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_storageKey);
    if (saved == null) {
      _products.addAll(_seedProducts);
      await _saveProducts();
      return;
    }

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      _products.addAll(
        decoded.map((item) => _productFromJson(item as Map<String, dynamic>)),
      );
    } on Object {
      _products
        ..clear()
        ..addAll(_seedProducts);
      await _saveProducts();
    }
  }

  Future<void> _saveProducts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(_products.map(_productToJson).toList()),
    );
  }

  static Map<String, dynamic> _productToJson(Product product) => {
    'id': product.id,
    'name': product.name,
    'sku': product.sku,
    'categoryId': product.categoryId,
    'categoryName': product.categoryName,
    'description': product.description,
    'imageUrls': product.imageUrls,
    'pricePerDay': product.pricePerDay,
    'dimensions': product.dimensions,
    'stockTotal': product.stockTotal,
    'stockAvailable': product.stockAvailable,
    'isActive': product.isActive,
    'isFeatured': product.isFeatured,
    'availabilityStatus': product.availabilityStatus,
  };

  static Product _productFromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    sku: json['sku'] as String,
    categoryId: json['categoryId'] as String,
    categoryName: json['categoryName'] as String,
    description: json['description'] as String?,
    imageUrls: (json['imageUrls'] as List<dynamic>? ?? const []).cast<String>(),
    pricePerDay: (json['pricePerDay'] as num).toDouble(),
    dimensions: json['dimensions'] as String,
    stockTotal: json['stockTotal'] as int,
    stockAvailable: json['stockAvailable'] as int,
    isActive: json['isActive'] as bool,
    isFeatured: json['isFeatured'] as bool? ?? false,
    availabilityStatus: json['availabilityStatus'] as String? ?? 'available',
  );

  Future<List<ProductCategory>> getCategories() async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 400));
    return _categories;
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    int page = 1,
    int perPage = 10,
  }) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 600));
    var result = _products.where((p) => p.isActive).toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q),
          )
          .toList();
    }
    if (sortBy == 'price_asc') {
      result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (sortBy == 'price_desc') {
      result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    }
    return result
        .map(
          (p) => Product(
            id: p.id,
            name: p.name,
            sku: p.sku,
            categoryId: p.categoryId,
            categoryName: p.categoryName,
            description: p.description,
            imageUrls: p.imageUrls,
            pricePerDay: p.pricePerDay,
            dimensions: p.dimensions,
            stockTotal: p.stockTotal,
            stockAvailable: p.stockAvailable,
            isActive: p.isActive,
            isFeatured: p.isFeatured,
            availabilityStatus: p.availabilityStatus,
            isFavorited: _favorites.contains(p.id),
          ),
        )
        .toList();
  }

  Future<Product> getProductById(String id) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 300));
    final p = _products.firstWhere((p) => p.id == id);
    return Product(
      id: p.id,
      name: p.name,
      sku: p.sku,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      description: p.description,
      imageUrls: p.imageUrls,
      pricePerDay: p.pricePerDay,
      dimensions: p.dimensions,
      stockTotal: p.stockTotal,
      stockAvailable: p.stockAvailable,
      isActive: p.isActive,
      isFeatured: p.isFeatured,
      availabilityStatus: p.availabilityStatus,
      isFavorited: _favorites.contains(p.id),
    );
  }

  Future<bool> toggleFavorite(String productId) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
    if (_favorites.contains(productId)) {
      _favorites.remove(productId);
      return false;
    } else {
      _favorites.add(productId);
      return true;
    }
  }

  Future<List<Product>> getFavorites() async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 400));
    return _products
        .where((p) => _favorites.contains(p.id))
        .map(
          (p) => Product(
            id: p.id,
            name: p.name,
            sku: p.sku,
            categoryId: p.categoryId,
            categoryName: p.categoryName,
            description: p.description,
            imageUrls: p.imageUrls,
            pricePerDay: p.pricePerDay,
            dimensions: p.dimensions,
            stockTotal: p.stockTotal,
            stockAvailable: p.stockAvailable,
            isActive: p.isActive,
            isFeatured: p.isFeatured,
            availabilityStatus: p.availabilityStatus,
            isFavorited: true,
          ),
        )
        .toList();
  }

  Future<Product> addProduct(Product product) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_products.any((existing) => existing.id == product.id)) {
      throw StateError('ID produk ${product.id} sudah digunakan.');
    }
    _products.insert(0, product);
    await _saveProducts();
    return product;
  }

  Future<Product> updateProduct(Product product) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw StateError('Produk ${product.id} tidak ditemukan.');
    }
    _products[index] = product;
    await _saveProducts();
    return product;
  }

  Future<bool> deleteProduct(String id) async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products.removeAt(index);
      _favorites.remove(id);
      await _saveProducts();
      return true;
    }
    return false;
  }
}
