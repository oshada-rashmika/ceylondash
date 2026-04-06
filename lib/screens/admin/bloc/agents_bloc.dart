import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/database_service.dart';
import '../../../../models/user_model.dart';

// --- Events ---
abstract class AgentsEvent {}
class LoadAgents extends AgentsEvent {}
class AgentsUpdated extends AgentsEvent {
  final List<UserModel> agents;
  AgentsUpdated(this.agents);
}
class AddAgent extends AgentsEvent {
  final UserModel agent;
  AddAgent(this.agent);
}
class DeactivateAgent extends AgentsEvent {
  final String uid;
  DeactivateAgent(this.uid);
}

// --- States ---
abstract class AgentsState {}
class AgentsLoading extends AgentsState {}
class AgentsLoaded extends AgentsState {
  final List<UserModel> agents;
  AgentsLoaded(this.agents);
}
class AgentsError extends AgentsState {
  final String message;
  AgentsError(this.message);
}

// --- Bloc ---
class AgentsBloc extends Bloc<AgentsEvent, AgentsState> {
  final DatabaseService _db = DatabaseService();
  StreamSubscription? _agentsSubscription;

  AgentsBloc() : super(AgentsLoading()) {
    on<LoadAgents>(_onLoadAgents);
    on<AgentsUpdated>(_onAgentsUpdated);
    on<AddAgent>(_onAddAgent);
    on<DeactivateAgent>(_onDeactivateAgent);
  }

  void _onLoadAgents(LoadAgents event, Emitter<AgentsState> emit) {
    emit(AgentsLoading());
    _agentsSubscription?.cancel();
    _agentsSubscription = _db.getAgentsStream().listen(
      (agents) => add(AgentsUpdated(agents)),
      onError: (e) => emit(AgentsError(e.toString())),
    );
  }

  void _onAgentsUpdated(AgentsUpdated event, Emitter<AgentsState> emit) {
    emit(AgentsLoaded(event.agents));
  }

  Future<void> _onAddAgent(AddAgent event, Emitter<AgentsState> emit) async {
    try {
      await _db.createAgentDocument(event.agent);
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _onDeactivateAgent(DeactivateAgent event, Emitter<AgentsState> emit) async {
    try {
      await _db.deactivateAgent(event.uid);
    } catch (e) {
      // Error handling
    }
  }

  @override
  Future<void> close() {
    _agentsSubscription?.cancel();
    return super.close();
  }
}
