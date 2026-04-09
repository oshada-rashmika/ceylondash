import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_navigation_event.dart';
import 'admin_navigation_state.dart';

class AdminNavigationBloc extends Bloc<AdminNavigationEvent, AdminNavigationState> {
  AdminNavigationBloc() : super(AdminNavigationState.initial()) {
    on<TabChanged>((event, emit) {
      emit(AdminNavigationState(tabIndex: event.tabIndex));
    });
  }
}
