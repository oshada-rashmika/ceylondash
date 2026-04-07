import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class RiderDeliveryHistoryScreen extends StatefulWidget {
  const RiderDeliveryHistoryScreen({super.key});

  @override
  State<RiderDeliveryHistoryScreen> createState() =>
      _RiderDeliveryHistoryScreenState();
}

class _RiderDeliveryHistoryScreenState
    extends State<RiderDeliveryHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Stream<List<OrderModel>> _getHistoryStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: _uid)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          list.sort((a, b) {
            final ta =
                a.timestamps['deliveredAt'] ??
                a.timestamps['updatedAt'] ??
                a.rawData['createdAt'];
            final tb =
                b.timestamps['deliveredAt'] ??
                b.timestamps['updatedAt'] ??
                b.rawData['createdAt'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta); // descending
            }
            return 0; // fallback
          });
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Delivery History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        surfaceTintColor: Colors.white,
      ),
      body: _uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<OrderModel>>(
              stream: _getHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading history: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final jobs = snapshot.data ?? [];
                if (jobs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text(
                          'No completed deliveries yet.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return _HistoryCard(order: job);
                  },
                );
              },
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final OrderModel order;
  const _HistoryCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final fee = order.rawData['deliveryFee'] ?? order.rawData['codAmount'] ?? 0;

    final deliveredTs =
        order.timestamps['deliveredAt'] ??
        order.timestamps['updatedAt'] ??
        order.rawData['createdAt'];

    String formattedDate = 'Processing Date';
    if (deliveredTs is Timestamp) {
      formattedDate = DateFormat(
        'MMM d, yyyy • h:mm a',
      ).format(deliveredTs.toDate());
    }

    final handoverPin =
        order.verification['handoverPin'] ?? order.rawData['handoverPin'];
    String proofMethod = 'Location Verified';
    IconData proofIcon = Icons.location_on_outlined;

    if (handoverPin != null) {
      proofMethod = 'Verified via PIN Code';
      proofIcon = Icons.password_rounded;
    } else if (order.rawData['qrCodeUuid'] != null) {
      proofMethod = 'Verified via QR Code';
      proofIcon = Icons.qr_code_scanner_rounded;
    }

    final pickup = order.rawData['pickupAddress'] ?? 'Shop Location';
    final dropoff = order.dropoffAddress.isNotEmpty
        ? order.dropoffAddress
        : 'Customer Location';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LKR $fee',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickup,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            height: 20,
            width: 2,
            color: Colors.black12,
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dropoff,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(proofIcon, size: 16, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  proofMethod,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
