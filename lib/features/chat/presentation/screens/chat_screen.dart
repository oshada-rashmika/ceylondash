import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/chat_service.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatelessWidget {
  final String trackingId;
  final String currentUserId;
  final String currentUserName;

  const ChatScreen({
    Key? key,
    required this.trackingId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(chatService: ChatService())
        ..add(LoadChatMessages(trackingId)),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Support Chat'),
              Text(
                'Tracking ID: $trackingId',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          backgroundColor: Colors.blue[600],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading || state is ChatInitial) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (state is ChatLoaded) {
                    final messages = state.messages;
                    if (messages.isEmpty) {
                      return const Center(child: Text('No messages yet. Start the conversation!'));
                    }
                    
                    return ListView.builder(
                      reverse: true, // we get them ordered by descending from stream
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isIncoming = message.senderId != currentUserId;
                        return ChatBubble(
                          message: message,
                          isIncoming: isIncoming,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            MessageInput(
              trackingId: trackingId,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
            ),
          ],
        ),
      ),
    );
  }
}
