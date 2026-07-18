class CartItemModel {
  final int productId;
  final String productName;
  final double sellingPrice;
  int quantity;
  final String? imageUrl;

  CartItemModel({
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    this.quantity = 1,
    this.imageUrl,
  });

  double get lineTotal => sellingPrice * quantity;
}
