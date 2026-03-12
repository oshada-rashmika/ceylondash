import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
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

  OrderModel({
    required this.id,
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
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
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