import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/data/services/fcm_service.dart';
import 'package:real_state/core/constants/ui_constants.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:real_state/features/notifications/presentation/models/notification_property_summary.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart'
    as perms;

import '../../../../core/constants/user_role.dart';

/// NotificationsBloc orchestrates notification list + actions without
/// ever dropping back to a loading skeleton once data is shown.
/// Action states always wrap the previously rendered loaded data to
/// keep cached summaries and avoid UI flicker during mutations.

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _notificationsRepo;
  final AuthRepositoryDomain _auth;
  final FcmService _fcm;
  final PropertiesRepository _propertiesRepo;
  final LocationAreaRemoteDataSource _locations;
  final AcceptAccessRequestUseCase _acceptAccessRequestUseCase;
  final RejectAccessRequestUseCase _rejectAccessRequestUseCase;

  StreamSubscription<UserEntity?>? _authSub;
  StreamSubscription<AppNotification>? _fcmSub;
  String? _currentUserId;
  UserRole? _currentRole;
  bool _isOwner = false;
  bool _isCollector = false;
  final Map<String, NotificationPropertySummary> _propertyCache = {};
  final Set<String> _pendingRequestIds = {};
  bool _isLoadingMore = false;
  bool _hasLoadedOnce = false;

  String? get currentUserId => _currentUserId;
  bool get isOwner => _isOwner;
  bool get isCollector => _isCollector;
  UserRole? get currentRole => _currentRole;

  NotificationsBloc(
    this._notificationsRepo,
    this._auth,
    this._fcm,
    this._propertiesRepo,
    this._locations,
    this._acceptAccessRequestUseCase,
    this._rejectAccessRequestUseCase,
  ) : super(const NotificationsInitial()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<NotificationsLoadMoreRequested>(_onLoadMore);
    on<NotificationsMarkReadRequested>(_onMarkRead);
    on<NotificationsAcceptRequested>(_onAccept);
    on<NotificationsRejectRequested>(_onReject);
    on<NotificationsIncomingPushed>(_onIncoming);
    on<NotificationsClearInfoRequested>(_onClearInfo);

    _authSub = _auth.userChanges.listen((u) {
      if (u == null) {
        _currentUserId = null;
        _currentRole = null;
        _isOwner = false;
        _isCollector = false;
        _propertyCache.clear();
        _pendingRequestIds.clear();
        _hasLoadedOnce = false;
        add(const NotificationsStarted());
      } else {
        _currentUserId = u.id;
        _currentRole = u.role;
        _isOwner = (u.role == UserRole.owner);
        _isCollector = u.role == UserRole.collector;
        _propertyCache.clear();
        _pendingRequestIds.clear();
        _hasLoadedOnce = false;
        add(const NotificationsStarted());
      }
    });
    _fcmSub = _fcm.foregroundNotifications.listen((n) {
      if (_currentUserId != null) {
        add(NotificationsIncomingPushed(n, _currentUserId!));
      }
    });
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    _fcmSub?.cancel();
    return super.close();
  }

  Future<String?> accept(String notificationId, String requestId) {
    final completer = Completer<String?>();
    add(
      NotificationsAcceptRequested(
        notificationId,
        requestId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<String?> reject(String notificationId, String requestId) {
    final completer = Completer<String?>();
    add(
      NotificationsRejectRequested(
        notificationId,
        requestId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  void loadFirstPage() => add(const NotificationsStarted());
  void loadMore() => add(const NotificationsLoadMoreRequested());
  void refresh() => add(const NotificationsRefreshRequested());
  void markRead(String id) => add(NotificationsMarkReadRequested(id));
  void clearInfo() => add(const NotificationsClearInfoRequested());

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_currentUserId == null) {
      // Stay in current state (initial/loading or last loaded) until auth emits.
      return;
    }
    final alreadyLoaded = state is NotificationsDataState;
    if (!alreadyLoaded) {
      emit(NotificationsLoading(isOwner: _isOwner, isCollector: _isCollector));
    }
    try {
      final page = await _notificationsRepo.fetchPage(
        userId: _currentUserId!,
        limit: UiConstants.notificationsPageLimit,
      );
      final resolution = await _resolveProperties(page.items);
      emit(
        _resolutionState(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          infoMessage: null,
          resolution: resolution,
        ),
      );
      _hasLoadedOnce = true;
    } catch (e) {
      if (_hasLoadedOnce) {
        emit(
          NotificationsFailure(
            message: mapErrorMessage(e),
            isOwner: _isOwner,
            isCollector: _isCollector,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _reloadWithoutLoading(emit);
  }

  Future<void> _onLoadMore(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (current == null ||
        !current.hasMore ||
        state is NotificationsActionInProgress ||
        _currentUserId == null ||
        _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    emit(_actionInProgressFrom(current));
    try {
      final page = await _notificationsRepo.fetchPage(
        userId: _currentUserId!,
        startAfter: current.lastDoc,
        limit: UiConstants.notificationsPageLimit,
      );
      final items = List<AppNotification>.from(current.items)
        ..addAll(page.items);
      final resolution = await _resolveProperties(items);
      emit(
        _resolutionState(
          items: items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          infoMessage: null,
          resolution: resolution,
        ),
      );
    } catch (e) {
      final resolution = await _resolveProperties(current.items);
      emit(
        NotificationsPartialFailure(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          isOwner: _isOwner,
          isCollector: _isCollector,
          propertySummaries: resolution.summaries,
          pendingRequestIds: _pendingSnapshot(),
          message: mapErrorMessage(e),
          infoMessage: null,
        ),
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onAccept(
    NotificationsAcceptRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _handleAccept(event, emit);
  }

  Future<void> _onReject(
    NotificationsRejectRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _handleReject(event, emit);
  }

  Future<void> _onMarkRead(
    NotificationsMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _handleMarkRead(event, emit);
  }

  Future<void> _onIncoming(
    NotificationsIncomingPushed event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (event.currentUserId != _currentUserId) return;
    if (current == null) return;
    if (event.notification.targetUserId != null &&
        event.notification.targetUserId != _currentUserId)
      return;
    final existing = current.items
        .where((n) => n.id == event.notification.id)
        .isNotEmpty;
    if (existing) return;
    final items = [event.notification, ...current.items];
    final message = event.notification.body.isNotEmpty
        ? event.notification.body
        : event.notification.title;
    final resolution = await _resolveProperties(items);
    emit(
      _resolutionState(
        items: items,
        lastDoc: current.lastDoc,
        hasMore: current.hasMore,
        infoMessage: message,
        resolution: resolution,
      ),
    );
  }

  Future<void> _onClearInfo(
    NotificationsClearInfoRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (current != null) {
      emit(
        NotificationsLoaded(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          isOwner: _isOwner,
          isCollector: _isCollector,
          propertySummaries: current.propertySummaries,
          pendingRequestIds: _pendingSnapshot(),
        ),
      );
    }
  }

  NotificationsDataState? _dataState(NotificationsState state) {
    if (state is NotificationsDataState) return state;
    return null;
  }

  void _emitWithMessage(String message, Emitter<NotificationsState> emit) {
    final current = _dataState(state);
    if (current != null) {
      emit(
        NotificationsPartialFailure(
          items: current.items,
          lastDoc: current.lastDoc,
          hasMore: current.hasMore,
          isOwner: _isOwner,
          isCollector: _isCollector,
          propertySummaries: current.propertySummaries,
          pendingRequestIds: _pendingSnapshot(),
          message: message,
        ),
      );
    } else {
      emit(
        NotificationsFailure(
          message: message,
          isOwner: _isOwner,
          isCollector: _isCollector,
        ),
      );
    }
  }

  Future<_PropertyResolutionResult> _resolveProperties(
    List<AppNotification> notifications,
  ) async {
    final missingIds = notifications
        .map((n) => n.propertyId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .where((id) => !_propertyCache.containsKey(id))
        .toList();

    if (missingIds.isEmpty) {
      return _PropertyResolutionResult(Map.of(_propertyCache));
    }

    final Map<String, Property?> fetched = {};
    String? firstError;
    try {
      final batch = await _propertiesRepo.fetchByIds(missingIds);
      fetched.addAll(batch);
    } catch (e, st) {
      debugPrint('[NotificationsBloc] Failed batch fetch: $e\n$st');
      firstError ??= mapErrorMessage(e, stackTrace: st);
      for (final id in missingIds) {
        fetched[id] = null;
      }
    }

    final areaIds = fetched.values
        .whereType<Property>()
        .map((p) => p.locationAreaId)
        .whereType<String>()
        .toSet()
        .toList();
    Map<String, LocationArea> areaNames = {};
    try {
      areaNames = await _locations.fetchNamesByIds(areaIds);
    } catch (e, st) {
      debugPrint('[NotificationsBloc] Failed to fetch location names: $e\n$st');
      firstError ??= mapErrorMessage(e, stackTrace: st);
    }

    fetched.forEach((id, prop) {
      if (prop == null) {
        _propertyCache[id] = const NotificationPropertySummary(
          title: 'property_not_available',
          isMissing: true,
        );
      } else {
        _propertyCache[id] = NotificationPropertySummary(
          title: prop.title ?? '',
          areaName: areaNames[prop.locationAreaId]?.localizedName() ?? '',
          purposeKey: 'purpose.${prop.purpose.name}',
          coverImageUrl:
              prop.coverImageUrl ??
              (prop.imageUrls.isNotEmpty ? prop.imageUrls.first : null),
          isMissing: false,
          price: prop.price,
          formattedPrice: prop.price != null
              ? PriceFormatter.format(prop.price!, currency: 'AED')
              : null,
        );
      }
    });

    return _PropertyResolutionResult(
      Map.of(_propertyCache),
      errorMessage: firstError,
    );
  }

  NotificationsDataState _resolutionState({
    required List<AppNotification> items,
    required DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    required bool hasMore,
    required _PropertyResolutionResult resolution,
    String? infoMessage,
  }) {
    if (resolution.errorMessage != null) {
      return NotificationsPartialFailure(
        items: items,
        lastDoc: lastDoc,
        hasMore: hasMore,
        isOwner: _isOwner,
        isCollector: _isCollector,
        propertySummaries: resolution.summaries,
        pendingRequestIds: _pendingSnapshot(),
        message: resolution.errorMessage!,
        infoMessage: infoMessage,
      );
    }
    return NotificationsLoaded(
      items: items,
      lastDoc: lastDoc,
      hasMore: hasMore,
      isOwner: _isOwner,
      isCollector: _isCollector,
      propertySummaries: resolution.summaries,
      pendingRequestIds: _pendingSnapshot(),
      infoMessage: infoMessage,
    );
  }

  bool _isRequestPending(String requestId) =>
      _pendingRequestIds.contains(requestId);

  Set<String> _pendingSnapshot() => Set<String>.from(_pendingRequestIds);

  AppNotification? _findNotification(NotificationsDataState state, String id) {
    for (final n in state.items) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Action handlers must always wrap the previously rendered loaded state to avoid
  /// flashing skeletons and to preserve cached summaries during mutations.
  Future<void> _handleAccept(
    NotificationsAcceptRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (current == null) {
      event.completer?.complete(null);
      return;
    }
    final notification = _findNotification(current, event.notificationId);
    if (!perms.canAcceptRejectAccessRequests(_currentRole) ||
        (notification?.targetUserId != null &&
            notification?.targetUserId != _currentUserId)) {
      _emitWithMessage('access_request_action_not_allowed'.tr(), emit);
      event.completer?.complete('access_request_action_not_allowed'.tr());
      return;
    }
    if (notification?.requestStatus != null &&
        notification!.requestStatus != AccessRequestStatus.pending) {
      event.completer?.complete('access_request_action_not_allowed'.tr());
      return;
    }
    if (_currentUserId == null ||
        event.requestId.isEmpty ||
        _isRequestPending(event.requestId)) {
      event.completer?.complete(null);
      return;
    }
    _setRequestPending(event.requestId, true);
    emit(_actionInProgressFrom(current));
    try {
      final updated = await _acceptAccessRequestUseCase(
        requestId: event.requestId,
        userId: _currentUserId!,
        role: _currentRole,
      );
      await _notificationsRepo.sendAccessRequestDecision(
        request: updated,
        accepted: true,
      );
      await _notificationsRepo.markAsRead(event.notificationId);
      final loaded = _applyLocalStatus(
        event.notificationId,
        AccessRequestStatus.accepted,
        current,
      );
      _setRequestPending(event.requestId, false);
      _emitSuccessFrom(loaded, emit);
      event.completer?.complete(null);
    } catch (e) {
      _setRequestPending(event.requestId, false);
      final message = mapErrorMessage(e);
      emit(_actionFailureFrom(current, message));
      event.completer?.complete(message);
    }
  }

  Future<void> _handleReject(
    NotificationsRejectRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (current == null) {
      event.completer?.complete(null);
      return;
    }
    final notification = _findNotification(current, event.notificationId);
    if (!perms.canAcceptRejectAccessRequests(_currentRole) ||
        (notification?.targetUserId != null &&
            notification?.targetUserId != _currentUserId)) {
      _emitWithMessage('access_request_action_not_allowed'.tr(), emit);
      event.completer?.complete('access_request_action_not_allowed'.tr());
      return;
    }
    if (notification?.requestStatus != null &&
        notification!.requestStatus != AccessRequestStatus.pending) {
      event.completer?.complete('access_request_action_not_allowed'.tr());
      return;
    }
    if (_currentUserId == null ||
        event.requestId.isEmpty ||
        _isRequestPending(event.requestId)) {
      event.completer?.complete(null);
      return;
    }
    _setRequestPending(event.requestId, true);
    emit(_actionInProgressFrom(current));
    try {
      final updated = await _rejectAccessRequestUseCase(
        requestId: event.requestId,
        userId: _currentUserId!,
        role: _currentRole,
      );
      await _notificationsRepo.sendAccessRequestDecision(
        request: updated,
        accepted: false,
      );
      await _notificationsRepo.markAsRead(event.notificationId);
      final loaded = _applyLocalStatus(
        event.notificationId,
        AccessRequestStatus.rejected,
        current,
      );
      _setRequestPending(event.requestId, false);
      _emitSuccessFrom(loaded, emit);
      event.completer?.complete(null);
    } catch (e) {
      _setRequestPending(event.requestId, false);
      final message = mapErrorMessage(e);
      emit(_actionFailureFrom(current, message));
      event.completer?.complete(message);
    }
  }

  Future<void> _handleMarkRead(
    NotificationsMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = _dataState(state);
    if (current == null) return;
    emit(_actionInProgressFrom(current));
    try {
      await _notificationsRepo.markAsRead(event.notificationId);
      final updatedItems = current.items
          .map(
            (n) => n.id == event.notificationId ? n.copyWith(isRead: true) : n,
          )
          .toList();
      final loaded = NotificationsLoaded(
        items: updatedItems,
        lastDoc: current.lastDoc,
        hasMore: current.hasMore,
        isOwner: _isOwner,
        isCollector: _isCollector,
        propertySummaries: current.propertySummaries,
        pendingRequestIds: _pendingSnapshot(),
        infoMessage: current.infoMessage,
      );
      _emitSuccessFrom(loaded, emit);
    } catch (e, st) {
      debugPrint('[NotificationsBloc] markRead failed: $e\n$st');
      _emitWithMessage(mapErrorMessage(e, stackTrace: st), emit);
    }
  }

  NotificationsLoaded _applyLocalStatus(
    String notificationId,
    AccessRequestStatus status,
    NotificationsDataState current,
  ) {
    final updatedItems = current.items
        .map(
          (n) => n.id == notificationId
              ? n.copyWith(requestStatus: status, isRead: true)
              : n,
        )
        .toList();
    return NotificationsLoaded(
      items: updatedItems,
      lastDoc: current.lastDoc,
      hasMore: current.hasMore,
      isOwner: _isOwner,
      isCollector: _isCollector,
      propertySummaries: current.propertySummaries,
      pendingRequestIds: _pendingSnapshot(),
      infoMessage: current.infoMessage,
    );
  }

  void _setRequestPending(String requestId, bool pending) {
    if (pending) {
      _pendingRequestIds.add(requestId);
    } else {
      _pendingRequestIds.remove(requestId);
    }
  }

  NotificationsActionInProgress _actionInProgressFrom(
    NotificationsDataState current,
  ) {
    // During actions we must keep the previously rendered data to avoid skeleton flicker
    // and to preserve cached summaries/area names.
    return NotificationsActionInProgress(
      items: current.items,
      lastDoc: current.lastDoc,
      hasMore: current.hasMore,
      isOwner: _isOwner,
      isCollector: _isCollector,
      propertySummaries: current.propertySummaries,
      pendingRequestIds: _pendingSnapshot(),
      infoMessage: current.infoMessage,
    );
  }

  NotificationsActionFailure _actionFailureFrom(
    NotificationsDataState current,
    String message,
  ) {
    return NotificationsActionFailure(
      items: current.items,
      lastDoc: current.lastDoc,
      hasMore: current.hasMore,
      isOwner: _isOwner,
      isCollector: _isCollector,
      propertySummaries: current.propertySummaries,
      pendingRequestIds: _pendingSnapshot(),
      message: message,
      infoMessage: current.infoMessage,
    );
  }

  void _emitSuccessFrom(
    NotificationsLoaded loaded,
    Emitter<NotificationsState> emit,
  ) {
    // Emit a transient success state (for listeners) while keeping the list stable.
    emit(
      NotificationsActionSuccess(
        items: loaded.items,
        lastDoc: loaded.lastDoc,
        hasMore: loaded.hasMore,
        isOwner: loaded.isOwner,
        isCollector: loaded.isCollector,
        propertySummaries: loaded.propertySummaries,
        pendingRequestIds: loaded.pendingRequestIds,
        infoMessage: loaded.infoMessage,
      ),
    );
    emit(loaded);
  }

  Future<void> _reloadWithoutLoading(Emitter<NotificationsState> emit) async {
    if (_currentUserId == null) return;
    try {
      final page = await _notificationsRepo.fetchPage(
        userId: _currentUserId!,
        limit: UiConstants.notificationsPageLimit,
      );
      final resolution = await _resolveProperties(page.items);
      emit(
        _resolutionState(
          items: page.items,
          lastDoc: page.lastDocument,
          hasMore: page.hasMore,
          infoMessage: null,
          resolution: resolution,
        ),
      );
      _hasLoadedOnce = true;
    } catch (e) {
      if (_hasLoadedOnce) {
        emit(
          NotificationsFailure(
            message: mapErrorMessage(e),
            isOwner: _isOwner,
            isCollector: _isCollector,
          ),
        );
      }
    }
  }
}

class _PropertyResolutionResult {
  final Map<String, NotificationPropertySummary> summaries;
  final String? errorMessage;

  _PropertyResolutionResult(this.summaries, {this.errorMessage});
}
