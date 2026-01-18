import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';

import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final PropertiesRepository _repo;
  final GetLocationAreasUseCase _areas;
  final PropertyMutationsStream _mutations;
  final AuthRepositoryDomain _auth;
  late final StreamSubscription<PropertyMutation> _mutationSub;
  StreamSubscription? _authSub;
  Completer<void>? _locationsLoadCompleter;
  bool _locationsLoaded = false;
  bool _isCollector = false;

  CategoriesCubit(this._repo, this._areas, this._mutations, this._auth)
    : super(const CategoriesInitial()) {
    _mutationSub = _mutations.mutationStream.listen((mutation) {
      final current = _asListState(state);
      if (current == null) {
        unawaited(loadFirstPage());
        return;
      }
      if (_isCollector && mutation.ownerScope == PropertyOwnerScope.broker) {
        return;
      }
      emit(
        CategoriesRefreshing(
          filter: current.filter,
          locationAreas: current.locationAreas,
          areaNames: current.areaNames,
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: true,
        ),
      );
      unawaited(refresh());
    });
    _authSub = _auth.userChanges.listen((u) {
      _isCollector = u?.role == UserRole.collector;
    });
    _auth.userChanges.first.then(
      (u) => _isCollector = u?.role == UserRole.collector,
    );
    // Ensure locations are loaded early for filters
    unawaited(ensureLocationsLoaded(force: true));
  }

  /// Load location areas for filter dropdown
  Future<void> loadLocations() async {
    await ensureLocationsLoaded(force: true);
  }

  Future<void> ensureLocationsLoaded({bool force = false}) async {
    if (_locationsLoaded && _coreState().locationAreas.isNotEmpty && !force)
      return;
    if (_locationsLoadCompleter != null) return _locationsLoadCompleter!.future;

    _locationsLoadCompleter = Completer<void>();
    try {
      final core = _coreState();
      emit(
        CategoriesLoadInProgress(
          filter: core.filter,
          locationAreas: core.locationAreas,
          areaNames: core.areaNames,
        ),
      );
      final areas = await _areas.call(force: force);
      final map = {for (final a in areas) a.id: a};
      _locationsLoaded = true;
      emit(_stateWithLocations(areas, map));
      _locationsLoadCompleter?.complete();
    } catch (e) {
      _locationsLoaded = false;
      _locationsLoadCompleter?.completeError(e);
      // Keep current state on failure to avoid losing list data
    } finally {
      _locationsLoadCompleter = null;
    }
  }

  /// Load first page with current filter
  Future<void> loadFirstPage() async {
    final existing = _asListState(state);
    if (existing != null && existing.items.isNotEmpty) {
      return;
    }
    final core = _coreState();
    await ensureLocationsLoaded();
    await _fetchFirstPage(
      filter: core.filter,
      locations: core.locationAreas,
      cachedAreas: core.areaNames,
    );
  }

  /// Apply new filter - resets pagination and fetches first page
  Future<void> applyFilter(PropertyFilter filter) async {
    final core = _coreState();
    await ensureLocationsLoaded();
    await _fetchFirstPage(
      filter: filter,
      locations: core.locationAreas,
      cachedAreas: core.areaNames,
    );
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await applyFilter(PropertyFilter.empty);
  }

  /// Refresh - re-fetch first page with current filter
  Future<void> refresh() async {
    final current = _asListState(state);
    if (current == null) {
      await loadFirstPage();
      return;
    }
    emit(
      CategoriesRefreshing(
        filter: current.filter,
        locationAreas: current.locationAreas,
        areaNames: current.areaNames,
        items: current.items,
        lastDoc: current.lastDoc,
        hasMore: true,
      ),
    );
    try {
      final page = await _fetchPageForRole(
        limit: UiConstants.propertiesPageLimit,
        filter: current.filter,
      );
      final filtered = _filterForRole(page.items);
      final areaNames = await _fetchAreaNamesFor(filtered);
      emit(
        CategoriesLoadSuccess(
          filter: current.filter,
          locationAreas: current.locationAreas,
          areaNames: {...current.areaNames, ...areaNames},
          items: filtered,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      emit(
        CategoriesPartialFailure(
          filter: current.filter,
          locationAreas: current.locationAreas,
          areaNames: current.areaNames,
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  /// Load more items (pagination)
  Future<void> loadMore() async {
    final current = _asListState(state);
    if (current == null ||
        !current.hasMore ||
        state is CategoriesLoadMoreInProgress ||
        state is CategoriesRefreshing)
      return;
    emit(
      CategoriesLoadMoreInProgress(
        filter: current.filter,
        locationAreas: current.locationAreas,
        areaNames: current.areaNames,
        items: current.items,
        lastDoc: current.lastDoc,
        hasMore: current.hasMore,
      ),
    );
    try {
      final page = await _fetchPageForRole(
        startAfter: current.lastDoc,
        limit: UiConstants.propertiesPageLimit,
        filter: current.filter,
      );
      final filtered = _filterForRole(page.items);
      final items = List<Property>.from(current.items)..addAll(filtered);
      final areaNames = await _fetchAreaNamesFor(filtered);
      emit(
        CategoriesLoadSuccess(
          filter: current.filter,
          locationAreas: current.locationAreas,
          areaNames: {...current.areaNames, ...areaNames},
          items: items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      emit(
        CategoriesPartialFailure(
          filter: current.filter,
          locationAreas: current.locationAreas,
          areaNames: current.areaNames,
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          message: mapErrorMessage(e),
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
        .where((id) => !_coreState().areaNames.containsKey(id))
        .toList();
    if (ids.isEmpty) return {};
    try {
      return await _areas.namesByIds(ids);
    } catch (_) {
      return {};
    }
  }

  CategoriesCoreState _coreState() {
    if (state is CategoriesCoreState) {
      return state as CategoriesCoreState;
    }
    return const CategoriesInitial();
  }

  CategoriesListState? _asListState(CategoriesState state) {
    if (state is CategoriesListState) return state;
    return null;
  }

  Future<void> _fetchFirstPage({
    required PropertyFilter filter,
    required List<LocationArea> locations,
    required Map<String, LocationArea> cachedAreas,
  }) async {
    emit(
      CategoriesLoadInProgress(
        filter: filter,
        locationAreas: locations,
        areaNames: cachedAreas,
      ),
    );
    try {
      final page = await _fetchPageForRole(
        limit: UiConstants.propertiesPageLimit,
        filter: filter,
      );
      final filtered = _filterForRole(page.items);
      final areaNames = await _fetchAreaNamesFor(filtered);
      emit(
        CategoriesLoadSuccess(
          filter: filter,
          locationAreas: locations,
          areaNames: {...cachedAreas, ...areaNames},
          items: filtered,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
        ),
      );
    } catch (e) {
      final previous = _asListState(state);
      if (previous != null && previous.items.isNotEmpty) {
        emit(
          CategoriesPartialFailure(
            filter: filter,
            locationAreas: locations,
            areaNames: cachedAreas,
            items: previous.items,
            lastDoc: previous.lastDoc,
            hasMore: previous.hasMore,
            message: mapErrorMessage(e),
          ),
        );
      } else {
        emit(
          CategoriesFailure(
            filter: filter,
            locationAreas: locations,
            areaNames: cachedAreas,
            message: mapErrorMessage(e),
          ),
        );
      }
    }
  }

  CategoriesState _stateWithLocations(
    List<LocationArea> areas,
    Map<String, LocationArea> names,
  ) {
    final current = _coreState();
    if (state is CategoriesLoadSuccess) {
      final listState = state as CategoriesLoadSuccess;
      return CategoriesLoadSuccess(
        filter: listState.filter,
        locationAreas: areas,
        areaNames: {...names, ...listState.areaNames},
        items: listState.items,
        lastDoc: listState.lastDoc,
        hasMore: listState.hasMore,
      );
    }
    if (state is CategoriesRefreshing) {
      final listState = state as CategoriesRefreshing;
      return CategoriesRefreshing(
        filter: listState.filter,
        locationAreas: areas,
        areaNames: {...names, ...listState.areaNames},
        items: listState.items,
        lastDoc: listState.lastDoc,
        hasMore: listState.hasMore,
      );
    }
    if (state is CategoriesLoadMoreInProgress) {
      final listState = state as CategoriesLoadMoreInProgress;
      return CategoriesLoadMoreInProgress(
        filter: listState.filter,
        locationAreas: areas,
        areaNames: {...names, ...listState.areaNames},
        items: listState.items,
        lastDoc: listState.lastDoc,
        hasMore: listState.hasMore,
      );
    }
    if (state is CategoriesPartialFailure) {
      final listState = state as CategoriesPartialFailure;
      return CategoriesPartialFailure(
        filter: listState.filter,
        locationAreas: areas,
        areaNames: {...names, ...listState.areaNames},
        items: listState.items,
        lastDoc: listState.lastDoc,
        hasMore: listState.hasMore,
        message: listState.message,
      );
    }
    if (state is CategoriesFailure) {
      final failure = state as CategoriesFailure;
      return CategoriesFailure(
        filter: failure.filter,
        locationAreas: areas,
        areaNames: {...names, ...failure.areaNames},
        message: failure.message,
      );
    }
    if (state is CategoriesLoadInProgress) {
      return CategoriesInitial(
        filter: current.filter,
        locationAreas: areas,
        areaNames: {...names, ...current.areaNames},
      );
    }
    return CategoriesInitial(
      filter: current.filter,
      locationAreas: areas,
      areaNames: {...names, ...current.areaNames},
    );
  }

  @override
  Future<void> close() async {
    await _mutationSub.cancel();
    await _authSub?.cancel();
    return super.close();
  }

  List<Property> _filterForRole(List<Property> items) {
    if (!_isCollector) return items;
    return items
        .where((p) => p.ownerScope == PropertyOwnerScope.company)
        .toList();
  }

  Future<PageResult<Property>> _fetchPageForRole({
    PageToken? startAfter,
    required int limit,
    PropertyFilter? filter,
  }) {
    if (_isCollector) {
      return _repo.fetchCompanyPage(
        startAfter: startAfter,
        limit: limit,
        filter: filter,
      );
    }
    return _repo.fetchPage(
      startAfter: startAfter,
      limit: limit,
      filter: filter,
    );
  }
}
