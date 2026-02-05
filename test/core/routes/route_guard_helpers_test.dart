import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

void main() {
  test('collector cannot access broker routes', () {
    expect(canAccessBrokersRoutes(UserRole.collector), isFalse);
    expect(canAccessBrokersRoutes(UserRole.broker), isTrue);
    expect(canAccessBrokersRoutes(UserRole.owner), isTrue);
  });
}
