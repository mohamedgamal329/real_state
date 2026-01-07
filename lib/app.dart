import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/di/app_di.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository_domain.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/load_theme_mode_usecase.dart';
import 'features/settings/domain/usecases/update_theme_mode_usecase.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/users/domain/repositories/user_management_repository.dart';
import 'features/notifications/presentation/notification_coordinator.dart';

class App extends StatelessWidget {
  App({super.key, AppDi? di}) : _di = di ?? AppDi();

  // Hold dependencies once for the app lifetime.
  final AppDi _di;
  late final GoRouter _router = AppRouter.create(_di.auth);
  final NotificationCoordinator _notificationCoordinator =
      NotificationCoordinator();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _di.buildProviders(),

      child: Builder(
        builder: (context) {
          final theme = AppTheme.light();
          final dark = AppTheme.dark();

          unawaited(
            _notificationCoordinator.configure(
              context: context,
              router: _router,
            ),
          );

          return BlocProvider(
            create: (_) => SettingsCubit(
              context.read<AuthRepositoryDomain>(),
              context.read<UserManagementRepository>(),
              LoadThemeModeUseCase(context.read<SettingsRepository>()),
              UpdateThemeModeUseCase(context.read<SettingsRepository>()),
            ),
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                return MaterialApp.router(
                  key: ValueKey(context.locale.languageCode),
                  onGenerateTitle: (context) => 'app_title'.tr(),
                  theme: theme,
                  darkTheme: dark,
                  debugShowCheckedModeBanner: false,
                  themeMode: state.themeMode,
                  routeInformationParser: _router.routeInformationParser,
                  routeInformationProvider: _router.routeInformationProvider,
                  routerDelegate: _router.routerDelegate,
                  localizationsDelegates: context.localizationDelegates,
                  supportedLocales: context.supportedLocales,
                  locale: context.locale,
                  builder: (context, child) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      child: child,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
