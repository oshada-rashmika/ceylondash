import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getSupportChatStream(String userId) {
    return _firestore.collection('support_chats').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> connectToAgent(String userId, String userName) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'userId': userId,
      'userName': userName,
      'status': 'waiting_for_agent',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> assignAgent(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'status': 'active',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markResolved(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'status': 'resolved',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String text,
    required bool isBot,
  }) async {
    final docRef = _firestore
        .collection('support_chats')
        .doc(threadUserId)
        .collection('messages')
        .doc();

    await docRef.set({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isBot': isBot,
    });

    await _firestore.collection('support_chats').doc(threadUserId).set({
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getActiveSupportChats() {
    return _firestore
        .collection('support_chats')
        .where('status', whereIn: ['waiting_for_agent', 'active'])
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }
}
