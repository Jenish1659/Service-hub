import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocationFlowStatus {
  permission,
  detecting,
  selecting,
  confirming,
  saving,
  completed,
  error,
}

class LocationFlowState {
  final LocationFlowStatus status;
  final String? message;

  const LocationFlowState({
    this.status = LocationFlowStatus.permission,
    this.message,
  });

  LocationFlowState copyWith({
    LocationFlowStatus? status,
    String? message,
  }) {
    return LocationFlowState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class LocationFlowController extends StateNotifier<LocationFlowState> {
  LocationFlowController() : super(const LocationFlowState());

  void setStatus(LocationFlowStatus status, {String? message}) {
    state = state.copyWith(status: status, message: message);
  }
}
