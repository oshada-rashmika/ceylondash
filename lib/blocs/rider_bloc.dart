import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../services/rider_service.dart';
import '../models/order_model.dart';

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

class PendingJobsUpdated extends RiderEvent {
  final List<OrderModel> jobs;
  PendingJobsUpdated(this.jobs);
}

class ActiveRouteJobsUpdated extends RiderEvent {
  final List<OrderModel> jobs;
  ActiveRouteJobsUpdated(this.jobs);
}

class ClaimJobEvent extends RiderEvent {
  final String orderId;
  final String riderUid;
  ClaimJobEvent({required this.orderId, required this.riderUid});
}

// States
abstract class RiderState {
  final bool isAvailable;
  final List<OrderModel> pendingJobs;
  final List<OrderModel> activeRouteJobs;
  RiderState({required this.isAvailable, this.pendingJobs = const [], this.activeRouteJobs = const []});
}

class RiderInitial extends RiderState {
  RiderInitial({super.isAvailable = false, super.pendingJobs = const [], super.activeRouteJobs = const []});
}

class RiderStatusUpdating extends RiderState {
  RiderStatusUpdating({required super.isAvailable, super.pendingJobs = const [], super.activeRouteJobs = const []});
}

class RiderStatusUpdated extends RiderState {
  RiderStatusUpdated({required super.isAvailable, super.pendingJobs = const [], super.activeRouteJobs = const []});
}

class RiderStatusError extends RiderState {
  final String message;
  RiderStatusError({required super.isAvailable, super.pendingJobs = const [], super.activeRouteJobs = const [], required this.message});
}

// BLoC
class RiderBloc extends Bloc<RiderEvent, RiderState> {
  final RiderService _riderService;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<OrderModel>>? _jobsSubscription;
  StreamSubscription<List<OrderModel>>? _activeRouteSubscription;
  String? _uid;

  RiderBloc({required RiderService riderService})
      : _riderService = riderService,
        super(RiderInitial()) {
    on<ToggleAvailabilityStatus>(_onToggleAvailabilityStatus);
    on<SetInitialAvailability>(_onSetInitialAvailability);
    on<PendingJobsUpdated>(_onPendingJobsUpdated);
    on<ActiveRouteJobsUpdated>(_onActiveRouteJobsUpdated);
    on<ClaimJobEvent>(_onClaimJob);
  }

  void _onPendingJobsUpdated(PendingJobsUpdated event, Emitter<RiderState> emit) {
    emit(RiderStatusUpdated(isAvailable: state.isAvailable, pendingJobs: event.jobs, activeRouteJobs: state.activeRouteJobs));
  }

  void _onActiveRouteJobsUpdated(ActiveRouteJobsUpdated event, Emitter<RiderState> emit) {
    emit(RiderStatusUpdated(isAvailable: state.isAvailable, pendingJobs: state.pendingJobs, activeRouteJobs: event.jobs));
  }

  Future<void> _onClaimJob(ClaimJobEvent event, Emitter<RiderState> emit) async {
    try {
      await _riderService.claimJob(event.orderId, event.riderUid);
    } catch (_) {}
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

        await _jobsSubscription?.cancel();
        _jobsSubscription = _riderService.getPendingJobsStream().listen((jobs) {
          add(PendingJobsUpdated(jobs));
        });

        await _activeRouteSubscription?.cancel();
        _activeRouteSubscription = _riderService.getMyActiveRouteStream(_uid!).listen((jobs) {
          add(ActiveRouteJobsUpdated(jobs));
        });

        emit(RiderStatusUpdated(isAvailable: true, pendingJobs: state.pendingJobs, activeRouteJobs: state.activeRouteJobs));
      } else {
        await _locationSubscription?.cancel();
        _locationSubscription = null;
        
        await _jobsSubscription?.cancel();
        _jobsSubscription = null;

        await _activeRouteSubscription?.cancel();
        _activeRouteSubscription = null;
        
        await _riderService.updateRiderAvailability(event.uid, false);
        emit(RiderStatusUpdated(isAvailable: false, pendingJobs: const [], activeRouteJobs: const []));
      }
    } catch (e) {
      emit(RiderStatusError(
          message: e.toString(), isAvailable: !event.isAvailable));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _jobsSubscription?.cancel();
    _activeRouteSubscription?.cancel();
    return super.close();
  }
}
