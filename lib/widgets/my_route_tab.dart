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

        return Stack(
          children: [
            // Ensure the map takes the full height of the stack
            Positioned.fill(child: _buildMap(activeJobs)),
            if (activeJobs.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: _buildJobList(activeJobs),
              ),
            if (activeJobs.isEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No active jobs to display.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
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
      if (job.dropoffLocation.latitude != 0 &&
          job.dropoffLocation.longitude != 0) {
        markerPos = LatLng(
          job.dropoffLocation.latitude,
          job.dropoffLocation.longitude,
        );
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
      options: MapOptions(initialCenter: center, initialZoom: 7.0),
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
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 230,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ActiveJobCard(order: job),
          );
        },
      ),
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
        TopSnackbar.show(
          context,
          message: 'Status updated to Delivered!',
          type: SnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TopSnackbar.show(
          context,
          message: 'Update failed',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropoff = widget.order.dropoffAddress.isNotEmpty
        ? widget.order.dropoffAddress
        : 'Customer location';
    final name = widget.order.orderName.isNotEmpty
        ? widget.order.orderName
        : 'Order #${widget.order.id.substring(0, 8)}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.cyan.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyan.shade200),
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.order.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: Colors.cyan.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dropoff,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: widget.order.status == 'delivered' || _isUpdating
                    ? null
                    : _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isUpdating
                    ? const SizedBox.shrink()
                    : const Icon(Icons.check_circle_outline, size: 22),
                label: _isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Mark as Delivered',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
