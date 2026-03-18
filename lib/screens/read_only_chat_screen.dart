import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReadOnlyChatScreen extends StatelessWidget {
  final String archiveId;
  final String agentName;

  const ReadOnlyChatScreen({
    super.key,
    required this.archiveId,
    required this.agentName,
  });

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('archived_chats')
        .doc(archiveId)
        .collection('messages')
        .orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(title: Text('Chat with $agentName'), elevation: 0),
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages in this conversation.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe =
                        data['senderId'] ==
                        FirebaseFirestore
                            .instance
                            .app
                            .name; // unlikely; keep simple
                    final isBot = data['isBot'] ?? false;
                    final isSystem =
                        data['isSystem'] == true ||
                        data['senderId'] == 'system';

                    if (isSystem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            data['text'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // We can't reliably determine the current user's id here,
                    // so render non-system messages as agent (left) or user (right)
                    final senderId = data['senderId'] as String?;
                    final bool renderedAsMe =
                        senderId == 'user' || senderId == 'customer';

                    return _buildChatBubble(
                      context,
                      data['text'] ?? '',
                      renderedAsMe,
                      isBot,
                    );
                  },
                );
              },
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: const Color(0xFFF5F5F7),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'This conversation has been resolved and is read-only.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context,
    String text,
    bool isMe,
    bool isBot,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? null : Colors.white,
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF141E30), Color(0xFF243B55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
            bottomLeft: !isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isMe)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
