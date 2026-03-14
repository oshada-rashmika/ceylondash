import 'package:flutter/foundation.dart';
import '../models/shop_model.dart';

class CartItem {
  final ShopItemModel item;
  final int quantity;

  const CartItem({required this.item, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(item: item, quantity: quantity ?? this.quantity);
}

class CartConflictException implements Exception {
  final String existingShopId;
  const CartConflictException(this.existingShopId);

  @override
  String toString() =>
      'CartConflictException: Cart already contains items from shop "$existingShopId".';
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _currentShopId;
  List<CartItem> get items => List.unmodifiable(_items.values);
  String? get currentShopId => _currentShopId;
  int get itemCount =>
      _items.values.fold(0, (sum, ci) => sum + ci.quantity);
  double get subtotal =>
      _items.values.fold(
        0.0,
        (sum, ci) => sum + (ci.item.price * ci.quantity),
      );
  bool get isEmpty => _items.isEmpty;
  int quantityOf(String itemName) => _items[itemName]?.quantity ?? 0;
  void addItem(ShopItemModel item, String shopId) {
    if (_currentShopId != null && _currentShopId != shopId) {
      throw CartConflictException(_currentShopId!);
    }
    _currentShopId = shopId;

    final existing = _items[item.name];
    if (existing != null) {
      _items[item.name] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      _items[item.name] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
  }

  void decrementItem(String itemName) {
    final existing = _items[itemName];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      _items.remove(itemName);
      if (_items.isEmpty) _currentShopId = null;
    } else {
      _items[itemName] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  void removeItem(String itemName) {
    _items.remove(itemName);
    if (_items.isEmpty) _currentShopId = null;
    notifyListeners();
  }
  
  void clearCart() {
    _items.clear();
    _currentShopId = null;
    notifyListeners();
  }
}
