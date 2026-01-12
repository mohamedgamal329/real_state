import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/single_flight_guard.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/usecases/get_company_properties_page_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

import 'company_properties_event.dart';
import 'company_properties_state.dart';

class CompanyPropertiesBloc
    extends Bloc<CompanyPropertiesEvent, CompanyPropertiesState> {
  final GetCompanyPropertiesPageUseCase _getCompanyPage;
  final LocationAreaRemoteDataSource _areaDs;
  final PropertyMutationsBloc _mutations;
  StreamSubscription<PropertyMutation>? _mutationSub;

  CompanyPropertiesBloc(this._getCompanyPage, this._areaDs, this._mutations)
    : super(const CompanyPropertiesInitial()) {
    on<CompanyPropertiesStarted>(_onStarted);
    on<CompanyPropertiesRefreshed>(_onRefreshed);
    on<CompanyPropertiesLoadMore>(_onLoadMore);
    on<CompanyPropertiesFilterChanged>(_onFilterChanged);

    _mutationSub = _mutations.mutationStream.listen((event) {
      if (event.ownerScope != null &&
          event.ownerScope != PropertyOwnerScope.company)
        return;
      if (state is CompanyPropertiesLoadSuccess) {
        final currentFilter = (state as CompanyPropertiesLoadSuccess).filter;
        if (currentFilter?.locationAreaId != null &&
            event.locationAreaId != null &&
            currentFilter!.locationAreaId != event.locationAreaId) {
          return;
        }
        add(CompanyPropertiesRefreshed(filter: currentFilter));
      } else {
        add(const CompanyPropertiesRefreshed());
      }
    });
  }

  Future<void> _onStarted(
    CompanyPropertiesStarted event,
    Emitter<CompanyPropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, filter: event.filter, reset: true),
    );
  }

  Future<void> _onRefreshed(
    CompanyPropertiesRefreshed event,
    Emitter<CompanyPropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, filter: event.filter, reset: true),
    );
  }

  Future<void> _onFilterChanged(
    CompanyPropertiesFilterChanged event,
    Emitter<CompanyPropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, filter: event.filter, reset: true),
    );
  }

  final SingleFlightGuard _requestGuard = SingleFlightGuard();
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  Future<void> _onLoadMore(
    CompanyPropertiesLoadMore event,
    Emitter<CompanyPropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: false,
      job: () async {
        final current = state;
        if (current is! CompanyPropertiesLoadSuccess &&
            current is! CompanyPropertiesLoadMoreInProgress &&
            current is! CompanyPropertiesFailure) {
          return;
        }

        final List<Property> items;
        final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
        final bool hasMore;
        final Map<String, LocationArea> areaNames;
        final PropertyFilter? filter;

        if (current is CompanyPropertiesLoadSuccess) {
          items = current.items;
          lastDoc = current.lastDoc;
          hasMore = current.hasMore;
          areaNames = current.areaNames;
          filter = current.filter;
        } else if (current is CompanyPropertiesLoadMoreInProgress) {
          items = current.items;
          lastDoc = current.lastDoc;
          hasMore = current.hasMore;
          areaNames = current.areaNames;
          filter = current.filter;
        } else {
          final data = current as CompanyPropertiesFailure;
          items = data.items;
          lastDoc = data.lastDoc;
          hasMore = data.hasMore;
          areaNames = data.areaNames;
          filter = data.filter;
        }

        if (!hasMore) return;

        emit(
          CompanyPropertiesLoadMoreInProgress(
            items: items,
            lastDoc: lastDoc,
            hasMore: hasMore,
            areaNames: areaNames,
            filter: filter,
          ),
        );
        try {
          final page = await _getCompanyPage(
            startAfter: lastDoc,
            limit: UiConstants.propertiesPageLimit,
            filter: filter,
          );
          final mergedAreas = Map<String, LocationArea>.from(areaNames)
            ..addAll(await _fetchAreaNamesFor(page.items));
          emit(
            CompanyPropertiesLoadSuccess(
              items: [...items, ...page.items],
              lastDoc: page.lastDocument,
              hasMore: page.hasMore,
              areaNames: mergedAreas,
              filter: filter,
            ),
          );
        } catch (e, st) {
          emit(
            CompanyPropertiesFailure(
              message: mapErrorMessage(e, stackTrace: st),
              items: items,
              lastDoc: lastDoc,
              hasMore: hasMore,
              areaNames: areaNames,
              filter: filter,
            ),
          );
        }
      },
    );
  }

  Future<void> _load(
    Emitter<CompanyPropertiesState> emit, {
    required bool reset,
    PropertyFilter? filter,
  }) async {
    final current = state;
    if (current is CompanyPropertiesLoadSuccess) {
      emit(
        CompanyPropertiesLoadInProgress(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          areaNames: current.areaNames,
          filter: filter ?? current.filter,
        ),
      );
    } else if (current is CompanyPropertiesLoadInProgress) {
      emit(
        CompanyPropertiesLoadInProgress(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          areaNames: current.areaNames,
          filter: filter ?? current.filter,
        ),
      );
    } else {
      emit(CompanyPropertiesLoadInProgress(filter: filter));
    }

    try {
      final page = await _getCompanyPage(
        limit: UiConstants.propertiesPageLimit,
        filter: filter,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      emit(
        CompanyPropertiesLoadSuccess(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
          filter: filter,
        ),
      );
    } catch (e, st) {
      final s = state;
      if (s is CompanyPropertiesLoadInProgress && s.items.isNotEmpty) {
        emit(
          CompanyPropertiesFailure(
            message: mapErrorMessage(e, stackTrace: st),
            items: s.items,
            lastDoc: s.lastDoc,
            hasMore: s.hasMore,
            areaNames: s.areaNames,
            filter: filter,
          ),
        );
      } else {
        emit(
          CompanyPropertiesFailure(
            message: mapErrorMessage(e, stackTrace: st),
            items: const [],
            lastDoc: null,
            hasMore: true,
            areaNames: const {},
            filter: filter,
          ),
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
    final known = state is CompanyPropertiesLoadSuccess
        ? (state as CompanyPropertiesLoadSuccess).areaNames.keys.toSet()
        : <String>{};
    final ids = props
        .where((p) => p.locationAreaId != null)
        .map((p) => p.locationAreaId!)
        .where((id) => !known.contains(id))
        .toSet()
        .toList();
    if (ids.isEmpty) return {};
    try {
      return await _areaDs.fetchNamesByIds(ids);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> close() async {
    await _mutationSub?.cancel();
    return super.close();
  }
}
