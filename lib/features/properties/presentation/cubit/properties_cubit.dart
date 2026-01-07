import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';
import 'package:real_state/core/constants/ui_constants.dart';

import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertiesRepository _repo;
  final LocationAreaRemoteDataSource _areaDs;
  final PropertyMutationsBloc _mutations;
  late final StreamSubscription<PropertyMutation> _mutationSub;

  PropertiesCubit(this._repo, this._areaDs, this._mutations)
    : super(const PropertiesInitial()) {
    _mutationSub = _mutations.mutationStream.listen((_) {
      unawaited(refresh());
    });
  }

  Future<void> loadFirstPage() async {
    emit(const PropertiesLoadInProgress());
    try {
      final page = await _repo.fetchPage(
        limit: UiConstants.propertiesPageLimit,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      emit(
        PropertiesLoadSuccess(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
        ),
      );
    } catch (e) {
      emit(PropertiesFailure(mapErrorMessage(e)));
    }
  }

  Future<void> refresh() async {
    final current = _asDataState(state);
    emit(
      PropertiesRefreshing(
        items: current?.items ?? const [],
        lastDoc: current?.lastDoc,
        hasMore: current?.hasMore ?? true,
        areaNames: current?.areaNames ?? const {},
      ),
    );
    try {
      final page = await _repo.fetchPage(
        limit: UiConstants.propertiesPageLimit,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      emit(
        PropertiesLoadSuccess(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
        ),
      );
    } catch (e) {
      final previous = _asDataState(state);
      if (previous != null) {
        emit(
          PropertiesPartialFailure(
            message: mapErrorMessage(e),
            items: previous.items,
            lastDoc: previous.lastDoc,
            hasMore: previous.hasMore,
            areaNames: previous.areaNames,
          ),
        );
      } else {
        emit(PropertiesFailure(mapErrorMessage(e)));
      }
    }
  }

  Future<void> loadMore() async {
    final current = _asDataState(state);
    if (current == null ||
        !current.hasMore ||
        state is PropertiesLoadMoreInProgress)
      return;
    emit(
      PropertiesLoadMoreInProgress(
        items: current.items,
        lastDoc: current.lastDoc,
        hasMore: current.hasMore,
        areaNames: current.areaNames,
      ),
    );
    try {
      final page = await _repo.fetchPage(
        startAfter: current.lastDoc,
        limit: UiConstants.propertiesPageLimit,
      );
      final items = List<Property>.from(current.items)..addAll(page.items);
      final areaNames = Map<String, LocationArea>.from(current.areaNames)
        ..addAll(await _fetchAreaNamesFor(page.items));
      emit(
        PropertiesLoadSuccess(
          items: items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
        ),
      );
    } catch (e) {
      emit(
        PropertiesPartialFailure(
          message: mapErrorMessage(e),
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          areaNames: current.areaNames,
        ),
      );
    }
  }

  Future<Map<String, LocationArea>> _fetchAreaNamesFor(
    List<Property> props,
  ) async {
    final ids = props
        .where((p) => p.locationAreaId != null)
        .map((p) => p.locationAreaId!)
        .toSet()
        .toList();
    if (ids.isEmpty) return {};
    try {
      final res = await _areaDs.fetchNamesByIds(ids);
      return res;
    } catch (_) {
      return {};
    }
  }

  PropertiesDataState? _asDataState(PropertiesState state) {
    if (state is PropertiesDataState) return state;
    return null;
  }

  @override
  Future<void> close() async {
    await _mutationSub.cancel();
    return super.close();
  }
}
