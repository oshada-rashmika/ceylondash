import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../blocs/rider_bloc.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';
import 'top_snackbar.dart';

class MyRouteTab extends StatelessWidget {
  const MyRouteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RiderBloc, RiderState>(
      builder: (context, state) {
        if (!state.isAvailable) {
          return const Center(child: Text('Go Online to view your route'));
        }

        final activeJobs = state.activeRouteJobs;

        return Column(
          children: [
            Expanded(
              flex: 6,
              child: _buildMap(activeJobs),
            ),
            Expanded(
              flex: 4,
              child: _buildJobList(activeJobs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(List<OrderModel> jobs) {
    // Default to a central coordinate for Sri Lanka
    final center = const LatLng(7.8731, 80.7718);
    
    // Markers
    final markers = jobs.map((job) {
      LatLng markerPos;
      if (job.dropoffLocation.latitude != 0 && job.dropoffLocation.longitude != 0) {
        markerPos = LatLng(job.dropoffLocation.latitude, job.dropoffLocation.longitude);
      } else {
        markerPos = center; // TODO: Geocode dropoffAddress to LatLng
      }
      return Marker(
        point: markerPos,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 7.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ceylondash',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildJobList(List<OrderModel> jobs) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No active jobs to display.'));
    }
    return ListView.builder(
      itemCount: jobs.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return ActiveJobCard(order: job);
      },
    );
  }
}

class ActiveJobCard extends StatefulWidget {
  final OrderModel order;
  const ActiveJobCard({super.key, required this.order});

  @override
  State<ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends State<ActiveJobCard> {
  bool _isUpdating = false;

  void _updateStatus() async {
    setState(() => _isUpdating = true);
    try {
      await DatabaseService().updateOrderStatus(widget.order.id, 'delivered');
      if (mounted) {
        TopSnackbar.show(context, message: 'Status updated to Delivered!', type: SnackbarType.success);
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.show(context, message: 'Update failed', type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropoff = widget.order.dropoffAddress.isNotEmpty ? widget.order.dropoffAddress : 'Customer location';
    final name = widget.order.orderName.isNotEmpty ? widget.order.orderName : 'Order #${widget.order.id.substring(0, 8)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.order.status, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(dropoff, style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.order.status == 'delivered' || _isUpdating ? null : _updateStatus,
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUpdating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Mark as Delivered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
