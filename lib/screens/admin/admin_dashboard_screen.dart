import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'admin_chat_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getActiveSupportChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No active support requests.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String userId = docs[index].id;
              final String userName = data['userName'] ?? 'Customer';
              final String status = data['status'] ?? 'bot';
              final Timestamp? lastUpdated = data['lastUpdated'] as Timestamp?;

              String timeAgo = "Just now";
              if (lastUpdated != null) {
                final diff = DateTime.now().difference(lastUpdated.toDate());
                if (diff.inMinutes > 60) {
                  timeAgo = "${diff.inHours}h ago";
                } else if (diff.inMinutes > 0) {
                  timeAgo = "${diff.inMinutes}m ago";
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: status == 'waiting_for_agent'
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      status == 'waiting_for_agent'
                          ? Icons.warning_rounded
                          : Icons.chat_bubble_outline,
                      color: status == 'waiting_for_agent'
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    status == 'waiting_for_agent'
                        ? 'Needs assistance'
                        : 'Active chat',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (status == 'waiting_for_agent')
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.circle,
                            color: Colors.red,
                            size: 10,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminChatScreen(userId: userId, userName: userName),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
