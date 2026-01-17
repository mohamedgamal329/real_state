// no direct material import needed here
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/features/brokers/presentation/pages/broker_areas_page.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_bloc.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_bloc.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutation_cubit.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/settings/presentation/cubit/profile_info_cubit.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

import '../../core/auth/auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository_domain.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/brokers/presentation/pages/broker_area_properties/broker_area_properties_page.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import '../../features/categories/presentation/pages/categories_filter_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/company_areas/presentation/pages/company_areas_page.dart';
import '../../features/company_areas/presentation/pages/company_area_properties/company_area_properties_page.dart';
import '../../features/main_shell/presentation/pages/main_shell_page.dart';
import '../../features/models/entities/property.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/properties/presentation/pages/filtered_properties_page.dart';
import '../../features/properties/presentation/pages/property_editor_page.dart';
import '../../features/properties/presentation/pages/property_image_viewer/property_image_viewer_page.dart';
import '../../features/properties/presentation/pages/property_detail/property_page.dart';
import '../../features/settings/presentation/pages/archive_properties/archive_properties_page.dart';
import '../../features/settings/presentation/pages/manage_locations_page.dart';
import '../../features/settings/presentation/pages/manage_users_page.dart';
import '../../features/settings/presentation/pages/my_added_properties/my_added_properties_page.dart';
import '../../features/settings/presentation/pages/profile_info_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'not_found_page.dart';
import 'route_guards.dart';

/// Creates a GoRouter configured with redirects that depend on
/// the provided [AuthRepository]. The router refreshes whenever the
/// auth state changes (via ChangeNotifier).
class AppRouter {
  AppRouter._();

  static GoRouter create(AuthRepository auth) {
    const publicRoutes = {'/', '/login'};
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const SplashPage()),
        GoRoute(path: '/login', builder: (c, s) => LoginPage()),
        GoRoute(path: '/main', builder: (c, s) => const MainShellPage()),
        GoRoute(
          path: '/notifications',
          builder: (c, s) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/settings/users',
          builder: (c, s) {
            if (!canManageUsers(auth.role)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppSnackbar.show(
                  c,
                  'access_denied'.tr(),
                  type: AppSnackbarType.error,
                );
                c.go('/main');
              });
              return const SizedBox.shrink();
            }
            return const ManageUsersPage();
          },
        ),
        GoRoute(
          path: '/settings/locations',
          builder: (c, s) {
            if (!canManageLocations(auth.role)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppSnackbar.show(
                  c,
                  'access_denied'.tr(),
                  type: AppSnackbarType.error,
                );
                c.go('/main');
              });
              return const SizedBox.shrink();
            }
            return const ManageLocationsPage();
          },
        ),
        GoRoute(
          path: '/settings/profile',
          builder: (c, s) => BlocProvider(
            create: (context) => ProfileInfoCubit(
              context.read<AuthRepositoryDomain>(),
              context.read<UserManagementRepository>(),
            ),
            child: const ProfileInfoPage(),
          ),
        ),
        GoRoute(
          path: '/property/new',
          builder: (c, s) => const PropertyEditorPage(),
        ),
        GoRoute(
          path: '/property/:id/edit',
          builder: (c, s) => PropertyEditorPage(property: s.extra as Property?),
        ),
        GoRoute(
          path: '/property/:id',
          builder: (c, s) {
            final readOnly =
                s.extra is Map && (s.extra as Map)['readOnly'] == true;
            return PropertyPage(
              id: s.pathParameters['id']!,
              readOnly: readOnly,
            );
          },
        ),
        GoRoute(
          path: '/property/:id/images',
          builder: (c, s) {
            final args = s.extra as PropertyImageViewerArgs?;
            if (args == null) return const NotFoundPage();
            return PropertyImageViewerPage(args: args);
          },
        ),
        GoRoute(
          path: '/broker/:id',
          builder: (c, s) {
            // Reusing existing guard logic if needed, or keeping it open if this page is public?
            // Assuming access control is same as areas page for now.
            if (!canAccessBrokersRoutes(auth.role)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppSnackbar.show(
                  c,
                  'access_denied'.tr(),
                  type: AppSnackbarType.error,
                );
                c.go('/main');
              });
              return const SizedBox.shrink();
            }
            String? brokerName;
            if (s.extra is Map) {
              final extra = s.extra as Map;
              if (extra['name'] is String) {
                brokerName = extra['name'] as String;
              }
            }
            return BrokerAreasPage(
              brokerId: s.pathParameters['id']!,
              brokerName: brokerName,
            );
          },
          routes: [
            GoRoute(
              path: 'areas',
              redirect: (context, state) =>
                  '/broker/${state.pathParameters['id']}',
            ),
          ],
        ),
        GoRoute(
          path: '/broker/:brokerId/area/:areaId',
          builder: (c, s) {
            if (!canAccessBrokersRoutes(auth.role)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppSnackbar.show(
                  c,
                  'access_denied'.tr(),
                  type: AppSnackbarType.error,
                );
                c.go('/main');
              });
              return const SizedBox.shrink();
            }
            final brokerId = s.pathParameters['brokerId']!;
            final areaId = s.pathParameters['areaId']!;
            String areaName = '';
            String brokerName = '';
            if (s.extra is String) {
              areaName = s.extra as String;
            } else if (s.extra is Map) {
              final extra = s.extra as Map;
              if (extra['areaName'] is String) {
                areaName = extra['areaName'] as String;
              }
              if (extra['brokerName'] is String) {
                brokerName = extra['brokerName'] as String;
              }
            }
            return BrokerAreaPropertiesPage(
              brokerId: brokerId,
              areaId: areaId,
              areaName: areaName,
              brokerName: brokerName,
            );
          },
        ),
        GoRoute(
          path: '/filters/results',
          builder: (c, s) {
            final filter = s.extra as PropertyFilter?;
            if (filter == null) return const NotFoundPage();
            return FilteredPropertiesPage(filter: filter);
          },
        ),
        GoRoute(
          path: '/filters/categories',
          builder: (c, s) {
            final cubit = s.extra is CategoriesCubit
                ? s.extra as CategoriesCubit
                : null;
            if (cubit == null) return const NotFoundPage();
            return BlocProvider.value(
              value: cubit,
              child: const CategoriesFilterPage(),
            );
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (c, s) {
            final cubit = s.extra is CategoriesCubit
                ? s.extra as CategoriesCubit
                : null;
            if (cubit == null) return const NotFoundPage();
            return BlocProvider.value(
              value: cubit,
              child: const CategoriesPage(),
            );
          },
        ),
        GoRoute(
          path: '/company/area/:id',
          builder: (c, s) => CompanyAreaPropertiesPage(
            areaId: s.pathParameters['id']!,
            areaName: (s.extra as String?) ?? '',
          ),
        ),
        GoRoute(
          path: '/properties/archive',
          builder: (c, s) {
            final mutationCubitFactory = c
                .read<PropertyMutationCubit Function()>();
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => ArchivePropertiesBloc(
                    context.read<PropertiesRepository>(),
                    context.read<LocationAreasRepository>(),
                    context.read<PropertyMutationsBloc>(),
                  ),
                ),
                BlocProvider<PropertyMutationCubit>(
                  create: (_) => mutationCubitFactory(),
                ),
              ],
              child: const ArchivePropertiesPage(),
            );
          },
        ),
        GoRoute(
          path: '/company/areas',
          builder: (c, s) {
            final bloc = s.extra is CompanyAreasBloc
                ? s.extra as CompanyAreasBloc
                : null;
            if (bloc == null) return const NotFoundPage();
            return BlocProvider.value(
              value: bloc,
              child: const CompanyAreasPage(),
            );
          },
        ),
        GoRoute(
          path: '/properties/my-added',
          builder: (c, s) => const MyAddedPropertiesPage(),
        ),
      ],
      errorBuilder: (context, state) => const NotFoundPage(),
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final goingTo = state.matchedLocation;

        final isPublic = publicRoutes.contains(goingTo);
        if (!loggedIn && !isPublic) return '/login';
        if (loggedIn && goingTo == '/login') return '/main';

        final role = auth.role;
        final guardRedirect = RouteGuards.guardCollector(
          context: context,
          location: goingTo,
          role: role,
        );
        if (guardRedirect != null) return guardRedirect;
        return null;
      },
    );
  }
}
