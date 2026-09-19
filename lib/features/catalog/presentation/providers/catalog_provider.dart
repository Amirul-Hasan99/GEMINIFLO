import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../../../core/database/neon_database_service.dart';
import '../../data/datasources/catalog_mock_datasource.dart';
import '../../data/datasources/catalog_neon_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';

final catalogMockDataSourceProvider = Provider<CatalogMockDataSource>((ref) {
  return CatalogMockDataSource();
});

final catalogNeonDataSourceProvider = Provider<CatalogNeonDataSource>((ref) {
  final neonDb = ref.watch(neonDatabaseServiceProvider);
  return CatalogNeonDataSource(neonDb);
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    mockDataSource: ref.watch(catalogMockDataSourceProvider),
    neonDataSource: ref.watch(catalogNeonDataSourceProvider),
  );
});

// Categories
final categoriesProvider = FutureProvider<List<ProductCategory>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

// Catalog Filter
class CatalogFilter {
  final String? categoryId;
  final String? search;
  final String? sortBy;
  final String? date;

  const CatalogFilter({
    this.categoryId,
    this.search,
    this.sortBy,
    this.date,
  });

  CatalogFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? search,
    String? sortBy,
    String? date,
  }) {
    return CatalogFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      date: date ?? this.date,
    );
  }
}

// Catalog State
class CatalogState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final CatalogFilter filter;

  const CatalogState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.filter = const CatalogFilter(),
  });

  CatalogState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    CatalogFilter? filter,
  }) {
    return CatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

// Riverpod 3: Use Notifier instead of StateNotifier
class CatalogNotifier extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    Future.microtask(() => loadProducts());
    return const CatalogState();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      final products = await repo.getProducts(
        categoryId: state.filter.categoryId,
        search: state.filter.search,
        sortBy: state.filter.sortBy,
        date: state.filter.date,
      );
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(CatalogFilter filter) {
    state = state.copyWith(filter: filter);
    loadProducts();
  }

  void setCategory(String? categoryId) {
    final filter = categoryId == null
        ? state.filter.copyWith(clearCategory: true)
        : state.filter.copyWith(categoryId: categoryId);
    setFilter(filter);
  }

  void setSearch(String search) {
    setFilter(state.filter.copyWith(search: search.isEmpty ? null : search));
  }

  void setSortBy(String? sortBy) {
    setFilter(state.filter.copyWith(sortBy: sortBy));
  }
}

final catalogProvider = NotifierProvider<CatalogNotifier, CatalogState>(
  CatalogNotifier.new,
);

// Single product detail
final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProductById(id);
});

// Favorites using Riverpod 3 Notifier
class FavoritesNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    Future.microtask(() => loadFavorites());
    return [];
  }

  Future<void> loadFavorites() async {
    try {
      final repo = ref.read(catalogRepositoryProvider);
      state = await repo.getFavorites();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String productId) async {
    final repo = ref.read(catalogRepositoryProvider);
    await repo.toggleFavorite(productId);
    await loadFavorites();
    // Refresh catalog to update isFavorited flag
    ref.read(catalogProvider.notifier).loadProducts();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Product>>(
  FavoritesNotifier.new,
);
