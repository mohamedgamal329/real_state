import 'package:real_state/features/brokers/domain/entities/broker.dart';

abstract class BrokersRepository {
  Future<List<Broker>> fetchBrokers();
}
