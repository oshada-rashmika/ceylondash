import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/accessibility_provider.dart';
import '../screens/order_detail_screen.dart';
import '../widgets/slide_page_route.dart';

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

class AnimatedOrderCard extends StatefulWidget {
  final OrderModel order;
  const AnimatedOrderCard({super.key, required this.order});

  @override
  State<AnimatedOrderCard> createState() => _AnimatedOrderCardState();
}

class _AnimatedOrderCardState extends State<AnimatedOrderCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final current = _statusIndex(o.status);
    final ts = _formatTimestamp(o.timestamps['createdAt']);

    final a11y = Provider.of<AccessibilityProvider>(context);
    final shouldPulse = !a11y.needsNeuroSupport;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          SlidePageRoute(page: OrderDetailScreen(order: o)),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  final currentlyActiveStep = i == current;
                  final isLast = i == _statusSteps.length - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        _buildStepIcon(
                          i,
                          currentlyActiveStep,
                          active,
                          shouldPulse,
                        ),
                        if (!isLast) _buildAnimatedLine(i, current),
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

  Widget _buildStepIcon(
    int i,
    bool currentlyActiveStep,
    bool active,
    bool shouldPulse,
  ) {
    Widget iconBase = Semantics(
      label: '${_statusLabels[i]} ${active ? "done" : "pending"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Theme.of(context).primaryColor
              : Colors.black.withOpacity(0.04),
          boxShadow: active && !currentlyActiveStep
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
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
    );

    if (currentlyActiveStep && shouldPulse) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.15);
          final shadowOpacity = (_pulseController.value * 0.35);

          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(shadowOpacity),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: iconBase,
            ),
          );
        },
      );
    }

    return iconBase;
  }

  Widget _buildAnimatedLine(int i, int current) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Colors.black.withOpacity(0.04),
              ),
            ),
            if (i < current)
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      final curvedValue = Curves.easeOutCubic.transform(
                        _progressController.value,
                      );
                      return Container(
                        width: constraints.maxWidth * curvedValue,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
