import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/promotion_model.dart';

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
    print("Fetching promotions...");
    final currentMonth = DateTime.now().month;
    final snapshot = await _db.collection('promotions').get();

    print('Found ${snapshot.docs.length} total promotions in database.');
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

      print(
        "Promo ID: ${doc.id} | matchesRegion: $matchesRegion | isSeasonActive: $isSeasonActive",
      );

      if (matchesRegion && isSeasonActive) {
        print("Promo ${doc.id} Accepted");
        final promo = PromotionModel.fromMap(doc.id, data);
        promotions.add(promo);
      } else {
        print(
          "Promo ${doc.id} Rejected (Reason: ${!matchesRegion ? 'Region mismatch' : ''}${!isSeasonActive && !matchesRegion ? ' / ' : ''}${!isSeasonActive ? 'Month mismatch' : ''})",
        );
      }
    }
    return promotions;
  }

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
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

  Future<String> createOrder(OrderModel order) async {
    DocumentReference docRef = await _db
        .collection('orders')
        .add(order.toMap());
    return docRef.id;
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
}
