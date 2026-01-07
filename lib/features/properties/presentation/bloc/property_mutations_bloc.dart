import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_event.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';

/// Broadcasts property mutations so list blocs can refresh without nav callbacks.
class PropertyMutationsBloc
    extends Bloc<PropertyMutationsEvent, PropertyMutationsState> {
  PropertyMutationsBloc() : super(const PropertyMutationsInitial()) {
    on<PropertyMutationStarted>(_onStarted);
    on<PropertyMutationFailed>(_onFailed);
    on<PropertyMutationReset>(_onReset);
  }

  int _tick = 0;

  Stream<PropertyMutation> get mutationStream =>
      stream.where((s) => s.latest != null).map((s) => s.latest!);

  void notify(
    PropertyMutationType type, {
    String? propertyId,
    PropertyOwnerScope? ownerScope,
    String? locationAreaId,
  }) {
    add(
      PropertyMutationStarted(
        type: type,
        propertyId: propertyId,
        ownerScope: ownerScope,
        locationAreaId: locationAreaId,
      ),
    );
  }

  void notifyError(Object error, {PropertyMutation? previous}) {
    add(PropertyMutationFailed(error, previous: previous));
  }

  Future<void> _onStarted(
    PropertyMutationStarted event,
    Emitter<PropertyMutationsState> emit,
  ) async {
    final previous = state.latest;
    final mutation = PropertyMutation(
      type: event.type,
      propertyId: event.propertyId,
      ownerScope: event.ownerScope,
      locationAreaId: event.locationAreaId,
      tick: ++_tick,
    );
    emit(PropertyMutationsActionInProgress(previous: previous));
    emit(
      PropertyMutationsActionSuccess(mutation: mutation, previous: mutation),
    );
  }

  Future<void> _onFailed(
    PropertyMutationFailed event,
    Emitter<PropertyMutationsState> emit,
  ) async {
    emit(
      PropertyMutationsActionFailure(
        message: mapErrorMessage(event.error),
        previous: event.previous ?? state.latest,
      ),
    );
  }

  Future<void> _onReset(
    PropertyMutationReset event,
    Emitter<PropertyMutationsState> emit,
  ) async {
    emit(const PropertyMutationsInitial());
  }
}
