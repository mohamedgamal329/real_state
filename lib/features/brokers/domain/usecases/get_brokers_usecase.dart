import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/brokers/domain/repositories/brokers_repository.dart';

class GetBrokersUseCase {
  final BrokersRepository _repository;

  GetBrokersUseCase(this._repository);

  Future<List<Broker>> call() => _repository.fetchBrokers();
}
