import '../entities/company_area_summary.dart';
import '../repositories/company_areas_repository.dart';

class GetCompanyAreasUseCase {
  final CompanyAreasRepository _repository;

  GetCompanyAreasUseCase(this._repository);

  Future<List<AreaSummary>> call() {
    return _repository.fetchCompanyAreas();
  }
}
