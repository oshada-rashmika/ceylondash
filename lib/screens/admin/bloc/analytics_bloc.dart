import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/database_service.dart';

// --- Events ---
abstract class AnalyticsEvent {}
class LoadAnalytics extends AnalyticsEvent {}

// --- States ---
abstract class AnalyticsState {}
class AnalyticsLoading extends AnalyticsState {}
class AnalyticsLoaded extends AnalyticsState {
  final int totalOrders;
  final int activeUsers;
  final int activeRiders;
  final double totalRevenue;

  AnalyticsLoaded({
    required this.totalOrders,
    required this.activeUsers,
    required this.activeRiders,
    required this.totalRevenue,
  });
}
class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
}

// --- Bloc ---
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final DatabaseService _db = DatabaseService();

  AnalyticsBloc() : super(AnalyticsLoading()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(LoadAnalytics event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    try {
      final totalOrders = await _db.getTotalOrdersCount();
      final activeUsers = await _db.getActiveUsersCount();
      final activeRiders = await _db.getActiveRidersCount();
      final totalRevenue = await _db.getTotalRevenue();
      
      emit(AnalyticsLoaded(
        totalOrders: totalOrders,
        activeUsers: activeUsers,
        activeRiders: activeRiders,
        totalRevenue: totalRevenue,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
