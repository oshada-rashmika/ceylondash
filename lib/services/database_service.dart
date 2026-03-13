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
    final currentMonth = DateTime.now().month;
    final snap = await _db.collection('promotions').where('type', isEqualTo: 'seasonal').get();
    
    final promotions = <PromotionModel>[];
    for (final doc in snap.docs) {
      final promo = PromotionModel.fromMap(doc.id, doc.data());
      
      bool monthMatches = true;
      if (promo.activeMonths != null && promo.activeMonths!.isNotEmpty) {
        monthMatches = promo.activeMonths!.contains(currentMonth);
      }

      bool regionMatches = true;
      if (promo.targetRegion != null && promo.targetRegion!.isNotEmpty) {
        regionMatches = userAddress.toLowerCase().contains(promo.targetRegion!.toLowerCase());
      }
      
      if (monthMatches && regionMatches) {
        promotions.add(promo);
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

  /// Real-time stream of the user document.
  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  /// Update specific fields on the user document.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  Future<String> createOrder(OrderModel order) async {
    DocumentReference docRef = await _db
        .collection('orders')
        .add(order.toMap());
    return docRef.id;
  }

  //Admin/Rider action
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  //Courier Admin action
  Future<void> assignRider(String orderId, String riderId) async {
    await _db.collection('orders').doc(orderId).update({
      'riderId': riderId,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  //Customer tracking view
  Stream<OrderModel> streamOrder(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((snapshot) {
      return OrderModel.fromFirestore(snapshot);
    });
  }

  /// Stream all orders for a given customer, ordered by createdAt descending.
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
