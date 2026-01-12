import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:real_state/core/constants/user_role.dart';

@immutable
class ManagedUser extends Equatable {
  final String id;
  final String? name;
  final String? email;
  final UserRole role;
  final String? phone;
  final String? jobTitle;
  final bool active;

  const ManagedUser({
    required this.id,
    required this.role,
    this.name,
    this.email,
    this.phone,
    this.jobTitle,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, name, email, role, phone, jobTitle, active];
}
