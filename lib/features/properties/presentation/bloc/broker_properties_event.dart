import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';

abstract class BrokerPropertiesEvent extends Equatable {
  const BrokerPropertiesEvent();

  @override
  List<Object?> get props => [];
}

class BrokerPropertiesStarted extends BrokerPropertiesEvent {
  final String brokerId;
  final PropertyFilter? filter;
  const BrokerPropertiesStarted({required this.brokerId, this.filter});

  @override
  List<Object?> get props => [brokerId, filter];
}

class BrokerPropertiesRefreshed extends BrokerPropertiesEvent {
  final String brokerId;
  final PropertyFilter? filter;
  const BrokerPropertiesRefreshed({required this.brokerId, this.filter});

  @override
  List<Object?> get props => [brokerId, filter];
}

class BrokerPropertiesLoadMore extends BrokerPropertiesEvent {
  final String brokerId;
  final DocumentSnapshot<Map<String, dynamic>>? startAfter;
  const BrokerPropertiesLoadMore({required this.brokerId, this.startAfter});

  @override
  List<Object?> get props => [brokerId, startAfter];
}

class BrokerPropertiesFilterChanged extends BrokerPropertiesEvent {
  final String brokerId;
  final PropertyFilter filter;
  const BrokerPropertiesFilterChanged({
    required this.brokerId,
    required this.filter,
  });

  @override
  List<Object?> get props => [brokerId, filter];
}
