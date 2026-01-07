import 'package:equatable/equatable.dart';

class BrokerArea extends Equatable {
  final String id;
  final String name;
  final int propertyCount;

  const BrokerArea({
    required this.id,
    required this.name,
    required this.propertyCount,
  });

  @override
  List<Object?> get props => [id, name, propertyCount];
}
