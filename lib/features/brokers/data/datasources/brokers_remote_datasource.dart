import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';

class BrokersRemoteDataSource {
  final UsersRepository _usersRepository;

  BrokersRemoteDataSource(this._usersRepository);

  Future<List<Broker>> fetchBrokers() async {
    final users = await _usersRepository.fetchUsers(role: UserRole.broker);
    return users
        .map(
          (u) =>
              Broker(id: u.id, name: u.name, email: u.email, active: u.active),
        )
        .toList();
  }
}
