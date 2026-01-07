import 'package:equatable/equatable.dart';

abstract class BrokerAreasEvent extends Equatable {
  const BrokerAreasEvent();

  @override
  List<Object?> get props => [];
}

class BrokerAreasRequested extends BrokerAreasEvent {
  final String brokerId;
  const BrokerAreasRequested(this.brokerId);

  @override
  List<Object?> get props => [brokerId];
}
