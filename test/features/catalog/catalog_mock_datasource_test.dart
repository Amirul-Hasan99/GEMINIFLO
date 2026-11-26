import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geminiflo_booking/features/catalog/data/datasources/catalog_mock_datasource.dart';
import 'package:geminiflo_booking/features/catalog/domain/entities/product.dart';

void main() {
  late CatalogMockDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dataSource = CatalogMockDataSource();
  });

  group('CatalogMockDataSource', () {
    test('getCategories returns list of categories', () async {
      final categories = await dataSource.getCategories();
      expect(categories, isNotEmpty);
      expect(categories.length, 7);
    });

    test(
      'getProducts returns products and can be filtered by category',
      () async {
        final allProducts = await dataSource.getProducts();
        expect(allProducts, isNotEmpty);
        expect(allProducts.length, 15); // Seeded catalogue boards

        final boardProducts = await dataSource.getProducts(categoryId: '7');
        expect(boardProducts, hasLength(15));
        expect(boardProducts.every((p) => p.categoryId == '7'), isTrue);
      },
    );

    test('getProducts can be searched by name or sku', () async {
      final searchResult = await dataSource.getProducts(search: 'pink');
      expect(searchResult, isNotEmpty);
      expect(
        searchResult.every(
          (p) =>
              p.name.toLowerCase().contains('pink') ||
              p.categoryName.toLowerCase().contains('pink'),
        ),
        isTrue,
      );
    });

    test('getProducts can be sorted by price', () async {
      final ascProducts = await dataSource.getProducts(sortBy: 'price_asc');
      expect(ascProducts, isNotEmpty);
      for (int i = 0; i < ascProducts.length - 1; i++) {
        expect(
          ascProducts[i].pricePerDay <= ascProducts[i + 1].pricePerDay,
          isTrue,
        );
      }

      final descProducts = await dataSource.getProducts(sortBy: 'price_desc');
      expect(descProducts, isNotEmpty);
      for (int i = 0; i < descProducts.length - 1; i++) {
        expect(
          descProducts[i].pricePerDay >= descProducts[i + 1].pricePerDay,
          isTrue,
        );
      }
    });

    test('toggleFavorite adds and removes from favorites', () async {
      final productId = '1';

      // Add to favorites
      final isAdded = await dataSource.toggleFavorite(productId);
      expect(isAdded, isTrue);

      var favorites = await dataSource.getFavorites();
      expect(favorites.any((p) => p.id == productId), isTrue);

      // Remove from favorites
      final isRemoved = await dataSource.toggleFavorite(productId);
      expect(isRemoved, isFalse);

      favorites = await dataSource.getFavorites();
      expect(favorites.any((p) => p.id == productId), isFalse);
    });

    test('addProduct adds new product to catalog', () async {
      final initialCount = (await dataSource.getProducts()).length;
      final newProduct = Product(
        id: '999',
        name: 'Papan Bunga Test Custom',
        sku: 'GF-TEST-001',
        categoryId: '1',
        categoryName: 'Pernikahan',
        description: 'Keterangan produk test untuk unit test',
        pricePerDay: 200000,
        dimensions: '120cm × 180cm',
        stockTotal: 5,
        stockAvailable: 5,
        isActive: true,
      );

      final added = await dataSource.addProduct(newProduct);
      expect(added.id, '999');
      expect(added.description, 'Keterangan produk test untuk unit test');

      final currentProducts = await dataSource.getProducts();
      expect(currentProducts.length, initialCount + 1);
      expect(currentProducts.any((p) => p.id == '999'), isTrue);
    });

    test(
      'seeds 15 products with the names, tariffs, and bundled images',
      () async {
        final products = await dataSource.getProducts();
        expect(
          products.map((p) => p.name),
          containsAll([
            'Landscape VI',
            'Thumbelina V2',
            'Kubah Pink',
            'Standing Black',
            'Maroon',
            'Potret V2',
            'Pink I',
            'Pink White',
            'Blue',
            'Pink Fanta',
            'Standing Ungu',
            'Convex Mirror',
            'Bulat Pink V2',
            'Blue White',
            'Bulat Maroon',
          ]),
        );
        expect(products.first.pricePerDay, 110000);
        expect(
          products.first.imageUrls.single,
          'assets/images/products/geminiflo_1.jpg',
        );
        expect(products.last.pricePerDay, 85000);
      },
    );

    test('catalog changes persist for a new data source instance', () async {
      final product = await dataSource.getProductById('1');
      await dataSource.updateProduct(
        Product(
          id: product.id,
          name: 'Landscape VI Update',
          sku: product.sku,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          description: product.description,
          imageUrls: product.imageUrls,
          pricePerDay: 120000,
          dimensions: product.dimensions,
          stockTotal: product.stockTotal,
          stockAvailable: product.stockAvailable,
          isActive: product.isActive,
        ),
      );

      final reopened = CatalogMockDataSource();
      final updated = await reopened.getProductById('1');
      expect(updated.name, 'Landscape VI Update');
      expect(updated.pricePerDay, 120000);
    });

    test('updateProduct modifies existing product', () async {
      final product = await dataSource.getProductById('1');
      final updatedProduct = Product(
        id: product.id,
        name: 'Papan Bunga Updated Name',
        sku: product.sku,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        description: 'Keterangan baru yang telah diedit',
        pricePerDay: 195000,
        dimensions: product.dimensions,
        stockTotal: product.stockTotal,
        stockAvailable: product.stockAvailable,
        isActive: product.isActive,
      );

      final result = await dataSource.updateProduct(updatedProduct);
      expect(result.name, 'Papan Bunga Updated Name');
      expect(result.description, 'Keterangan baru yang telah diedit');
      expect(result.pricePerDay, 195000);

      final fetched = await dataSource.getProductById('1');
      expect(fetched.name, 'Papan Bunga Updated Name');
    });

    test('deleteProduct removes product from catalog', () async {
      final newProduct = Product(
        id: 'delete-target-id',
        name: 'Target Hapus',
        sku: 'GF-DEL-001',
        categoryId: '2',
        categoryName: 'Grand Opening',
        description: 'Produk yang akan dihapus',
        pricePerDay: 100000,
        dimensions: '100cm × 150cm',
        stockTotal: 2,
        stockAvailable: 2,
        isActive: true,
      );

      await dataSource.addProduct(newProduct);
      expect(
        (await dataSource.getProducts()).any((p) => p.id == 'delete-target-id'),
        isTrue,
      );

      final success = await dataSource.deleteProduct('delete-target-id');
      expect(success, isTrue);
      expect(
        (await dataSource.getProducts()).any((p) => p.id == 'delete-target-id'),
        isFalse,
      );
    });
  });
}
