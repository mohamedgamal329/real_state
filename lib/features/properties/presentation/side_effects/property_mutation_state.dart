import 'package:equatable/equatable.dart';

enum PropertyMutationAction { archive, delete, restore }

sealed class PropertyMutationState extends Equatable {
  final PropertyMutationAction? action;
  const PropertyMutationState([this.action]);

  @override
  List<Object?> get props => [action];
}

class PropertyMutationIdle extends PropertyMutationState {
  const PropertyMutationIdle();
}

class PropertyMutationInProgress extends PropertyMutationState {
  const PropertyMutationInProgress(PropertyMutationAction action)
    : super(action);
}

class PropertyMutationSuccess extends PropertyMutationState {
  const PropertyMutationSuccess(PropertyMutationAction action) : super(action);
}

class PropertyMutationFailure extends PropertyMutationState {
  final String errorMessage;

  const PropertyMutationFailure(
    PropertyMutationAction action,
    this.errorMessage,
  ) : super(action);

  @override
  List<Object?> get props => [action, errorMessage];
}
