import 'package:equatable/equatable.dart';

abstract class GlobalAlertEvent extends Equatable {
  const GlobalAlertEvent();

  @override
  List<Object?> get props => [];
}

class ShowNetworkFailure extends GlobalAlertEvent {
  final bool isTimeout;
  final DateTime timestamp;

  ShowNetworkFailure({required this.isTimeout}) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [isTimeout, timestamp];
}
