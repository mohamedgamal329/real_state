import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/brokers/domain/entities/broker_area.dart';

abstract class BrokerAreasRepository {
  Future<List<BrokerArea>> fetchBrokerAreas(
    String brokerId, {
    UserRole? role,
    Map<String, String> cachedAreaNames = const {},
  });
}
