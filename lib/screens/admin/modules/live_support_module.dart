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
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring Station',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withAlpha(220),
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oversee live agent performance and history',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blueAccent,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.label,
                padding: EdgeInsets.symmetric(horizontal: 12),
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: [
                  Tab(text: "Live Ongoing"),
                  Tab(text: "Archived History"),
                ],
              ),
            ],
          ),
        ),
        body: BlocBuilder<SupportChatsBloc, SupportChatsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }
            if (state.error != null) {
              return Center(child: Text('Monitor Offline: ${state.error}'));
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              collectionName == 'support_chats' ? Icons.chat_bubble_outline_rounded : Icons.history_edu_rounded, 
              size: 80, 
              color: Colors.grey.withAlpha(80)
            ),
            const SizedBox(height: 24),
            Text(
              collectionName == 'support_chats' ? 'No Live Traffic' : 'No Archive Entries',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'All clear! Agents are currently idling.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final data = chats[index].data() as Map<String, dynamic>;
        final String chatId = chats[index].id;
        final String customerName = data['userName'] ?? data['customerName'] ?? 'Pro-User';
        final String agentName = data['agentName'] ?? 'Awaiting Agent';
        final String lastMessage = data['lastMessage'] ?? 'System: Conversation Handover';
        final String status = data['status'] ?? 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.blueAccent, size: 30),
                ),
                if (collectionName == 'support_chats' && status == 'active')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Operator: $agentName',
                  style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 28),
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
