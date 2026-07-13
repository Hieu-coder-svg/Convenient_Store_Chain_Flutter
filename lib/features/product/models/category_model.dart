class CategoryModel {
  final int categoryId;
  final String categoryName;
  final String? description;
  final int productCount; // Hỗ trợ hiển thị số lượng sản phẩm trên giao diện

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.description,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] ?? json['id'] ?? 0,
      categoryName: json['categoryName'] ?? json['name'] ?? '',
      description: json['description'],
      productCount: json['productCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
    };
  }

  CategoryModel copyWith({
    int? categoryId,
    String? categoryName,
    String? description,
    int? productCount,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      productCount: productCount ?? this.productCount,
    );
  }
}
