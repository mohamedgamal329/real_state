import 'package:equatable/equatable.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';

abstract class CompanyPropertiesEvent extends Equatable {
  const CompanyPropertiesEvent();

  @override
  List<Object?> get props => [];
}

class CompanyPropertiesStarted extends CompanyPropertiesEvent {
  final PropertyFilter? filter;
  const CompanyPropertiesStarted({this.filter});

  @override
  List<Object?> get props => [filter];
}

class CompanyPropertiesRefreshed extends CompanyPropertiesEvent {
  final PropertyFilter? filter;
  const CompanyPropertiesRefreshed({this.filter});

  @override
  List<Object?> get props => [filter];
}

class CompanyPropertiesLoadMore extends CompanyPropertiesEvent {
  final PageToken? startAfter;
  const CompanyPropertiesLoadMore({this.startAfter});

  @override
  List<Object?> get props => [startAfter];
}

class CompanyPropertiesFilterChanged extends CompanyPropertiesEvent {
  final PropertyFilter filter;
  const CompanyPropertiesFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}
