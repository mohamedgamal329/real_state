import 'package:real_state/features/brokers/data/datasources/brokers_remote_datasource.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/brokers/domain/repositories/brokers_repository.dart';

class BrokersRepositoryImpl implements BrokersRepository {
  final BrokersRemoteDataSource _remote;

  BrokersRepositoryImpl(this._remote);

  @override
  Future<List<Broker>> fetchBrokers() {
    return _remote.fetchBrokers();
  }
}
