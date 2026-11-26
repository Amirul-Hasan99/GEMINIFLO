import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_neon_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogNeonDataSource remoteDataSource;
  CatalogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductCategory>> getCategories() =>
      remoteDataSource.getCategories();
  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    String? date,
    int page = 1,
    int perPage = 10,
  }) => remoteDataSource.getProducts(
    categoryId: categoryId,
    search: search,
    sortBy: sortBy,
    page: page,
    perPage: perPage,
  );
  @override
  Future<Product> getProductById(String id) =>
      remoteDataSource.getProductById(id);
  @override
  Future<bool> toggleFavorite(String productId) =>
      remoteDataSource.toggleFavorite(productId);
  @override
  Future<List<Product>> getFavorites() => remoteDataSource.getFavorites();
  @override
  Future<Product> addProduct(Product product) =>
      remoteDataSource.addProduct(product);
  @override
  Future<Product> updateProduct(Product product) =>
      remoteDataSource.updateProduct(product);
  @override
  Future<bool> deleteProduct(String id) => remoteDataSource.deleteProduct(id);
}
