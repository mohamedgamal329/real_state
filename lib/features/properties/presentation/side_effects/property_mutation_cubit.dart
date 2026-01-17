import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/usecases/archive_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/delete_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/restore_property_usecase.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'property_mutation_state.dart';

class PropertyMutationCubit extends Cubit<PropertyMutationState> {
  final ArchivePropertyUseCase _archiveUseCase;
  final DeletePropertyUseCase _deleteUseCase;
  final RestorePropertyUseCase _restoreUseCase;
  final PropertyMutationsBloc _mutations;

  PropertyMutationCubit(
    this._archiveUseCase,
    this._deleteUseCase,
    this._restoreUseCase,
    this._mutations,
  ) : super(const PropertyMutationIdle());

  Future<void> archive({
    required Property property,
    required String userId,
    required UserRole userRole,
  }) async {
    await _performMutation(
      action: PropertyMutationAction.archive,
      job: () => _archiveUseCase(
        property: property,
        userId: userId,
        userRole: userRole,
      ),
      mutate: (updated) {
        _mutations.notify(
          PropertyMutationType.archived,
          propertyId: updated.id,
          ownerScope: updated.ownerScope,
          locationAreaId: updated.locationAreaId,
        );
      },
    );
  }

  Future<void> delete({
    required Property property,
    required String userId,
    required UserRole userRole,
  }) async {
    await _performMutation(
      action: PropertyMutationAction.delete,
      job: () async {
        await _deleteUseCase(
          property: property,
          userId: userId,
          userRole: userRole,
        );
        return property;
      },
      mutate: (_) {
        _mutations.notify(
          PropertyMutationType.deleted,
          propertyId: property.id,
          ownerScope: property.ownerScope,
          locationAreaId: property.locationAreaId,
        );
      },
    );
  }

  Future<void> restore({
    required Property property,
    required String userId,
    required UserRole userRole,
  }) async {
    await _performMutation(
      action: PropertyMutationAction.restore,
      job: () => _restoreUseCase(
        property: property,
        userId: userId,
        userRole: userRole,
      ),
      mutate: (updated) {
        _mutations.notify(
          PropertyMutationType.updated,
          propertyId: updated.id,
          ownerScope: updated.ownerScope,
          locationAreaId: updated.locationAreaId,
        );
      },
    );
  }

  Future<void> _performMutation({
    required PropertyMutationAction action,
    required Future<Property> Function() job,
    required void Function(Property updated) mutate,
  }) async {
    emit(PropertyMutationInProgress(action));
    try {
      final updated = await job();
      mutate(updated);
      emit(PropertyMutationSuccess(action));
    } catch (e, st) {
      final message = mapErrorMessage(e, stackTrace: st);
      emit(PropertyMutationFailure(action, message));
      rethrow;
    }
  }
}
