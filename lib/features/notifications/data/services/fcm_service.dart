import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/firebase_options.dart';

/// Background message handler must be a top-level function.
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Centralized FCM handler for token management and message parsing.
class FcmService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  FcmService(this._messaging, this._firestore, this._auth);

  final StreamController<AppNotification> _foregroundController =
      StreamController<AppNotification>.broadcast();
  final StreamController<AppNotification> _tapController =
      StreamController<AppNotification>.broadcast();

  String? _currentUserId;
  String? _cachedToken;
  String? _lastSavedToken;
  String? _lastSavedUserId;
  Timer? _apnsRetryTimer;

  bool get _requiresApns =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Stream<AppNotification> get foregroundNotifications =>
      _foregroundController.stream;
  Stream<AppNotification> get notificationTaps => _tapController.stream;

  Future<void> initialize() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
  }

  Future<void> attachUser(String? userId) async {
    if (userId == null) {
      await _deleteCurrentToken(forUser: _currentUserId);
      _cancelApnsRetry();
      _clearCachedToken();
      _currentUserId = null;
      return;
    }
    _currentUserId = userId;
    _cancelApnsRetry();
    try {
      await _requestPermission();
      await _registerInitialToken(userId);
    } catch (e, st) {
      _logFailure('FCM attachUser failed', e, st);
    }
  }

  Future<void> detachUser() async {
    try {
      await _deleteCurrentToken(forUser: _currentUserId);
    } catch (e, st) {
      _logCleanupFailure('FCM detachUser failed', e, st);
    } finally {
      _cancelApnsRetry();
      _clearCachedToken();
      _currentUserId = null;
    }
  }

  Future<AppNotification?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return _parseMessage(message);
  }

  Future<List<String>> fetchTokensForUsers(List<String> userIds) async {
    final tokens = <String>{};
    for (final id in userIds) {
      final snap = await _firestore
          .collection(AppCollections.users.path)
          .doc(id)
          .collection(AppCollections.fcmTokens.path)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final isActive = (data['active'] as bool?) ?? true;
        if (!isActive) continue;
        final token = data['token'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }
    }
    return tokens.toList();
  }

  Future<void> sendToTokens({
    required List<String> tokens,
    required Map<String, String> data,
    String? title,
    String? body,
  }) async {
    if (tokens.isEmpty) return;
    const serverKey = String.fromEnvironment('FCM_SERVER_KEY');
    if (serverKey.isEmpty) {
      debugPrint('FCM server key missing; skipping send.');
      return;
    }
    final payload = {
      'registration_ids': tokens,
      'priority': 'high',
      'notification': {'title': title, 'body': body},
      'data': data,
    };
    try {
      final res = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 300) {
        debugPrint('FCM send failed (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      debugPrint('FCM send error: $e');
    }
  }

  Future<void> _registerInitialToken(String userId) async {
    if (_currentUserId != userId) return;
    if (!_canWriteForUser(userId)) {
      _markTokenDetached();
      return;
    }
    if (_requiresApns) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null || apns.isEmpty) {
        debugPrint('Awaiting APNs token before requesting FCM token');
        _scheduleApnsRetry(userId);
        return;
      }
    }
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _handleTokenRefresh(token);
        _cancelApnsRetry();
        return;
      }
      _scheduleApnsRetry(userId);
    } catch (e, st) {
      _logFailure('Unable to register initial FCM token', e, st);
      _scheduleApnsRetry(userId);
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    if (!_canWriteForUser(userId)) {
      _markTokenDetached();
      return;
    }
    try {
      await _firestore
          .collection(AppCollections.users.path)
          .doc(userId)
          .collection(AppCollections.fcmTokens.path)
          .doc(token)
          .set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
            'active': true,
            'revokedAt': FieldValue.delete(),
          }, SetOptions(merge: true));
    } catch (e, st) {
      final failure = mapExceptionToFailure(e, st);
      debugPrint('Unable to save FCM token: $failure');
      throw failure;
    }
  }

  Future<void> _saveTokenIfNeeded(String userId, String token) async {
    if (_lastSavedToken == token && _lastSavedUserId == userId) return;
    await _saveToken(userId, token);
    _lastSavedToken = token;
    _lastSavedUserId = userId;
  }

  Future<void> _deleteCurrentToken({String? forUser}) async {
    final userId = forUser ?? _currentUserId;
    final authUser = _auth.currentUser;
    if (userId == null || authUser == null) {
      _markTokenDetached();
      return;
    }
    if (!_canWriteForUser(userId)) {
      _markTokenDetached();
      return;
    }

    var tokenToDelete = _cachedToken;
    if (tokenToDelete == null || tokenToDelete.isEmpty) {
      try {
        tokenToDelete = await _messaging.getToken();
      } catch (e, st) {
        _logCleanupFailure('Unable to fetch FCM token for deletion', e, st);
      }
    }

    if (tokenToDelete != null && tokenToDelete.isNotEmpty) {
      try {
        await _deactivateTokenDoc(userId, tokenToDelete);
      } catch (e, st) {
        _logCleanupFailure('Unable to deactivate FCM token', e, st);
      }
      _markTokenDetached();
      return;
    }

    try {
      await _deactivateAllTokens(userId);
    } catch (e, st) {
      _logCleanupFailure(
        'Unable to deactivate all FCM tokens via fallback',
        e,
        st,
      );
    }
    _markTokenDetached();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final parsed = _parseMessage(message);
    if (parsed != null) {
      _foregroundController.add(parsed);
    }
  }

  void _handleTap(RemoteMessage message) {
    final parsed = _parseMessage(message);
    if (parsed != null) {
      _tapController.add(parsed);
    }
  }

  AppNotification? _parseMessage(RemoteMessage message) {
    final data = message.data;
    final id = data['notificationId'] ?? message.messageId;
    final type = AppNotificationTypeX.fromCode(data['type'] as String?);
    if (id == null) return null;

    AccessRequestType? requestType;
    switch (data['requestType']) {
      case 'phone':
        requestType = AccessRequestType.phone;
        break;
      case 'images':
        requestType = AccessRequestType.images;
        break;
      case 'locationUrl':
      case 'location':
        requestType = AccessRequestType.location;
        break;
    }

    AccessRequestStatus? status;
    switch (data['requestStatus']) {
      case 'accepted':
        status = AccessRequestStatus.accepted;
        break;
      case 'rejected':
        status = AccessRequestStatus.rejected;
        break;
      case 'pending':
        status = AccessRequestStatus.pending;
        break;
    }

    final created =
        DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now();

    return AppNotification(
      id: id,
      type: type,
      title: message.notification?.title ?? data['title'] as String? ?? '',
      body: message.notification?.body ?? data['body'] as String? ?? '',
      propertyId: data['propertyId'] as String?,
      requesterId: data['requesterId'] as String?,
      requestId: data['requestId'] as String?,
      requestType: requestType,
      requestStatus: status,
      requestMessage: data['requestMessage'] as String?,
      targetUserId: data['targetUserId'] as String?,
      createdAt: created,
      isRead: false,
    );
  }

  Future<void> dispose() async {
    _cancelApnsRetry();
    await _foregroundController.close();
    await _tapController.close();
  }

  Future<void> _handleTokenRefresh(String token) async {
    final previousToken = _cachedToken;
    _cachedToken = token;
    if (_currentUserId == null) return;
    final userId = _currentUserId!;
    if (!_canWriteForUser(userId)) {
      _markTokenDetached();
      return;
    }
    try {
      if (previousToken != null && previousToken != token) {
        await _deactivateTokenDoc(userId, previousToken);
      }
      await _saveTokenIfNeeded(userId, token);
    } catch (e, st) {
      _logFailure('FCM token refresh error', e, st);
    }
  }

  Future<void> _deactivateTokenDoc(String userId, String token) async {
    try {
      await _firestore
          .collection(AppCollections.users.path)
          .doc(userId)
          .collection(AppCollections.fcmTokens.path)
          .doc(token)
          .set({
            'token': token,
            'active': false,
            'revokedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e, st) {
      final failure = mapExceptionToFailure(e, st);
      debugPrint('Unable to deactivate FCM token: $failure');
      throw failure;
    }
  }

  Future<void> _deactivateAllTokens(String userId) async {
    try {
      final snap = await _firestore
          .collection(AppCollections.users.path)
          .doc(userId)
          .collection(AppCollections.fcmTokens.path)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.set({
          'active': false,
          'revokedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e, st) {
      final failure = mapExceptionToFailure(e, st);
      debugPrint(
        'Unable to deactivate all FCM tokens for user $userId: $failure',
      );
      throw failure;
    }
  }

  void _scheduleApnsRetry(String userId) {
    if (_currentUserId != userId) return;
    _apnsRetryTimer?.cancel();
    _apnsRetryTimer = Timer(const Duration(seconds: 10), () {
      if (_currentUserId != userId) return;
      unawaited(_registerInitialToken(userId));
    });
  }

  void _cancelApnsRetry() {
    _apnsRetryTimer?.cancel();
    _apnsRetryTimer = null;
  }

  void _clearCachedToken() {
    _cachedToken = null;
    _lastSavedToken = null;
    _lastSavedUserId = null;
  }

  bool _canWriteForUser(String userId) {
    final authUser = _auth.currentUser;
    return authUser != null && authUser.uid == userId;
  }

  void _markTokenDetached() {
    _cachedToken = null;
    _lastSavedToken = null;
    _lastSavedUserId = null;
  }

  void _logFailure(String context, Object error, [StackTrace? st]) {
    final failure = mapExceptionToFailure(error, st);
    debugPrint('$context: $failure');
    if (st != null) {
      debugPrint('Stacktrace: $st');
    }
  }

  bool _isPermissionDenied(Object error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }

  void _logCleanupFailure(String context, Object error, [StackTrace? st]) {
    if (_isPermissionDenied(error)) {
      debugPrint('$context skipped (permission-denied)');
      return;
    }
    _logFailure(context, error, st);
  }
}
