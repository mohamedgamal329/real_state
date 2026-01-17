import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/company_areas/presentation/pages/company_area_properties/company_properties_bloc.dart';
import 'package:real_state/features/company_areas/presentation/pages/company_area_properties/company_properties_event.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';
import 'package:real_state/features/properties/domain/usecases/get_company_properties_page_usecase.dart';

class CompanyAreaPropertiesController {
  final GetCompanyPropertiesPageUseCase _getCompanyPage;
  final LocationAreasRepository _locationAreasRepository;
  final PropertyMutationsStream _mutations;

  CompanyAreaPropertiesController(
    this._getCompanyPage,
    this._locationAreasRepository,
    this._mutations,
  );

  CompanyPropertiesBloc createBloc({required PropertyFilter filter}) {
    return CompanyPropertiesBloc(
      _getCompanyPage,
      _locationAreasRepository,
      _mutations,
    )..add(CompanyPropertiesStarted(filter: filter));
  }
}
