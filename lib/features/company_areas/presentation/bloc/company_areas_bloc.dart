import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';

import '../../domain/entities/company_area_summary.dart';
import '../../domain/usecases/get_company_areas_usecase.dart';
import 'company_areas_event.dart';
import 'company_areas_state.dart';

class CompanyAreasBloc extends Bloc<CompanyAreasEvent, CompanyAreasState> {
  final GetCompanyAreasUseCase _useCase;
  final PropertyMutationsStream _mutations;
  late final StreamSubscription<PropertyMutation> _mutationSub;

  CompanyAreasBloc(this._useCase, this._mutations)
    : super(const CompanyAreasInitial()) {
    on<CompanyAreasRequested>(_onRequested);

    _mutationSub = _mutations.mutationStream.listen((event) {
      if (event.ownerScope == null ||
          event.ownerScope == PropertyOwnerScope.company) {
        add(const CompanyAreasRequested());
      }
    });
  }

  Future<void> _onRequested(
    CompanyAreasRequested event,
    Emitter<CompanyAreasState> emit,
  ) async {
    final currentAreas = state is CompanyAreasLoadSuccess
        ? (state as CompanyAreasLoadSuccess).areas
        : (state is CompanyAreasLoadInProgress
              ? (state as CompanyAreasLoadInProgress).areas
              : const <AreaSummary>[]);
    emit(CompanyAreasLoadInProgress(currentAreas));
    try {
      final areas = await _useCase.call();
      emit(CompanyAreasLoadSuccess(areas));
    } catch (e, st) {
      emit(CompanyAreasFailure(mapErrorMessage(e, stackTrace: st)));
    }
  }

  @override
  Future<void> close() async {
    await _mutationSub.cancel();
    return super.close();
  }
}
