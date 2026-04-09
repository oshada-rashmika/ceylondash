import 'package:equatable/equatable.dart';
import '../../../utils/fraud_detection_engine.dart';

abstract class RedFlagsEvent extends Equatable {
  const RedFlagsEvent();

  @override
  List<Object?> get props => [];
}

class FetchRedFlags extends RedFlagsEvent {}
