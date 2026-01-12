import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/single_flight_guard.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/usecases/get_broker_properties_page_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

import 'broker_area_properties_event.dart';
import 'broker_area_properties_state.dart';

class BrokerAreaPropertiesBloc
    extends Bloc<BrokerAreaPropertiesEvent, BrokerAreaPropertiesState> {
  final GetBrokerPropertiesPageUseCase _getBrokerPage;
  final PropertyMutationsBloc _mutations;
  StreamSubscription<PropertyMutation>? _mutationSub;
  String? _brokerId;
  PropertyFilter _filter;
  final SingleFlightGuard _requestGuard = SingleFlightGuard();
  bool _isLoadingMore = false;

  BrokerAreaPropertiesBloc(
    this._getBrokerPage,
    this._mutations,
    String brokerId,
    String areaId,
  ) : _filter = PropertyFilter(locationAreaId: areaId),
      super(const BrokerAreaPropertiesInitial()) {
    on<BrokerAreaPropertiesStarted>(_onStarted);
    on<BrokerAreaPropertiesRefreshed>(_onRefreshed);
    on<BrokerAreaPropertiesLoadMore>(_onLoadMore);
    on<BrokerAreaPropertiesFilterChanged>(_onFilterChanged);

    _brokerId = brokerId;
    _mutationSub = _mutations.mutationStream.listen((mutation) {
      if (mutation.ownerScope != PropertyOwnerScope.broker) return;
      if (mutation.locationAreaId != null &&
          mutation.locationAreaId != _filter.locationAreaId)
        return;
      if (_brokerId != null) {
        add(
          BrokerAreaPropertiesRefreshed(
            brokerId: _brokerId!,
            areaId: _filter.locationAreaId!,
          ),
        );
      }
    });
  }

  Future<void> _onStarted(
    BrokerAreaPropertiesStarted event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    _brokerId = event.brokerId;
    _filter =
        (event.filter ?? const PropertyFilter()).copyWith(
          locationAreaId: event.areaId,
        );
    await _guarded(() => _load(emit, reset: true));
  }

  Future<void> _onRefreshed(
    BrokerAreaPropertiesRefreshed event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    _brokerId = event.brokerId;
    _filter =
        (event.filter ?? _filter).copyWith(locationAreaId: event.areaId);
    await _guarded(() => _load(emit, reset: true));
  }

  Future<void> _onFilterChanged(
    BrokerAreaPropertiesFilterChanged event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    _filter = event.filter.copyWith(
      locationAreaId: _filter.locationAreaId,
    );
    await _guarded(() => _load(emit, reset: true));
  }

  Future<void> _onLoadMore(
    BrokerAreaPropertiesLoadMore event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    final current = state;
    if (current is! BrokerAreaPropertiesLoadSuccess &&
        current is! BrokerAreaPropertiesLoadMoreInProgress) {
      return;
    }
    if (current is BrokerAreaPropertiesLoadSuccess && !current.hasMore) return;
    if (current is BrokerAreaPropertiesLoadMoreInProgress && !current.hasMore) return;
    if (_requestGuard.isBusy || _isLoadingMore) return;
    await _guarded(() async {
      _isLoadingMore = true;
      final items = current is BrokerAreaPropertiesLoadSuccess ? current.items : (current as BrokerAreaPropertiesLoadMoreInProgress).items;
      final lastDoc = current is BrokerAreaPropertiesLoadSuccess ? current.lastDoc : (current as BrokerAreaPropertiesLoadMoreInProgress).lastDoc;
      final hasMore = current is BrokerAreaPropertiesLoadSuccess ? current.hasMore : (current as BrokerAreaPropertiesLoadMoreInProgress).hasMore;
      final filter = current is BrokerAreaPropertiesLoadSuccess ? current.filter : (current as BrokerAreaPropertiesLoadMoreInProgress).filter;

      emit(
        BrokerAreaPropertiesLoadMoreInProgress(
          items: items,
          lastDoc: lastDoc,
          hasMore: hasMore,
          filter: filter,
        ),
      );
      try {
        final page = await _getBrokerPage(
          brokerId: _brokerId!,
          startAfter: lastDoc,
          limit: UiConstants.propertiesPageLimit,
          filter: filter,
        );
        emit(
          BrokerAreaPropertiesLoadSuccess(
            items: [...items, ...page.items],
            lastDoc: page.lastDocument,
            hasMore: page.hasMore,
            filter: filter,
          ),
        );
      } catch (e, st) {
        emit(
          BrokerAreaPropertiesFailure(
            message: mapErrorMessage(e, stackTrace: st),
            items: items,
            lastDoc: lastDoc,
            hasMore: hasMore,
            filter: filter,
          ),
        );
      } finally {
        _isLoadingMore = false;
      }
    });
  }

  Future<void> _load(
    Emitter<BrokerAreaPropertiesState> emit, {
    required bool reset,
  }) async {
    emit(BrokerAreaPropertiesLoadInProgress(filter: _filter));
    try {
      final page = await _getBrokerPage(
        brokerId: _brokerId!,
        startAfter: null,
        limit: UiConstants.propertiesPageLimit,
        filter: _filter,
      );
      emit(
        BrokerAreaPropertiesLoadSuccess(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          filter: _filter,
        ),
      );
    } catch (e, st) {
      emit(
        BrokerAreaPropertiesFailure(
          message: mapErrorMessage(e, stackTrace: st),
          items: const [],
          lastDoc: null,
          hasMore: true,
          filter: _filter,
        ),
      );
    }
  }

  Future<bool> _guarded(Future<void> Function() action) => _requestGuard.run(action);

  @override
  Future<void> close() async {
    await _mutationSub?.cancel();
    return super.close();
  }
}
