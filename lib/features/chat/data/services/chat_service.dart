import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Get stream of messages for a particular trackingId
  Stream<List<MessageModel>> getMessagesStream(String trackingId) {
    return _firestore
        .collection('chats')
        .doc(trackingId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage({
    required String trackingId,
    required String senderId,
    required String senderName,
    String? text,
    File? mediaFile,
    required MessageType messageType,
    String? fileExtension,
  }) async {
    String messageId = _uuid.v4();
    String? mediaUrl;

    if (mediaFile != null) {
      String ext = fileExtension ?? 'unknown';
      String storagePath = 'chats/$trackingId/$messageId.$ext';
      Reference ref = _storage.ref().child(storagePath);
      TaskSnapshot uploadTask = await ref.putFile(mediaFile);
      mediaUrl = await uploadTask.ref.getDownloadURL();
    }

    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      mediaUrl: mediaUrl,
      messageType: messageType,
      timestamp: DateTime.now(), // Local timestamp, will be overwritten by serverTimestamp in toMap
    );

    // Write to firestore
    await _firestore
        .collection('chats')
        .doc(trackingId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());
        
    // Also update parent chat document update time
    await _firestore.collection('chats').doc(trackingId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
