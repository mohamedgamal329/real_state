import 'package:equatable/equatable.dart';

import '../../domain/entities/company_area_summary.dart';

abstract class CompanyAreasState extends Equatable {
  const CompanyAreasState();

  @override
  List<Object?> get props => [];
}

class CompanyAreasInitial extends CompanyAreasState {
  const CompanyAreasInitial();
}

class CompanyAreasLoadInProgress extends CompanyAreasState {
  final List<AreaSummary> areas;
  const CompanyAreasLoadInProgress([this.areas = const []]);

  @override
  List<Object?> get props => [areas];
}

class CompanyAreasLoadSuccess extends CompanyAreasState {
  final List<AreaSummary> areas;
  const CompanyAreasLoadSuccess(this.areas);

  @override
  List<Object?> get props => [areas];
}

class CompanyAreasFailure extends CompanyAreasState {
  final String message;
  const CompanyAreasFailure(this.message);

  @override
  List<Object?> get props => [message];
}
