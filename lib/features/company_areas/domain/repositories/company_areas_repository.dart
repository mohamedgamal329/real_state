import '../entities/company_area_summary.dart';

abstract class CompanyAreasRepository {
  Future<List<AreaSummary>> fetchCompanyAreas();
}
