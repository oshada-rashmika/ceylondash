import 'package:flutter/foundation.dart';
import '../models/shop_model.dart';

class CartItem {
  final ShopItemModel item;
  final int quantity;

  const CartItem({required this.item, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(item: item, quantity: quantity ?? this.quantity);
}

class CartShopBucket {
  final String shopId;
  final String shopName;
  final Map<String, CartItem> items;

  CartShopBucket({
    required this.shopId,
    required this.shopName,
    Map<String, CartItem>? items,
  }) : items = items ?? {};
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartShopBucket> _shopBuckets = {};

  Map<String, CartShopBucket> get shopBuckets =>
      Map.unmodifiable(_shopBuckets);

  bool get isEmpty => _shopBuckets.isEmpty;

  int get globalItemCount => _shopBuckets.values.fold(
        0,
        (sum, bucket) =>
            sum + bucket.items.values.fold(0, (s, ci) => s + ci.quantity),
      );

  double getShopSubtotal(String shopId) {
    final bucket = _shopBuckets[shopId];
    if (bucket == null) return 0.0;
    return bucket.items.values.fold(
      0.0,
      (sum, ci) => sum + (ci.item.price * ci.quantity),
    );
  }

  int quantityOf(String shopId, String itemName) =>
      _shopBuckets[shopId]?.items[itemName]?.quantity ?? 0;

  void addItem(ShopItemModel item, String shopId, String shopName) {
    if (!_shopBuckets.containsKey(shopId)) {
      _shopBuckets[shopId] = CartShopBucket(
        shopId: shopId,
        shopName: shopName,
      );
    }
    final bucket = _shopBuckets[shopId]!;
    final existing = bucket.items[item.name];
    if (existing != null) {
      bucket.items[item.name] =
          existing.copyWith(quantity: existing.quantity + 1);
    } else {
      bucket.items[item.name] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
  }

  void decrementItem(String shopId, String itemName) {
    final bucket = _shopBuckets[shopId];
    if (bucket == null) return;

    final existing = bucket.items[itemName];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      bucket.items.remove(itemName);
      if (bucket.items.isEmpty) _shopBuckets.remove(shopId);
    } else {
      bucket.items[itemName] =
          existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  void removeItem(String shopId, String itemName) {
    final bucket = _shopBuckets[shopId];
    if (bucket == null) return;
    bucket.items.remove(itemName);
    if (bucket.items.isEmpty) _shopBuckets.remove(shopId);
    notifyListeners();
  }

  void clearShop(String shopId) {
    _shopBuckets.remove(shopId);
    notifyListeners();
  }

  void clearAll() {
    _shopBuckets.clear();
    notifyListeners();
  }
}
