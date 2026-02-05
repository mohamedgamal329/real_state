import 'package:bloc/bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/location/domain/usecases/get_sub_locations_usecase.dart';
import 'package:real_state/features/location/presentation/cubit/sub_locations_state.dart';

class SubLocationsCubit extends Cubit<SubLocationsState> {
  final GetSubLocationsUseCase _useCase;

  SubLocationsCubit(this._useCase) : super(const SubLocationsInitial());

  Future<void> load(String areaId) async {
    emit(const SubLocationsLoadInProgress());
    try {
      final items = await _useCase(areaId);
      emit(SubLocationsLoadSuccess(items));
    } catch (e, st) {
      emit(SubLocationsFailure(mapErrorMessage(e, stackTrace: st)));
    }
  }
}
