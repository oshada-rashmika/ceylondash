import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'database_service.dart';

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

  /// Agent action: mark the chat as resolved without archiving.
  /// Agent-side: mark chat resolved and create an initial archive entry
  /// without deleting active messages. The customer will append the rating
  /// and perform cleanup later.
  Future<void> markChatResolved(
    String userId,
    String agentId,
    String agentName,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final archivedDocRef = FirebaseFirestore.instance
        .collection('archived_chats')
        .doc();
    final expireAt = DateTime.now().add(const Duration(days: 30));

    // 1) write initial metadata with null rating
    batch.set(archivedDocRef, {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'rating': null,
      'resolvedAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(expireAt),
    });

    // 2) copy messages into archive/messages (do not delete originals yet)
    final chatDocRef = _firestore.collection('support_chats').doc(userId);
    final messagesSnap = await chatDocRef.collection('messages').get();

    for (var msg in messagesSnap.docs) {
      final target = archivedDocRef.collection('messages').doc(msg.id);
      batch.set(target, msg.data());
      // Intentionally do NOT delete the original message here.
    }

    // 3) update support_chats/<userId> to resolved and store latestArchiveId
    batch.update(chatDocRef, {
      'status': 'resolved',
      'latestArchiveId': archivedDocRef.id,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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
  /// Customer action: submit rating and archive the chat to the root
  /// `archived_chats` collection (retained for 30 days). This performs a
  /// batched copy of messages then deletes the active messages and resets
  /// the support chat to the bot state.
  /// Customer-side: append rating to the previously-created archive and
  /// then delete active messages and reset the support chat to bot state.
  Future<void> submitRatingAndArchive(String userId, int rating) async {
    final chatDocRef = _firestore.collection('support_chats').doc(userId);
    final chatSnap = await chatDocRef.get();
    final data = chatSnap.data();
    final latestArchiveId = data != null
        ? data['latestArchiveId'] as String?
        : null;

    final batch = FirebaseFirestore.instance.batch();

    if (latestArchiveId != null) {
      final archivedDocRef = FirebaseFirestore.instance
          .collection('archived_chats')
          .doc(latestArchiveId);

      // 1) update rating on existing archive doc
      batch.update(archivedDocRef, {'rating': rating});

      // 2) fetch and delete active messages
      final messagesSnap = await chatDocRef.collection('messages').get();
      for (var msg in messagesSnap.docs) {
        batch.delete(msg.reference);
      }

      // 3) reset support chat to bot state and remove latestArchiveId
      batch.update(chatDocRef, {
        'status': 'bot',
        'agentId': FieldValue.delete(),
        'latestArchiveId': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } else {
      // Fallback: if no archive exists, create one and move messages then set rating
      final archivedDocRef = FirebaseFirestore.instance
          .collection('archived_chats')
          .doc();
      final expireAt = DateTime.now().add(const Duration(days: 30));

      batch.set(archivedDocRef, {
        'userId': userId,
        'agentId': data?['agentId'] ?? '',
        'agentName': data?['agentName'] ?? 'Agent',
        'rating': rating,
        'resolvedAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expireAt),
      });

      final messagesSnap = await chatDocRef.collection('messages').get();
      for (var msg in messagesSnap.docs) {
        final target = archivedDocRef.collection('messages').doc(msg.id);
        batch.set(target, msg.data());
        batch.delete(msg.reference);
      }

      batch.update(chatDocRef, {
        'status': 'bot',
        'agentId': FieldValue.delete(),
        'latestArchiveId': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  /// Resolve and archive an active support chat into the root
  /// `archived_chats` collection with a 30-day expiry timestamp.
  Future<void> resolveAndArchiveChat(
    String userId,
    String agentId,
    String agentName,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // New root archived doc
    final archivedDocRef = FirebaseFirestore.instance
        .collection('archived_chats')
        .doc();

    // expiry set to 30 days from now
    final expireAt = DateTime.now().add(const Duration(days: 30));

    // 1) write metadata to archived_chats/<newId>
    batch.set(archivedDocRef, {
      'userId': userId,
      'agentId': agentId,
      'agentName': agentName,
      'resolvedAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(expireAt),
    });

    // 2) fetch messages from support_chats/<userId>/messages and copy/delete
    final chatDocRef = _firestore.collection('support_chats').doc(userId);
    final messagesSnap = await chatDocRef.collection('messages').get();

    for (var msg in messagesSnap.docs) {
      final target = archivedDocRef.collection('messages').doc(msg.id);
      batch.set(target, msg.data());
      // delete original
      batch.delete(msg.reference);
    }

    // 3) update the main support_chats/<userId> doc to bot state and clear agent
    batch.update(chatDocRef, {
      'status': 'bot',
      'agentId': FieldValue.delete(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 4) commit the batched write
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

    // Notify customer if sender is not them
    if (senderId != threadUserId && !isBot && !isSystem) {
      await DatabaseService().createNotification(
        NotificationModel(
          id: '',
          userId: threadUserId,
          title: 'New Support Message',
          body: text,
          type: NotificationType.support,
          createdAt: DateTime.now(),
          relatedId: threadUserId,
        ),
      );
    }
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
