// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $h:$min $amPm';
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

  @override
  Widget build(BuildContext context) {
    final title = order.orderName.isNotEmpty
        ? order.orderName
        : 'Order #${order.id.substring(0, 5)}';
    final isDelivered = order.status == 'delivered';
    final isCancelled = order.status == 'cancelled';
    final isCompleted = isDelivered || isCancelled;

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
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Hero(
              tag: 'order_status_icon_${order.id}',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.black.withOpacity(0.04)
                      : (isDelivered
                            ? Colors.black.withOpacity(0.04)
                            : Colors.cyan.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _orderIcon(order.status),
                  color: isCancelled
                      ? Colors.black38
                      : (isDelivered ? Colors.black87 : Colors.cyan.shade600),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                  _buildDetailRow(
                    'Created',
                    _formatTimestamp(order.timestamps['createdAt']),
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    'Status',
                    _readableStatus(order.status),
                    valueColor: isCompleted
                        ? Colors.black87
                        : Colors.cyan.shade600,
                    valueWeight: FontWeight.w800,
                  ),
                  _buildDivider(),
                  _buildDetailRow('Seller ID', order.sellerId),
                  _buildDivider(),
                  _buildDetailRow(
                    'Rider ID',
                    order.riderId ?? 'Assigning Rider...',
                    valueColor: order.riderId == null
                        ? Colors.black38
                        : Colors.black87,
                    isItalicValue: order.riderId == null,
                  ),
                  if (isDelivered &&
                      order.timestamps['deliveredAt'] != null) ...[
                    _buildDivider(),
                    _buildDetailRow(
                      'Delivered At',
                      _formatTimestamp(order.timestamps['deliveredAt']),
                      isLast: true,
                    ),
                  ],
                  if (!isDelivered || order.timestamps['deliveredAt'] == null)
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
    bool isFirst = false,
    bool isLast = false,
    bool isItalicValue = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: isFirst ? 24 : 16,
        bottom: isLast ? 24 : 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? Colors.black87,
                fontWeight: valueWeight ?? FontWeight.w600,
                fontStyle: isItalicValue ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.black.withOpacity(0.04),
      ),
    );
  }
}
