import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';

class AdminChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _chatService.assignAgent(widget.userId);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    _chatService.updateTypingStatus(widget.userId, _focusNode.hasFocus);
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final text = _msgController.text.trim();
    _msgController.clear();
    _chatService.updateTypingStatus(widget.userId, false);

    await _chatService.sendMessage(
      threadUserId: widget.userId,
      senderId: 'admin',
      text: text,
      isBot: false,
    );
  }

  void _markResolved() async {
    await _chatService.resolveChat(widget.userId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: Text(
          '${widget.userName} - Support',
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Mark as Resolved?'),
                  content: const Text(
                    'This will close the active support chat.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _markResolved();
                      },
                      child: const Text(
                        'Resolved',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Mark Resolved',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.userId),
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
                    final isAdmin = data['senderId'] == 'admin';
                    return _buildChatBubble(
                      data['text'],
                      isAdmin,
                      data['senderId'],
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type reply...',
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
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isAdmin, String senderId) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isAdmin
                ? const Radius.circular(0)
                : const Radius.circular(20),
            bottomLeft: !isAdmin
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAdmin && senderId != widget.userId)
              Text(
                senderId.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (!isAdmin && senderId != widget.userId)
              const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: isAdmin ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
