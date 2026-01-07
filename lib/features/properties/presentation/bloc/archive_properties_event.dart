import 'package:equatable/equatable.dart';

abstract class ArchivePropertiesEvent extends Equatable {
  const ArchivePropertiesEvent();

  @override
  List<Object?> get props => [];
}

class ArchivePropertiesStarted extends ArchivePropertiesEvent {
  const ArchivePropertiesStarted();
}

class ArchivePropertiesRefreshed extends ArchivePropertiesEvent {
  const ArchivePropertiesRefreshed();
}

class ArchivePropertiesLoadMoreRequested extends ArchivePropertiesEvent {
  const ArchivePropertiesLoadMoreRequested();
}

class ArchivePropertiesRetryRequested extends ArchivePropertiesEvent {
  const ArchivePropertiesRetryRequested();
}

class ArchivePropertiesExternalMutationReceived extends ArchivePropertiesEvent {
  const ArchivePropertiesExternalMutationReceived();
}
