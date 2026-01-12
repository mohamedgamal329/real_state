import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/single_flight_guard.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/archive_properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/archive_properties_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

class ArchivePropertiesBloc
    extends Bloc<ArchivePropertiesEvent, ArchivePropertiesState> {
  final PropertiesRepository _repo;
  final LocationAreaRemoteDataSource _areaDs;
  final PropertyMutationsBloc _mutations;
  StreamSubscription<PropertyMutation>? _mutationSub;
  final SingleFlightGuard _requestGuard = SingleFlightGuard();
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  ArchivePropertiesBloc(this._repo, this._areaDs, this._mutations)
    : super(const ArchivePropertiesInitial()) {
    on<ArchivePropertiesStarted>(_onStarted);
    on<ArchivePropertiesRefreshed>(_onRefreshed);
    on<ArchivePropertiesLoadMoreRequested>(_onLoadMore);
    on<ArchivePropertiesRetryRequested>(_onRetry);
    on<ArchivePropertiesExternalMutationReceived>(_onExternalMutation);

    _mutationSub = _mutations.mutationStream.listen((_) {
      add(const ArchivePropertiesExternalMutationReceived());
    });
  }

  Future<void> _onStarted(
    ArchivePropertiesStarted event,
    Emitter<ArchivePropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        emit(const ArchivePropertiesLoading());
        await _loadPage(emit);
      },
    );
  }

  Future<void> _onRefreshed(
    ArchivePropertiesRefreshed event,
    Emitter<ArchivePropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        final current = _asLoaded(state);
        if (current == null) {
          emit(const ArchivePropertiesLoading());
          await _loadPage(emit);
          return;
        }
        emit(ArchivePropertiesActionInProgress(current));
        await _loadPage(emit, previous: current);
      },
    );
  }

  Future<void> _onLoadMore(
    ArchivePropertiesLoadMoreRequested event,
    Emitter<ArchivePropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: false,
      job: () async {
        final current = _asLoaded(state);
        if (current == null ||
            !current.hasMore ||
            state is ArchivePropertiesActionInProgress) {
          return;
        }
        try {
          final page = await _repo.fetchArchivedPage(
            startAfter: current.lastDoc,
            limit: UiConstants.propertiesPageLimit,
          );
          final items = List<Property>.from(current.items)..addAll(page.items);
          final areaNames = Map<String, LocationArea>.from(current.areaNames)
            ..addAll(await _fetchAreaNamesFor(page.items));
          emit(
            ArchivePropertiesLoaded(
              items: items,
              lastDoc: page.lastDocument,
              hasMore: page.hasMore,
              areaNames: areaNames,
            ),
          );
        } catch (e, st) {
          emit(
            ArchivePropertiesActionFailure(
              current,
              mapErrorMessage(e, stackTrace: st),
            ),
          );
        }
      },
    );
  }

  Future<void> _onRetry(
    ArchivePropertiesRetryRequested event,
    Emitter<ArchivePropertiesState> emit,
  ) async {
    if (state is ArchivePropertiesLoaded) {
      add(const ArchivePropertiesRefreshed());
    } else {
      add(const ArchivePropertiesStarted());
    }
  }

  Future<void> _onExternalMutation(
    ArchivePropertiesExternalMutationReceived event,
    Emitter<ArchivePropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () async {
        final current = _asLoaded(state);
        if (current == null) return;
        emit(ArchivePropertiesActionInProgress(current));
        await _loadPage(emit, previous: current);
      },
    );
  }

  Future<void> _loadPage(
    Emitter<ArchivePropertiesState> emit, {
    ArchivePropertiesLoaded? previous,
  }) async {
    try {
      final page = await _repo.fetchArchivedPage(
        limit: UiConstants.propertiesPageLimit,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      if (previous != null) {
        emit(ArchivePropertiesActionSuccess(previous));
      }
      emit(
        ArchivePropertiesLoaded(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
        ),
      );
    } catch (e, st) {
      if (previous != null) {
        emit(
          ArchivePropertiesActionFailure(
            previous,
            mapErrorMessage(e, stackTrace: st),
          ),
        );
      } else {
        emit(ArchivePropertiesFailure(mapErrorMessage(e, stackTrace: st)));
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

  ArchivePropertiesLoaded? _asLoaded(ArchivePropertiesState state) {
    if (state is ArchivePropertiesLoaded) return state;
    if (state is ArchivePropertiesActionInProgress) return state.previous;
    if (state is ArchivePropertiesActionFailure) return state.previous;
    if (state is ArchivePropertiesActionSuccess) return state.previous;
    return null;
  }

  @override
  Future<void> close() async {
    await _mutationSub?.cancel();
    return super.close();
  }
}
