import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/promotion_model.dart';
import '../models/shop_model.dart';
import '../models/notification_model.dart';

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

  Future<void> createPromotion(PromotionModel promotion) async {
    final docRef = _db.collection('promotions').doc();
    await docRef.set(promotion.toMap());
    
    // Notify all customers about the new promotion
    await broadcastNotification(
      title: 'New Special Offer! 🎁',
      body: 'A new promotion "${promotion.title}" is now available. Check it out!',
      type: NotificationType.promo,
      relatedId: docRef.id,
    );
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
    await batch.commit();

    // Notify customer about the new order
    await createNotification(
      NotificationModel(
        id: '',
        userId: userId ?? order.customerId,
        title: 'Order Placed! 🛍️',
        body: 'Your order #${orderRef.id.substring(0, 5).toUpperCase()} has been successfully placed.',
        type: NotificationType.order,
        createdAt: DateTime.now(),
        relatedId: orderRef.id,
      ),
    );

    return orderRef.id;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });

    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final customerId = orderDoc.data()?['customerId'];
      if (customerId != null) {
        await createNotification(
          NotificationModel(
            id: '',
            userId: customerId,
            title: 'Order Updated',
            body: 'Your order status is now ${newStatus.replaceAll('_', ' ')}',
            type: NotificationType.order,
            createdAt: DateTime.now(),
            relatedId: orderId,
          ),
        );
      }
    }
  }

  Future<void> assignRider(String orderId, String riderId) async {
    await _db.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'status': 'assigned',
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });

    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final customerId = orderDoc.data()?['customerId'];
      if (customerId != null) {
        await createNotification(
          NotificationModel(
            id: '',
            userId: customerId,
            title: 'Rider Assigned! 🛵',
            body: 'A rider has been assigned to your order. They will pick it up soon!',
            type: NotificationType.order,
            createdAt: DateTime.now(),
            relatedId: orderId,
          ),
        );
      }
    }
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
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
        );
  }

  Stream<List<OrderModel>> getPendingJobsStream() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'processing')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => OrderModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> claimJob(String orderId, String riderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'on_the_way',
      'riderId': riderId,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });

    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final customerId = orderDoc.data()?['customerId'];
      if (customerId != null) {
        await createNotification(
          NotificationModel(
            id: '',
            userId: customerId,
            title: 'Rider on the way! 🚀',
            body: 'Your rider has claimed the order and is heading to the restaurant.',
            type: NotificationType.order,
            createdAt: DateTime.now(),
            relatedId: orderId,
          ),
        );
      }
    }
  }

  Stream<List<OrderModel>> getMyActiveRouteStream(String riderUid) {
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromFirestore(d))
            .where((o) =>
                o.status == 'on_the_way' || o.status == 'out_for_delivery')
            .toList());
  }

  Future<void> verifyDelivery(String orderId, String inputPin) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) throw Exception('Order does not exist');
    final data = doc.data() as Map<String, dynamic>;
    final verifiedPin = data['verification']?['handoverPin'] ?? 
                        data['rawData']?['handoverPin'] ?? 
                        data['handoverPin'];
    if (verifiedPin != null && verifiedPin.toString() != inputPin) {
      throw Exception('Incorrect PIN');
    }

    await _db.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'timestamps.deliveredAt': FieldValue.serverTimestamp(),
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });

    final customerId = data['customerId'];
    if (customerId != null) {
      await createNotification(
        NotificationModel(
          id: '',
          userId: customerId,
          title: 'Order Delivered',
          body: 'Your order has been safely delivered. Enjoy!',
          type: NotificationType.order,
          createdAt: DateTime.now(),
          relatedId: orderId,
        ),
      );
    }
  }

  Future<List<ShopModel>> getAllShops() async {
    final snap = await _db.collection('shops').get();
    return snap.docs.map((d) => ShopModel.fromJson(d.id, d.data())).toList();
  }

  Future<ShopModel?> getShop(String id) async {
    final doc = await _db.collection('shops').doc(id).get();
    if (doc.exists) {
      return ShopModel.fromJson(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> seedBotSellers() async {
    // 1. Gadget Hub
    final shop1Id = 'Cv38tAlSKDEoKOSz2aMI';
    final seller1Id = 'U7T5r95C7RXJKjcjwHW9VG2VIGvl';
    
    final seller1Ref = _db.collection('users').doc(seller1Id);
    await seller1Ref.set({
      'uid': seller1Id,
      'name': 'SENUKA',
      'email': 'ranasingheasila@gmail.com',
      'fcmToken': '',
      'phone': '+94768223528',
      'role': 'seller',
      'businessName': 'Gadget Hub',
      'businessAddress': 'SVDJHDSFSFE',
      'shopId': shop1Id,
    }, SetOptions(merge: true));
    
    await _db.collection('shops').doc(shop1Id).set({'sellerId': seller1Id}, SetOptions(merge: true));

    // 2. Urban Wear (Existing test seller)
    final shop2Id = 'Uij5NuEdftwRTf0eVUmY';
    final seller2Id = 'test_seller_456';
    
    final seller2Ref = _db.collection('users').doc(seller2Id);
    await seller2Ref.set({
      'uid': seller2Id,
      'name': 'Urban Wear Seller',
      'email': 'urbanwear@example.com',
      'role': 'seller',
      'businessName': 'Urban Wear',
      'businessAddress': 'Colombo 07',
      'shopId': shop2Id,
    }, SetOptions(merge: true));
    
    await _db.collection('shops').doc(shop2Id).set({'sellerId': seller2Id}, SetOptions(merge: true));

    await _db.collection('shops').doc(shop2Id).set({'sellerId': seller2Id}, SetOptions(merge: true));

    debugPrint('✅ Bot Sellers and Shop Links seeded successfully!');
  }

  Future<void> createReturnReport(Map<String, dynamic> reportData) async {
    final reportId = _db.collection('reports').doc().id;
    await _db.collection('reports').doc(reportId).set({
      'reportId': reportId,
      ...reportData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Notification Methods ---

  Future<void> createNotification(NotificationModel notification) async {
    await _db.collection('notifications').add(notification.toMap());
  }

  Future<void> broadcastNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    final customersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();

    final batch = _db.batch();
    for (var doc in customersSnap.docs) {
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': doc.id,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': relatedId,
      });
    }
    await batch.commit();
  }

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final unreadSnap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in unreadSnap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
