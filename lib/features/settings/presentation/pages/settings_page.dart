import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
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
import 'package:real_state/core/widgets/clean_logo.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'settings',
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: CleanLogo(size: 32),
          ),
        ],
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state is SettingsFailure) {
            AppSnackbar.show(
              context,
              state.message,
              type: AppSnackbarType.error,
            );
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final isLoading = state is SettingsHydrating;
          final role = state.userRole;
          final showManageUsers = role != null && canManageUsers(role);
          final showManageLocations = role != null && canManageLocations(role);
          final showAnyAdmin = showManageUsers || showManageLocations;
          final containerColor = theme.brightness == Brightness.dark
              ? colorScheme.surfaceContainerHighest
              : Colors.white;

          return AppSkeletonizer(
            enabled: isLoading,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                kBottomNavigationBarHeight +
                    kBottomNavigationBarHeight +
                    140 + // Increased from 100 to ensure visibility
                    MediaQuery.of(context).padding.bottom,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('profile_info'.tr()),
                        dense: true,
                        leading: const AppSvgIcon(AppSVG.profile),
                        onTap: () => context.push('/settings/profile'),
                      ),
                      Divider(color: colorScheme.surfaceContainer),
                      ListTile(
                        title: Text('archive'.tr()),

                        dense: true,

                        leading: const AppSvgIcon(AppSVG.inventory),
                        onTap: () => context.push('/properties/archive'),
                      ),

                      Divider(color: colorScheme.surfaceContainer),

                      ListTile(
                        title: Text('my_added_properties'.tr()),
                        dense: true,

                        leading: const AppSvgIcon(AppSVG.mapsHomeWork),
                        onTap: () => context.push('/properties/my-added'),
                      ),
                      Divider(color: colorScheme.surfaceContainer),
                      if (showAnyAdmin) ...[
                        if (showManageUsers) ...[
                          ListTile(
                            title: Text('manage_users'.tr()),
                            dense: true,

                            leading: const AppSvgIcon(AppSVG.people),
                            onTap: () => context.push('/settings/users'),
                          ),
                          Divider(color: colorScheme.surfaceContainer),
                        ],

                        if (showManageLocations) ...[
                          ListTile(
                            title: Text('manage_locations'.tr()),
                            dense: true,

                            leading: const AppSvgIcon(AppSVG.locationOn),
                            onTap: () => context.push('/settings/locations'),
                          ),
                        ],
                      ] else if (!isLoading) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12,
                          ),
                          child: Text(
                            'section_hidden_for_role'.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('notifications'.tr()),
                        dense: true,

                        leading: const AppSvgIcon(AppSVG.notifications),
                        onTap: () => context.push('/notifications'),
                      ),
                      Divider(color: colorScheme.surfaceContainer),
                      _buildLanguageTile(context),
                      Divider(color: colorScheme.surfaceContainer),

                      _buildThemeTile(context, state, isLoading: isLoading),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                PrimaryButton(
                  label: 'sign_out'.tr(),
                  iconWidget: AppSvgIcon(AppSVG.logout),
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
      subtitle: Text(
        locale.languageCode == 'ar' ? 'arabic'.tr() : 'english'.tr(),
      ),
      leading: const AppSvgIcon(AppSVG.language),
      onTap: () async {
        final newLocale = locale.languageCode == 'ar'
            ? const Locale('en')
            : const Locale('ar');
        await context.setLocale(newLocale);
      },
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    SettingsState state, {
    required bool isLoading,
  }) {
    return ListTile(
      title: Text('theme'.tr()),
      subtitle: Text(_themeModeLabel(state.themeMode)),
      leading: const AppSvgIcon(AppSVG.theme),
      onTap: isLoading
          ? null
          : () async {
              final next = switch (state.themeMode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              await LoadingDialog.show(
                context,
                context.read<SettingsCubit>().changeTheme(next),
              );
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
