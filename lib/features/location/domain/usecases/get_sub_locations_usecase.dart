import 'package:real_state/features/location/domain/repositories/sub_locations_repository.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

class GetSubLocationsUseCase {
  final SubLocationsRepository _repository;

  GetSubLocationsUseCase(this._repository);

  Future<List<SubLocation>> call(String areaId) {
    return _repository.fetchByArea(areaId);
  }
}
