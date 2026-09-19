import '../entities/product.dart';
import '../entities/product_category.dart';

abstract class CatalogRepository {
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    String? sortBy,
    String? date,
    int page = 1,
    int perPage = 10,
  });
  Future<Product> getProductById(String id);
  Future<List<ProductCategory>> getCategories();
  Future<bool> toggleFavorite(String productId);
  Future<List<Product>> getFavorites();
}
