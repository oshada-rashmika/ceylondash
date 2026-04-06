import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';
import 'order_detail_screen.dart';
import '../widgets/animated_order_card.dart';
import '../widgets/slide_page_route.dart';

const _activeStatuses = {
  'processing',
  'placed',
  'preparing',
  'on_the_way',
  'in_transit',
  'out_for_delivery',
  'pickup_scheduled',
  'picked_up',
  'assigned'
};
const _recentStatuses = {'delivered', 'cancelled'};

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

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DatabaseService _db = DatabaseService();
  StreamSubscription<List<OrderModel>>? _ordersSub;
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _pastOrders = [];
  bool _isLoading = true;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadOrders();
  }

  void _loadOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    _ordersSub = _db.streamCustomerOrders(user.uid).listen((orders) {
      if (!mounted) return;
      setState(() {
        _activeOrders = orders
            .where((o) => _activeStatuses.contains(o.status))
            .toList();
        _pastOrders = orders
            .where((o) => _recentStatuses.contains(o.status))
            .toList();
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSegmentedControl(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (idx) {
                        setState(() => _currentIndex = idx);
                      },
                      children: [
                        _buildOrderList(
                          _activeOrders,
                          Icons.receipt_long_outlined,
                          'No active orders right now',
                          isActive: true,
                        ),
                        _buildOrderList(
                          _pastOrders,
                          Icons.history_rounded,
                          'No past orders found',
                          isActive: false,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final pillWidth = (width - 8) / 2;

          return Container(
            height: 48,
            width: width,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(4),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: _currentIndex == 0 ? 0 : pillWidth,
                  top: 0,
                  bottom: 0,
                  width: pillWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Center(
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _currentIndex == 0
                                  ? Colors.black
                                  : Colors.black45,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Center(
                          child: Text(
                            'Past',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _currentIndex == 1
                                  ? Colors.black
                                  : Colors.black45,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(
    List<OrderModel> orders,
    IconData emptyIcon,
    String emptyText, {
    required bool isActive,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 48, color: Colors.black26),
              ),
              const SizedBox(height: 24),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 120),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return isActive
            ? AnimatedOrderCard(order: order)
            : _RecentOrderTile(order: order);
      },
    );
  }
}

class _RecentOrderTile extends StatefulWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  @override
  State<_RecentOrderTile> createState() => _RecentOrderTileState();
}

class _RecentOrderTileState extends State<_RecentOrderTile>
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
    final ts = _formatTimestamp(widget.order.timestamps['createdAt']);
    final cancelled = widget.order.status == 'cancelled';

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.push(
          context,
          SlidePageRoute(page: OrderDetailScreen(order: widget.order)),
        );
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'order_status_icon_${widget.order.id}',
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cancelled
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.cyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cancelled
                        ? Icons.cancel_rounded
                        : Icons.check_circle_rounded,
                    size: 22,
                    color: cancelled ? Colors.black38 : Colors.cyan.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.orderName.isNotEmpty
                          ? widget.order.orderName
                          : 'Order #${widget.order.id.substring(0, 5)}',
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
                    ],
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
