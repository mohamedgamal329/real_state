import 'package:equatable/equatable.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

abstract class SubLocationsState extends Equatable {
  const SubLocationsState();

  @override
  List<Object?> get props => [];
}

class SubLocationsInitial extends SubLocationsState {
  const SubLocationsInitial();
}

class SubLocationsLoadInProgress extends SubLocationsState {
  final List<SubLocation> items;
  const SubLocationsLoadInProgress([this.items = const []]);

  @override
  List<Object?> get props => [items];
}

class SubLocationsLoadSuccess extends SubLocationsState {
  final List<SubLocation> items;
  const SubLocationsLoadSuccess(this.items);

  @override
  List<Object?> get props => [items];
}

class SubLocationsFailure extends SubLocationsState {
  final String message;
  const SubLocationsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
