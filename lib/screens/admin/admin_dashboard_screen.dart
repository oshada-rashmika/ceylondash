import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import 'admin_chat_history_screen.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'admin_chat_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Agent Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Archived Chats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminChatHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getActiveSupportChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList();
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No active support requests.",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['lastUpdated'] as Timestamp?;
            final timeB = dataB['lastUpdated'] as Timestamp?;
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String userId = docs[index].id;
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

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  String userName = data['userName'] ?? 'Customer';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final udata =
                        userSnap.data!.data() as Map<String, dynamic>?;
                    userName = udata?['name'] ?? userName;
                  }

                  return _AdminDashboardItem(
                    userId: userId,
                    userName: userName,
                    status: status,
                    timeAgo: timeAgo,
                    chatService: chatService,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminDashboardItem extends StatefulWidget {
  final String userId;
  final String userName;
  final String status;
  final String timeAgo;
  final ChatService chatService;

  const _AdminDashboardItem({
    required this.userId,
    required this.userName,
    required this.status,
    required this.timeAgo,
    required this.chatService,
  });

  @override
  State<_AdminDashboardItem> createState() => _AdminDashboardItemState();
}

class _AdminDashboardItemState extends State<_AdminDashboardItem> {
  bool _isClaiming = false;

  Future<void> _claimChat() async {
    setState(() {
      _isClaiming = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Agent not logged in');
      }

      final agentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final String agentName =
          agentDoc.data()?['name'] ?? user.displayName ?? 'Support Agent';

      final success = await widget.chatService.acceptSupportRequest(
        widget.userId,
        user.uid,
        agentName,
      );

      if (!mounted) return;

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatScreen(
              userId: widget.userId,
              userName: widget.userName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request already claimed by another agent.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming chat: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: widget.status == 'waiting_for_agent'
              ? Colors.red.shade100
              : Colors.green.shade100,
          child: Icon(
            widget.status == 'waiting_for_agent'
                ? Icons.warning_rounded
                : Icons.chat_bubble_outline,
            color: widget.status == 'waiting_for_agent'
                ? Colors.red
                : Colors.green,
          ),
        ),
        title: Text(
          widget.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          widget.status == 'waiting_for_agent'
              ? 'Needs assistance'
              : 'Active chat',
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: widget.status == 'waiting_for_agent'
            ? _isClaiming
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      onPressed: _claimChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
        onTap: widget.status == 'active'
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminChatScreen(
                      userId: widget.userId,
                      userName: widget.userName,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
