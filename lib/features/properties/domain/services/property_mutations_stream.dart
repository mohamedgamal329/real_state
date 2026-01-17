import 'package:real_state/features/properties/domain/models/property_mutation.dart';

abstract class PropertyMutationsStream {
  Stream<PropertyMutation> get mutationStream;
}
