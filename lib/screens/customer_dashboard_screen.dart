import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/shop_model.dart';
import '../widgets/slide_page_route.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_detail_screen.dart';
import 'shop_detail_screen.dart';
import 'global_search_screen.dart';
import '../widgets/animated_order_card.dart';

const _activeStatuses = {'processing', 'placed', 'preparing', 'on_the_way'};

const _statusSteps = ['placed', 'preparing', 'on_the_way', 'delivered'];
const _statusLabels = ['Placed', 'Preparing', 'On Way', 'Delivered'];
const _statusIcons = [
  Icons.receipt_long_rounded,
  Icons.soup_kitchen_rounded,
  Icons.delivery_dining_rounded,
  Icons.check_circle_rounded,
];

int _statusIndex(String status) {
  final i = _statusSteps.indexOf(status);
  return i == -1 ? 0 : i;
}

IconData _orderIcon(String status) {
  return switch (status) {
    'preparing' => Icons.soup_kitchen_rounded,
    'on_the_way' => Icons.delivery_dining_rounded,
    'delivered' => Icons.check_circle_rounded,
    'cancelled' => Icons.cancel_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

String _readableStatus(String s) {
  return switch (s) {
    'on_the_way' => 'On the Way',
    'processing' => 'Processing',
    _ => '${s[0].toUpperCase()}${s.substring(1)}',
  };
}

String _formatTimestamp(dynamic ts) {
  if (ts == null) return '';
  DateTime dt;
  if (ts is DateTime) {
    dt = ts;
  } else {
    try {
      dt = (ts as dynamic).toDate();
    } catch (_) {
      return '';
    }
  }
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final amPm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day}, $h:$min $amPm';
}

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  UserModel? _user;
  bool _userLoading = true;

  StreamSubscription<List<OrderModel>>? _ordersSub;
  List<OrderModel> _activeOrders = [];
  bool _ordersLoading = true;
  Timer? _searchDebounce;
  String _searchQuery = '';

  List<ShopModel> _shops = [];
  bool _shopsLoading = true;

  late final AnimationController _staggerCtrl;
  static const _sections = 4;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fades = List.generate(_sections, (i) {
      final s = i * 0.25;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slides = List.generate(_sections, (i) {
      final s = i * 0.25;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );
    });
    _searchController.addListener(_handleSearchTextChanged);
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    _loadUser();
  }

  List<OrderModel> get _filteredActiveOrders => _filterOrders(_activeOrders);

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  Future<void> _loadUser() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      if (mounted) setState(() => _userLoading = false);
      return;
    }
    final user = await _db.getUser(fbUser.uid);
    if (!mounted) return;
    setState(() {
      _user = user;
      _userLoading = false;
    });
    _subscribeOrders(fbUser.uid);
    _loadShops();
    _staggerCtrl.forward();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await _db.getAllShops();
      if (!mounted) return;
      setState(() {
        _shops = shops;
        _shopsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _shopsLoading = false);
    }
  }

  void _subscribeOrders(String uid) {
    _ordersSub = _db.streamCustomerOrders(uid).listen((orders) {
      if (!mounted) return;
      setState(() {
        _activeOrders = orders
            .where((o) => _activeStatuses.contains(o.status))
            .toList();
        _ordersLoading = false;
      });
    });
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (!_isSearching) return orders;
    return orders.where((order) => order.matchesQuery(_searchQuery)).toList();
  }

  void _handleSearchTextChanged() {
    if (mounted) setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  void _handleSearchFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (!mounted) return;
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchTextChanged)
      ..dispose();
    _searchFocusNode
      ..removeListener(_handleSearchFocusChanged)
      ..dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  void _openProfile() {
    Navigator.push(context, SlidePageRoute(page: const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    if (_userLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad + 32)),
              SliverToBoxAdapter(child: _anim(0, _buildHeader())),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(child: _anim(1, _buildActiveSection())),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(child: _anim(2, _buildDiscoverShopsSection())),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _user?.name ?? 'Customer';
    final firstName = name.split(' ').first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -1.2,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => CartScreen(user: _user),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.black87,
                            size: 22,
                          ),
                        ),
                        if (cart.globalItemCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${cart.globalItemCount > 9 ? '9+' : cart.globalItemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSearchBar(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                GlobalSearchScreen(
                  allShops: _shops,
                  userOrders: _activeOrders,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: const [
            const Icon(Icons.search_rounded, color: Colors.black38, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Search shops, items, or orders...',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection() {
    final activeOrders = _filteredActiveOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Active Orders',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.8,
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeOrders.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_ordersLoading)
          ..._buildShimmers(2)
        else if (activeOrders.isEmpty)
          _buildEmpty(
            Icons.receipt_long_outlined,
            _isSearching ? 'No Active Order Matches' : 'No Active Orders',
          )
        else
          ...activeOrders.map((o) => AnimatedOrderCard(order: o)),
      ],
    );
  }

  Widget _buildEmpty(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.black26),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black38,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShimmers(int count) {
    return List.generate(count, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _ShimmerBlock(height: 140, borderRadius: 24),
      );
    });
  }

  Widget _buildDiscoverShopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Discover Shops',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_shopsLoading)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ShimmerBlock(height: 200, borderRadius: 16),
              ),
            ),
          )
        else if (_shops.isEmpty)
          _buildEmpty(Icons.store_outlined, 'No Shops Available')
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _shops.length,
              itemBuilder: (context, index) =>
                  _ShopCard(shop: _shops[index], user: _user),
            ),
          ),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double height;
  final double borderRadius;
  const _ShimmerBlock({required this.height, required this.borderRadius});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * v, 0),
              end: Alignment(2.0 * v, 0),
              colors: [
                Colors.black.withOpacity(0.02),
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.02),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatefulWidget {
  final String name;
  final VoidCallback onTap;
  const _ProfileAvatar({required this.name, required this.onTap});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Semantics(
          label: 'Open profile',
          button: true,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.cyan.shade700,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatefulWidget {
  final ShopModel shop;
  final UserModel? user;
  const _ShopCard({required this.shop, this.user});

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.push(
          context,
          SlidePageRoute(
            page: ShopDetailScreen(shop: shop, user: widget.user),
          ),
        );
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 160,
          height: 200,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: shop.headerImage.isNotEmpty
                        ? Image.network(
                            shop.headerImage,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.black.withOpacity(0.04),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.cyan,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black.withOpacity(0.04),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Colors.black26,
                                size: 36,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.black.withOpacity(0.04),
                            child: const Icon(
                              Icons.store_rounded,
                              color: Colors.black26,
                              size: 36,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _capitalize(shop.type),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black45,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
