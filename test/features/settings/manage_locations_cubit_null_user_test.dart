import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_state/features/location/domain/repositories/location_repository.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/location/domain/location_areas_cache.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_locations_cubit.dart';

import '../fake_auth_repo/fake_auth_repo.dart';

class _FakeLocationRepo implements LocationRepository {
  @override
  Future<bool> canDelete(String id) async => true;

  @override
  Future<String> create({
    required String nameAr,
    required String nameEn,
    required XFile imageFile,
  }) async {
    return 'id';
  }

  @override
  Future<void> delete(String id) async {
    return;
  }

  @override
  Future<List<LocationArea>> fetchAll() async => const [];

  @override
  Future<void> update({
    required String id,
    required String nameAr,
    required String nameEn,
    XFile? imageFile,
    String? previousImageUrl,
  }) async {
    return;
  }
}

void main() {
  test(
    'initialize emits AccessDenied when user is null (no hanging loading)',
    () async {
      final repo = _FakeLocationRepo();
      final areasRepo = _FakeLocationAreasRepo();
      final cache = LocationAreasCache(repo, areasRepo);
      final cubit = ManageLocationsCubit(
        repo,
        FakeAuthRepo(null),
        GetLocationAreasUseCase(cache),
      );
      addTearDown(cubit.close);

      await cubit.initialize();
      expect(cubit.state, isA<ManageLocationsAccessDenied>());
    },
  );
}

class _FakeLocationAreasRepo implements LocationAreasRepository {
  @override
  Future<Map<String, LocationArea>> fetchAll() async => const {};

  @override
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) async =>
      const {};
}
