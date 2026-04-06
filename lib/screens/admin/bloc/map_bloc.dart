import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/order_model.dart';
import '../../../../models/user_model.dart';
import '../../../../services/database_service.dart';

// --- Events ---
abstract class MapEvent {}

class LoadMapData extends MapEvent {}

class RidersUpdated extends MapEvent {
  final List<UserModel> riders;
  RidersUpdated(this.riders);
}

class OrdersUpdated extends MapEvent {
  final List<OrderModel> orders;
  OrdersUpdated(this.orders);
}

// --- Status ---
enum MapStatus { initial, loading, loaded, error }

// --- State ---
class MapState {
  final MapStatus status;
  final List<UserModel> activeRiders;
  final List<OrderModel> activeOrders;
  final String? error;

  MapState({
    required this.status,
    required this.activeRiders,
    required this.activeOrders,
    this.error,
  });

  factory MapState.initial() => MapState(
        status: MapStatus.initial,
        activeRiders: [],
        activeOrders: [],
      );

  MapState copyWith({
    MapStatus? status,
    List<UserModel>? activeRiders,
    List<OrderModel>? activeOrders,
    String? error,
  }) {
    return MapState(
      status: status ?? this.status,
      activeRiders: activeRiders ?? this.activeRiders,
      activeOrders: activeOrders ?? this.activeOrders,
      error: error ?? this.error,
    );
  }
}

// --- Bloc ---
class MapBloc extends Bloc<MapEvent, MapState> {
  final DatabaseService _db = DatabaseService();
  StreamSubscription? _ridersSubscription;
  StreamSubscription? _ordersSubscription;

  MapBloc() : super(MapState.initial()) {
    on<LoadMapData>(_onLoadMapData);
    on<RidersUpdated>(_onRidersUpdated);
    on<OrdersUpdated>(_onOrdersUpdated);
  }

  void _onLoadMapData(LoadMapData event, Emitter<MapState> emit) {
    emit(state.copyWith(status: MapStatus.loading));

    _ridersSubscription?.cancel();
    _ridersSubscription = _db.getActiveRidersStream().listen(
          (riders) => add(RidersUpdated(riders)),
          onError: (e) => emit(state.copyWith(status: MapStatus.error, error: e.toString())),
        );

    _ordersSubscription?.cancel();
    _ordersSubscription = _db.getActiveOrdersStream().listen(
          (orders) => add(OrdersUpdated(orders)),
          onError: (e) => emit(state.copyWith(status: MapStatus.error, error: e.toString())),
        );
  }

  void _onRidersUpdated(RidersUpdated event, Emitter<MapState> emit) {
    emit(state.copyWith(
      status: MapStatus.loaded,
      activeRiders: event.riders,
    ));
  }

  void _onOrdersUpdated(OrdersUpdated event, Emitter<MapState> emit) {
    emit(state.copyWith(
      status: MapStatus.loaded,
      activeOrders: event.orders,
    ));
  }

  @override
  Future<void> close() {
    _ridersSubscription?.cancel();
    _ordersSubscription?.cancel();
    return super.close();
  }
}
