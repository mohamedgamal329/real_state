import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:real_state/core/constants/app_collections.dart';

import '../../features/access_requests/data/repositories/access_requests_repository_impl.dart';
import '../../features/access_requests/domain/repositories/access_requests_repository.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../core/auth/current_user_accessor.dart';
import '../../features/auth/domain/repositories/auth_repository_domain.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/data/repositories/location_areas_repository_impl.dart';
import '../../features/location/domain/repositories/location_areas_repository.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/data/services/fcm_service.dart';
import '../../features/notifications/domain/services/notification_delivery_service.dart';
import '../../features/notifications/domain/services/notification_messaging_service.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/brokers/data/datasources/broker_areas_remote_datasource.dart';
import '../../features/brokers/data/repositories/broker_areas_repository_impl.dart';
import '../../features/brokers/domain/repositories/broker_areas_repository.dart';
import '../../features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import '../../features/brokers/presentation/bloc/areas/broker_areas_bloc.dart';
import '../../features/brokers/presentation/controller/broker_area_properties_controller.dart';
import '../../features/brokers/presentation/controller/broker_areas_controller.dart';
import '../../features/company_areas/data/repositories/company_areas_repository_impl.dart';
import '../../features/company_areas/domain/repositories/company_areas_repository.dart';
import '../../features/company_areas/domain/usecases/get_company_areas_usecase.dart';
import '../../features/company_areas/presentation/bloc/company_areas_bloc.dart';
import '../../features/company_areas/presentation/controller/company_area_properties_controller.dart';
import '../../features/properties/data/datasources/location_area_remote_datasource.dart';
import '../../features/properties/data/repositories/properties_repository_impl.dart';
import '../../features/properties/data/services/property_upload_service_impl.dart';
import '../../features/properties/domain/repositories/properties_repository.dart';
import '../../features/properties/domain/services/property_upload_service.dart';
import '../../features/properties/domain/services/property_mutations_stream.dart';
import '../../features/properties/domain/usecases/get_broker_properties_page_usecase.dart';
import '../../features/properties/domain/usecases/get_company_properties_page_usecase.dart';
import '../../features/properties/domain/usecases/create_property_usecase.dart';
import '../../features/properties/domain/usecases/update_property_usecase.dart';
import '../../features/properties/domain/usecases/archive_property_usecase.dart';
import '../../features/properties/domain/usecases/delete_property_usecase.dart';
import '../../features/properties/domain/usecases/restore_property_usecase.dart';
import '../../features/properties/domain/usecases/share_property_pdf_usecase.dart';
import '../../features/properties/domain/usecases/upload_property_images_usecase.dart';
import '../../features/properties/domain/usecases/delete_property_images_usecase.dart';
import '../../features/properties/presentation/side_effects/property_mutations_bloc.dart';
import '../../features/properties/presentation/side_effects/property_mutation_cubit.dart';
import '../../features/properties/presentation/side_effects/property_share_cubit.dart';
import '../../features/brokers/data/datasources/brokers_remote_datasource.dart';
import '../../features/brokers/data/repositories/brokers_repository_impl.dart';
import '../../features/brokers/domain/repositories/brokers_repository.dart';
import '../../features/brokers/domain/usecases/get_brokers_usecase.dart';
import '../../features/brokers/presentation/bloc/brokers_list_bloc.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/manage_locations_cubit.dart';
import '../../features/location/domain/location_areas_cache.dart';
import '../../features/location/domain/usecases/get_location_areas_usecase.dart';
import '../../features/categories/data/repositories/categories_repository_impl.dart';
import '../../features/categories/domain/repositories/categories_repository.dart';
import '../../features/categories/domain/usecases/apply_property_filter_usecase.dart';
import '../../features/categories/domain/usecases/get_categories_usecase.dart';
import '../../features/categories/presentation/cubit/categories_cubit.dart';
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../../features/users/data/repositories/user_management_repository_impl.dart';
import '../../features/users/data/repositories/users_repository.dart';
import '../../features/users/domain/repositories/users_lookup_repository.dart';
import '../../features/users/domain/repositories/user_management_repository.dart';
import '../../features/notifications/domain/usecases/handle_foreground_notification_usecase.dart';
import '../../features/notifications/domain/usecases/resolve_property_added_targets_usecase.dart';
import '../../features/access_requests/domain/resolve_access_request_target_usecase.dart';
import '../../features/access_requests/domain/usecases/create_access_request_usecase.dart';
import '../../features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import '../../features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import '../../features/properties/domain/services/property_share_service.dart';
import '../auth/auth_repository.dart';

/// Centralized dependency container to keep single instances across the app.
class AppDi {
  AppDi() {
    _listenAuthState();
  }

  // Core services
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final AuthRepository auth = AuthRepository();
  late final FcmService fcmService = FcmService(
    firebaseMessaging,
    firestore,
    firebaseAuth,
  );
  late final NotificationMessagingService notificationMessagingService =
      fcmService;
  late final NotificationDeliveryService notificationDeliveryService =
      fcmService;

  // Auth and core dependencies
  late final AuthRemoteDataSource authRemote = _createAuthRemote();
  late final AuthRepositoryImpl authRepoImpl = _createAuthRepoImpl();
  late final CurrentUserAccessor currentUserAccessor = authRepoImpl;

  // Feature repositories and services
  late final PropertiesRepository propertiesRepository =
      PropertiesRepositoryImpl(firestore);
  late final UsersRepository usersRepository = UsersRepository(firestore);
  late final UsersLookupRepository usersLookupRepository = usersRepository;
  late final UsersRemoteDataSource usersRemoteDataSource =
      UsersRemoteDataSource(
        firestore,
        firebaseAuth,
        collection: AppCollections.users.path,
      );
  late final UserManagementRepository userManagementRepository =
      UserManagementRepositoryImpl(usersRemoteDataSource);
  late final SettingsLocalDataSource settingsLocalDataSource =
      SettingsLocalDataSource();
  late final SettingsRepository settingsRepository = SettingsRepositoryImpl(
    settingsLocalDataSource,
  );
  late final AccessRequestsRepository accessRequestsRepository =
      AccessRequestsRepositoryImpl(firestore);
  late final LocationAreaRemoteDataSource locationAreaRemoteDataSource =
      LocationAreaRemoteDataSource(firestore);
  late final LocationAreasRepository locationAreasRepository =
      LocationAreasRepositoryImpl(locationAreaRemoteDataSource);
  late final LocationRepository locationRepository = LocationRepositoryImpl(
    firestore,
  );
  late final LocationAreasCache locationAreasCache = LocationAreasCache(
    locationRepository,
    locationAreasRepository,
  );
  late final GetLocationAreasUseCase getLocationAreasUseCase =
      GetLocationAreasUseCase(locationAreasCache);
  late final CategoriesRepository categoriesRepository =
      const CategoriesRepositoryImpl();
  late final GetCategoriesUseCase getCategoriesUseCase = GetCategoriesUseCase(
    categoriesRepository,
  );
  late final ApplyPropertyFilterUseCase applyPropertyFilterUseCase =
      const ApplyPropertyFilterUseCase();
  late final ResolvePropertyAddedTargetsUseCase
  resolvePropertyAddedTargetsUseCase = ResolvePropertyAddedTargetsUseCase(
    usersLookupRepository,
  );
  late final HandleForegroundNotificationUseCase
  handleForegroundNotificationUseCase = HandleForegroundNotificationUseCase(
    propertiesRepository,
    locationAreasRepository,
    usersLookupRepository,
  );
  late final NotificationsRepository notificationsRepository =
      NotificationsRepositoryImpl(
        firestore,
        fcmService,
        resolvePropertyAddedTargetsUseCase,
      );
  late final ResolveAccessRequestTargetUseCase
  resolveAccessRequestTargetUseCase = ResolveAccessRequestTargetUseCase(
    usersLookupRepository,
  );
  late final CreateAccessRequestUseCase createAccessRequestUseCase =
      CreateAccessRequestUseCase(
        accessRequestsRepository,
        resolveAccessRequestTargetUseCase,
      );
  late final AcceptAccessRequestUseCase acceptAccessRequestUseCase =
      AcceptAccessRequestUseCase(accessRequestsRepository);
  late final RejectAccessRequestUseCase rejectAccessRequestUseCase =
      RejectAccessRequestUseCase(accessRequestsRepository);
  late final BrokersRemoteDataSource brokersRemoteDataSource =
      BrokersRemoteDataSource(usersRepository);
  late final BrokersRepository brokersRepository = BrokersRepositoryImpl(
    brokersRemoteDataSource,
  );
  late final GetBrokersUseCase getBrokersUseCase = GetBrokersUseCase(
    brokersRepository,
  );
  late final PropertyMutationsBloc propertyMutationsBloc =
      PropertyMutationsBloc();
  late final GetCompanyPropertiesPageUseCase getCompanyPropertiesPageUseCase =
      GetCompanyPropertiesPageUseCase(propertiesRepository);
  late final GetBrokerPropertiesPageUseCase getBrokerPropertiesPageUseCase =
      GetBrokerPropertiesPageUseCase(propertiesRepository, authRepoImpl);
  late final CreatePropertyUseCase createPropertyUseCase =
      CreatePropertyUseCase(propertiesRepository);
  late final UpdatePropertyUseCase updatePropertyUseCase =
      UpdatePropertyUseCase(propertiesRepository);
  late final ArchivePropertyUseCase archivePropertyUseCase =
      ArchivePropertyUseCase(propertiesRepository);
  late final DeletePropertyUseCase deletePropertyUseCase =
      DeletePropertyUseCase(propertiesRepository);
  late final RestorePropertyUseCase restorePropertyUseCase =
      RestorePropertyUseCase(propertiesRepository);
  late final PropertyShareService propertyShareService = PropertyShareService();
  late final SharePropertyPdfUseCase sharePropertyPdfUseCase =
      SharePropertyPdfUseCase(propertyShareService);
  late final PropertyUploadService propertyUploadService =
      PropertyUploadServiceImpl();
  late final UploadPropertyImagesUseCase uploadPropertyImagesUseCase =
      UploadPropertyImagesUseCase(propertyUploadService);
  late final DeletePropertyImagesUseCase deletePropertyImagesUseCase =
      DeletePropertyImagesUseCase(propertyUploadService);
  late final BrokerAreasRemoteDataSource brokerAreasRemoteDataSource =
      BrokerAreasRemoteDataSource(
        propertiesRepository,
        locationAreaRemoteDataSource,
      );
  late final BrokerAreasRepository brokerAreasRepository =
      BrokerAreasRepositoryImpl(brokerAreasRemoteDataSource);
  late final GetBrokerAreasUseCase getBrokerAreasUseCase =
      GetBrokerAreasUseCase(brokerAreasRepository, authRepoImpl);
  late final CompanyAreasRepository companyAreasRepository =
      CompanyAreasRepositoryImpl(
        propertiesRepository,
        locationAreaRemoteDataSource,
      );
  late final GetCompanyAreasUseCase getCompanyAreasUseCase =
      GetCompanyAreasUseCase(companyAreasRepository);
  late final BrokersListBloc brokersListBloc = BrokersListBloc(
    getBrokersUseCase,
    authRepoImpl,
    propertyMutationsBloc,
  );

  List<SingleChildWidget> buildProviders() {
    return [
      ..._provideCore(),
      ..._provideAuth(),
      ..._provideLocations(),
      ..._provideNotifications(),
      ..._provideAccessRequests(),
      ..._provideProperties(),
      ..._provideCategories(),
      ..._provideBrokers(),
      ..._provideCompanyAreas(),
      ..._provideSettings(),
    ];
  }

  void _listenAuthState() {
    // Keep the core AuthRepository notifier in sync with Firebase auth state.
    authRepoImpl.userChanges.listen((user) {
      auth.updateRole(user?.role);
      if (user == null) {
        auth.logOut();
      } else {
        auth.logIn();
      }
    });
  }

  // Provider groupings
  List<SingleChildWidget> _provideCore() {
    return [
      ChangeNotifierProvider<AuthRepository>.value(value: auth),
      RepositoryProvider<NotificationDeliveryService>.value(
        value: notificationDeliveryService,
      ),
      RepositoryProvider<NotificationMessagingService>.value(
        value: notificationMessagingService,
      ),
    ];
  }

  List<SingleChildWidget> _provideAuth() {
    return [
      RepositoryProvider<AuthRepositoryDomain>.value(value: authRepoImpl),
      RepositoryProvider<CurrentUserAccessor>.value(value: currentUserAccessor),
      RepositoryProvider<UsersLookupRepository>.value(
        value: usersLookupRepository,
      ),
    ];
  }

  List<SingleChildWidget> _provideLocations() {
    return [
      RepositoryProvider<LocationAreaRemoteDataSource>.value(
        value: locationAreaRemoteDataSource,
      ),
      RepositoryProvider<LocationRepository>.value(value: locationRepository),
      RepositoryProvider<GetLocationAreasUseCase>.value(
        value: getLocationAreasUseCase,
      ),
      RepositoryProvider<LocationAreasRepository>.value(
        value: locationAreasRepository,
      ),
    ];
  }

  List<SingleChildWidget> _provideNotifications() {
    return [
      RepositoryProvider<NotificationsRepository>.value(
        value: notificationsRepository,
      ),
      RepositoryProvider<ResolvePropertyAddedTargetsUseCase>.value(
        value: resolvePropertyAddedTargetsUseCase,
      ),
      RepositoryProvider<HandleForegroundNotificationUseCase>.value(
        value: handleForegroundNotificationUseCase,
      ),
    ];
  }

  List<SingleChildWidget> _provideAccessRequests() {
    return [
      RepositoryProvider<AccessRequestsRepository>.value(
        value: accessRequestsRepository,
      ),
      RepositoryProvider<ResolveAccessRequestTargetUseCase>.value(
        value: resolveAccessRequestTargetUseCase,
      ),
      RepositoryProvider<CreateAccessRequestUseCase>.value(
        value: createAccessRequestUseCase,
      ),
      RepositoryProvider<AcceptAccessRequestUseCase>.value(
        value: acceptAccessRequestUseCase,
      ),
      RepositoryProvider<RejectAccessRequestUseCase>.value(
        value: rejectAccessRequestUseCase,
      ),
    ];
  }

  List<SingleChildWidget> _provideProperties() {
    return [
      RepositoryProvider<PropertiesRepository>.value(
        value: propertiesRepository,
      ),
      RepositoryProvider<PropertyShareService>.value(
        value: propertyShareService,
      ),
      RepositoryProvider<PropertyUploadService>.value(
        value: propertyUploadService,
      ),
      RepositoryProvider<UploadPropertyImagesUseCase>.value(
        value: uploadPropertyImagesUseCase,
      ),
      RepositoryProvider<DeletePropertyImagesUseCase>.value(
        value: deletePropertyImagesUseCase,
      ),
      RepositoryProvider<CreatePropertyUseCase>.value(
        value: createPropertyUseCase,
      ),
      RepositoryProvider<UpdatePropertyUseCase>.value(
        value: updatePropertyUseCase,
      ),
      RepositoryProvider<ArchivePropertyUseCase>.value(
        value: archivePropertyUseCase,
      ),
      RepositoryProvider<RestorePropertyUseCase>.value(
        value: restorePropertyUseCase,
      ),
      RepositoryProvider<DeletePropertyUseCase>.value(
        value: deletePropertyUseCase,
      ),
      RepositoryProvider<SharePropertyPdfUseCase>.value(
        value: sharePropertyPdfUseCase,
      ),
      RepositoryProvider<PropertyMutationsBloc>.value(
        value: propertyMutationsBloc,
      ),
      RepositoryProvider<PropertyMutationsStream>.value(
        value: propertyMutationsBloc,
      ),
      BlocProvider<PropertyMutationsBloc>.value(value: propertyMutationsBloc),
      RepositoryProvider<GetCompanyPropertiesPageUseCase>.value(
        value: getCompanyPropertiesPageUseCase,
      ),
      RepositoryProvider<GetBrokerPropertiesPageUseCase>.value(
        value: getBrokerPropertiesPageUseCase,
      ),

      Provider<PropertyMutationCubit Function()>(
        create: (context) =>
            () => PropertyMutationCubit(
              context.read<ArchivePropertyUseCase>(),
              context.read<DeletePropertyUseCase>(),
              context.read<RestorePropertyUseCase>(),
              context.read<PropertyMutationsBloc>(),
            ),
      ),
      Provider<PropertyShareCubit Function()>(
        create: (context) =>
            () => PropertyShareCubit(
              context.read<PropertyShareService>(),
              context.read<SharePropertyPdfUseCase>(),
            ),
      ),
    ];
  }

  List<SingleChildWidget> _provideCategories() {
    return [
      RepositoryProvider<CategoriesRepository>.value(
        value: categoriesRepository,
      ),
      RepositoryProvider<GetCategoriesUseCase>.value(
        value: getCategoriesUseCase,
      ),
      RepositoryProvider<ApplyPropertyFilterUseCase>.value(
        value: applyPropertyFilterUseCase,
      ),
      Provider<CategoriesCubit Function()>(
        create: (context) =>
            () => CategoriesCubit(
              context.read<PropertiesRepository>(),
              context.read<GetLocationAreasUseCase>(),
              context.read<PropertyMutationsStream>(),
              context.read<AuthRepositoryDomain>(),
            ),
      ),
    ];
  }

  List<SingleChildWidget> _provideBrokers() {
    return [
      RepositoryProvider<BrokersRepository>.value(value: brokersRepository),
      RepositoryProvider<GetBrokersUseCase>.value(value: getBrokersUseCase),
      RepositoryProvider<BrokerAreasRepository>.value(
        value: brokerAreasRepository,
      ),
      RepositoryProvider<GetBrokerAreasUseCase>.value(
        value: getBrokerAreasUseCase,
      ),
      Provider<BrokerAreasBloc Function()>(
        create: (context) =>
            () => BrokerAreasBloc(
              context.read<GetBrokerAreasUseCase>(),
              context.read<LocationAreasRepository>(),
              context.read<AuthRepositoryDomain>(),
              context.read<PropertyMutationsStream>(),
            ),
      ),
      BlocProvider<BrokersListBloc>.value(value: brokersListBloc),
      Provider<BrokerAreasController>(
        create: (context) => BrokerAreasController(
          context.read<GetBrokerAreasUseCase>(),
          context.read<LocationAreasRepository>(),
          context.read<AuthRepositoryDomain>(),
          context.read<PropertyMutationsStream>(),
        ),
      ),
      Provider<BrokerAreaPropertiesController>(
        create: (context) => BrokerAreaPropertiesController(
          context.read<GetBrokerPropertiesPageUseCase>(),
          context.read<PropertyMutationsStream>(),
        ),
      ),
    ];
  }

  List<SingleChildWidget> _provideCompanyAreas() {
    return [
      RepositoryProvider<CompanyAreasRepository>.value(
        value: companyAreasRepository,
      ),
      RepositoryProvider<GetCompanyAreasUseCase>.value(
        value: getCompanyAreasUseCase,
      ),
      Provider<CompanyAreasBloc Function()>(
        create: (context) =>
            () => CompanyAreasBloc(
              context.read<GetCompanyAreasUseCase>(),
              context.read<PropertyMutationsBloc>(),
            ),
      ),
      Provider<CompanyAreaPropertiesController>(
        create: (context) => CompanyAreaPropertiesController(
          context.read<GetCompanyPropertiesPageUseCase>(),
          context.read<LocationAreasRepository>(),
          context.read<PropertyMutationsStream>(),
        ),
      ),
    ];
  }

  List<SingleChildWidget> _provideSettings() {
    return [
      RepositoryProvider<UsersRepository>.value(value: usersRepository),
      RepositoryProvider<UserManagementRepository>.value(
        value: userManagementRepository,
      ),
      RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      Provider<ManageLocationsCubit Function()>(
        create: (context) =>
            () => ManageLocationsCubit(
              context.read<LocationRepository>(),
              context.read<AuthRepositoryDomain>(),
              context.read<GetLocationAreasUseCase>(),
            ),
      ),
    ];
  }

  AuthRemoteDataSource _createAuthRemote() {
    return AuthRemoteDataSource(firebaseAuth, firestore);
  }

  AuthRepositoryImpl _createAuthRepoImpl() {
    return AuthRepositoryImpl(authRemote, fcmService: fcmService);
  }
}
