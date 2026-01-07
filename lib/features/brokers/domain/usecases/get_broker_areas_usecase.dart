import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/entities/broker_area.dart';
import 'package:real_state/features/brokers/domain/repositories/broker_areas_repository.dart';

class GetBrokerAreasUseCase {
  final BrokerAreasRepository _repository;
  final AuthRepositoryDomain _auth;

  GetBrokerAreasUseCase(this._repository, this._auth);

  Future<List<BrokerArea>> call(String brokerId, {Map<String, String> cachedAreaNames = const {}}) {
    return _auth.userChanges.first.then((user) async {
      if (user?.role == UserRole.collector) {
        throw const LocalizedException('access_denied_broker_data');
      }
      return _repository.fetchBrokerAreas(
        brokerId,
        role: user?.role,
        cachedAreaNames: cachedAreaNames,
      );
    });
  }
}
