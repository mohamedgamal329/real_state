import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';

abstract class ArchivePropertiesEvent extends Equatable {
  const ArchivePropertiesEvent();

  @override
  List<Object?> get props => [];
}

class ArchivePropertiesStarted extends ArchivePropertiesEvent {
  final PropertyFilter filter;

  const ArchivePropertiesStarted({this.filter = const PropertyFilter()});

  @override
  List<Object?> get props => [filter];
}

class ArchivePropertiesRefreshed extends ArchivePropertiesEvent {
  final PropertyFilter? filter;

  const ArchivePropertiesRefreshed({this.filter});

  @override
  List<Object?> get props => [filter];
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
