class ProductCategory {
  final String id;
  final String name;
  final String? icon;
  final int productCount;

  const ProductCategory({
    required this.id,
    required this.name,
    this.icon,
    this.productCount = 0,
  });
}
