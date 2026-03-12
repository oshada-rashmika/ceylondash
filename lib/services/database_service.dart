import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
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

  Future<String> createOrder(OrderModel order) async {
    DocumentReference docRef = await _db.collection('orders').add(order.toMap());
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
}