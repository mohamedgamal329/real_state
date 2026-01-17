import 'package:equatable/equatable.dart';
import 'package:real_state/features/brokers/domain/entities/broker_area.dart';
import 'package:real_state/features/models/entities/location_area.dart';

abstract class BrokerAreasState extends Equatable {
  const BrokerAreasState();

  @override
  List<Object?> get props => [];
}

class BrokerAreasInitial extends BrokerAreasState {
  const BrokerAreasInitial();
}

class BrokerAreasLoadInProgress extends BrokerAreasState {
  final String brokerId;
  const BrokerAreasLoadInProgress(this.brokerId);

  @override
  List<Object?> get props => [brokerId];
}

class BrokerAreasLoadSuccess extends BrokerAreasState {
  final String brokerId;
  final List<BrokerArea> areas;
  final Map<String, LocationArea> areaDetails;

  const BrokerAreasLoadSuccess({
    required this.brokerId,
    required this.areas,
    required this.areaDetails,
  });

  @override
  List<Object?> get props => [brokerId, areas, areaDetails];
}

class BrokerAreasFailure extends BrokerAreasState {
  final String brokerId;
  final String message;

  const BrokerAreasFailure({required this.brokerId, required this.message});

  @override
  List<Object?> get props => [brokerId, message];
}
