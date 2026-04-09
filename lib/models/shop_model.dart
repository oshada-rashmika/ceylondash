class ShopItemModel {
  final String name;
  final double price;
  final String category;
  final String image;

  const ShopItemModel({
    required this.name,
    required this.price,
    required this.category,
    required this.image,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      name: (json['name'] as String?) ?? '',
      price: ((json['price'] as num?) ?? 0).toDouble(),
      category: (json['category'] as String?) ?? '',
      image: (json['image'] as String?) ?? '',
    );
  }
}

class ShopModel {
  final String id;
  final String name;
  final String type;
  final double rating;
  final String headerImage;
  final List<String> categories;
  final List<ShopItemModel> items;
  final String? sellerId;

  const ShopModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.headerImage,
    required this.categories,
    required this.items,
    this.sellerId,
  });

  factory ShopModel.fromJson(String id, Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final categories = rawCategories is List
        ? rawCategories.map((e) => e?.toString() ?? '').toList()
        : <String>[];

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ShopItemModel.fromJson)
              .toList()
        : <ShopItemModel>[];

    return ShopModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      rating: ((json['rating'] as num?) ?? 0.0).toDouble(),
      headerImage: (json['headerImage'] as String?) ?? '',
      categories: categories,
      items: items,
      sellerId: json['sellerId'] as String?,
    );
  }
}
