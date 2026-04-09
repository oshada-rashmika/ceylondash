import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../services/rider_service.dart';
import 'top_snackbar.dart';

class JobCard extends StatefulWidget {
  final OrderModel order;
  const JobCard({super.key, required this.order});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isClaiming = false;

  void _claimJob() async {
    setState(() => _isClaiming = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await RiderService().claimJob(widget.order.id, uid);
        if (mounted) {
          TopSnackbar.show(context, message: 'Job Claimed successfully!', type: SnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          TopSnackbar.show(context, message: 'Failed to claim job', type: SnackbarType.error);
        }
      } finally {
        if (mounted) setState(() => _isClaiming = false);
      }
    } else {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.order.rawData['pickupAddress'] ?? 'Shop location';
    final dropoff = widget.order.dropoffAddress.isNotEmpty ? widget.order.dropoffAddress : 'Customer location';
    final fee = widget.order.rawData['deliveryFee'] ?? widget.order.rawData['codAmount'] ?? 0;
    final orderName = widget.order.orderName.isNotEmpty 
        ? widget.order.orderName 
        : 'Order #${widget.order.id.substring(0, 8)}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    orderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LKR $fee',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.storefront, color: Colors.black54, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(pickup, style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
              child: Container(width: 2, height: 16, color: Colors.grey.shade300),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(dropoff, style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isClaiming ? null : _claimJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isClaiming
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Claim Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
