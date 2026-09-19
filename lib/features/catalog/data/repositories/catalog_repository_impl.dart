import '../../../../core/config/app_config.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_mock_datasource.dart';
import '../datasources/catalog_neon_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogMockDataSource mockDataSource;
  final CatalogNeonDataSource? neonDataSource;

  CatalogRepositoryImpl({
    required this.mockDataSource,
    this.neonDataSource,
  });

  @override
  Future<List<ProductCategory>> getCategories() async {
    if (AppConfig.useNeonDb && neonDataSource != null) {
      try {
        final neonCats = await neonDataSource!.getCategories();
        if (neonCats.isNotEmpty) return neonCats;
      } catch (_) {
        // Fallback to mock on network/DB exception
      }
    }
    return mockDataSource.getCategories();
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    String? date,
    int page = 1,
    int perPage = 10,
  }) async {
    if (AppConfig.useNeonDb && neonDataSource != null) {
      try {
        final neonProducts = await neonDataSource!.getProducts(
          categoryId: categoryId,
          search: search,
          sortBy: sortBy,
          page: page,
          perPage: perPage,
        );
        if (neonProducts.isNotEmpty) return neonProducts;
      } catch (_) {
        // Fallback to mock on network/DB exception
      }
    }
    return mockDataSource.getProducts(
      categoryId: categoryId,
      search: search,
      sortBy: sortBy,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<Product> getProductById(String id) async {
    if (AppConfig.useNeonDb && neonDataSource != null) {
      try {
        final product = await neonDataSource!.getProductById(id);
        if (product != null) return product;
      } catch (_) {
        // Fallback to mock on network/DB exception
      }
    }
    return mockDataSource.getProductById(id);
  }

  @override
  Future<bool> toggleFavorite(String productId) =>
      mockDataSource.toggleFavorite(productId);

  @override
  Future<List<Product>> getFavorites() => mockDataSource.getFavorites();
}
