import 'package:flutter_bloc/flutter_bloc.dart';
import 'global_alert_event.dart';
import 'global_alert_state.dart';

class GlobalAlertBloc extends Bloc<GlobalAlertEvent, GlobalAlertState> {
  GlobalAlertBloc() : super(GlobalAlertInitial()) {
    on<ShowNetworkFailure>((event, emit) {
      emit(GlobalAlertNetworkError(
        isTimeout: event.isTimeout,
        timestamp: event.timestamp,
      ));
    });
  }
}
