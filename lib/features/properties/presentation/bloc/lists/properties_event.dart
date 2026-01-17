import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';

abstract class PropertiesEvent extends Equatable {
  const PropertiesEvent();

  @override
  List<Object?> get props => [];
}

class PropertiesStarted extends PropertiesEvent {
  final PropertyFilter? filter;
  const PropertiesStarted({this.filter});

  @override
  List<Object?> get props => [filter];
}

class PropertiesRefreshed extends PropertiesEvent {
  final PropertyFilter? filter;
  const PropertiesRefreshed({this.filter});

  @override
  List<Object?> get props => [filter];
}

class PropertiesLoadMoreRequested extends PropertiesEvent {
  const PropertiesLoadMoreRequested();
}

class PropertiesExternalMutationReceived extends PropertiesEvent {
  const PropertiesExternalMutationReceived();
}

class PropertiesRetryRequested extends PropertiesEvent {
  const PropertiesRetryRequested();
}
