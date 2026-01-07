import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/location/data/repositories/location_repository.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';

part 'manage_locations_state.dart';

class ManageLocationsCubit extends Cubit<ManageLocationsState> {
  ManageLocationsCubit(this._repo, this._auth, this._areas)
    : super(const ManageLocationsCheckingAccess());

  final LocationRepository _repo;
  final AuthRepositoryDomain _auth;
  final GetLocationAreasUseCase _areas;
  bool _canManage = false;

  Future<void> initialize() async {
    emit(const ManageLocationsCheckingAccess());
    final user = await _auth.userChanges.first;
    _canManage =
        user?.role == UserRole.owner ||
        user?.role == UserRole.broker;
    if (!_canManage) {
      emit(ManageLocationsAccessDenied(message: 'access_denied'.tr()));
      return;
    }
    await load(showSkeleton: true);
  }

  Future<void> load({bool showSkeleton = false}) async {
    if (!_canManage) return;
    if (showSkeleton) {
      emit(const ManageLocationsLoadInProgress());
    }
    try {
      final all = await _repo.fetchAll();
      _areas.prime(all);
      emit(ManageLocationsLoadSuccess(items: all));
    } catch (e) {
      emit(ManageLocationsFailure(message: mapErrorMessage(e)));
    }
  }

  Future<void> create({
    required String nameAr,
    required String nameEn,
    required XFile imageFile,
  }) async {
    if (!_canManage) return;
    final current = _dataState();
    emit(ManageLocationsActionInProgress(items: current.items));
    try {
      await _repo.create(nameAr: nameAr, nameEn: nameEn, imageFile: imageFile);
      _areas.invalidate();
      await load(showSkeleton: true);
    } catch (e) {
      emit(
        ManageLocationsPartialFailure(
          items: current.items,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  Future<void> update(
    LocationArea item, {
    required String nameAr,
    required String nameEn,
    XFile? imageFile,
  }) async {
    if (!_canManage) return;
    final current = _dataState();
    emit(ManageLocationsActionInProgress(items: current.items));
    try {
      await _repo.update(
        id: item.id,
        nameAr: nameAr,
        nameEn: nameEn,
        imageFile: imageFile,
        previousImageUrl: item.imageUrl,
      );
      _areas.invalidate();
      await load(showSkeleton: true);
    } catch (e) {
      emit(
        ManageLocationsPartialFailure(
          items: current.items,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  Future<void> delete(LocationArea item) async {
    if (!_canManage) return;
    final current = _dataState();
    emit(ManageLocationsActionInProgress(items: current.items));
    try {
      final can = await _repo.canDelete(item.id);
      if (!can) {
        emit(
          ManageLocationsPartialFailure(
            items: current.items,
            message: 'cannot_delete_location'.tr(),
          ),
        );
        return;
      }
      await _repo.delete(item.id);
      _areas.invalidate();
      await load(showSkeleton: true);
    } catch (e) {
      emit(
        ManageLocationsPartialFailure(
          items: current.items,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  _LocationsData _dataState() {
    if (state is ManageLocationsDataState) {
      final s = state as ManageLocationsDataState;
      return _LocationsData(s.items);
    }
    return const _LocationsData([]);
  }
}

class _LocationsData {
  const _LocationsData(this.items);
  final List<LocationArea> items;
}
