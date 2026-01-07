import 'package:equatable/equatable.dart';

abstract class BrokersListEvent extends Equatable {
  const BrokersListEvent();

  @override
  List<Object?> get props => [];
}

class BrokersListRequested extends BrokersListEvent {
  const BrokersListRequested();
}

class BrokersListRefreshed extends BrokersListEvent {
  const BrokersListRefreshed();
}
