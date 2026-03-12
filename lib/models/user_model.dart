import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String fcmToken;
  final String? courierId;
  final GeoPoint? currentLocation;
  final bool? isAvailable;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.fcmToken,
    this.courierId,
    this.currentLocation,
    this.isAvailable,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'customer',
      fcmToken: data['fcmToken'] ?? '',
      courierId: data['courierId'],
      currentLocation: data['currentLocation'],
      isAvailable: data['isAvailable'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'fcmToken': fcmToken,
      if (courierId != null) 'courierId': courierId,
      if (currentLocation != null) 'currentLocation': currentLocation,
      if (isAvailable != null) 'isAvailable': isAvailable,
    };
  }
}