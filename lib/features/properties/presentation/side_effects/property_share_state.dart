import 'package:equatable/equatable.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';

sealed class PropertyShareState extends Equatable {
  const PropertyShareState();

  @override
  List<Object?> get props => [];
}

class PropertyShareIdle extends PropertyShareState {
  const PropertyShareIdle();
}

class PropertyShareInProgress extends PropertyShareState {
  final PropertyShareProgress progress;

  const PropertyShareInProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class PropertyShareSuccess extends PropertyShareState {
  const PropertyShareSuccess();
}

class PropertyShareFailure extends PropertyShareState {
  final String errorMessage;

  const PropertyShareFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
