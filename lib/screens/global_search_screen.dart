import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';
import 'shop_detail_screen.dart';
import 'order_detail_screen.dart';
import '../services/search_preferences_service.dart';

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
  final SearchPreferencesService _searchPrefs = SearchPreferencesService();

  String _query = '';
  Timer? _debounce;
  List<String> _recentSearches = [];
  List<ShopModel> _frequentShops = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final recent = await _searchPrefs.getRecentSearches();
    final frequentIds = await _searchPrefs.getFrequentShopIds();

    final List<ShopModel> frequent = [];
    for (String id in frequentIds) {
      try {
        final shop = widget.allShops.firstWhere((s) => s.id == id);
        frequent.add(shop);
      } catch (_) {
        // Shop not found in the list
      }
    }

    if (mounted) {
      setState(() {
        _recentSearches = recent;
        _frequentShops = frequent;
      });
    }
  }

  Future<void> _handleResultTap({ShopModel? shop}) async {
    if (_query.trim().isNotEmpty) {
      await _searchPrefs.addSearchQuery(_query.trim());
    }
    if (shop != null) {
      await _searchPrefs.incrementShopVisit(shop.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
        );
      }
    }
    // Refresh preferences after any update
    _loadPreferences();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentSearchesSection(),
          const SizedBox(height: 32),
          _buildFrequentShopsSection(),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _searchPrefs.clearRecentSearches();
                _loadPreferences();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentSearches.isEmpty)
          const Text(
            'No recent searches',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _recentSearches.map((query) {
              return ActionChip(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                label: Text(query),
                onPressed: () {
                  setState(() {
                    _searchController.text = query;
                    _query = query;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFrequentShopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Frequently Visited',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (_frequentShops.isEmpty)
          const Text(
            'Keep exploring to see your favorite shops.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
            itemCount: _frequentShops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shop = _frequentShops[index];
              return GestureDetector(
                onTap: () => _handleResultTap(shop: shop),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          image: shop.headerImage.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(shop.headerImage),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: shop.headerImage.isEmpty
                            ? const Icon(
                                Icons.storefront_rounded,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const Spacer(),
                      Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
          HapticFeedback.selectionClick();
          if (_query.trim().isNotEmpty) {
            SearchPreferencesService().addSearchQuery(_query.trim());
          }
          SearchPreferencesService().incrementShopVisit(shop.id);
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
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
          HapticFeedback.selectionClick();
          final String itemShopId = itemData['shopId'];
          final parentShop = widget.allShops.firstWhere((s) => s.id == itemShopId);
          if (_query.trim().isNotEmpty) {
            SearchPreferencesService().addSearchQuery(_query.trim());
          }
          SearchPreferencesService().incrementShopVisit(parentShop.id);
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => ShopDetailScreen(shop: parentShop)),
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
        onTap: () {
          HapticFeedback.selectionClick();
          if (_query.trim().isNotEmpty) {
            SearchPreferencesService().addSearchQuery(_query.trim());
          }
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
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
