import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderName;
  final String externalPlatformRef;
  final String sellerId;
  final String customerId;
  final String courierId;
  final String? riderId;
  final String status;
  final GeoPoint dropoffLocation;
  final String dropoffAddress;
  final Map<String, dynamic> verification;
  final Map<String, dynamic> timestamps;
  final Map<String, dynamic> rawData;

  OrderModel({
    required this.id,
    required this.orderName,
    required this.externalPlatformRef,
    required this.sellerId,
    required this.customerId,
    required this.courierId,
    this.riderId,
    required this.status,
    required this.dropoffLocation,
    required this.dropoffAddress,
    required this.verification,
    required this.timestamps,
    required this.rawData,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderName: data['orderName'] ?? '',
      externalPlatformRef: data['externalPlatformRef'] ?? '',
      sellerId: data['sellerId'] ?? '',
      customerId: data['customerId'] ?? '',
      courierId: data['courierId'] ?? '',
      riderId: data['riderId'],
      status: data['status'] ?? 'processing',
      dropoffLocation: data['dropoffLocation'],
      dropoffAddress: data['dropoffAddress'] ?? '',
      verification: data['verification'] ?? {},
      timestamps: data['timestamps'] ?? {},
      rawData: data,
    );
  }

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;

    final searchableText = <String>{
      id,
      externalPlatformRef,
      status,
      dropoffAddress,
      ..._extractSearchStrings(rawData),
    }.where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();

    return searchableText.contains(normalizedQuery);
  }

  static Set<String> _extractSearchStrings(Object? value, {String? key}) {
    final results = <String>{};

    if (value is String) {
      final normalizedKey = key?.toLowerCase() ?? '';
      if (normalizedKey.isEmpty || _isSearchFriendlyKey(normalizedKey)) {
        results.add(value);
      }
      return results;
    }

    if (value is Iterable) {
      for (final entry in value) {
        results.addAll(_extractSearchStrings(entry, key: key));
      }
      return results;
    }

    if (value is Map) {
      value.forEach((entryKey, entryValue) {
        results.addAll(
          _extractSearchStrings(entryValue, key: entryKey.toString()),
        );
      });
    }

    return results;
  }

  static bool _isSearchFriendlyKey(String key) {
    const keywords = {
      'item',
      'items',
      'name',
      'title',
      'product',
      'products',
      'status',
      'address',
      'store',
      'seller',
      'external',
      'ref',
    };

    return keywords.any(key.contains);
  }

  Map<String, dynamic> toMap() {
    return {
      'orderName': orderName,
      'externalPlatformRef': externalPlatformRef,
      'sellerId': sellerId,
      'customerId': customerId,
      'courierId': courierId,
      'riderId': riderId,
      'status': status,
      'dropoffLocation': dropoffLocation,
      'dropoffAddress': dropoffAddress,
      'verification': verification,
      'timestamps': {
        'createdAt': timestamps['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deliveredAt': timestamps['deliveredAt'],
      },
    };
  }
}
