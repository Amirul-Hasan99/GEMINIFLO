class Product {
  final String id;
  final String name;
  final String sku;
  final String categoryId;
  final String categoryName;
  final String? description;
  final List<String> imageUrls;
  final double pricePerDay;
  final String dimensions;
  final int stockTotal;
  final int stockAvailable;
  final bool isActive;
  final bool isFeatured;
  final String availabilityStatus; // 'available' | 'limited' | 'unavailable'
  final bool isFavorited;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.imageUrls = const [],
    required this.pricePerDay,
    required this.dimensions,
    required this.stockTotal,
    required this.stockAvailable,
    required this.isActive,
    this.isFeatured = false,
    this.availabilityStatus = 'available',
    this.isFavorited = false,
  });
}
