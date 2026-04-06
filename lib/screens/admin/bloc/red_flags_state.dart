import 'package:equatable/equatable.dart';
import '../../../utils/fraud_detection_engine.dart';

abstract class RedFlagsState extends Equatable {
  const RedFlagsState();

  @override
  List<Object?> get props => [];
}

class RedFlagsInitial extends RedFlagsState {}

class RedFlagsLoading extends RedFlagsState {}

class RedFlagsLoaded extends RedFlagsState {
  final List<RedFlag> flags;
  final int totalOrdersAnalyzed;
  final int totalReportsAnalyzed;

  const RedFlagsLoaded({
    required this.flags,
    required this.totalOrdersAnalyzed,
    required this.totalReportsAnalyzed,
  });

  @override
  List<Object?> get props => [flags, totalOrdersAnalyzed, totalReportsAnalyzed];
}

class RedFlagsError extends RedFlagsState {
  final String message;
  const RedFlagsError(this.message);

  @override
  List<Object?> get props => [message];
}
