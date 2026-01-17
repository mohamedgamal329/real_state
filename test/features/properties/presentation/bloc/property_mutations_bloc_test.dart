import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_event.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_state.dart';

void main() {
  group('PropertyMutationsBloc', () {
    blocTest<PropertyMutationsBloc, PropertyMutationsState>(
      'notify emits in progress then success with mutation',
      build: PropertyMutationsBloc.new,
      act: (bloc) => bloc.notify(
        PropertyMutationType.added,
        propertyId: 'p1',
        ownerScope: PropertyOwnerScope.company,
        locationAreaId: 'a1',
      ),
      expect: () => [
        isA<PropertyMutationsActionInProgress>(),
        isA<PropertyMutationsActionSuccess>()
            .having((s) => s.mutation.propertyId, 'propertyId', 'p1')
            .having(
              (s) => s.mutation.ownerScope,
              'ownerScope',
              PropertyOwnerScope.company,
            )
            .having((s) => s.mutation.locationAreaId, 'locationAreaId', 'a1'),
      ],
    );

    blocTest<PropertyMutationsBloc, PropertyMutationsState>(
      'notifyError emits failure with mapped message',
      build: PropertyMutationsBloc.new,
      act: (bloc) => bloc.notifyError(Exception('fail')),
      expect: () => [
        isA<PropertyMutationsActionFailure>().having(
          (s) => s.message.isNotEmpty,
          'message not empty',
          true,
        ),
      ],
    );

    blocTest<PropertyMutationsBloc, PropertyMutationsState>(
      'previous state is preserved during failure',
      build: PropertyMutationsBloc.new,
      seed: () => PropertyMutationsActionSuccess(
        mutation: const PropertyMutation(
          type: PropertyMutationType.updated,
          tick: 1,
          propertyId: 'p1',
          ownerScope: PropertyOwnerScope.company,
        ),
      ),
      act: (bloc) => bloc.add(PropertyMutationFailed(Exception('err'))),
      expect: () => [
        isA<PropertyMutationsActionFailure>().having(
          (s) => s.latest?.propertyId,
          'previous id',
          'p1',
        ),
      ],
    );
  });
}
