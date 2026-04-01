import 'package:equatable/equatable.dart';

abstract class GlobalAlertState extends Equatable {
  const GlobalAlertState();
  
  @override
  List<Object?> get props => [];
}

class GlobalAlertInitial extends GlobalAlertState {}

class GlobalAlertNetworkError extends GlobalAlertState {
  final bool isTimeout;
  final DateTime timestamp;

  const GlobalAlertNetworkError({
    required this.isTimeout,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [isTimeout, timestamp];
}
