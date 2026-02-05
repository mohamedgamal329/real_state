import 'package:real_state/features/models/entities/sub_location.dart';

abstract class SubLocationsRepository {
  Future<List<SubLocation>> fetchByArea(String areaId);
}
