import 'package:flutter/material.dart';
import 'package:real_state/features/settings/presentation/flows/manage_users_flow.dart';
import 'package:real_state/features/settings/presentation/views/manage_users_view.dart';

class ManageUsersPage extends StatelessWidget {
  const ManageUsersPage({super.key});

  static const _flow = ManageUsersFlow();

  @override
  Widget build(BuildContext context) {
    return ManageUsersView(flow: _flow);
  }
}
