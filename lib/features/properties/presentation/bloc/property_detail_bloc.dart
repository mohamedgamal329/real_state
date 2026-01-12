import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/resolve_access_request_target_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/create_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';
import 'package:real_state/features/properties/domain/usecases/archive_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/delete_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/share_property_pdf_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_detail_event.dart';
import 'package:real_state/features/properties/presentation/bloc/property_detail_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_state.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';

class PropertyDetailBloc extends Bloc<PropertyDetailEvent, PropertyDetailState> {
  final PropertiesRepository _propertiesRepository;
  final AccessRequestsRepository _accessRequestsRepository;
  final AuthRepositoryDomain _authRepository;
  final NotificationsRepository _notificationsRepository;
  final PropertyShareService _shareService;
  final UsersRepository _usersRepository;
  final PropertyMutationsBloc _mutations;
  final CreateAccessRequestUseCase _createAccessRequestUseCase;
  final ArchivePropertyUseCase _archivePropertyUseCase;
  final DeletePropertyUseCase _deletePropertyUseCase;
  final SharePropertyPdfUseCase _sharePropertyPdfUseCase;
  final Map<String, String?> _userNameCache = {};

  StreamSubscription<AccessRequest?>? _imagesReqSub;
  StreamSubscription<AccessRequest?>? _phoneReqSub;
  StreamSubscription<AccessRequest?>? _locationReqSub;
  StreamSubscription<PropertyMutation?>? _mutationSub;
  String? _currentPropertyId;

  PropertyDetailBloc(
    this._propertiesRepository,
    this._accessRequestsRepository,
    this._authRepository,
    this._notificationsRepository,
    this._shareService,
    UsersRepository usersRepository,
    this._mutations, {
    ResolveAccessRequestTargetUseCase? resolveAccessTargetUseCase,
    CreateAccessRequestUseCase? createAccessRequestUseCase,
    ArchivePropertyUseCase? archivePropertyUseCase,
    DeletePropertyUseCase? deletePropertyUseCase,
    SharePropertyPdfUseCase? sharePropertyPdfUseCase,
  }) : _usersRepository = usersRepository,
       _createAccessRequestUseCase =
           createAccessRequestUseCase ??
           CreateAccessRequestUseCase(
             _accessRequestsRepository,
             resolveAccessTargetUseCase ?? ResolveAccessRequestTargetUseCase(usersRepository),
           ),
       _archivePropertyUseCase =
           archivePropertyUseCase ?? ArchivePropertyUseCase(_propertiesRepository),
       _deletePropertyUseCase =
           deletePropertyUseCase ?? DeletePropertyUseCase(_propertiesRepository),
       _sharePropertyPdfUseCase = sharePropertyPdfUseCase ?? SharePropertyPdfUseCase(_shareService),
       super(const PropertyDetailInitial()) {
    on<PropertyDetailStarted>(_onStarted);
    on<PropertyAccessRequested>(_onAccessRequested);
    on<PropertyArchiveRequested>(_onArchive);
    on<PropertyDeleteRequested>(_onDelete);
    on<PropertyShareImagesRequested>(_onShareImages);
    on<PropertySharePdfRequested>(_onSharePdf);
    on<PropertyImagesLoadMoreRequested>(_onImagesLoadMore);
    on<PropertyInfoCleared>(_onInfoCleared);
    on<PropertyExternalMutationReceived>(_onExternalMutation);
    on<PropertyAccessRequestUpdated>(_onAccessRequestUpdated);

    _mutationSub = _mutations.mutationStream.listen((event) {
      final id = _currentPropertyId;
      if (id != null && (event.propertyId == null || event.propertyId == id)) {
        add(PropertyExternalMutationReceived(id));
      }
    });
  }

  Future<void> _onStarted(PropertyDetailStarted event, Emitter<PropertyDetailState> emit) async {
    _cancelStreams();
    _currentPropertyId = event.propertyId;
    emit(const PropertyDetailLoading());
    try {
      final user = await _authRepository.userChanges.first;
      final property = await _propertiesRepository.getById(event.propertyId);
      final userId = user?.id;
      final role = user?.role;
      final creatorId = property?.createdBy ?? '';
      final creatorName = creatorId.isNotEmpty ? await _resolveCreatorName(creatorId) : null;
      final imagesToShow = property != null
          ? (property.imageUrls.length >= 3 ? 3 : property.imageUrls.length)
          : 0;

      final loaded = PropertyDetailLoaded(
        property:
            property ??
            Property(
              id: event.propertyId,
              title: null,
              description: null,
              price: null,
              purpose: PropertyPurpose.sale,
              rooms: null,
              kitchens: null,
              floors: null,
              hasPool: false,
              locationAreaId: null,
              coverImageUrl: null,
              imageUrls: const [],
              ownerPhoneEncryptedOrHiddenStored: null,
              locationUrl: null,
              isImagesHidden: false,
              status: PropertyStatus.active,
              isDeleted: false,
              createdBy: userId ?? 'unknown',
              ownerScope: PropertyOwnerScope.company,
              brokerId: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              updatedBy: userId,
            ),
        userId: userId,
        userRole: role,
        imagesToShow: imagesToShow,
        creatorName: creatorName,
      );

      var emitted = loaded;
      if (userId != null) {
        final imagesGranted =
            await _accessRequestsRepository.fetchLatestAcceptedRequest(
              propertyId: event.propertyId,
              requesterId: userId,
              type: AccessRequestType.images,
            ) !=
            null;
        final phoneGranted =
            await _accessRequestsRepository.fetchLatestAcceptedRequest(
              propertyId: event.propertyId,
              requesterId: userId,
              type: AccessRequestType.phone,
            ) !=
            null;
        final locationGranted =
            await _accessRequestsRepository.fetchLatestAcceptedRequest(
              propertyId: event.propertyId,
              requesterId: userId,
              type: AccessRequestType.location,
            ) !=
            null;
        emitted = loaded.copyWith(
          imagesAccessGranted: imagesGranted,
          phoneAccessGranted: phoneGranted,
          locationAccessGranted: locationGranted,
        );
      }

      emit(emitted);

      if (emitted.userRole == UserRole.collector &&
          emitted.property.ownerScope == PropertyOwnerScope.broker) {
        emit(PropertyDetailFailure('access_denied'.tr()));
        return;
      }

      if (userId != null) {
        _imagesReqSub = _accessRequestsRepository
            .watchLatestRequest(
              propertyId: event.propertyId,
              requesterId: userId,
              type: AccessRequestType.images,
            )
            .listen(
              (r) => add(PropertyAccessRequestUpdated(type: AccessRequestType.images, request: r)),
            );
        if (emitted.hasPhone) {
          _phoneReqSub = _accessRequestsRepository
              .watchLatestRequest(
                propertyId: event.propertyId,
                requesterId: userId,
                type: AccessRequestType.phone,
              )
              .listen(
                (r) => add(PropertyAccessRequestUpdated(type: AccessRequestType.phone, request: r)),
              );
        }
        if (emitted.hasLocationUrl) {
          _locationReqSub = _accessRequestsRepository
              .watchLatestRequest(
                propertyId: event.propertyId,
                requesterId: userId,
                type: AccessRequestType.location,
              )
              .listen(
                (r) =>
                    add(PropertyAccessRequestUpdated(type: AccessRequestType.location, request: r)),
              );
        }
      }
    } catch (e, st) {
      emit(PropertyDetailFailure(mapErrorMessage(e, stackTrace: st)));
    }
  }

  Future<void> _onAccessRequested(
    PropertyAccessRequested event,
    Emitter<PropertyDetailState> emit,
  ) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    final userId = loaded.userId;
    final role = loaded.userRole;
    if (userId == null) return;
    if (!canRequestSensitiveInfo(role)) {
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: 'collector_action_not_allowed'.tr(),
          isError: true,
        ),
      );
      return;
    }
    if (event.type == AccessRequestType.phone && !loaded.hasPhone) return;
    if (event.type == AccessRequestType.location && !loaded.hasLocationUrl) return;

    try {
      final created = await _createAccessRequestUseCase(
        property: loaded.property,
        requesterId: userId,
        type: event.type,
        message: event.message,
      );
      final targetUserId = created.ownerId ?? '';
      final currentUser = _authRepository.currentUser;

      await _notificationsRepository.sendAccessRequest(
        requestId: created.id,
        propertyId: event.propertyId,
        targetUserId: targetUserId,
        requesterId: userId,
        requesterName: currentUser?.name,
        type: event.type,
        message: event.message?.isEmpty == true ? null : event.message,
      );
      emit(PropertyDetailActionSuccess(loaded, message: 'request_submitted'.tr()));
    } catch (e, st) {
      debugPrint(e.toString());
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: mapErrorMessage(e, stackTrace: st),
          isError: true,
        ),
      );
    }
  }

  Future<void> _onArchive(PropertyArchiveRequested event, Emitter<PropertyDetailState> emit) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    final property = loaded.property;
    final userId = loaded.userId;
    final role = loaded.userRole;
    if (userId == null || role == null) return;
    if (!loaded.canArchiveOrDelete) {
      final message = role == UserRole.collector
          ? 'collector_action_not_allowed'.tr()
          : 'access_denied_delete'.tr();
      emit(PropertyDetailActionSuccess(loaded, message: message, isError: true));
      return;
    }
    emit(PropertyDetailActionInProgress(loaded));
    try {
      final updated = await _archivePropertyUseCase(
        property: property,
        userId: userId,
        userRole: role,
      );
      _mutations.notify(
        PropertyMutationType.archived,
        propertyId: property.id,
        ownerScope: updated.ownerScope,
        locationAreaId: updated.locationAreaId,
      );
      emit(PropertyDetailActionSuccess(loaded, message: 'archive'.tr()));
    } catch (e, st) {
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: mapErrorMessage(e, stackTrace: st),
          isError: true,
        ),
      );
    }
  }

  Future<void> _onDelete(PropertyDeleteRequested event, Emitter<PropertyDetailState> emit) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    final property = loaded.property;
    final userId = loaded.userId;
    final role = loaded.userRole;
    if (userId == null || role == null) return;
    if (!loaded.canArchiveOrDelete) {
      final message = role == UserRole.collector
          ? 'collector_action_not_allowed'.tr()
          : 'access_denied_delete'.tr();
      emit(PropertyDetailActionSuccess(loaded, message: message, isError: true));
      return;
    }
    emit(PropertyDetailActionInProgress(loaded));
    try {
      await _deletePropertyUseCase(property: property, userId: userId, userRole: role);
      _mutations.notify(
        PropertyMutationType.deleted,
        propertyId: property.id,
        ownerScope: property.ownerScope,
        locationAreaId: property.locationAreaId,
      );
      emit(PropertyDetailActionSuccess(loaded));
    } catch (e, st) {
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: mapErrorMessage(e, stackTrace: st),
          isError: true,
        ),
      );
    }
  }

  Future<void> _onShareImages(
    PropertyShareImagesRequested event,
    Emitter<PropertyDetailState> emit,
  ) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    if (!loaded.canShare) {
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: 'collector_action_not_allowed'.tr(),
          isError: true,
        ),
      );
      return;
    }
    if (!loaded.imagesVisible) {
      emit(
        PropertyDetailActionSuccess(
          loaded.copyWith(infoMessage: 'share_images_not_allowed'.tr()),
          message: 'share_images_not_allowed'.tr(),
          isError: true,
        ),
      );
      return;
    }

    void progressReporter(PropertyShareProgress progress) {
      _emitShareProgress(loaded, progress, emit);
    }

    emit(
      PropertyDetailShareInProgress(
        loaded,
        PropertyShareProgress(
          stage: PropertyShareStage.preparingData,
          fraction: PropertyShareStage.preparingData.defaultFraction(),
        ),
      ),
    );

    try {
      await _shareService.shareImagesOnly(
        property: loaded.property,
        onProgress: progressReporter,
      );
      emit(PropertyDetailShareSuccess(loaded));
      emit(PropertyDetailActionSuccess(loaded));
    } catch (e, st) {
      emit(
        PropertyDetailShareFailure(
          loaded,
          message: mapErrorMessage(e, stackTrace: st),
        ),
      );
      emit(PropertyDetailActionSuccess(loaded));
    }
  }

  Future<void> _onSharePdf(
    PropertySharePdfRequested event,
    Emitter<PropertyDetailState> emit,
  ) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    if (!loaded.canShare) {
      emit(
        PropertyDetailActionSuccess(
          loaded,
          message: 'collector_action_not_allowed'.tr(),
          isError: true,
        ),
      );
      return;
    }
    final includeImages = loaded.imagesVisible;
    if (!loaded.canSharePdf) {
      emit(
        PropertyDetailActionSuccess(
          loaded.copyWith(infoMessage: 'share_pdf_not_allowed'.tr()),
          message: 'share_pdf_not_allowed'.tr(),
          isError: true,
        ),
      );
      return;
    }
    void progressReporter(PropertyShareProgress progress) {
      _emitShareProgress(loaded, progress, emit);
    }

    emit(
      PropertyDetailShareInProgress(
        loaded,
        PropertyShareProgress(
          stage: PropertyShareStage.preparingData,
          fraction: PropertyShareStage.preparingData.defaultFraction(),
        ),
      ),
    );
    try {
      await _sharePropertyPdfUseCase(
        property: loaded.property,
        role: loaded.userRole,
        userId: loaded.userId,
        imagesVisible: includeImages,
        locationVisible: loaded.locationVisible,
        localeCode: event.context.locale.toString(),
        includeImages: includeImages,
        onProgress: progressReporter,
      );
      emit(PropertyDetailShareSuccess(loaded));
      emit(PropertyDetailActionSuccess(loaded));
    } catch (e, st) {
      debugPrint(e.toString());
      emit(PropertyDetailShareFailure(loaded, message: mapErrorMessage(e, stackTrace: st)));
      emit(PropertyDetailActionSuccess(loaded));
    }
  }

  void _emitShareProgress(
    PropertyDetailLoaded loaded,
    PropertyShareProgress progress,
    Emitter<PropertyDetailState> emit,
  ) {
    emit(PropertyDetailShareInProgress(loaded, progress));
  }

  void _onImagesLoadMore(PropertyImagesLoadMoreRequested event, Emitter<PropertyDetailState> emit) {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    final total = loaded.property.imageUrls.length;
    final next = (loaded.imagesToShow + event.batch).clamp(0, total);
    emit(loaded.copyWith(imagesToShow: next, infoMessage: loaded.infoMessage));
  }

  void _onInfoCleared(PropertyInfoCleared event, Emitter<PropertyDetailState> emit) {
    final current = state;
    if (current is PropertyDetailLoaded) {
      emit(current.copyWith(infoMessage: null));
    } else if (current is PropertyDetailActionSuccess) {
      emit(PropertyDetailActionSuccess(current.data.copyWith(infoMessage: null)));
    }
  }

  void _onExternalMutation(
    PropertyExternalMutationReceived event,
    Emitter<PropertyDetailState> emit,
  ) {
    add(PropertyDetailStarted(event.propertyId));
  }

  Future<void> _onAccessRequestUpdated(
    PropertyAccessRequestUpdated event,
    Emitter<PropertyDetailState> emit,
  ) async {
    final current = state;
    if (current is! PropertyDetailLoaded && current is! PropertyDetailActionSuccess) return;
    final loaded = current is PropertyDetailLoaded
        ? current
        : (current as PropertyDetailActionSuccess).data;
    final hadAccess = _hasAccess(loaded, event.type);
    final updated = _withAccessRequest(loaded, event.type, event.request);
    final hasAccess = _hasAccess(updated, event.type);
    final message = !hadAccess && hasAccess
        ? event.type == AccessRequestType.images
              ? 'images_access_accepted'.tr()
              : event.type == AccessRequestType.phone
              ? 'phone_access_accepted'.tr()
              : 'location_access_accepted'.tr()
        : null;
    final withMessage = message != null ? updated.copyWith(infoMessage: message) : updated;
    emit(PropertyDetailActionSuccess(withMessage, message: message));
  }

  PropertyDetailLoaded _withAccessRequest(
    PropertyDetailLoaded loaded,
    AccessRequestType type,
    AccessRequest? request,
  ) {
    final isAccepted = request?.status == AccessRequestStatus.accepted;
    return loaded.copyWith(
      imagesAccessRequest: type == AccessRequestType.images ? request : loaded.imagesAccessRequest,
      phoneAccessRequest: type == AccessRequestType.phone ? request : loaded.phoneAccessRequest,
      locationAccessRequest: type == AccessRequestType.location
          ? request
          : loaded.locationAccessRequest,
      imagesAccessGranted: type == AccessRequestType.images
          ? (loaded.imagesAccessGranted || isAccepted)
          : loaded.imagesAccessGranted,
      phoneAccessGranted: type == AccessRequestType.phone
          ? (loaded.phoneAccessGranted || isAccepted)
          : loaded.phoneAccessGranted,
      locationAccessGranted: type == AccessRequestType.location
          ? (loaded.locationAccessGranted || isAccepted)
          : loaded.locationAccessGranted,
      infoMessage: loaded.infoMessage,
    );
  }

  bool _hasAccess(PropertyDetailLoaded loaded, AccessRequestType type) {
    switch (type) {
      case AccessRequestType.images:
        return loaded.imagesVisible;
      case AccessRequestType.phone:
        return loaded.phoneVisible;
      case AccessRequestType.location:
        return loaded.locationVisible;
    }
  }

  void _cancelStreams() {
    _imagesReqSub?.cancel();
    _phoneReqSub?.cancel();
    _locationReqSub?.cancel();
    _imagesReqSub = null;
    _phoneReqSub = null;
    _locationReqSub = null;
  }

  Future<String?> _resolveCreatorName(String creatorId) async {
    if (_userNameCache.containsKey(creatorId)) return _userNameCache[creatorId];
    try {
      final user = await _usersRepository.getById(creatorId);
      final name = (user.name ?? '').trim();
      _userNameCache[creatorId] = name.isNotEmpty ? name : null;
    } catch (_) {
      _userNameCache[creatorId] = null;
    }
    return _userNameCache[creatorId];
  }

  @override
  Future<void> close() {
    _cancelStreams();
    _mutationSub?.cancel();
    return super.close();
  }
}
