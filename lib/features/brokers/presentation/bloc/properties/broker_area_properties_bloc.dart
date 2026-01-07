import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
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
    await _load(emit, reset: true);
  }

  Future<void> _onRefreshed(
    BrokerAreaPropertiesRefreshed event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    _brokerId = event.brokerId;
    _filter =
        (event.filter ?? _filter).copyWith(locationAreaId: event.areaId);
    await _load(emit, reset: true);
  }

  Future<void> _onFilterChanged(
    BrokerAreaPropertiesFilterChanged event,
    Emitter<BrokerAreaPropertiesState> emit,
  ) async {
    _filter = event.filter.copyWith(
      locationAreaId: _filter.locationAreaId,
    );
    await _load(emit, reset: true);
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
    if (current is BrokerAreaPropertiesLoadSuccess) {
      if (!current.hasMore) return;
      emit(
        BrokerAreaPropertiesLoadMoreInProgress(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          filter: current.filter,
        ),
      );
      try {
        final page = await _getBrokerPage(
          brokerId: _brokerId!,
          startAfter: current.lastDoc,
          limit: UiConstants.propertiesPageLimit,
          filter: current.filter,
        );
        emit(
          BrokerAreaPropertiesLoadSuccess(
            items: [...current.items, ...page.items],
            lastDoc: page.lastDocument,
            hasMore: page.hasMore,
            filter: current.filter,
          ),
        );
      } catch (e, st) {
        emit(
          BrokerAreaPropertiesFailure(
            message: mapErrorMessage(e, stackTrace: st),
            items: current.items,
            lastDoc: current.lastDoc,
            hasMore: current.hasMore,
            filter: current.filter,
          ),
        );
      }
      return;
    }
    final data = current as BrokerAreaPropertiesLoadMoreInProgress;
    if (!data.hasMore) return;
    emit(
      BrokerAreaPropertiesLoadMoreInProgress(
        items: data.items,
        lastDoc: data.lastDoc,
        hasMore: data.hasMore,
        filter: data.filter,
      ),
    );
    try {
      final page = await _getBrokerPage(
        brokerId: _brokerId!,
        startAfter: data.lastDoc,
        limit: UiConstants.propertiesPageLimit,
        filter: data.filter,
      );
      emit(
        BrokerAreaPropertiesLoadSuccess(
          items: [...data.items, ...page.items],
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          filter: data.filter,
        ),
      );
    } catch (e, st) {
      emit(
        BrokerAreaPropertiesFailure(
          message: mapErrorMessage(e, stackTrace: st),
          items: data.items,
          lastDoc: data.lastDoc,
          hasMore: data.hasMore,
          filter: data.filter,
        ),
      );
    }
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

  @override
  Future<void> close() async {
    await _mutationSub?.cancel();
    return super.close();
  }
}
