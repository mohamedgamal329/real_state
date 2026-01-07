class Broker {
  final String id;
  final String? name;
  final String? email;
  final bool active;

  const Broker({required this.id, this.name, this.email, this.active = true});
}
