// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SellerShipmentsTab extends StatefulWidget {
  final String? initialFilter;

  const SellerShipmentsTab({super.key, this.initialFilter});

  @override
  State<SellerShipmentsTab> createState() => _SellerShipmentsTabState();
}

class _SellerShipmentsTabState extends State<SellerShipmentsTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  late String _selectedFilter;

  final List<String> _filters = [
    'All',
    'Pending',
    'In Transit',
    'Delivered',
    'Returned',
  ];

  final Map<String, String> _filterToStatus = {
    'All': '',
    'Pending': 'pickup_scheduled',
    'In Transit': 'in_transit',
    'Delivered': 'delivered',
    'Returned': 'returned',
  };

  // --- Demo Data ---
  final List<Map<String, dynamic>> _allShipments = [
    {
      'waybill': 'CYD-2026-00012345',
      'recipient': 'Amaya Silva',
      'city': 'Kandy',
      'status': 'in_transit',
      'cod': 7500.00,
      'date': '14 Mar',
    },
    {
      'waybill': 'CYD-2026-00012346',
      'recipient': 'Kasun Fernando',
      'city': 'Galle',
      'status': 'pickup_scheduled',
      'cod': 3200.00,
      'date': '14 Mar',
    },
    {
      'waybill': 'CYD-2026-00012347',
      'recipient': 'Nimali Perera',
      'city': 'Colombo',
      'status': 'out_for_delivery',
      'cod': 0.0,
      'date': '13 Mar',
    },
    {
      'waybill': 'CYD-2026-00012340',
      'recipient': 'Saman Jayasinghe',
      'city': 'Negombo',
      'status': 'delivered',
      'cod': 4800.00,
      'date': '13 Mar',
    },
    {
      'waybill': 'CYD-2026-00012339',
      'recipient': 'Dilani Rajapakse',
      'city': 'Matara',
      'status': 'delivered',
      'cod': 2100.00,
      'date': '12 Mar',
    },
    {
      'waybill': 'CYD-2026-00012338',
      'recipient': 'Ruwan Wickramasinghe',
      'city': 'Jaffna',
      'status': 'returned',
      'cod': 5600.00,
      'date': '12 Mar',
    },
    {
      'waybill': 'CYD-2026-00012337',
      'recipient': 'Thilini Bandara',
      'city': 'Anuradhapura',
      'status': 'delivered',
      'cod': 1950.00,
      'date': '11 Mar',
    },
  ];

  List<Map<String, dynamic>> get _filteredShipments {
    var list = _allShipments;

    // Filter by status
    if (_selectedFilter != 'All') {
      final s = _filterToStatus[_selectedFilter]!;
      list = list.where((item) => item['status'] == s).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        final r = (item['recipient'] as String).toLowerCase();
        final w = (item['waybill'] as String).toLowerCase();
        final c = (item['city'] as String).toLowerCase();
        return r.contains(q) || w.contains(q) || c.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final shipments = _filteredShipments;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad + 24)),

          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text(
                'Shipments',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchBar(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedFilter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.cyan : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Colors.cyan
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.black54,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${shipments.length} shipment${shipments.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Shipment list or empty state
          if (shipments.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildEmptyState(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = shipments[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _ShipmentListCard(
                      waybill: s['waybill'] as String,
                      recipient: s['recipient'] as String,
                      city: s['city'] as String,
                      status: s['status'] as String,
                      cod: s['cod'] as double,
                      date: s['date'] as String,
                    ),
                  );
                },
                childCount: shipments.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchController.text.isNotEmpty;
    final hasFocus = _searchFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasFocus ? Colors.cyan.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasFocus
                ? Colors.cyan.withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        cursorColor: Colors.cyan,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name, waybill, or city...',
          hintStyle: const TextStyle(
            color: Colors.black38,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.search_rounded, color: Colors.black38, size: 22),
          ),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _searchController.clear();
                    },
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.black26, size: 20),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
            child: const Icon(Icons.local_shipping_outlined,
                size: 36, color: Colors.black26),
          ),
          const SizedBox(height: 16),
          const Text(
            'No shipments found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your filters or search',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─── SHIPMENT LIST CARD ─────────────────────────────────────

class _ShipmentListCard extends StatelessWidget {
  final String waybill;
  final String recipient;
  final String city;
  final String status;
  final double cod;
  final String date;

  const _ShipmentListCard({
    required this.waybill,
    required this.recipient,
    required this.city,
    required this.status,
    required this.cod,
    required this.date,
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

  IconData _statusIcon() {
    return switch (status) {
      'pickup_scheduled' => Icons.schedule_rounded,
      'picked_up' => Icons.inventory_rounded,
      'in_transit' => Icons.local_shipping_rounded,
      'out_for_delivery' => Icons.delivery_dining_rounded,
      'delivered' => Icons.check_circle_rounded,
      'returned' => Icons.assignment_return_rounded,
      'pickup_failed' => Icons.error_rounded,
      'disputed' => Icons.gavel_rounded,
      _ => Icons.help_outline_rounded,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon(), color: color, size: 22),
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
                      city,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.qr_code_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    waybill,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (cod > 0) ...[
                  Container(
                    width: 1,
                    height: 14,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'COD Rs. ${cod.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 10),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
