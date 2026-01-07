import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/settings/presentation/cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings',
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Image.asset('assets/images/logo.jpeg', height: 26),
          ),
        ],
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state is SettingsFailure) {
            AppSnackbar.show(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state is SettingsHydrating;
          final role = state.userRole;
          final showManageUsers = role != null && canManageUsers(role);
          final showManageLocations = role != null && canManageLocations(role);
          final showAnyAdmin = showManageUsers || showManageLocations;

          return AppSkeletonizer(
            enabled: isLoading,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildLanguageTile(context),
                _buildThemeTile(context, state, isLoading: isLoading),
                ListTile(
                  title: Text('notifications'.tr()),
                  leading: const Icon(Icons.notifications),
                  onTap: () => context.push('/notifications'),
                ),
                ListTile(
                  title: Text('archive'.tr()),
                  leading: const Icon(Icons.inventory_2_outlined),
                  onTap: () => context.push('/properties/archive'),
                ),
                ListTile(
                  title: Text('my_added_properties'.tr()),
                  leading: const Icon(Icons.maps_home_work_outlined),
                  onTap: () => context.push('/properties/my-added'),
                ),
                const Divider(),
                if (showAnyAdmin) ...[
                  if (showManageUsers)
                    ListTile(
                      title: Text('manage_users'.tr()),
                      leading: const Icon(Icons.people),
                      onTap: () => context.push('/settings/users'),
                    ),
                  if (showManageLocations)
                    ListTile(
                      title: Text('manage_locations'.tr()),
                      leading: const Icon(Icons.location_on),
                      onTap: () => context.push('/settings/locations'),
                    ),
                ] else if (!isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                    child: Text(
                      'section_hidden_for_role'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'sign_out'.tr(),
                  onPressed: () async {
                    final result = await AppConfirmDialog.show(
                      context,
                      titleKey: 'logout_title',
                      descriptionKey: 'logout_desc',
                      confirmLabelKey: 'sign_out',
                      cancelLabelKey: 'cancel',
                    );
                    if (result == AppConfirmResult.confirmed) {
                      await context.read<SettingsCubit>().signOut();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final locale = context.locale;
    return ListTile(
      title: Text('language'.tr()),
      subtitle: Text(locale.languageCode == 'ar' ? 'arabic'.tr() : 'english'.tr()),
      leading: const Icon(Icons.language),
      onTap: () async {
        final newLocale = locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
        await context.setLocale(newLocale);
      },
    );
  }

  Widget _buildThemeTile(BuildContext context, SettingsState state, {required bool isLoading}) {
    return ListTile(
      title: Text('theme'.tr()),
      subtitle: Text(_themeModeLabel(state.themeMode)),
      leading: const Icon(Icons.brightness_6),
      onTap: isLoading
          ? null
          : () async {
              final next = switch (state.themeMode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              await LoadingDialog.show(context, context.read<SettingsCubit>().changeTheme(next));
            },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'theme_system'.tr(),
      ThemeMode.light => 'theme_light'.tr(),
      ThemeMode.dark => 'theme_dark'.tr(),
    };
  }
}
