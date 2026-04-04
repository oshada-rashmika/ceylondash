import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../services/rider_service.dart';

// Events
abstract class RiderEvent {}

class ToggleAvailabilityStatus extends RiderEvent {
  final bool isAvailable;
  final String uid;

  ToggleAvailabilityStatus({required this.isAvailable, required this.uid});
}

class SetInitialAvailability extends RiderEvent {
  final bool isAvailable;
  SetInitialAvailability({required this.isAvailable});
}

// States
abstract class RiderState {
  final bool isAvailable;
  RiderState({required this.isAvailable});
}

class RiderInitial extends RiderState {
  RiderInitial({super.isAvailable = false});
}

class RiderStatusUpdating extends RiderState {
  RiderStatusUpdating({required super.isAvailable});
}

class RiderStatusUpdated extends RiderState {
  RiderStatusUpdated({required super.isAvailable});
}

class RiderStatusError extends RiderState {
  final String message;
  RiderStatusError({required super.isAvailable, required this.message});
}

// BLoC
class RiderBloc extends Bloc<RiderEvent, RiderState> {
  final RiderService _riderService;
  StreamSubscription<Position>? _locationSubscription;
  String? _uid;

  RiderBloc({required RiderService riderService})
      : _riderService = riderService,
        super(RiderInitial()) {
    on<ToggleAvailabilityStatus>(_onToggleAvailabilityStatus);
    on<SetInitialAvailability>(_onSetInitialAvailability);
  }

  void _onSetInitialAvailability(
      SetInitialAvailability event, Emitter<RiderState> emit) {
    if (state is RiderInitial) {
      emit(RiderStatusUpdated(isAvailable: event.isAvailable));
    }
  }

  Future<void> _onToggleAvailabilityStatus(
      ToggleAvailabilityStatus event, Emitter<RiderState> emit) async {
    _uid = event.uid;
    // Optimistically update
    emit(RiderStatusUpdating(isAvailable: event.isAvailable));

    try {
      if (event.isAvailable) {
        bool hasPermission = await _riderService.requestLocationPermission();
        if (!hasPermission) {
          emit(RiderStatusError(
              message: "Location permission denied", isAvailable: false));
          return;
        }

        await _riderService.updateRiderAvailability(event.uid, true);

        await _locationSubscription?.cancel();
        _locationSubscription = _riderService.getPositionStream().listen((position) {
          if (_uid != null) {
            _riderService.updateRiderLocation(_uid!, position);
          }
        });

        emit(RiderStatusUpdated(isAvailable: true));
      } else {
        await _locationSubscription?.cancel();
        _locationSubscription = null;
        
        await _riderService.updateRiderAvailability(event.uid, false);
        emit(RiderStatusUpdated(isAvailable: false));
      }
    } catch (e) {
      emit(RiderStatusError(
          message: e.toString(), isAvailable: !event.isAvailable));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
