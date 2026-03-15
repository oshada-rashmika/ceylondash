import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ChatService _chatService = ChatService();
  final DatabaseService _dbService = DatabaseService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _msgController = TextEditingController();

  String _userName = 'Customer';
  bool _askedBotFirstQuestion = false;

  final List<String> _faqOptions = [
    "Where is my order?",
    "How to use promo codes?",
    "Refund policy",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (_uid != null) {
      final user = await _dbService.getUser(_uid);
      if (user != null) {
        if (mounted) {
          setState(
            () => _userName = user.name.isNotEmpty ? user.name : 'Customer',
          );
        }
      }
    }
  }

  Future<void> _handleLocalFaq(String question) async {
    if (_uid == null) return;

    // Create initial chat if doesn't exist
    await FirebaseFirestore.instance.collection('support_chats').doc(_uid).set({
      'userId': _uid,
      'userName': _userName,
      'status': 'bot',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Send User Question
    await _chatService.sendMessage(
      threadUserId: _uid,
      senderId: _uid,
      text: question,
      isBot: false,
    );

    // Simulate Bot typing
    await Future.delayed(const Duration(milliseconds: 600));

    // Bot Response
    String answer = "I'm sorry, I don't have information on that right now.";
    if (question == "Where is my order?") {
      answer =
          "You can track your order by visiting the 'Orders' section in your dashboard. It displays real-time status updates.";
    } else if (question == "How to use promo codes?") {
      answer =
          "To use a promo code, enter it at checkout before completing the payment.";
    } else if (question == "Refund policy") {
      answer =
          "Our refund policy allows you to request a refund within 14 days of your purchase if the item is undamaged.";
    }

    await _chatService.sendMessage(
      threadUserId: _uid,
      senderId: 'bot',
      text: answer,
      isBot: true,
    );

    if (mounted) {
      setState(() {
        _askedBotFirstQuestion = true;
      });
    }
  }

  Future<void> _contactAgent() async {
    final _uid = this._uid;
    if (_uid == null) return;
    await _chatService.connectToAgent(_uid, _userName);
    await _chatService.sendMessage(
      threadUserId: _uid,
      senderId: 'system',
      text: "Transferring to a live agent. Please hold...",
      isBot: true,
    );
  }

  void _sendMessage() async {
    final _uid = this._uid;
    if (_msgController.text.trim().isEmpty || _uid == null) return;
    final text = _msgController.text.trim();
    _msgController.clear();
    await _chatService.sendMessage(
      threadUserId: _uid,
      senderId: _uid,
      text: text,
      isBot: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _uid = this._uid;
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: const Center(child: Text('Please log in to use support.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Premium off-white
      appBar: AppBar(
        title: const Text(
          'Live Support',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getSupportChatStream(_uid),
        builder: (context, chatSnap) {
          final bool isWaiting;
          final bool isActive;

          if (!chatSnap.hasData || !chatSnap.data!.exists) {
            isWaiting = false;
            isActive = false;
          } else {
            final data = chatSnap.data!.data() as Map<String, dynamic>?;
            final status = data?['status'];
            isWaiting = status == 'waiting_for_agent';
            isActive = status == 'active';
          }

          final showAgentButton =
              _askedBotFirstQuestion && !isWaiting && !isActive;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessagesStream(_uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == _uid;
                        final isBot = data['isBot'] ?? false;
                        final isSystem = data['senderId'] == 'system';

                        return _buildChatBubble(
                          data['text'],
                          isMe,
                          isBot || isSystem,
                        );
                      },
                    );
                  },
                ),
              ),

              if (showAgentButton)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Did this solve your issue?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _contactAgent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Contact an Agent',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (!isWaiting && !isActive && !_askedBotFirstQuestion)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _faqOptions
                        .map(
                          (q) => ActionChip(
                            label: Text(
                              q,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => _handleLocalFaq(q),
                          ),
                        )
                        .toList(),
                  ),
                ),

              if (isWaiting || isActive)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.black,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe, bool isBot) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
            bottomLeft: !isMe
                ? const Radius.circular(0)
                : const Radius.circular(20),
          ),
          boxShadow: [
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
          ),
        ),
      ),
    );
  }
}
