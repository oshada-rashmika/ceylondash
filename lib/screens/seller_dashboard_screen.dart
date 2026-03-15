// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;
  static const _sections = 5;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  // --- Demo Data ---
  final Map<String, int> _kpis = {
    'Pending': 12,
    'In Transit': 34,
    'Delivered': 187,
    'Returned': 3,
  };

  final List<Map<String, dynamic>> _activeShipments = [
    {
      'waybill': 'CYD-2026-00012345',
      'recipient': 'Amaya Silva',
      'city': 'Kandy',
      'status': 'in_transit',
      'cod': 7500.00,
    },
    {
      'waybill': 'CYD-2026-00012346',
      'recipient': 'Kasun Fernando',
      'city': 'Galle',
      'status': 'pickup_scheduled',
      'cod': 3200.00,
    },
    {
      'waybill': 'CYD-2026-00012347',
      'recipient': 'Nimali Perera',
      'city': 'Colombo',
      'status': 'out_for_delivery',
      'cod': 0.0,
    },
  ];

  int _issueCount = 2;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fades = List.generate(_sections, (i) {
      final s = i * 0.2;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );
    });
    _slides = List.generate(_sections, (i) {
      final s = i * 0.2;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );
    });
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _fades[i],
        child: SlideTransition(position: _slides[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

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
              SliverToBoxAdapter(child: SizedBox(height: topPad + 24)),
              SliverToBoxAdapter(child: _anim(0, _buildHeader())),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(child: _anim(1, _buildKpiRow())),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _anim(2, _buildFinancialCard())),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _anim(3, _buildQuickActions())),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: _anim(4, _buildActiveShipmentsPreview())),
              if (_issueCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _anim(4, _buildIssueAlert()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Seller Hub',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showNotificationsSheet(context);
            },
            child: Container(
              width: 46,
              height: 46,
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.black87, size: 22),
                  if (_issueCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sign out
          GestureDetector(
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Container(
              width: 46,
              height: 46,
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
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            ),
          ),
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

  // ─── NOTIFICATIONS BOTTOM SHEET ───────────────────────────
  void _showNotificationsSheet(BuildContext context) {
    final issues = [
      {
        'title': 'Damaged package reported',
        'subtitle': 'Order CYD-2026-00012340 — Saman Jayasinghe',
        'time': '2 hours ago',
        'icon': Icons.broken_image_rounded,
        'color': Colors.redAccent,
      },
      {
        'title': 'Wrong item received',
        'subtitle': 'Order CYD-2026-00012339 — Dilani Rajapakse',
        'time': '5 hours ago',
        'icon': Icons.swap_horiz_rounded,
        'color': Colors.orange,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${issues.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: issues.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final issue = issues[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (issue['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (issue['color'] as Color).withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (issue['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            issue['icon'] as IconData,
                            color: issue['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                issue['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                issue['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                issue['time'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KPI CARDS ────────────────────────────────────────────
  Widget _buildKpiRow() {
    final entries = _kpis.entries.toList();
    final kpiColors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.redAccent,
    ];
    final kpiIcons = [
      Icons.hourglass_bottom_rounded,
      Icons.local_shipping_rounded,
      Icons.check_circle_rounded,
      Icons.assignment_return_rounded,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(entries.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 5,
                    right: i == entries.length - 1 ? 0 : 5,
                  ),
                  child: _KpiCard(
                    label: entries[i].key,
                    count: entries[i].value,
                    color: kpiColors[i],
                    icon: kpiIcons[i],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── FINANCIAL & COD TRACKER ──────────────────────────────
  Widget _buildFinancialCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade600,
              Colors.cyan.shade800,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _FinancialStat(
                    label: 'COD Collected',
                    value: 'Rs. 125,400',
                    icon: Icons.payments_rounded,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _FinancialStat(
                    label: 'Pending Payout',
                    value: 'Rs. 45,600',
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Next payout on March 18, 2026',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.local_shipping_rounded, 'label': 'New Shipment', 'color': Colors.cyan},
      {'icon': Icons.inventory_2_rounded, 'label': 'Bulk Pickup', 'color': Colors.indigo},
      {'icon': Icons.print_rounded, 'label': 'Print Labels', 'color': Colors.teal},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(actions.length, (i) {
              final a = actions[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 5,
                    right: i == actions.length - 1 ? 0 : 5,
                  ),
                  child: GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (a['color'] as Color).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              a['icon'] as IconData,
                              color: a['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            a['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVE SHIPMENTS PREVIEW ─────────────────────────────
  Widget _buildActiveShipmentsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Shipments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.6,
                ),
              ),
              GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.cyan.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeShipments.isEmpty)
            _buildEmptyState(
              Icons.local_shipping_outlined,
              'No Active Shipments',
              'Create your first shipment to get started.',
            )
          else
            ...List.generate(_activeShipments.length, (i) {
              final s = _activeShipments[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShipmentCard(
                  waybill: s['waybill'] as String,
                  recipient: s['recipient'] as String,
                  city: s['city'] as String,
                  status: s['status'] as String,
                  cod: s['cod'] as double,
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── CUSTOMER ISSUE ALERT ─────────────────────────────────
  Widget _buildIssueAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_issueCount Customer Issues',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Requires your attention',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FinancialStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FinancialStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  final String waybill;
  final String recipient;
  final String city;
  final String status;
  final double cod;

  const _ShipmentCard({
    required this.waybill,
    required this.recipient,
    required this.city,
    required this.status,
    required this.cod,
  });

  Color _badgeColor() {
    return switch (status) {
      'pickup_scheduled' => Colors.cyan,
      'picked_up' => Colors.blue,
      'in_transit' => Colors.indigo,
      'out_for_delivery' => Colors.amber.shade700,
      'delivered' => Colors.green,
      'returned' => Colors.redAccent,
      'pickup_failed' => Colors.red,
      'disputed' => Colors.orange,
      _ => Colors.grey,
    };
  }

  String _readableStatus() {
    return switch (status) {
      'pickup_scheduled' => 'Pickup Scheduled',
      'picked_up' => 'Picked Up',
      'in_transit' => 'In Transit',
      'out_for_delivery' => 'Out for Delivery',
      'delivered' => 'Delivered',
      'returned' => 'Returned',
      'pickup_failed' => 'Pickup Failed',
      'disputed' => 'Disputed',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_shipping_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$waybill  •  $city',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _readableStatus(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (cod > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'COD Rs. ${cod.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}