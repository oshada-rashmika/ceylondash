import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/promotion_model.dart';
import '../models/shop_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<int> getUserOrderCount(String uid) async {
    final snap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<List<PromotionModel>> getSeasonalPromotions(String userAddress) async {
    debugPrint("Fetching promotions...");
    final currentMonth = DateTime.now().month;
    final snapshot = await _db.collection('promotions').get();

    debugPrint('Found ${snapshot.docs.length} total promotions in database.');
    final promotions = <PromotionModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final activeMonths =
          (data['activeMonths'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [];

      final region = data['targetRegion'] as String? ?? '';
      final matchesRegion = userAddress.toLowerCase().contains(
        region.toLowerCase(),
      );
      final isSeasonActive = activeMonths.contains(currentMonth);

      debugPrint(
        "Promo ID: ${doc.id} | matchesRegion: $matchesRegion | isSeasonActive: $isSeasonActive",
      );

      if (matchesRegion && isSeasonActive) {
        debugPrint("Promo ${doc.id} Accepted");
        final promo = PromotionModel.fromMap(doc.id, data);
        promotions.add(promo);
      } else {
        debugPrint(
          "Promo ${doc.id} Rejected (Reason: ${!matchesRegion ? 'Region mismatch' : ''}${!isSeasonActive && !matchesRegion ? ' / ' : ''}${!isSeasonActive ? 'Month mismatch' : ''})",
        );
      }
    }
    return promotions;
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson());
    debugPrint('🔥 Firestore User Created: ${user.uid}');
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<String> createOrder(
    OrderModel order, {
    String? appliedPromoCode,
    String? userId,
  }) async {
    final batch = _db.batch();
    final orderRef = _db.collection('orders').doc();
    final orderData = order.toMap();
    orderData['id'] = orderRef.id;
    batch.set(orderRef, orderData);
    if (appliedPromoCode != null && userId != null) {
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {
        'usedPromotions': FieldValue.arrayUnion([appliedPromoCode]),
      });
    }
    await batch.commit();

    return orderRef.id;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignRider(String orderId, String riderId) async {
    await _db.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((snapshot) {
      return OrderModel.fromFirestore(snapshot);
    });
  }

  Stream<List<OrderModel>> streamCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamps.createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
        );
  }

  Future<List<ShopModel>> getAllShops() async {
    final snap = await _db.collection('shops').get();
    return snap.docs.map((d) => ShopModel.fromJson(d.id, d.data())).toList();
  }

  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }
}
