import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/domain/services/notification_delivery_service.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/location/data/repositories/location_areas_repository_impl.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';
import 'package:real_state/features/properties/domain/usecases/archive_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/delete_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/restore_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/share_property_pdf_usecase.dart';
import 'package:real_state/features/categories/domain/usecases/apply_property_filter_usecase.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutation_cubit.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_share_cubit.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';
import 'package:real_state/features/users/domain/repositories/users_lookup_repository.dart';

import '../features/fake_auth_repo/fake_auth_repo.dart';
import '../fakes/fake_repositories.dart';
import '../fakes/fake_services.dart';
import 'test_pump_utils.dart';

export 'test_pump_utils.dart';

class TestAppDependencies {
  TestAppDependencies({
    AuthRepositoryDomain? authRepositoryOverride,
    PropertiesRepository? propertiesRepositoryOverride,
    AccessRequestsRepository? accessRequestsRepositoryOverride,
    NotificationsRepository? notificationsRepositoryOverride,
    PropertyShareService? propertyShareServiceOverride,
    UsersRepository? usersRepositoryOverride,
    UsersLookupRepository? usersLookupRepositoryOverride,
    PropertyMutationsBloc? propertyMutationsBlocOverride,
    SharePropertyPdfUseCase? sharePropertyPdfUseCaseOverride,
    RestorePropertyUseCase? restorePropertyUseCaseOverride,
    NotificationMessagingService? notificationMessagingServiceOverride,
    NotificationDeliveryService? notificationDeliveryServiceOverride,
    LocationAreaRemoteDataSource? locationAreaDataSourceOverride,
    LocationAreasRepository? locationAreasRepositoryOverride,
    AcceptAccessRequestUseCase? acceptAccessRequestUseCaseOverride,
    RejectAccessRequestUseCase? rejectAccessRequestUseCaseOverride,
    ApplyPropertyFilterUseCase? applyPropertyFilterUseCaseOverride,
  }) {
    final resolvedAuth = authRepositoryOverride ?? FakeAuthRepo(_defaultUser);
    final resolvedProperties =
        propertiesRepositoryOverride ?? FakePropertiesRepository();
    final resolvedAccess =
        accessRequestsRepositoryOverride ?? FakeAccessRequestsRepository();
    final resolvedNotifications =
        notificationsRepositoryOverride ?? FakeNotificationsRepository();
    final resolvedUsers = usersRepositoryOverride ?? FakeUsersRepository();
    final resolvedUsersLookup = usersLookupRepositoryOverride ?? resolvedUsers;
    final resolvedMutations =
        propertyMutationsBlocOverride ?? PropertyMutationsBloc();
    final resolvedShareService =
        propertyShareServiceOverride ?? PropertyShareService();
    final resolvedSharePdfUseCase =
        sharePropertyPdfUseCaseOverride ??
        SharePropertyPdfUseCase(resolvedShareService);
    final resolvedArchiveUseCase = ArchivePropertyUseCase(resolvedProperties);
    final resolvedDeleteUseCase = DeletePropertyUseCase(resolvedProperties);
    final resolvedRestoreUseCase =
        restorePropertyUseCaseOverride ??
        RestorePropertyUseCase(resolvedProperties);
    final resolvedMessaging =
        notificationMessagingServiceOverride ?? FakeFcmService();
    final resolvedDelivery =
        notificationDeliveryServiceOverride ?? FakeFcmService();
    final resolvedLocationSource =
        locationAreaDataSourceOverride ?? FakeLocationAreaRemoteDataSource();
    final resolvedLocationAreasRepository =
        locationAreasRepositoryOverride ??
        LocationAreasRepositoryImpl(resolvedLocationSource);
    final resolvedAccept =
        acceptAccessRequestUseCaseOverride ??
        AcceptAccessRequestUseCase(resolvedAccess);
    final resolvedReject =
        rejectAccessRequestUseCaseOverride ??
        RejectAccessRequestUseCase(resolvedAccess);
    final resolvedApplyFilter =
        applyPropertyFilterUseCaseOverride ??
        const ApplyPropertyFilterUseCase();

    authRepository = resolvedAuth;
    propertiesRepository = resolvedProperties;
    accessRequestsRepository = resolvedAccess;
    notificationsRepository = resolvedNotifications;
    usersRepository = resolvedUsers;
    usersLookupRepository = resolvedUsersLookup;
    propertyMutationsBloc = resolvedMutations;
    propertyShareService = resolvedShareService;
    sharePropertyPdfUseCase = resolvedSharePdfUseCase;
    restorePropertyUseCase = resolvedRestoreUseCase;
    archivePropertyUseCase = resolvedArchiveUseCase;
    deletePropertyUseCase = resolvedDeleteUseCase;
    notificationMessagingService = resolvedMessaging;
    notificationDeliveryService = resolvedDelivery;
    locationAreaRemoteDataSource = resolvedLocationSource;
    locationAreasRepository = resolvedLocationAreasRepository;
    acceptAccessRequestUseCase = resolvedAccept;
    rejectAccessRequestUseCase = resolvedReject;
    applyPropertyFilterUseCase = resolvedApplyFilter;
  }

  static final _defaultUser = const UserEntity(
    id: 'owner1',
    email: 'owner@example.com',
    name: 'Owner',
    role: UserRole.owner,
  );

  late final AuthRepositoryDomain authRepository;
  late final PropertiesRepository propertiesRepository;
  late final AccessRequestsRepository accessRequestsRepository;
  late final NotificationsRepository notificationsRepository;
  late final UsersRepository usersRepository;
  late final UsersLookupRepository usersLookupRepository;
  late final PropertyShareService propertyShareService;
  late final PropertyMutationsBloc propertyMutationsBloc;
  late final SharePropertyPdfUseCase sharePropertyPdfUseCase;
  late final RestorePropertyUseCase restorePropertyUseCase;
  late final ArchivePropertyUseCase archivePropertyUseCase;
  late final DeletePropertyUseCase deletePropertyUseCase;
  late final NotificationMessagingService notificationMessagingService;
  late final NotificationDeliveryService notificationDeliveryService;
  late final LocationAreaRemoteDataSource locationAreaRemoteDataSource;
  late final LocationAreasRepository locationAreasRepository;
  late final AcceptAccessRequestUseCase acceptAccessRequestUseCase;
  late final RejectAccessRequestUseCase rejectAccessRequestUseCase;
  late final ApplyPropertyFilterUseCase applyPropertyFilterUseCase;

  List<SingleChildWidget> get providers => [
    RepositoryProvider<AuthRepositoryDomain>.value(value: authRepository),
    RepositoryProvider<PropertiesRepository>.value(value: propertiesRepository),
    RepositoryProvider<AccessRequestsRepository>.value(
      value: accessRequestsRepository,
    ),
    RepositoryProvider<NotificationsRepository>.value(
      value: notificationsRepository,
    ),
    RepositoryProvider<UsersRepository>.value(value: usersRepository),
    RepositoryProvider<UsersLookupRepository>.value(
      value: usersLookupRepository,
    ),
    RepositoryProvider<NotificationMessagingService>.value(
      value: notificationMessagingService,
    ),
    RepositoryProvider<NotificationDeliveryService>.value(
      value: notificationDeliveryService,
    ),
    RepositoryProvider<ApplyPropertyFilterUseCase>.value(
      value: applyPropertyFilterUseCase,
    ),
    RepositoryProvider<PropertyShareService>.value(value: propertyShareService),
    RepositoryProvider<PropertyMutationsBloc>.value(
      value: propertyMutationsBloc,
    ),
    RepositoryProvider<SharePropertyPdfUseCase>.value(
      value: sharePropertyPdfUseCase,
    ),
    RepositoryProvider<RestorePropertyUseCase>.value(
      value: restorePropertyUseCase,
    ),
    RepositoryProvider<LocationAreaRemoteDataSource>.value(
      value: locationAreaRemoteDataSource,
    ),
    RepositoryProvider<LocationAreasRepository>.value(
      value: locationAreasRepository,
    ),
    RepositoryProvider<AcceptAccessRequestUseCase>.value(
      value: acceptAccessRequestUseCase,
    ),
    RepositoryProvider<RejectAccessRequestUseCase>.value(
      value: rejectAccessRequestUseCase,
    ),
    Provider<PropertyMutationCubit Function()>(
      create: (context) =>
          () => PropertyMutationCubit(
            archivePropertyUseCase,
            deletePropertyUseCase,
            restorePropertyUseCase,
            context.read<PropertyMutationsBloc>(),
          ),
    ),
    Provider<PropertyShareCubit Function()>(
      create: (context) =>
          () =>
              PropertyShareCubit(propertyShareService, sharePropertyPdfUseCase),
    ),
  ];
}

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.child,
    this.dependencies,
    this.additionalProviders = const [],
  });

  final Widget child;
  final TestAppDependencies? dependencies;
  final List<SingleChildWidget> additionalProviders;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies ?? TestAppDependencies();
    return EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MultiProvider(
          providers: [...deps.providers, ...additionalProviders],
          child: MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: child,
          ),
        ),
      ),
    );
  }
}

class _TestAppRouter extends StatelessWidget {
  const _TestAppRouter({
    required this.router,
    this.dependencies,
    this.additionalProviders = const [],
  });

  final GoRouter router;
  final TestAppDependencies? dependencies;
  final List<SingleChildWidget> additionalProviders;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies ?? TestAppDependencies();
    return EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MultiProvider(
          providers: [...deps.providers, ...additionalProviders],
          child: MaterialApp.router(
            routerConfig: router,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          ),
        ),
      ),
    );
  }
}

Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  TestAppDependencies? dependencies,
  List<SingleChildWidget> additionalProviders = const [],
  bool disableAnimations = true,
  GoRouter? router,
}) async {
  final app = router == null
      ? TestApp(
          dependencies: dependencies,
          additionalProviders: additionalProviders,
          child: child,
        )
      : _TestAppRouter(
          dependencies: dependencies,
          additionalProviders: additionalProviders,
          router: router,
        );
  final widget = disableAnimations
      ? TickerMode(enabled: false, child: app)
      : app;
  await tester.pumpWidget(widget);
  await pumpLocalization(tester);
}
