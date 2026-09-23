import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

class CatalogMockDataSource {
  static final List<ProductCategory> _categories = [
    const ProductCategory(id: '1', name: 'Pernikahan', productCount: 8),
    const ProductCategory(id: '2', name: 'Grand Opening', productCount: 12),
    const ProductCategory(id: '3', name: 'Ulang Tahun', productCount: 6),
    const ProductCategory(id: '4', name: 'Duka Cita', productCount: 4),
    const ProductCategory(id: '5', name: 'Wisuda', productCount: 5),
    const ProductCategory(id: '6', name: 'Promosi', productCount: 7),
  ];

  static final List<Product> _products = [
    const Product(
      id: '1',
      name: 'Papan Bunga Grand Opening Elegant',
      sku: 'GF-GO-001',
      categoryId: '2',
      categoryName: 'Grand Opening',
      description:
          'Papan bunga mewah dengan rangkaian bunga segar pilihan, cocok untuk grand opening bisnis premium. Dilengkapi dengan kalimat ucapan selamat yang dapat dikustomisasi.',
      imageUrls: [],
      pricePerDay: 850000,
      dimensions: '120cm × 180cm',
      stockTotal: 5,
      stockAvailable: 3,
      isActive: true,
      isFeatured: true,
      availabilityStatus: 'available',
    ),
    const Product(
      id: '2',
      name: 'Papan Bunga Pernikahan Romantis',
      sku: 'GF-WD-001',
      categoryId: '1',
      categoryName: 'Pernikahan',
      description:
          'Rangkaian bunga mawar dan lily putih yang elegan, sempurna untuk memperindah venue pernikahan Anda.',
      imageUrls: [],
      pricePerDay: 1200000,
      dimensions: '100cm × 160cm',
      stockTotal: 4,
      stockAvailable: 2,
      isActive: true,
      isFeatured: true,
      availabilityStatus: 'limited',
    ),
    const Product(
      id: '3',
      name: 'Papan Ucapan Ulang Tahun Ceria',
      sku: 'GF-BD-001',
      categoryId: '3',
      categoryName: 'Ulang Tahun',
      description:
          'Papan bunga berwarna-warni dengan sentuhan modern untuk merayakan hari istimewa.',
      imageUrls: [],
      pricePerDay: 650000,
      dimensions: '90cm × 140cm',
      stockTotal: 6,
      stockAvailable: 5,
      isActive: true,
      isFeatured: false,
      availabilityStatus: 'available',
    ),
    const Product(
      id: '4',
      name: 'Papan Bunga Duka Cita',
      sku: 'GF-DK-001',
      categoryId: '4',
      categoryName: 'Duka Cita',
      description:
          'Rangkaian bunga putih yang khidmat dan menyentuh hati untuk menyampaikan belasungkawa.',
      imageUrls: [],
      pricePerDay: 550000,
      dimensions: '100cm × 150cm',
      stockTotal: 3,
      stockAvailable: 0,
      isActive: true,
      isFeatured: false,
      availabilityStatus: 'unavailable',
    ),
    const Product(
      id: '5',
      name: 'Papan Bunga Wisuda Prestisius',
      sku: 'GF-WS-001',
      categoryId: '5',
      categoryName: 'Wisuda',
      description:
          'Papan bunga warna emas dan hijau untuk merayakan pencapaian akademik yang membanggakan.',
      imageUrls: [],
      pricePerDay: 750000,
      dimensions: '110cm × 160cm',
      stockTotal: 4,
      stockAvailable: 3,
      isActive: true,
      isFeatured: true,
      availabilityStatus: 'available',
    ),
    const Product(
      id: '6',
      name: 'Papan Promosi Modern Minimalis',
      sku: 'GF-PM-001',
      categoryId: '6',
      categoryName: 'Promosi',
      description:
          'Papan bunga dengan desain minimalis modern yang cocok untuk promosi produk dan event bisnis.',
      imageUrls: [],
      pricePerDay: 700000,
      dimensions: '100cm × 150cm',
      stockTotal: 8,
      stockAvailable: 6,
      isActive: true,
      isFeatured: false,
      availabilityStatus: 'available',
    ),
  ];

  final Set<String> _favorites = {};

  Future<List<ProductCategory>> getCategories() async {
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
    await Future.delayed(const Duration(milliseconds: 600));
    var result = _products.where((p) => p.isActive).toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList();
    }
    if (sortBy == 'price_asc') {
      result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
    } else if (sortBy == 'price_desc') {
      result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    }
    return result
        .map((p) => Product(
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
            ))
        .toList();
  }

  Future<Product> getProductById(String id) async {
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
    await Future.delayed(const Duration(milliseconds: 400));
    return _products
        .where((p) => _favorites.contains(p.id))
        .map((p) => Product(
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
            ))
        .toList();
  }
}
