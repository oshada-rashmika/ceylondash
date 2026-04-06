import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/database_service.dart';
import '../../../utils/fraud_detection_engine.dart';
import 'red_flags_event.dart';
import 'red_flags_state.dart';

class RedFlagsBloc extends Bloc<RedFlagsEvent, RedFlagsState> {
  final DatabaseService _db = DatabaseService();

  RedFlagsBloc() : super(RedFlagsInitial()) {
    on<FetchRedFlags>((event, emit) async {
      emit(RedFlagsLoading());
      try {
        final duration = const Duration(days: 7);
        final orders = await _db.getRecentOrders(duration);
        final reports = await _db.getRecentReports(duration);

        final flags = FraudDetectionEngine.detectAnomalies(orders, reports);

        emit(RedFlagsLoaded(
          flags: flags,
          totalOrdersAnalyzed: orders.length,
          totalReportsAnalyzed: reports.length,
        ));
      } catch (e) {
        emit(RedFlagsError(e.toString()));
      }
    });
  }
}
