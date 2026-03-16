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

  Future<bool> acceptSupportRequest(
    String userId,
    String agentId,
    String agentName,
  ) async {
    final docRef = _firestore.collection('support_chats').doc(userId);
    final messagesRef = docRef.collection('messages').doc();

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists || snapshot.get('status') != 'waiting_for_agent') {
          return false;
        }

        transaction.update(docRef, {
          'status': 'active',
          'agentId': agentId,
          'agentName': agentName,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        transaction.set(messagesRef, {
          'senderId': 'system',
          'text': 'Hello! You are connected to $agentName.',
          'timestamp': FieldValue.serverTimestamp(),
          'isSystem': true,
          'isBot': false,
        });

        return true;
      });
    } catch (e) {
      return false;
    }
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

  /// Public API to resolve a chat (kept separate from older `markResolved`).
  Future<void> resolveChat(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'status': 'resolved',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Submit a rating and archive the chat messages into a `history` entry
  /// using a batched write to preserve integrity.
  Future<void> submitRatingAndArchive(
    String userId,
    int rating,
    String agentName,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final chatDocRef = _firestore.collection('support_chats').doc(userId);
    final historyCollection = chatDocRef.collection('history');
    final newHistoryRef = historyCollection.doc();

    // 1) Write metadata to the history doc
    batch.set(newHistoryRef, {
      'resolvedAt': FieldValue.serverTimestamp(),
      'rating': rating,
      'agentName': agentName,
    });

    // 2) Fetch current messages and copy them into history/<id>/messages
    final messagesSnap = await chatDocRef.collection('messages').get();
    for (var msg in messagesSnap.docs) {
      final target = newHistoryRef.collection('messages').doc(msg.id);
      batch.set(target, msg.data());
      // 3) delete original message
      batch.delete(msg.reference);
    }

    // 4) Update main support_chats doc to reset to bot state and clear agent
    batch.update(chatDocRef, {
      'status': 'bot',
      'agentId': FieldValue.delete(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> sendMessage({
    required String threadUserId,
    required String senderId,
    required String text,
    required bool isBot,
    bool isSystem = false,
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
      if (isSystem) 'isSystem': true,
    });

    await _firestore.collection('support_chats').doc(threadUserId).set({
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getActiveSupportChats() {
    return _firestore
        .collection('support_chats')
        .where('status', whereIn: ['waiting_for_agent', 'active'])
        .snapshots();
  }

  Future<void> clearChat(String userId) async {
    final messages = await _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('support_chats').doc(userId).delete();
  }

  Future<void> updateTypingStatus(String userId, bool isTyping) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'isTyping': isTyping,
    }, SetOptions(merge: true));
  }
}
