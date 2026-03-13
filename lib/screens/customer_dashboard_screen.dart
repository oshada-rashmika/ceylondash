// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../widgets/slide_page_route.dart';
import 'profile_screen.dart';

const _activeStatuses = {'processing', 'placed', 'preparing', 'on_the_way'};
const _recentStatuses = {'delivered', 'cancelled'};

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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
  List<OrderModel> _recentOrders = [];
  bool _ordersLoading = true;
  Timer? _searchDebounce;
  String _searchQuery = '';

  late final AnimationController _staggerCtrl;
  static const _sections = 3; // header, active, recent
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

  List<OrderModel> get _filteredRecentOrders => _filterOrders(_recentOrders);

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
    _staggerCtrl.forward();
  }

  void _subscribeOrders(String uid) {
    _ordersSub = _db.streamCustomerOrders(uid).listen((orders) {
      if (!mounted) return;
      setState(() {
        _activeOrders = orders
            .where((o) => _activeStatuses.contains(o.status))
            .toList();
        _recentOrders = orders
            .where((o) => _recentStatuses.contains(o.status))
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
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9FB),
        body: Center(child: CircularProgressIndicator(color: Colors.cyan)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPad + 32)),
              SliverToBoxAdapter(child: _anim(0, _buildHeader())),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(child: _anim(1, _buildActiveSection())),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
              SliverToBoxAdapter(child: _anim(2, _buildRecentSection())),
              const SliverToBoxAdapter(child: SizedBox(height: 140)), // Padding for floating nav bar
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
              _ProfileAvatar(name: name, onTap: _openProfile),
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
    final hasText = _searchController.text.isNotEmpty;
    final hasFocus = _searchFocusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasFocus ? Colors.cyan.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasFocus
                ? Colors.cyan.withOpacity(0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        cursorColor: Colors.cyan,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: const TextStyle(
            color: Colors.black38,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(
              Icons.search_rounded,
              color: Colors.black38,
              size: 22,
            ),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear-search'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _clearSearch();
                    },
                    splashRadius: 24,
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: Colors.black26,
                      size: 20,
                    ),
                  )
                : const SizedBox(key: ValueKey('empty-search-suffix')),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeOrders.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.cyan,
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
          ...activeOrders.map((o) => _ActiveOrderCard(order: o)),
      ],
    );
  }

  Widget _buildRecentSection() {
    final recentOrders = _filteredRecentOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Recent Orders',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recentOrders.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
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
        else if (recentOrders.isEmpty)
          _buildEmpty(
            Icons.history_rounded,
            _isSearching ? 'No Recent Order Matches' : 'No Recent Orders',
          )
        else
          ...(_isSearching ? recentOrders : recentOrders.take(5)).map(
            (o) => _RecentOrderTile(order: o),
          ),
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

class _ActiveOrderCard extends StatefulWidget {
  final OrderModel order;
  const _ActiveOrderCard({required this.order});

  @override
  State<_ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<_ActiveOrderCard>
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
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final current = _statusIndex(o.status);
    final ts = _formatTimestamp(o.timestamps['createdAt']);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_orderIcon(o.status), color: Colors.cyan.shade600, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.dropoffAddress.isNotEmpty ? o.dropoffAddress : o.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (ts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ts,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _readableStatus(o.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.cyan.shade700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: List.generate(_statusSteps.length, (i) {
                  final active = i <= current;
                  final isLast = i == _statusSteps.length - 1;
                  return Expanded(
                    child: Row(
                      children: [
                        Semantics(
                          label: '${_statusLabels[i]} ${active ? "done" : "pending"}',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Colors.cyan.shade600
                                  : Colors.black.withOpacity(0.04),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _statusIcons[i],
                              size: 16,
                              color: active ? Colors.white : Colors.black26,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i < current
                                    ? Colors.cyan.shade600
                                    : Colors.black.withOpacity(0.04),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatefulWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  @override
  State<_RecentOrderTile> createState() => _RecentOrderTileState();
}

class _RecentOrderTileState extends State<_RecentOrderTile> with SingleTickerProviderStateMixin {
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
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = _formatTimestamp(widget.order.timestamps['createdAt']);
    final cancelled = widget.order.status == 'cancelled';

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cancelled 
                      ? Colors.black.withOpacity(0.04) 
                      : Colors.cyan.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  size: 22,
                  color: cancelled ? Colors.black38 : Colors.cyan.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.dropoffAddress.isNotEmpty
                          ? widget.order.dropoffAddress
                          : widget.order.id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ts,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              Text(
                cancelled ? 'Cancelled' : 'Delivered',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cancelled ? Colors.black38 : Colors.cyan.shade700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}