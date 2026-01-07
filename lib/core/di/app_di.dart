import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:real_state/core/constants/app_collections.dart';

import '../../features/access_requests/data/repositories/access_requests_repository.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../core/auth/current_user_accessor.dart';
import '../../features/auth/domain/repositories/auth_repository_domain.dart';
import '../../features/location/data/repositories/location_repository.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/data/services/fcm_service.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/brokers/data/datasources/broker_areas_remote_datasource.dart';
import '../../features/brokers/data/repositories/broker_areas_repository_impl.dart';
import '../../features/brokers/domain/repositories/broker_areas_repository.dart';
import '../../features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import '../../features/company_areas/data/repositories/company_areas_repository_impl.dart';
import '../../features/company_areas/domain/repositories/company_areas_repository.dart';
import '../../features/company_areas/domain/usecases/get_company_areas_usecase.dart';
import '../../features/properties/data/datasources/location_area_remote_datasource.dart';
import '../../features/properties/data/repositories/properties_repository.dart';
import '../../features/properties/domain/usecases/get_broker_properties_page_usecase.dart';
import '../../features/properties/domain/usecases/get_company_properties_page_usecase.dart';
import '../../features/properties/domain/usecases/create_property_usecase.dart';
import '../../features/properties/domain/usecases/update_property_usecase.dart';
import '../../features/properties/domain/usecases/archive_property_usecase.dart';
import '../../features/properties/domain/usecases/delete_property_usecase.dart';
import '../../features/properties/domain/usecases/share_property_pdf_usecase.dart';
import '../../features/properties/presentation/bloc/property_mutations_bloc.dart';
import '../../features/brokers/data/datasources/brokers_remote_datasource.dart';
import '../../features/brokers/data/repositories/brokers_repository_impl.dart';
import '../../features/brokers/domain/repositories/brokers_repository.dart';
import '../../features/brokers/domain/usecases/get_brokers_usecase.dart';
import '../../features/brokers/presentation/bloc/brokers_list_bloc.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/location/domain/location_areas_cache.dart';
import '../../features/location/domain/usecases/get_location_areas_usecase.dart';
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../../features/users/data/repositories/user_management_repository_impl.dart';
import '../../features/users/data/repositories/users_repository.dart';
import '../../features/users/domain/repositories/user_management_repository.dart';
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

  // Auth and core dependencies
  late final AuthRemoteDataSource authRemote = _createAuthRemote();
  late final AuthRepositoryImpl authRepoImpl = _createAuthRepoImpl();
  late final CurrentUserAccessor currentUserAccessor = authRepoImpl;

  // Feature repositories and services
  late final PropertiesRepository propertiesRepository = PropertiesRepository(
    firestore,
  );
  late final UsersRepository usersRepository = UsersRepository(firestore);
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
      AccessRequestsRepository(firestore);
  late final LocationAreaRemoteDataSource locationAreaRemoteDataSource =
      LocationAreaRemoteDataSource(firestore);
  late final LocationRepository locationRepository = LocationRepository(
    firestore,
  );
  late final LocationAreasCache locationAreasCache = LocationAreasCache(
    locationRepository,
    locationAreaRemoteDataSource,
  );
  late final GetLocationAreasUseCase getLocationAreasUseCase =
      GetLocationAreasUseCase(locationAreasCache);
  late final ResolvePropertyAddedTargetsUseCase
  resolvePropertyAddedTargetsUseCase = ResolvePropertyAddedTargetsUseCase(
    usersRepository,
  );
  late final NotificationsRepository notificationsRepository =
      NotificationsRepositoryImpl(
        firestore,
        fcmService,
        resolvePropertyAddedTargetsUseCase,
      );
  late final ResolveAccessRequestTargetUseCase
  resolveAccessRequestTargetUseCase = ResolveAccessRequestTargetUseCase(
    usersRepository,
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
  late final PropertyShareService propertyShareService = PropertyShareService();
  late final SharePropertyPdfUseCase sharePropertyPdfUseCase =
      SharePropertyPdfUseCase(propertyShareService);
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
      RepositoryProvider<FcmService>.value(value: fcmService),
    ];
  }

  List<SingleChildWidget> _provideAuth() {
    return [
      RepositoryProvider<AuthRepositoryDomain>.value(value: authRepoImpl),
      RepositoryProvider<CurrentUserAccessor>.value(value: currentUserAccessor),
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
      RepositoryProvider<CreatePropertyUseCase>.value(
        value: createPropertyUseCase,
      ),
      RepositoryProvider<UpdatePropertyUseCase>.value(
        value: updatePropertyUseCase,
      ),
      RepositoryProvider<ArchivePropertyUseCase>.value(
        value: archivePropertyUseCase,
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
      BlocProvider<PropertyMutationsBloc>.value(value: propertyMutationsBloc),
      RepositoryProvider<GetCompanyPropertiesPageUseCase>.value(
        value: getCompanyPropertiesPageUseCase,
      ),
      RepositoryProvider<GetBrokerPropertiesPageUseCase>.value(
        value: getBrokerPropertiesPageUseCase,
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
      BlocProvider<BrokersListBloc>.value(value: brokersListBloc),
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
    ];
  }

  List<SingleChildWidget> _provideSettings() {
    return [
      RepositoryProvider<UsersRepository>.value(value: usersRepository),
      RepositoryProvider<UserManagementRepository>.value(
        value: userManagementRepository,
      ),
      RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
    ];
  }

  AuthRemoteDataSource _createAuthRemote() {
    return AuthRemoteDataSource(firebaseAuth, firestore);
  }

  AuthRepositoryImpl _createAuthRepoImpl() {
    return AuthRepositoryImpl(
      authRemote,
      fcmService: fcmService,
    );
  }
}
