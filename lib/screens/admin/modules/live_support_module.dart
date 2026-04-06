import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/support_chats_bloc.dart';
import 'admin_read_only_chat_screen.dart';

class LiveSupportModule extends StatelessWidget {
  const LiveSupportModule({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupportChatsBloc()..add(LoadSupportChats()),
      child: const LiveSupportView(),
    );
  }
}

class LiveSupportView extends StatelessWidget {
  const LiveSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: ColorfulTabBar(),
        ),
        body: BlocBuilder<SupportChatsBloc, SupportChatsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }

            return TabBarView(
              children: [
                _buildChatList(state.ongoingChats, 'support_chats', context),
                _buildChatList(state.archivedChats, 'archived_chats', context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatList(List<QueryDocumentSnapshot> chats, String collectionName, BuildContext context) {
    if (chats.isEmpty) {
      return Center(
        child: Text(
          collectionName == 'support_chats' ? 'No ongoing support chats.' : 'No archived chats.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final data = chats[index].data() as Map<String, dynamic>;
        final String chatId = chats[index].id;
        final String agentName = data['agentName'] ?? 'Unknown Agent';
        final String customerName = data['customerName'] ?? 'Unknown Customer';
        final String lastMessage = data['lastMessage'] ?? 'No messages yet';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE3E8FF),
                  child: Icon(Icons.support_agent, color: Colors.blueAccent),
                ),
                if (collectionName == 'support_chats')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              '$customerName - $agentName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReadOnlyChatScreen(
                    chatId: chatId,
                    agentName: agentName,
                    customerName: customerName,
                    collectionName: collectionName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ColorfulTabBar extends StatelessWidget {
  const ColorfulTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const TabBar(
        labelColor: Colors.blueAccent,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blueAccent,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        tabs: [
          Tab(text: "Ongoing"),
          Tab(text: "Archived"),
        ],
      ),
    );
  }
}
