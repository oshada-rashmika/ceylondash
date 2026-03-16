import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'chat_history_screen.dart';

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
  int _selectedRating = 0;

  String _userName = 'Customer';
  bool _askedBotFirstQuestion = false;

  final List<String> _faqOptions = [
    "Where is my order?",
    "How to use promo codes?",
    "Refund policy",
    "Change delivery address",
    "Payment methods",
    "Report a missing item",
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
    String answer =
        "I'm sorry, I don't have information on that right now. Please contact a live agent for assistance.";
    if (question == "Where is my order?") {
      try {
        final orderQuery = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (orderQuery.docs.isNotEmpty) {
          final orderData = orderQuery.docs.first.data();
          final orderId = orderQuery.docs.first.id;
          final status = orderData['status'] ?? 'unknown';
          answer =
              "Your latest order (#${orderId.substring(0, 5)}) is currently $status.";
        } else {
          answer = "You currently have no active orders.";
        }
      } catch (e) {
        answer =
            "You can track your order by visiting the 'Orders' section in your dashboard. It displays real-time status updates.";
      }
    } else if (question == "How to use promo codes?") {
      answer =
          "To use a promo code, enter it at checkout before completing the payment.";
    } else if (question == "Refund policy") {
      answer =
          "Our refund policy allows you to request a refund within 14 days of your purchase if the item is undamaged.";
    } else if (question == "Change delivery address") {
      answer =
          "You can change your delivery address from your profile settings, or adjust it during checkout before placing the order.";
    } else if (question == "Payment methods") {
      answer =
          "We accept all major credit cards, debit cards, and local digital payment methods.";
    } else if (question == "Report a missing item") {
      answer =
          "We apologize for the inconvenience. Please contact our live agent right away to resolve missing item issues.";
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
    final uid = this._uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('support_chats').doc(uid).set({
      'userId': uid,
      'userName': FirebaseAuth.instance.currentUser?.displayName ?? _userName,
      'status': 'waiting_for_agent',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _chatService.sendMessage(
      threadUserId: uid,
      senderId: 'system',
      text: "Transferring to a live agent. Please hold...",
      isBot: false,
      isSystem: true,
    );
  }

  void _sendMessage() async {
    final uid = this._uid;
    if (_msgController.text.trim().isEmpty || uid == null) return;
    final text = _msgController.text.trim();
    _msgController.clear();
    await _chatService.sendMessage(
      threadUserId: uid,
      senderId: uid,
      text: text,
      isBot: false,
    );
    // Auto-escalate to a live agent when a custom message is sent
    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(uid)
          .update({
            'status': 'waiting_for_agent',
            'userName':
                FirebaseAuth.instance.currentUser?.displayName ?? _userName,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      // If update fails (doc may not exist), set with merge
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(uid)
          .set({
            'status': 'waiting_for_agent',
            'userName':
                FirebaseAuth.instance.currentUser?.displayName ?? _userName,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    // Write an automated system message informing the user
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(uid)
        .collection('messages')
        .add({
          'senderId': 'system',
          'text': 'Transferring you to a live agent. Please hold...',
          'timestamp': FieldValue.serverTimestamp(),
          'isSystem': true,
        });
  }

  Future<void> _showClearChatDialog() async {
    final uid = this._uid;
    if (uid == null) return;

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Start a new chat?'),
        content: const Text('This will clear your current conversation.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Chat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.clearChat(uid);
      if (mounted) {
        setState(() {
          _askedBotFirstQuestion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = this._uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: const Center(child: Text('Please log in to use support.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Premium off-white
      appBar: AppBar(
        title: const Text(
          'Live Support',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clock),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash),
            onPressed: _showClearChatDialog,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatService.getSupportChatStream(uid),
        builder: (context, chatSnap) {
          final bool isWaiting;
          final bool isActive;
          final bool isTyping;

          String? statusStr;
          String? agentName;
          if (!chatSnap.hasData || !chatSnap.data!.exists) {
            isWaiting = false;
            isActive = false;
            isTyping = false;
            statusStr = null;
            agentName = null;
          } else {
            final data = chatSnap.data!.data() as Map<String, dynamic>?;
            statusStr = data?['status'] as String?;
            agentName = data?['agentName'] as String?;
            isWaiting = statusStr == 'waiting_for_agent';
            isActive = statusStr == 'active';
            isTyping = data?['isTyping'] ?? false;
          }

          final showAgentButton =
              _askedBotFirstQuestion && !isWaiting && !isActive;

          return Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessagesStream(uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    final int itemCount = docs.length + 1;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          return _buildChatBubble(
                            "Hello! Welcome to CeylonDash Premium Support. How can we assist you today?",
                            false,
                            true,
                          );
                        }

                        final data = docs[index].data() as Map<String, dynamic>;
                        final isMe = data['senderId'] == uid;
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

                        return _buildChatBubble(data['text'], isMe, isBot);
                      },
                    );
                  },
                ),
              ),

              if (isTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildTypingIndicator(),
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
                  color: Colors.transparent,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _faqOptions
                          .map(
                            (q) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                label: Text(
                                  q,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                elevation: 0,
                                pressElevation: 0,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ),
                                onPressed: () => _handleLocalFaq(q),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: (statusStr == 'resolved')
                    ? Container(
                        key: const ValueKey('rating_card'),
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Issue Resolved. How was your experience?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                final idx = i + 1;
                                final filled = _selectedRating >= idx;
                                return GestureDetector(
                                  onTap: () async {
                                    HapticFeedback.mediumImpact();
                                    setState(() {
                                      _selectedRating = idx;
                                    });
                                  },
                                  child: AnimatedScale(
                                    scale: filled ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                      ),
                                      child: Icon(
                                        Icons.star,
                                        color: filled
                                            ? Colors.amber
                                            : Colors.grey[300],
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _selectedRating == 0
                                    ? null
                                    : () async {
                                        if (uid == null) return;
                                        await _chatService
                                            .submitRatingAndArchive(
                                              uid,
                                              _selectedRating,
                                              agentName ?? 'Agent',
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Thanks for your feedback!',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    'Submit Rating',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : (isWaiting)
                    ? Container(
                        key: const ValueKey('connecting'),
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 12),
                            Text(
                              'Connecting to a premium agent...',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: const ValueKey('message_input'),
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 200)),
            curve: Curves.easeInOutSine,
            builder: (context, value, child) {
              return Opacity(
                opacity: (value + 0.5) % 1.0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          );
        }),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe, bool isBot) {
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
