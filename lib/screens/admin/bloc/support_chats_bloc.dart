import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/database_service.dart';

// --- Events ---
abstract class SupportChatsEvent {}
class LoadSupportChats extends SupportChatsEvent {}
class OngoingChatsUpdated extends SupportChatsEvent {
  final List<QueryDocumentSnapshot> chats;
  OngoingChatsUpdated(this.chats);
}
class ArchivedChatsUpdated extends SupportChatsEvent {
  final List<QueryDocumentSnapshot> chats;
  ArchivedChatsUpdated(this.chats);
}

// --- States ---
class SupportChatsState {
  final bool isLoading;
  final List<QueryDocumentSnapshot> ongoingChats;
  final List<QueryDocumentSnapshot> archivedChats;
  final String? error;

  SupportChatsState({
    required this.isLoading,
    required this.ongoingChats,
    required this.archivedChats,
    this.error,
  });

  factory SupportChatsState.initial() => SupportChatsState(
        isLoading: true,
        ongoingChats: [],
        archivedChats: [],
      );

  SupportChatsState copyWith({
    bool? isLoading,
    List<QueryDocumentSnapshot>? ongoingChats,
    List<QueryDocumentSnapshot>? archivedChats,
    String? error,
  }) {
    return SupportChatsState(
      isLoading: isLoading ?? this.isLoading,
      ongoingChats: ongoingChats ?? this.ongoingChats,
      archivedChats: archivedChats ?? this.archivedChats,
      error: error ?? this.error,
    );
  }
}

// --- Bloc ---
class SupportChatsBloc extends Bloc<SupportChatsEvent, SupportChatsState> {
  final DatabaseService _db = DatabaseService();
  StreamSubscription? _ongoingSubscription;
  StreamSubscription? _archivedSubscription;

  SupportChatsBloc() : super(SupportChatsState.initial()) {
    on<LoadSupportChats>(_onLoadSupportChats);
    on<OngoingChatsUpdated>((event, emit) => emit(state.copyWith(isLoading: false, ongoingChats: event.chats)));
    on<ArchivedChatsUpdated>((event, emit) => emit(state.copyWith(isLoading: false, archivedChats: event.chats)));
  }

  void _onLoadSupportChats(LoadSupportChats event, Emitter<SupportChatsState> emit) {
    emit(state.copyWith(isLoading: true));
    
    _ongoingSubscription?.cancel();
    _ongoingSubscription = _db.getOngoingSupportChatsStream().listen(
      (snapshot) => add(OngoingChatsUpdated(snapshot.docs)),
      onError: (e) => emit(state.copyWith(error: e.toString(), isLoading: false)),
    );

    _archivedSubscription?.cancel();
    _archivedSubscription = _db.getArchivedSupportChatsStream().listen(
      (snapshot) => add(ArchivedChatsUpdated(snapshot.docs)),
      onError: (e) => emit(state.copyWith(error: e.toString(), isLoading: false)),
    );
  }

  @override
  Future<void> close() {
    _ongoingSubscription?.cancel();
    _archivedSubscription?.cancel();
    return super.close();
  }
}
