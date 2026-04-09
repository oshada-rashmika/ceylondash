import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice, document, location }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final String? mediaUrl;
  final MessageType messageType;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.mediaUrl,
    required this.messageType,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    MessageType type = MessageType.text;
    String typeStr = map['messageType'] ?? 'text';
    switch (typeStr) {
      case 'image':
        type = MessageType.image;
        break;
      case 'voice':
        type = MessageType.voice;
        break;
      case 'document':
        type = MessageType.document;
        break;
      case 'location':
        type = MessageType.location;
        break;
      default:
        type = MessageType.text;
    }

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      messageType: type,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'mediaUrl': mediaUrl,
      'messageType': messageType.name,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
