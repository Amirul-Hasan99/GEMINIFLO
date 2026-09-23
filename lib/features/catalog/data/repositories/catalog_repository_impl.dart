import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_mock_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogMockDataSource mockDataSource;

  CatalogRepositoryImpl({required this.mockDataSource});

  @override
  Future<List<ProductCategory>> getCategories() async {
    // Future: call a backend REST API here when AppConfig.useNeonDb is true.
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
    return mockDataSource.getProductById(id);
  }

  @override
  Future<bool> toggleFavorite(String productId) =>
      mockDataSource.toggleFavorite(productId);

  @override
  Future<List<Product>> getFavorites() => mockDataSource.getFavorites();
}
