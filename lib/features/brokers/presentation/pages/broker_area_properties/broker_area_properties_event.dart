import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';

abstract class BrokerAreaPropertiesEvent extends Equatable {
  const BrokerAreaPropertiesEvent();

  @override
  List<Object?> get props => [];
}

class BrokerAreaPropertiesStarted extends BrokerAreaPropertiesEvent {
  final String brokerId;
  final String areaId;
  final PropertyFilter? filter;

  const BrokerAreaPropertiesStarted({
    required this.brokerId,
    required this.areaId,
    this.filter,
  });

  @override
  List<Object?> get props => [brokerId, areaId, filter];
}

class BrokerAreaPropertiesRefreshed extends BrokerAreaPropertiesEvent {
  final String brokerId;
  final String areaId;
  final PropertyFilter? filter;

  const BrokerAreaPropertiesRefreshed({
    required this.brokerId,
    required this.areaId,
    this.filter,
  });

  @override
  List<Object?> get props => [brokerId, areaId, filter];
}

class BrokerAreaPropertiesLoadMore extends BrokerAreaPropertiesEvent {
  const BrokerAreaPropertiesLoadMore();
}

class BrokerAreaPropertiesFilterChanged extends BrokerAreaPropertiesEvent {
  final PropertyFilter filter;
  const BrokerAreaPropertiesFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}
