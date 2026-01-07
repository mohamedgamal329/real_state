import 'package:equatable/equatable.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';

abstract class BrokersListState extends Equatable {
  const BrokersListState();

  @override
  List<Object?> get props => [];
}

class BrokersListInitial extends BrokersListState {
  const BrokersListInitial();
}

class BrokersListLoadInProgress extends BrokersListState {
  final List<Broker> brokers;
  const BrokersListLoadInProgress([this.brokers = const []]);

  @override
  List<Object?> get props => [brokers];
}

class BrokersListLoadSuccess extends BrokersListState {
  final List<Broker> brokers;
  const BrokersListLoadSuccess(this.brokers);

  @override
  List<Object?> get props => [brokers];
}

class BrokersListFailure extends BrokersListState {
  final String message;
  const BrokersListFailure(this.message);

  @override
  List<Object?> get props => [message];
}
