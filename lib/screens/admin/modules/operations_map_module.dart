import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/map_bloc.dart';
import '../../../../models/order_model.dart';
import '../../../../models/user_model.dart';

class OperationsMapModule extends StatelessWidget {
  const OperationsMapModule({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapBloc()..add(LoadMapData()),
      child: const MapView(),
    );
  }
}

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        if (state.status == MapStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        if (state.status == MapStatus.error) {
          return Center(child: Text('Map Error: ${state.error}'));
        }

        return Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(6.9271, 79.8612), // Colombo Center
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ceylondash.app',
                ),
                MarkerLayer(
                  markers: [
                    ...state.activeOrders.map((order) => _buildOrderMarker(order)),
                    ...state.activeRiders.map((rider) => _buildRiderMarker(rider)),
                  ],
                ),
              ],
            ),
            _buildMapOverlayCount(state.activeRiders.length, state.activeOrders.length),
          ],
        );
      },
    );
  }

  Marker _buildOrderMarker(OrderModel order) {
    return Marker(
      point: LatLng(order.dropoffLocation.latitude, order.dropoffLocation.longitude),
      width: 40,
      height: 40,
      child: Tooltip(
        message: 'Order: ${order.id.substring(0, 5).toUpperCase()}\nStatus: ${order.status}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withAlpha(200),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.orangeAccent.withAlpha(100), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Marker _buildRiderMarker(UserModel rider) {
    return Marker(
      point: LatLng(rider.currentLocation!.latitude, rider.currentLocation!.longitude),
      width: 60,
      height: 60,
      child: Column(
        children: [
          Tooltip(
            message: 'Rider: ${rider.name}\n${rider.phone}',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
            ),
            child: Text(
              rider.name.split(' ').first,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOverlayCount(int riderCount, int orderCount) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCountItem(Icons.motorcycle_rounded, Colors.blueAccent, '$riderCount Online Riders'),
            const SizedBox(height: 8),
            _buildCountItem(Icons.inventory_2_rounded, Colors.orangeAccent, '$orderCount Active Orders'),
          ],
        ),
      ),
    );
  }

  Widget _buildCountItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
