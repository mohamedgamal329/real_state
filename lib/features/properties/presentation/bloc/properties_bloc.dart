import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/single_flight_guard.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/properties_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final PropertiesRepository _repo;
  final LocationAreaRemoteDataSource _areaDs;
  final PropertyMutationsBloc _mutations;
  StreamSubscription<PropertyMutation>? _mutationSub;
  final SingleFlightGuard _requestGuard = SingleFlightGuard();
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  PropertyFilter? _currentFilter;

  PropertiesBloc(this._repo, this._areaDs, this._mutations)
    : super(const PropertiesInitial()) {
    on<PropertiesStarted>(_onStarted);
    on<PropertiesRefreshed>(_onRefreshed);
    on<PropertiesLoadMoreRequested>(_onLoadMore);
    on<PropertiesExternalMutationReceived>(_onExternalMutation);
    on<PropertiesRetryRequested>(_onRetry);

    _mutationSub = _mutations.mutationStream.listen((_) {
      add(const PropertiesExternalMutationReceived());
    });
  }

  Future<void> _onStarted(
    PropertiesStarted event,
    Emitter<PropertiesState> emit,
  ) async {
    _currentFilter = event.filter;
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        emit(PropertiesLoading(filter: _currentFilter));
        await _loadPage(emit, filter: _currentFilter);
      },
    );
  }

  Future<void> _onRefreshed(
    PropertiesRefreshed event,
    Emitter<PropertiesState> emit,
  ) async {
    _currentFilter = event.filter ?? _currentFilter;
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        final current = _asLoaded(state);
        if (current == null) {
          emit(PropertiesLoading(filter: _currentFilter));
          await _loadPage(emit, filter: _currentFilter);
          return;
        }
        emit(PropertiesActionInProgress(current));
        await _loadPage(emit, filter: _currentFilter, previous: current);
      },
    );
  }

  Future<void> _onExternalMutation(
    PropertiesExternalMutationReceived event,
    Emitter<PropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        final current = _asLoaded(state);
        if (current == null) return;
        emit(PropertiesActionInProgress(current));
        await _loadPage(emit, filter: _currentFilter, previous: current);
      },
    );
  }

  Future<void> _onRetry(
    PropertiesRetryRequested event,
    Emitter<PropertiesState> emit,
  ) async {
    if (state is PropertiesLoaded) {
      add(const PropertiesRefreshed());
    } else {
      add(PropertiesStarted(filter: _currentFilter));
    }
  }

  Future<void> _onLoadMore(
    PropertiesLoadMoreRequested event,
    Emitter<PropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: false,
      job: () async {
        final current = _asLoaded(state);
        if (current == null ||
            !current.hasMore ||
            state is PropertiesActionInProgress) {
          return;
        }
        try {
          final page = await _repo.fetchPage(
            startAfter: current.lastDoc,
            limit: UiConstants.propertiesPageLimit,
            filter: _currentFilter,
          );
          final items = List<Property>.from(current.items)..addAll(page.items);
          final areaNames = Map<String, LocationArea>.from(current.areaNames)
            ..addAll(await _fetchAreaNamesFor(page.items));
          emit(
            PropertiesLoaded(
              items: items,
              lastDoc: page.lastDocument,
              hasMore: page.hasMore,
              areaNames: areaNames,
              filter: _currentFilter,
            ),
          );
        } catch (e, st) {
          emit(
            PropertiesActionFailure(
              current,
              mapErrorMessage(e, stackTrace: st),
            ),
          );
        }
      },
    );
  }

  Future<void> _loadPage(
    Emitter<PropertiesState> emit, {
    PropertyFilter? filter,
    PropertiesLoaded? previous,
  }) async {
    try {
      final page = await _repo.fetchPage(
        limit: UiConstants.propertiesPageLimit,
        filter: filter,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      if (previous != null) {
        emit(PropertiesActionSuccess(previous));
      }
      emit(
        PropertiesLoaded(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
          filter: filter,
        ),
      );
    } catch (e, st) {
      if (previous != null) {
        emit(
          PropertiesActionFailure(previous, mapErrorMessage(e, stackTrace: st)),
        );
      } else {
        emit(
          PropertiesFailure(mapErrorMessage(e, stackTrace: st), filter: filter),
        );
      }
    }
  }

  Future<bool> _runGuardedRequest({
    required bool isRefresh,
    required Future<void> Function() job,
  }) async {
    if (isRefresh && _isLoadingMore) return false;
    if (!isRefresh && _isRefreshing) return false;
    return _requestGuard.run(() async {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoadingMore = true;
      }
      try {
        await job();
      } finally {
        if (isRefresh) {
          _isRefreshing = false;
        } else {
          _isLoadingMore = false;
        }
      }
    });
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

  PropertiesLoaded? _asLoaded(PropertiesState state) {
    if (state is PropertiesLoaded) return state;
    if (state is PropertiesActionInProgress) return state.previous;
    if (state is PropertiesActionFailure) return state.previous;
    if (state is PropertiesActionSuccess) return state.previous;
    return null;
  }

  @override
  Future<void> close() async {
    await _mutationSub?.cancel();
    return super.close();
  }
}
