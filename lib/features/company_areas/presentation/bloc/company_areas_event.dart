import 'package:equatable/equatable.dart';

abstract class CompanyAreasEvent extends Equatable {
  const CompanyAreasEvent();

  @override
  List<Object?> get props => [];
}

class CompanyAreasRequested extends CompanyAreasEvent {
  const CompanyAreasRequested();
}
