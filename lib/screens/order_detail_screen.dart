import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import '../services/payhere_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoadingPayment = false;
  final PayHereService _payHereService = PayHereService();

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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$min $amPm';
  }

  IconData _orderIcon(String status) {
    return switch (status) {
      'preparing' => Icons.soup_kitchen_rounded,
      'on_the_way' => Icons.delivery_dining_rounded,
      'delivered' => Icons.check_circle_rounded,
      'past' => Icons.check_circle_rounded,
      'cancelled' => Icons.cancel_rounded,
      _ => Icons.receipt_long_rounded,
    };
  }

  String _readableStatus(String s) {
    return switch (s) {
      'on_the_way' => 'On the Way',
      'processing' => 'Processing',
      'pending' => 'Pending Payment',
      _ => '${s[0].toUpperCase()}${s.substring(1)}',
    };
  }

  (Color, Color) _getStatusColors(BuildContext context, String status) {
    if (status == 'delivered' || status == 'past') {
      return (const Color(0xFF4CAF50), const Color(0xFFE8F5E9));
    } else if (status == 'cancelled') {
      return (Colors.red.shade700, Colors.red.shade50);
    } else {
      final primary = Theme.of(context).primaryColor;
      return (primary, primary.withValues(alpha: 0.1));
    }
  }

  void _startPayment() async {
    setState(() => _isLoadingPayment = true);

    await _payHereService.startCheckout(
      context: context,
      orderId: widget.order.id,
      amount: (widget.order.rawData['totalAmount'] as num?)?.toDouble() ?? 1000.0, // fallback if totalAmount is missing
      customerName: "Customer Name", // Replace with real customer data if available
      customerPhone: "+94771234567", // Replace with real customer phone if available
      onCompleted: (paymentId) {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Successful! ID: $paymentId")),
        );
        // Additional logic like refreshing the order or popping back
      },
      onError: (error) {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment Error: $error")),
        );
      },
      onCanceled: () {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Canceled")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.order.orderName.isNotEmpty
        ? widget.order.orderName
        : 'Order #${widget.order.id.substring(0, 5)}';

    final textScaler = MediaQuery.textScalerOf(context);
    final (primaryColor, bgColor) = _getStatusColors(context, widget.order.status);
    
    // Attempting to resolve paymentStatus, otherwise fallback to widget.order.status == 'pending'
    final paymentStatus = (widget.order.rawData['paymentStatus'] as String?) ?? 'unknown';
    final needsPayment = paymentStatus == 'pending' || widget.order.status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: textScaler.scale(20),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: needsPayment ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: _isLoadingPayment ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isLoadingPayment
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Pay Now',
                  style: TextStyle(
                    fontSize: textScaler.scale(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
          ),
        ),
      ) : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 2.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _orderIcon(widget.order.status),
                        color: primaryColor,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Order ${_readableStatus(widget.order.status)}',
                style: TextStyle(
                  fontSize: textScaler.scale(22),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth = constraints.constrainWidth();
                  const dashedWidth = 6.0;
                  const dashedHeight = 1.5;
                  final dashCount = (boxWidth / (2 * dashedWidth)).floor();
                  return Flex(
                    direction: Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(dashCount, (_) {
                      return SizedBox(
                        width: dashedWidth,
                        height: dashedHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 32),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            'Created',
                            _formatTimestamp(widget.order.timestamps['createdAt']),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            context,
                            'Status',
                            _readableStatus(widget.order.status),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(context, 'Seller ID', widget.order.sellerId),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            context,
                            'Rider ID',
                            widget.order.riderId ?? 'Assigning Rider...',
                          ),
                          if ((widget.order.status == 'delivered' ||
                                  widget.order.status == 'past') &&
                              widget.order.timestamps['deliveredAt'] != null) ...[
                            const SizedBox(height: 20),
                            _buildDetailRow(
                              context,
                              'Delivered At',
                              _formatTimestamp(widget.order.timestamps['deliveredAt']),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: textScaler.scale(16),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: textScaler.scale(16),
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
