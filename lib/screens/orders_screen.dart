import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';
import '../widgets/slide_page_route.dart';
import 'order_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.8,
            ),
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.black45,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : TabBarView(
                physics: const BouncingScrollPhysics(),
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
                  color: Colors.black.withOpacity(0.03),
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
            ? _ActiveOrderCard(order: order)
            : _RecentOrderTile(order: order);
      },
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
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        Navigator.push(
          context,
          SlidePageRoute(page: OrderDetailScreen(order: o)),
        );
      },
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
                  Hero(
                    tag: 'order_status_icon_${o.id}',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _orderIcon(o.status),
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.orderName.isNotEmpty
                              ? o.orderName
                              : 'Order #${o.id.substring(0, 5)}',
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
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
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
                          label:
                              '${_statusLabels[i]} ${active ? "done" : "pending"}',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? Theme.of(context).primaryColor
                                  : Colors.black.withOpacity(0.04),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
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
                                    ? Theme.of(context).primaryColor
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                        ? Colors.black.withOpacity(0.04)
                        : Colors.cyan.withOpacity(0.1),
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
