import 'package:equatable/equatable.dart';

abstract class AccessRequestActionState extends Equatable {
  const AccessRequestActionState();

  @override
  List<Object?> get props => [];
}

class AccessRequestActionInitial extends AccessRequestActionState {
  const AccessRequestActionInitial();
}

class AccessRequestActionInProgress extends AccessRequestActionState {
  const AccessRequestActionInProgress();
}

class AccessRequestActionSuccess extends AccessRequestActionState {
  const AccessRequestActionSuccess();
}

class AccessRequestActionFailure extends AccessRequestActionState {
  final String message;
  const AccessRequestActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
