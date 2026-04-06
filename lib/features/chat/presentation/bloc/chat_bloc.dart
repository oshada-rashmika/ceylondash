import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/message_model.dart';
import '../../data/services/chat_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService chatService;
  StreamSubscription<List<MessageModel>>? _chatSubscription;

  ChatBloc({required this.chatService}) : super(ChatInitial()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SendMessage>(_onSendMessage);
  }

  Future<void> _onLoadChatMessages(LoadChatMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    await emit.forEach<List<MessageModel>>(
      chatService.getMessagesStream(event.trackingId),
      onData: (messages) => ChatLoaded(messages),
      onError: (error, stackTrace) => ChatError(error.toString()),
    );
  }


  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      await chatService.sendMessage(
        trackingId: event.trackingId,
        senderId: event.senderId,
        senderName: event.senderName,
        text: event.text,
        mediaFile: event.mediaFile,
        messageType: event.messageType,
        fileExtension: event.fileExtension,
      );
    } catch (e) {
      if (state is ChatLoaded) {
        // Here we could emit a ChatError, but to keep the loaded state, 
        // we might want to just handle UI errors via a global listener or separate state.
        // For simplicity, we can yield error and then back to loaded if required, 
        // but stream updates will override anyway.
        emit(ChatError('Failed to send message: ${e.toString()}'));
        emit(ChatLoaded((state as ChatLoaded).messages));
      }
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
