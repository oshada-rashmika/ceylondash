import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/message_model.dart';
import 'media_bubble.dart';
import 'voice_player.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isIncoming;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('hh:mm a');
    final timeString = dateFormat.format(message.timestamp);

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isIncoming ? Colors.grey[200] : Colors.blue[600],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isIncoming ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight: isIncoming ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isIncoming ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isIncoming) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
            ],
            _buildContent(),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 10,
                color: isIncoming ? Colors.black54 : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: isIncoming ? Colors.black87 : Colors.white,
            fontSize: 16,
          ),
        );
      case MessageType.voice:
        if (message.mediaUrl != null) {
          return VoicePlayer(
            audioUrl: message.mediaUrl!,
            isIncoming: isIncoming,
          );
        }
        return const Text('Voice message missing');
      case MessageType.image:
      case MessageType.document:
      case MessageType.location:
        return MediaBubble(
          messageType: message.messageType.name,
          mediaUrl: message.mediaUrl,
          text: message.text,
          isIncoming: isIncoming,
        );
    }
  }
}
