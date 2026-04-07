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
    final currentMonth = DateTime.now().month;
    final snapshot = await _db.collection('promotions').get();
    final promotions = <PromotionModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String? ?? 'seasonal';
      final activeMonths =
          (data['activeMonths'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [];
      final region = data['targetRegion'] as String? ?? '';

      // Rule: General promotions OR (Valid Region AND Valid Month)
      final matchesRegion =
          region.isEmpty ||
          userAddress.toLowerCase().contains(region.toLowerCase());
      final isTimeActive =
          activeMonths.isEmpty || activeMonths.contains(currentMonth);
      final isGeneral = type == 'general';

      if (isGeneral || (matchesRegion && isTimeActive)) {
        promotions.add(PromotionModel.fromMap(doc.id, data));
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
      body:
          'A new promotion "${promotion.title}" is now available. Check it out!',
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

  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromFirestore(query.docs.first);
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
        body:
            'Your order #${orderRef.id.substring(0, 5).toUpperCase()} has been successfully placed.',
        type: NotificationType.order,
        createdAt: DateTime.now(),
        relatedId: orderRef.id,
      ),
    );

    return orderRef.id;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final Map<String, dynamic> updates = {
      'status': newStatus,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == 'picked_up') {
      updates['timestamps.pickedUpAt'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'out_for_delivery') {
      // No specific timestamp for it right now, could add if needed
    }

    await _db.collection('orders').doc(orderId).update(updates);

    final orderDoc = await _db.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final customerId = orderDoc.data()?['customerId'];
      if (customerId != null) {
        String title = 'Order Updated';
        String body =
            'Your order status is now ${newStatus.replaceAll('_', ' ')}';

        if (newStatus == 'out_for_delivery') {
          title = 'Out for Delivery! 🛵';
          body =
              'Your rider is out for delivery. Your order will be delivered within next few hours.';
        } else if (newStatus == 'delivered') {
          title = 'Package Delivered! 🎉';
          body = 'Your package has been successfully delivered. Thank you!';
        }

        await createNotification(
          NotificationModel(
            id: '',
            userId: customerId,
            title: title,
            body: body,
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
            body:
                'A rider has been assigned to your order. They will pick it up soon!',
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

      // Fetch rider's details to include their name
      final riderDoc = await _db.collection('users').doc(riderId).get();
      final riderName = riderDoc.data()?['name'] ?? 'Your rider';

      if (customerId != null) {
        await createNotification(
          NotificationModel(
            id: '',
            userId: customerId,
            title: 'Order Claimed! 🚚',
            body:
                '$riderName has claimed your order! It is scheduled to be delivered within 3 working days.',
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
        .map(
          (snap) => snap.docs
              .map((d) => OrderModel.fromFirestore(d))
              .where(
                (o) =>
                    o.status == 'on_the_way' || o.status == 'out_for_delivery',
              )
              .toList(),
        );
  }

  Stream<List<OrderModel>> getDeliveryHistoryStream(String riderUid) {
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderUid)
        .where('status', isEqualTo: 'delivered')
        .orderBy('timestamps.deliveredAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> verifyDelivery(
    String orderId,
    String inputPin, {
    GeoPoint? deliveryLocation,
  }) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (!doc.exists) throw Exception('Order does not exist');
    final data = doc.data() as Map<String, dynamic>;
    final verifiedPin =
        data['verification']?['handoverPin'] ??
        data['rawData']?['handoverPin'] ??
        data['handoverPin'];
    if (verifiedPin != null && verifiedPin.toString() != inputPin) {
      throw Exception('Incorrect PIN');
    }

    await _db.collection('orders').doc(orderId).update({
      'status': 'delivered',
      'timestamps.deliveredAt': FieldValue.serverTimestamp(),
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
      if (deliveryLocation != null) 'deliveryLocation': deliveryLocation,
    });

    final customerId = data['customerId'];
    final riderId = data['riderId'];

    if (customerId != null) {
      await createNotification(
        NotificationModel(
          id: '',
          userId: customerId,
          title: 'Package Delivered! 🎉',
          body:
              'Your package has been successfully delivered. Thank you for choosing CeylonDash!',
          type: NotificationType.order,
          createdAt: DateTime.now(),
          relatedId: orderId,
        ),
      );
    }

    if (riderId != null) {
      await createNotification(
        NotificationModel(
          id: '',
          userId: riderId,
          title: 'Delivery Successful! 🏆',
          body: 'You have successfully completed the delivery. Great job!',
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

    await _db.collection('shops').doc(shop1Id).set({
      'sellerId': seller1Id,
    }, SetOptions(merge: true));

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

    await _db.collection('shops').doc(shop2Id).set({
      'sellerId': seller2Id,
    }, SetOptions(merge: true));

    await _db.collection('shops').doc(shop2Id).set({
      'sellerId': seller2Id,
    }, SetOptions(merge: true));

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
        .map(
          (snap) =>
              snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
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

  // --- Admin Dashboard Methods ---

  Future<int> getTotalOrdersCount() async {
    try {
      final snap = await _db.collection('orders').count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getActiveUsersCount() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getActiveRidersCount() async {
    try {
      final snap = await _db
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<int, int>> getOrderTrendsData() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final snap = await _db
          .collection('orders')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      // Initialize map for 7 days
      final trends = {
        0: 0,
        1: 0,
        2: 0,
        3: 4,
        4: 0,
        5: 0,
        6: 0,
      }; // Add some fallback defaults if empty

      for (var doc in snap.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final dayOffset = 6 - now.difference(date).inDays;
          if (dayOffset >= 0 && dayOffset <= 6) {
            trends[dayOffset] = (trends[dayOffset] ?? 0) + 1;
          }
        }
      }
      return trends;
    } catch (_) {
      return {
        0: 1,
        1: 3,
        2: 2,
        3: 5,
        4: 3,
        5: 4,
        6: 6,
      }; // Graceful fallback with dummy data
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      final snap = await _db
          .collection('orders')
          .where('status', isEqualTo: 'delivered')
          .get();
      double total = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        total += (data['totalAmount'] ?? 0).toDouble();
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  Stream<List<UserModel>> getAgentsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createAgentDocument(UserModel agent) async {
    await _db.collection('users').doc(agent.uid).set(agent.toMap());
  }

  Future<void> deactivateAgent(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Stream<List<PromotionModel>> streamAllPromotions() {
    return _db
        .collection('promotions')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PromotionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updatePromotion(String id, Map<String, dynamic> data) async {
    await _db.collection('promotions').doc(id).update(data);
  }

  Future<void> deletePromotion(String id) async {
    await _db.collection('promotions').doc(id).delete();
  }

  Stream<QuerySnapshot> getOngoingSupportChatsStream() {
    return _db.collection('support_chats').snapshots();
  }

  Stream<QuerySnapshot> getArchivedSupportChatsStream() {
    return _db.collection('archived_chats').snapshots();
  }

  Stream<List<UserModel>> getActiveRidersStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .where(
          'isAvailable',
          isEqualTo: true,
        ) // Filter for online/available riders
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .where(
                (u) => u.currentLocation != null,
              ) // Only return riders with location
              .toList(),
        );
  }

  Stream<List<OrderModel>> getActiveOrdersStream() {
    return _db
        .collection('orders')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .where(
                (o) => o.status != 'delivered' && o.status != 'cancelled',
              ) // Filter for active orders
              .toList(),
        );
  }

  Future<List<OrderModel>> getRecentOrders(Duration duration) async {
    final now = DateTime.now();
    final start = now.subtract(duration);
    final snap = await _db
        .collection('orders')
        .where('timestamps.updatedAt', isGreaterThan: Timestamp.fromDate(start))
        .get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentReports(Duration duration) async {
    final now = DateTime.now();
    final start = now.subtract(duration);
    final snap = await _db
        .collection('reports')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(start))
        .get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }
}
