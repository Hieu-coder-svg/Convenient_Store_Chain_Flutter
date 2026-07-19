class ProductModel {
  final int productId;
  final String productName;
  final int categoryId;
  final String categoryName;
  final int? supplierId;
  final String? supplierName;
  final String? barcode;
  final double costPrice;
  final double sellingPrice;
  final bool isActive;
  final String? imageUrl;
  final String? unit;
  final String? importUnit;
  final int conversionFactor;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.categoryName,
    this.supplierId,
    this.supplierName,
    this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.isActive,
    this.imageUrl,
    this.unit,
    this.importUnit,
    required this.conversionFactor,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? json['id'] ?? 0,
      productName: json['productName'] ?? json['name'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      barcode: json['barcode'],
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      unit: json['unit'],
      importUnit: json['importUnit'],
      conversionFactor: json['conversionFactor'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'categoryId': categoryId,
      'supplierId': supplierId,
      'barcode': barcode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'unit': unit,
      'importUnit': importUnit,
      'conversionFactor': conversionFactor,
    };
  }

  ProductModel copyWith({
    int? productId,
    String? productName,
    int? categoryId,
    String? categoryName,
    int? supplierId,
    String? supplierName,
    String? barcode,
    double? costPrice,
    double? sellingPrice,
    bool? isActive,
    String? imageUrl,
    String? unit,
    String? importUnit,
    int? conversionFactor,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      importUnit: importUnit ?? this.importUnit,
      conversionFactor: conversionFactor ?? this.conversionFactor,
    );
  }
}
