import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/brokers/domain/usecases/get_brokers_usecase.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

import 'brokers_list_event.dart';
import 'brokers_list_state.dart';

class BrokersListBloc extends Bloc<BrokersListEvent, BrokersListState> {
  final GetBrokersUseCase _getBrokers;
  final AuthRepositoryDomain _auth;
  StreamSubscription? _authSub;
  StreamSubscription<PropertyMutation>? _mutationSub;
  bool _isCollector = false;

  BrokersListBloc(this._getBrokers, this._auth, PropertyMutationsBloc mutations)
    : super(const BrokersListInitial()) {
    on<BrokersListRequested>(_onRequested);
    on<BrokersListRefreshed>(_onRequested);

    _auth.userChanges.first.then((user) {
      _isCollector = user?.role == UserRole.collector;
    });
    _authSub = _auth.userChanges.listen((user) {
      _isCollector = user?.role == UserRole.collector;
    });
    _mutationSub = mutations.mutationStream.listen((mutation) {
      if (mutation.ownerScope == PropertyOwnerScope.broker || mutation.ownerScope == null) {
        add(const BrokersListRefreshed());
      }
    });
  }

  Future<void> _onRequested(BrokersListEvent event, Emitter<BrokersListState> emit) async {
    if (_isCollector) {
      emit(BrokersListFailure('access_denied'.tr()));
      return;
    }
    final currentBrokers = state is BrokersListLoadSuccess
        ? (state as BrokersListLoadSuccess).brokers
        : (state is BrokersListLoadInProgress
              ? (state as BrokersListLoadInProgress).brokers
              : const <Broker>[]);
    emit(BrokersListLoadInProgress(currentBrokers));
    try {
      final brokers = await _getBrokers();
      emit(BrokersListLoadSuccess(brokers));
    } catch (e, st) {
      emit(BrokersListFailure(mapErrorMessage(e, stackTrace: st)));
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _mutationSub?.cancel();
    return super.close();
  }
}
