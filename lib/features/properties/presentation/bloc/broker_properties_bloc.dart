import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/core/utils/single_flight_guard.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/domain/usecases/get_broker_properties_page_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

import 'broker_properties_event.dart';
import 'broker_properties_state.dart';

class BrokerPropertiesBloc
    extends Bloc<BrokerPropertiesEvent, BrokerPropertiesState> {
  final GetBrokerPropertiesPageUseCase _getBrokerPage;
  final LocationAreaRemoteDataSource _areaDs;
  final PropertyMutationsBloc _mutations;
  final AuthRepositoryDomain _auth;
  StreamSubscription<PropertyMutation?>? _mutationSub;
  StreamSubscription? _authSub;
  bool _isCollector = false;
  final SingleFlightGuard _requestGuard = SingleFlightGuard();
  bool _isRefreshing = false;
  bool _isLoadingMore = false;

  BrokerPropertiesBloc(
    this._getBrokerPage,
    this._areaDs,
    this._mutations,
    this._auth,
  ) : super(const BrokerPropertiesInitial()) {
    on<BrokerPropertiesStarted>(_onStarted);
    on<BrokerPropertiesRefreshed>(_onRefreshed);
    on<BrokerPropertiesLoadMore>(_onLoadMore);
    on<BrokerPropertiesFilterChanged>(_onFilterChanged);

    _auth.userChanges.first.then(
      (user) => _isCollector = user?.role == UserRole.collector,
    );
    _authSub = _auth.userChanges.listen((user) {
      _isCollector = user?.role == UserRole.collector;
    });

    _mutationSub = _mutations.mutationStream.listen((mutation) {
      final current = state;
      if (current is BrokerPropertiesLoadSuccess ||
          current is BrokerPropertiesLoadMoreInProgress) {
        final brokerId = current is BrokerPropertiesLoadSuccess
            ? current.brokerId
            : (current as BrokerPropertiesLoadMoreInProgress).brokerId;
        add(
          BrokerPropertiesRefreshed(brokerId: brokerId, filter: _currentFilter),
        );
      }
    });
  }

  PropertyFilter? _currentFilter;

  Future<void> _onStarted(
    BrokerPropertiesStarted event,
    Emitter<BrokerPropertiesState> emit,
  ) async {
    _currentFilter = event.filter;
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, brokerId: event.brokerId, filter: event.filter),
    );
  }

  Future<void> _onRefreshed(
    BrokerPropertiesRefreshed event,
    Emitter<BrokerPropertiesState> emit,
  ) async {
    _currentFilter = event.filter ?? _currentFilter;
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, brokerId: event.brokerId, filter: _currentFilter),
    );
  }

  Future<void> _onFilterChanged(
    BrokerPropertiesFilterChanged event,
    Emitter<BrokerPropertiesState> emit,
  ) async {
    _currentFilter = event.filter;
    await _runGuardedRequest(
      isRefresh: true,
      job: () => _load(emit, brokerId: event.brokerId, filter: _currentFilter),
    );
  }

  Future<void> _onLoadMore(
    BrokerPropertiesLoadMore event,
    Emitter<BrokerPropertiesState> emit,
  ) async {
    await _runGuardedRequest(
      isRefresh: false,
      job: () async {
        final current = state;
        if (current is! BrokerPropertiesLoadSuccess &&
            current is! BrokerPropertiesLoadMoreInProgress) {
          return;
        }
        final List<Property> items;
        final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
        final bool hasMore;
        final Map<String, LocationArea> areaNames;
        final PropertyFilter? filter;
        final String brokerId;
        if (current is BrokerPropertiesLoadSuccess) {
          items = current.items;
          lastDoc = current.lastDoc;
          hasMore = current.hasMore;
          areaNames = current.areaNames;
          filter = current.filter;
          brokerId = current.brokerId;
        } else {
          final data = current as BrokerPropertiesLoadMoreInProgress;
          items = data.items;
          lastDoc = data.lastDoc;
          hasMore = data.hasMore;
          areaNames = data.areaNames;
          filter = data.filter;
          brokerId = data.brokerId;
        }
        if (!hasMore) return;
        emit(
          BrokerPropertiesLoadMoreInProgress(
            brokerId: brokerId,
            items: items,
            lastDoc: lastDoc,
            hasMore: hasMore,
            areaNames: areaNames,
            filter: filter,
          ),
        );
        try {
          final page = await _getBrokerPage(
            brokerId: brokerId,
            startAfter: lastDoc,
            limit: UiConstants.propertiesPageLimit,
            filter: filter,
          );
          final mergedAreas = Map<String, LocationArea>.from(areaNames)
            ..addAll(await _fetchAreaNamesFor(page.items));
          emit(
            BrokerPropertiesLoadSuccess(
              brokerId: brokerId,
              items: [...items, ...page.items],
              lastDoc: page.lastDocument,
              hasMore: page.hasMore,
              areaNames: mergedAreas,
              filter: filter,
            ),
          );
        } catch (e, st) {
          emit(
            BrokerPropertiesFailure(
              brokerId: brokerId,
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
    Emitter<BrokerPropertiesState> emit, {
    required String brokerId,
    PropertyFilter? filter,
  }) async {
    if (_isCollector) {
      emit(
        BrokerPropertiesFailure(
          brokerId: brokerId,
          message: 'access_denied'.tr(),
          items: const [],
          lastDoc: null,
          hasMore: true,
          areaNames: const {},
          filter: filter,
        ),
      );
      return;
    }
    emit(BrokerPropertiesLoadInProgress(brokerId: brokerId, filter: filter));
    try {
      final page = await _getBrokerPage(
        brokerId: brokerId,
        limit: UiConstants.propertiesPageLimit,
        filter: filter,
      );
      final areaNames = await _fetchAreaNamesFor(page.items);
      emit(
        BrokerPropertiesLoadSuccess(
          brokerId: brokerId,
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          areaNames: areaNames,
          filter: filter,
        ),
      );
    } catch (e, st) {
      emit(
        BrokerPropertiesFailure(
          brokerId: brokerId,
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
    final known = state is BrokerPropertiesLoadSuccess
        ? (state as BrokerPropertiesLoadSuccess).areaNames.keys.toSet()
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
    await _authSub?.cancel();
    return super.close();
  }
}
