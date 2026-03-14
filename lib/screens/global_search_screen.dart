import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';
import 'shop_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final List<ShopModel> allShops;
  final List<OrderModel> userOrders;

  const GlobalSearchScreen({
    super.key,
    required this.allShops,
    required this.userOrders,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<ShopModel> get filteredShops {
    if (_query.isEmpty) return [];
    return widget.allShops.where((shop) {
      return shop.name.toLowerCase().contains(_query) ||
          shop.type.toLowerCase().contains(_query);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredItems {
    if (_query.isEmpty) return [];
    final List<Map<String, dynamic>> results = [];
    for (final shop in widget.allShops) {
      for (final item in shop.items) {
        if (item.name.toLowerCase().contains(_query) ||
            item.category.toLowerCase().contains(_query)) {
          results.add({
            'item': item,
            'shopId': shop.id,
            'shopName': shop.name,
            'shop': shop,
          });
        }
      }
    }
    return results;
  }

  List<OrderModel> get filteredOrders {
    if (_query.isEmpty) return [];
    return widget.userOrders.where((order) {
      return order.id.toLowerCase().contains(_query) ||
          order.matchesQuery(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shops = filteredShops;
    final items = filteredItems;
    final orders = filteredOrders;

    final bool isEmptyState = _query.isEmpty;
    final bool hasNoResults =
        !isEmptyState && shops.isEmpty && items.isEmpty && orders.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: isEmptyState
                  ? _buildEmptyState()
                  : hasNoResults
                  ? _buildNoResults()
                  : _buildSearchResults(shops, items, orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              autofocus: true,
              placeholder: 'Search shops, items, or orders',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          const Text(
            'Search for restaurants, gadgets, or past orders.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No results for "$_searchController.text"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    List<ShopModel> shops,
    List<Map<String, dynamic>> items,
    List<OrderModel> orders,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shops.isNotEmpty) ...[
          _buildSectionHeader('Shops'),
          ...shops.map((shop) => _buildShopTile(shop)),
          const SizedBox(height: 24),
        ],
        if (items.isNotEmpty) ...[
          _buildSectionHeader('Menu & Products'),
          ...items.map((itemData) => _buildItemTile(itemData)),
          const SizedBox(height: 24),
        ],
        if (orders.isNotEmpty) ...[
          _buildSectionHeader('Past Orders'),
          ...orders.map((order) => _buildOrderTile(order)),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildShopTile(ShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
          );
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: shop.headerImage.isNotEmpty
              ? NetworkImage(shop.headerImage)
              : null,
          child: shop.headerImage.isEmpty
              ? const Icon(Icons.storefront_rounded, color: Colors.grey)
              : null,
        ),
        title: Text(
          shop.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text('${shop.rating} • ${shop.type}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> itemData) {
    final ShopItemModel item = itemData['item'];
    final ShopModel shop = itemData['shop'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
          );
        },
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            image: item.image.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(item.image),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.image.isEmpty
              ? const Icon(Icons.fastfood_rounded, color: Colors.grey)
              : null,
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'From ${shop.name}',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Text(
          'LKR ${item.price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.cyan,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTile(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.cyan.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.cyan),
        ),
        title: Text(
          'Order #${order.id.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Status: ${order.status.toUpperCase()}',
          style: TextStyle(
            color: order.status == 'completed' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
