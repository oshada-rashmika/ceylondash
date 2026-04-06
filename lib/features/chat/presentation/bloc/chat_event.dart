import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatMessages extends ChatEvent {
  final String trackingId;

  const LoadChatMessages(this.trackingId);

  @override
  List<Object> get props => [trackingId];
}

class UpdateChatMessages extends ChatEvent {
  final List<MessageModel> messages;

  const UpdateChatMessages(this.messages);

  @override
  List<Object> get props => [messages];
}

class SendMessage extends ChatEvent {
  final String trackingId;
  final String senderId;
  final String senderName;
  final String? text;
  final File? mediaFile;
  final MessageType messageType;
  final String? fileExtension;

  const SendMessage({
    required this.trackingId,
    required this.senderId,
    required this.senderName,
    this.text,
    this.mediaFile,
    required this.messageType,
    this.fileExtension,
  });

  @override
  List<Object?> get props => [
        trackingId,
        senderId,
        senderName,
        text,
        mediaFile,
        messageType,
        fileExtension,
      ];
}
