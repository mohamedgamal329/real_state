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
        if (!state.filter.isEmpty) {
          unawaited(loadFirstPage());
        }
        return;
      }
      if (_isCollector && mutation.ownerScope == PropertyOwnerScope.broker) {
        return;
      }
      unawaited(refresh());
    });

    _authSub = _auth.userChanges.listen((u) {
      final wasCollector = _isCollector;
      _isCollector = u?.role == UserRole.collector;
      if (wasCollector != _isCollector) {
        unawaited(refresh());
      }
    });

    _auth.userChanges.first.then((u) {
      _isCollector = u?.role == UserRole.collector;
    });

    // Load locations once on init
    unawaited(ensureLocationsLoaded());
  }

  Future<void> ensureLocationsLoaded({bool force = false}) async {
    // FIX A: Ensure we actually have areas. If loaded=true but list is empty, retry.
    final hasAreas = _coreState().locationAreas.isNotEmpty;
    if (_locationsLoaded && hasAreas && !force) return;
    if (_locationsLoadCompleter != null) return _locationsLoadCompleter!.future;

    _locationsLoadCompleter = Completer<void>();
    try {
      final core = _coreState();
      // Only emit loading if we don't have areas yet or forcing
      if (core.locationAreas.isEmpty || force) {
        emit(
          CategoriesLoadInProgress(
            filter: core.filter,
            locationAreas: core.locationAreas,
            areaNames: core.areaNames,
          ),
        );
      }

      final areas = await _areas.call(force: force);
      final map = {for (final a in areas) a.id: a};

      _locationsLoaded = true;
      emit(_stateWithLocations(areas, map));
      _locationsLoadCompleter?.complete();
    } catch (e) {
      _locationsLoaded = false;
      _locationsLoadCompleter?.completeError(e);

      final core = _coreState();
      emit(
        CategoriesFailure(
          filter: core.filter,
          locationAreas: core.locationAreas,
          areaNames: core.areaNames,
          message: mapErrorMessage(e),
        ),
      );
    } finally {
      _locationsLoadCompleter = null;
    }
  }

  /// Load first page with current filter
  Future<void> loadFirstPage() async {
    final core = _coreState();
    await ensureLocationsLoaded();
    await _fetchFirstPage(
      filter: core.filter,
      locations: _coreState().locationAreas,
      cachedAreas: _coreState().areaNames,
    );
  }

  /// Apply new filter - resets pagination and fetches first page
  Future<void> applyFilter(PropertyFilter filter) async {
    await ensureLocationsLoaded();
    final core = _coreState();
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
      if (!state.filter.isEmpty) {
        await loadFirstPage();
      }
      return;
    }

    emit(
      CategoriesRefreshing(
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
        state is CategoriesRefreshing) {
      return;
    }

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
    final s = state;
    if (s is CategoriesCoreState) return s;
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
    if (filter.isEmpty) {
      emit(
        CategoriesInitial(
          filter: filter,
          locationAreas: locations,
          areaNames: cachedAreas,
        ),
      );
      return;
    }

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

  CategoriesState _stateWithLocations(
    List<LocationArea> areas,
    Map<String, LocationArea> names,
  ) {
    final s = state;
    if (s is CategoriesLoadSuccess) {
      return CategoriesLoadSuccess(
        filter: s.filter,
        locationAreas: areas,
        areaNames: {...names, ...s.areaNames},
        items: s.items,
        lastDoc: s.lastDoc,
        hasMore: s.hasMore,
      );
    }
    if (s is CategoriesRefreshing) {
      return CategoriesRefreshing(
        filter: s.filter,
        locationAreas: areas,
        areaNames: {...names, ...s.areaNames},
        items: s.items,
        lastDoc: s.lastDoc,
        hasMore: s.hasMore,
      );
    }
    if (s is CategoriesLoadMoreInProgress) {
      return CategoriesLoadMoreInProgress(
        filter: s.filter,
        locationAreas: areas,
        areaNames: {...names, ...s.areaNames},
        items: s.items,
        lastDoc: s.lastDoc,
        hasMore: s.hasMore,
      );
    }
    if (s is CategoriesPartialFailure) {
      return CategoriesPartialFailure(
        filter: s.filter,
        locationAreas: areas,
        areaNames: {...names, ...s.areaNames},
        items: s.items,
        lastDoc: s.lastDoc,
        hasMore: s.hasMore,
        message: s.message,
      );
    }
    if (s is CategoriesFailure) {
      return CategoriesFailure(
        filter: s.filter,
        locationAreas: areas,
        areaNames: {...names, ...s.areaNames},
        message: s.message,
      );
    }

    final currentCore = _coreState();
    return CategoriesInitial(
      filter: currentCore.filter,
      locationAreas: areas,
      areaNames: {...names, ...currentCore.areaNames},
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
