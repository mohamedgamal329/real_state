import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/services/property_mutations_stream.dart';

import 'broker_areas_event.dart';
import 'broker_areas_state.dart';

class BrokerAreasBloc extends Bloc<BrokerAreasEvent, BrokerAreasState> {
  final GetBrokerAreasUseCase _getAreas;
  final LocationAreasRepository _areasRepo;
  final Map<String, LocationArea> _areaCache = {};
  final AuthRepositoryDomain _auth;
  StreamSubscription? _authSub;
  StreamSubscription<PropertyMutation>? _mutationSub;
  bool _isCollector = false;
  String? _activeBrokerId;

  BrokerAreasBloc(
    this._getAreas,
    this._areasRepo,
    this._auth,
    PropertyMutationsStream mutations,
  ) : super(const BrokerAreasInitial()) {
    on<BrokerAreasRequested>(_onRequested);
    _auth.userChanges.first.then(
      (user) => _isCollector = user?.role == UserRole.collector,
    );
    _authSub = _auth.userChanges.listen((user) {
      _isCollector = user?.role == UserRole.collector;
    });
    _mutationSub = mutations.mutationStream.listen((mutation) {
      if (mutation.ownerScope == PropertyOwnerScope.broker &&
          _activeBrokerId != null) {
        add(BrokerAreasRequested(_activeBrokerId!));
      }
    });
  }

  Future<void> _onRequested(
    BrokerAreasRequested event,
    Emitter<BrokerAreasState> emit,
  ) async {
    _activeBrokerId = event.brokerId;
    if (_isCollector) {
      emit(
        BrokerAreasFailure(
          brokerId: event.brokerId,
          message: 'access_denied'.tr(),
        ),
      );
      return;
    }
    emit(BrokerAreasLoadInProgress(event.brokerId));
    try {
      final cachedNames = <String, String>{
        for (final entry in _areaCache.entries) entry.key: entry.value.name,
      };
      final areas = await _getAreas(
        event.brokerId,
        cachedAreaNames: cachedNames,
      );
      final areaIds = areas.map((area) => area.id).toList();
      final missing = areaIds
          .where((id) => !_areaCache.containsKey(id))
          .toList();
      if (missing.isNotEmpty) {
        final fetched = await _areasRepo.fetchNamesByIds(missing);
        _areaCache.addAll(fetched);
      }
      final areaDetails = <String, LocationArea>{
        for (final id in areaIds)
          if (_areaCache[id] != null) id: _areaCache[id]!,
      };
      emit(
        BrokerAreasLoadSuccess(
          brokerId: event.brokerId,
          areas: areas,
          areaDetails: areaDetails,
        ),
      );
    } catch (e, st) {
      emit(
        BrokerAreasFailure(
          brokerId: event.brokerId,
          message: mapErrorMessage(e, stackTrace: st),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _mutationSub?.cancel();
    return super.close();
  }
}
