import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReadOnlyChatScreen extends StatelessWidget {
  final String chatId;
  final String agentName;
  final String customerName;
  final String collectionName; // 'support_chats' or 'archived_chats'

  const AdminReadOnlyChatScreen({
    super.key,
    required this.chatId,
    required this.agentName,
    required this.customerName,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat: $customerName & $agentName'), 
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
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
                    final isSystem = data['isSystem'] == true || data['senderId'] == 'system';

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

                    final senderId = data['senderId'] as String?;
                    // Customer/User on the right, Agent on the left
                    final bool isCustomer = senderId == 'user' || senderId == 'customer';
                    
                    return _buildChatBubble(
                      context,
                      data['text'] ?? '',
                      isCustomer,
                      data['senderName'] ?? (isCustomer ? customerName : agentName),
                    );
                  },
                );
              },
            ),
          ),

          if (collectionName == 'archived_chats')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              color: const Color(0xFFF5F5F7),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This conversation is archived and read-only.',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
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
    bool isCustomer,
    String senderName,
  ) {
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              senderName,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCustomer ? null : Colors.white,
              gradient: isCustomer
                  ? const LinearGradient(
                      colors: [Color(0xFF141E30), Color(0xFF243B55)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isCustomer
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
                bottomLeft: !isCustomer
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              boxShadow: [
                if (!isCustomer)
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
                color: isCustomer ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
