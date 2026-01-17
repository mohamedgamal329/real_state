import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/features/settings/presentation/cubit/profile_info_cubit.dart';
import 'package:real_state/features/settings/presentation/widgets/change_password_dialog.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileInfoCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'profile_info'.tr()),
      body: BlocConsumer<ProfileInfoCubit, ProfileInfoState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackbar.show(
              context,
              state.errorMessage!,
              type: AppSnackbarType.error,
            );
          }
        },
        builder: (context, state) {
          final name = state.name?.trim();
          final email = state.email?.trim();

          return AppSkeletonizer(
            enabled: state.isLoading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoRow(
                  label: 'profile_name'.tr(),
                  value: (name == null || name.isEmpty) ? '-' : name,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'profile_email'.tr(),
                  value: (email == null || email.isEmpty) ? '-' : email,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'change_password'.tr(),
                  onPressed: (email == null || email.isEmpty)
                      ? null
                      : () => _onChangePassword(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onChangePassword(BuildContext context) async {
    final result = await ChangePasswordDialog.show(context);
    if (result == null) return;
    if (!context.mounted) return;

    try {
      await LoadingDialog.show(
        context,
        context.read<ProfileInfoCubit>().changePasswordInApp(
          currentPassword: result.currentPassword,
          newPassword: result.newPassword,
        ),
      );
      if (!context.mounted) return;
      AppSnackbar.show(context, 'password_changed_success'.tr());
    } catch (e, st) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        mapErrorMessage(e, stackTrace: st),
        type: AppSnackbarType.error,
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
