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
  final Map<int, int> trends;

  AnalyticsLoaded({
    required this.totalOrders,
    required this.activeUsers,
    required this.activeRiders,
    required this.totalRevenue,
    required this.trends,
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

  Future<void> _onLoadAnalytics(
      LoadAnalytics event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    try {
      final results = await Future.wait([
        _db.getTotalOrdersCount(),
        _db.getActiveUsersCount(),
        _db.getActiveRidersCount(),
        _db.getTotalRevenue(),
        _db.getOrderTrendsData(),
      ]);

      emit(AnalyticsLoaded(
        totalOrders: results[0] as int,
        activeUsers: results[1] as int,
        activeRiders: results[2] as int,
        totalRevenue: results[3] as double,
        trends: results[4] as Map<int, int>,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }
}
