import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import 'qr_gen.dart' as qr_gen;
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/top_snackbar.dart';
import 'support_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DatabaseService _db = DatabaseService();
  String? _riderName;
  String? _sellerName;
  String? _shopName;
  String? _customerName;
  bool _loadingData = true;
  bool _isSubmittingReturn = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final futures = <Future<void>>[];

      // Fetch Rider
      if (widget.order.riderId != null) {
        futures.add(_db.getUser(widget.order.riderId!).then((user) {
          if (mounted) setState(() => _riderName = user?.name);
        }));
      }

      // Fetch Customer Name
      futures.add(_db.getUser(widget.order.customerId).then((user) {
        if (mounted) setState(() => _customerName = user?.name);
      }));

      // Fetch Shop and then the Shop's Seller
      futures.add(_db.getShop(widget.order.sellerId).then((shop) async {
        if (shop != null) {
          if (mounted) setState(() => _shopName = shop.name);
          
          if (shop.sellerId != null) {
            final sellerDoc = await _db.getUser(shop.sellerId!);
            if (mounted) {
              setState(() {
                _sellerName = sellerDoc?.name;
              });
            }
          }
        }
      }));

      await Future.wait(futures);
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _showReturnBottomSheet() {
    String? selectedReason;
    final otherController = TextEditingController();
    bool isOther = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              top: 32,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return the Parcel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please tell us why you want to return this item.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ...[
                  'Defective/Damaged',
                  'Incorrect Item Received',
                  'Quality not as expected',
                  'No longer needed',
                  'Other',
                ].map((reason) {
                  final isSelected = selectedReason == reason;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedReason = reason;
                        isOther = reason == 'Other';
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyan.withValues(alpha: 0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.cyan : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: isSelected ? Colors.cyan : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            reason,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.cyan.shade900 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (isOther) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: otherController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Please describe the issue...',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.cyan),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (selectedReason == null || (isOther && otherController.text.isEmpty))
                        ? null
                        : () => _submitReturn(
                              selectedReason == 'Other' ? otherController.text : selectedReason!,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Submit Return Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReturn(String reason) async {
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isSubmittingReturn = true);

    try {
      final reportData = {
        'orderId': widget.order.id,
        'customerName': _customerName ?? 'Unknown Customer',
        'shopName': _shopName ?? 'Unknown Shop',
        'orderedItem': widget.order.orderName,
        'reason': reason,
        'status': 'pending',
      };

      await _db.createReturnReport(reportData);
      await _db.updateOrderStatus(widget.order.id, 'Return Requested');

      if (mounted) {
        TopSnackbar.schedulePending(
          message: 'Return request submitted successfully!',
          type: SnackbarType.success,
        );
        Navigator.pop(context); // Back to order list
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.schedulePending(
          message: 'Failed to submit return: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReturn = false);
    }
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$min $amPm';
  }

  IconData _orderIcon(String status) {
    return switch (status) {
      'Return Requested' => Icons.assignment_return_rounded,
      'preparing' || 'pickup_scheduled' || 'picked_up' => Icons.soup_kitchen_rounded,
      'on_the_way' || 'in_transit' || 'out_for_delivery' => Icons.delivery_dining_rounded,
      'delivered' || 'past' => Icons.check_circle_rounded,
      'cancelled' => Icons.cancel_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  String _readableStatus(String s) {
    return switch (s) {
      'on_the_way' => 'On the Way',
      'in_transit' => 'In Transit',
      'out_for_delivery' => 'Out for Delivery',
      'pickup_scheduled' => 'Pickup Scheduled',
      'picked_up' => 'Picked Up',
      'processing' => 'Processing',
      'assigned' => 'Assigned to Rider',
      _ => s,
    };
  }

  (Color, Color) _getStatusColors(BuildContext context, String status) {
    if (status == 'delivered' || status == 'past') {
      return (const Color(0xFF4CAF50), const Color(0xFFE8F5E9));
    } else if (status == 'cancelled' || status == 'Return Requested') {
      return (Colors.red.shade700, Colors.red.shade50);
    } else {
      final primary = Theme.of(context).primaryColor;
      return (primary, primary.withValues(alpha: 0.1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.order.orderName.isNotEmpty ? widget.order.orderName : 'Order Details';
    final textScaler = MediaQuery.textScalerOf(context);
    final (primaryColor, bgColor) = _getStatusColors(context, widget.order.status);

    final cartItems = widget.order.rawData['items'] as List<dynamic>?;
    String displayItemName = widget.order.orderName;
    if (displayItemName.startsWith('Order from') && cartItems != null && cartItems.isNotEmpty) {
      final firstItem = cartItems.first['name'] as String? ?? 'Item';
      if (cartItems.length > 1) {
        displayItemName = '$firstItem + ${cartItems.length - 1} more';
      } else {
        displayItemName = firstItem;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order',
          style: TextStyle(
            color: Colors.black87,
            fontSize: textScaler.scale(18),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isSubmittingReturn
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                          child: Icon(_orderIcon(widget.order.status), color: primaryColor, size: 40),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _readableStatus(widget.order.status),
                          style: TextStyle(
                            fontSize: textScaler.scale(24),
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.order.id,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 32),
                        _buildInfoRow('Created', _formatTimestamp(widget.order.timestamps['createdAt'])),
                        const SizedBox(height: 20),
                        _buildInfoRow('Item', displayItemName),
                        const SizedBox(height: 20),
                        _buildInfoRow('Shop', _loadingData ? 'Loading...' : (_shopName ?? 'Unknown')),
                        const SizedBox(height: 20),
                        _buildInfoRow('Seller', _loadingData ? 'Loading...' : (_sellerName ?? 'Unknown')),
                        const SizedBox(height: 20),
                        _buildInfoRow('Rider', _loadingData ? 'Loading...' : (_riderName ?? 'Assigning...')),
                        if (widget.order.status == 'delivered' && !_loadingData) ...[
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _showReturnBottomSheet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                foregroundColor: Colors.red.shade700,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.red.shade100, width: 1.5),
                                ),
                              ),
                              child: const Text(
                                'Return the Parcel',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.order.status != 'delivered' && widget.order.status != 'cancelled' && widget.order.status != 'Return Requested')
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SupportScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.cyan.shade900,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Need help with your order?',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Contact our 24/7 support team.',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => qr_gen.QRGeneratorScreen(order: order),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Generate Qr Code',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
