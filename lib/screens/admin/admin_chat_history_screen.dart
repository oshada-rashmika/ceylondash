import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChatHistoryScreen extends StatelessWidget {
  const AdminChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Agent Chat History',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: uid == null
          ? const Center(child: Text('Agent not signed in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('archived_chats')
                  .where('agentId', isEqualTo: uid)
                  .orderBy('resolvedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No archived chats yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final userId = data['userId'] ?? 'Unknown';
                    final resolvedTs = data['resolvedAt'] as Timestamp?;
                    final expireTs = data['expireAt'] as Timestamp?;

                    String resolvedAtStr = 'Unknown';
                    if (resolvedTs != null) {
                      resolvedAtStr = resolvedTs
                          .toDate()
                          .toLocal()
                          .toString()
                          .split('.')
                          .first;
                    }

                    String expiresIn = '';
                    if (expireTs != null) {
                      final diff = expireTs.toDate().difference(DateTime.now());
                      if (diff.inDays >= 1) {
                        expiresIn = '${diff.inDays} days left';
                      } else if (diff.inHours >= 1) {
                        expiresIn = '${diff.inHours} hours left';
                      } else {
                        expiresIn = 'Less than 1 hour';
                      }
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          userId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Resolved: $resolvedAtStr'),
                            const SizedBox(height: 4),
                            Text(
                              'Auto-deletes in 30 days · $expiresIn',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminChatHistoryDetailScreen(
                                archivedDocId: doc.id,
                                title: userId,
                              ),
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

class AdminChatHistoryDetailScreen extends StatelessWidget {
  final String archivedDocId;
  final String title;

  const AdminChatHistoryDetailScreen({
    super.key,
    required this.archivedDocId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('archived_chats')
        .doc(archivedDocId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: StreamBuilder<QuerySnapshot>(
        stream: messagesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(
              child: Text('No messages in this archived chat.'),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isAdmin = data['senderId'] == 'admin';
              final text = data['text'] ?? '';

              return Align(
                alignment: isAdmin
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.blueAccent : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isAdmin ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
