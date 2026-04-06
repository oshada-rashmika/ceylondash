import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

enum AnomalyType { speedHack, gpsSpoofing, highReturnRate }

class RedFlag {
  final String id;
  final String entityId; // Order ID or Shop Name
  final String title;
  final String description;
  final AnomalyType type;
  final DateTime timestamp;
  final String severity; // High, Medium

  RedFlag({
    required this.id,
    required this.entityId,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.severity,
  });
}

class FraudDetectionEngine {
  /// Haversine formula to calculate distance between two GeoPoints in kilometers.
  static double calculateDistance(GeoPoint p1, GeoPoint p2) {
    const double radius = 6371; // Earth's radius in km
    final double dLat = _toRadians(p2.latitude - p1.latitude);
    final double dLon = _toRadians(p2.longitude - p1.longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  static List<RedFlag> detectAnomalies(
    List<OrderModel> orders,
    List<Map<String, dynamic>> reports,
  ) {
    final List<RedFlag> flags = [];

    // 1. Detect Speed Hacks and GPS Spoofing
    for (var order in orders) {
      if (order.status == 'delivered') {
        // Speed Hack Check
        final pickedUpAt = order.timestamps['pickedUpAt'];
        final deliveredAt = order.timestamps['deliveredAt'];

        if (pickedUpAt is Timestamp && deliveredAt is Timestamp) {
          final difference = deliveredAt.toDate().difference(pickedUpAt.toDate());
          if (difference.inMinutes < 3) {
            flags.add(RedFlag(
              id: 'SH-${order.id}',
              entityId: order.id,
              title: 'Suspicious Speed',
              description: 'Order delivered in ${difference.inMinutes}m ${difference.inSeconds % 60}s after pickup.',
              type: AnomalyType.speedHack,
              timestamp: deliveredAt.toDate(),
              severity: 'High',
            ));
          }
        }

        // GPS Spoofing Check
        final deliveryLocation = order.rawData['deliveryLocation'] as GeoPoint?;
        final dropoffLocation = order.dropoffLocation;

        if (deliveryLocation != null) {
          final distance = calculateDistance(deliveryLocation, dropoffLocation);
          if (distance > 5.0) {
            flags.add(RedFlag(
              id: 'GPS-${order.id}',
              entityId: order.id,
              title: 'Location Mismatch',
              description: 'Delivered ${distance.toStringAsFixed(2)}km away from customer drop-off point.',
              type: AnomalyType.gpsSpoofing,
              timestamp: deliveredAt is Timestamp ? deliveredAt.toDate() : DateTime.now(),
              severity: 'High',
            ));
          }
        }
      }
    }

    // 2. Detect High Return Rates
    // Group orders by shopName (from rawData or sellerId)
    final Map<String, int> shopOrderCount = {};
    for (var order in orders) {
      final shopName = order.rawData['shopName'] ?? order.sellerId;
      shopOrderCount[shopName] = (shopOrderCount[shopName] ?? 0) + 1;
    }

    // Group reports (returns) by shopName
    final Map<String, int> shopReturnCount = {};
    for (var report in reports) {
      final shopName = report['shopName'] ?? 'Unknown Shop';
      shopReturnCount[shopName] = (shopReturnCount[shopName] ?? 0) + 1;
    }

    // Calculate rates
    shopReturnCount.forEach((shopName, returnCount) {
      final totalOrders = shopOrderCount[shopName] ?? 0;
      if (totalOrders > 0) {
        final rate = (returnCount / totalOrders) * 100;
        if (rate > 20.0) {
          flags.add(RedFlag(
            id: 'HRR-$shopName',
            entityId: shopName,
            title: 'High Return Rate',
            description: 'Shop has a return rate of ${rate.toStringAsFixed(1)}% ($returnCount returns in $totalOrders orders).',
            type: AnomalyType.highReturnRate,
            timestamp: DateTime.now(),
            severity: returnCount > 5 ? 'High' : 'Medium',
          ));
        }
      }
    });

    return flags;
  }
}
