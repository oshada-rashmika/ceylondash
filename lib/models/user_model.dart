import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final String fcmToken;
  final String? email;

  //Rider
  final String? courierCompany;
  final String? nic;
  final GeoPoint? currentLocation;
  final bool? isAvailable;

  //Customer
  final String? photoUrl;
  final String? address;
  final List<String>? accessibilityNeeds;

  //Seller
  final String? businessName;
  final String? businessAddress;
  final String? socials;
  final String? shopId;

  final String? courierId;
  final List<String>? usedPromotions;

  final int? trustScore;
  final String? birthday;
  final String? gender;
  final bool? isPremium;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.fcmToken,
    this.email,
    this.photoUrl,
    this.address,
    this.courierCompany,
    this.nic,
    this.currentLocation,
    this.isAvailable,
    this.businessName,
    this.businessAddress,
    this.socials,
    this.shopId,
    this.courierId,
    this.accessibilityNeeds,
    this.usedPromotions,
    this.trustScore,
    this.birthday,
    this.gender,
    this.isPremium,
  });

  String get loyaltyTier {
    final score = trustScore ?? 0;
    if (score >= 10000) return 'Diamond';
    if (score >= 5000) return 'Gold';
    if (score >= 3000) return 'Silver';
    return 'Bronze';
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'customer',
      fcmToken: data['fcmToken'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      address: data['address'],
      courierCompany: data['courierCompany'],
      nic: data['nic'],
      currentLocation: data['currentLocation'],
      isAvailable: data['isAvailable'],
      businessName: data['businessName'],
      businessAddress: data['businessAddress'],
      socials: data['socials'],
      shopId: data['shopId'],
      courierId: data['courierId'],
      accessibilityNeeds: data['accessibilityNeeds'] != null
          ? List<String>.from(data['accessibilityNeeds'])
          : null,
      usedPromotions: data['usedPromotions'] != null
          ? List<String>.from(data['usedPromotions'])
          : null,
      trustScore: data['trustScore'],
      birthday: data['birthday'],
      gender: data['gender'],
      isPremium: data['isPremium'],
    );
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': role,
      'fcmToken': fcmToken,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (address != null) 'address': address,
      if (courierCompany != null) 'courierCompany': courierCompany,
      if (nic != null) 'nic': nic,
      if (currentLocation != null) 'currentLocation': currentLocation,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (businessName != null) 'businessName': businessName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (socials != null) 'socials': socials,
      if (shopId != null) 'shopId': shopId,
      if (courierId != null) 'courierId': courierId,
      if (accessibilityNeeds != null) 'accessibilityNeeds': accessibilityNeeds,
      if (usedPromotions != null) 'usedPromotions': usedPromotions,
      if (trustScore != null) 'trustScore': trustScore,
      if (birthday != null) 'birthday': birthday,
      if (gender != null) 'gender': gender,
      if (isPremium != null) 'isPremium': isPremium,
    };
  }
}
