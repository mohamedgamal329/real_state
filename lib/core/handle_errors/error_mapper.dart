import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

import '../errors/localized_exception.dart';
import '../failure/auth_failure.dart';
import '../failure/failure.dart';
import '../failure/firestore_failure.dart';
import '../failure/network_failure.dart';
import '../failure/storage_failure.dart';
import '../failure/unknown_failure.dart';
import '../failure/validation_failure.dart';
import 'failure_message_mapper.dart';

Failure mapExceptionToFailure(Object exception, [StackTrace? st]) {
  if (exception is Failure) return exception;

  if (exception is LocalizedException) {
    return ValidationFailure(error: exception, stackTrace: st);
  }

  if (exception is fb_auth.FirebaseAuthException) {
    if (exception.code == 'network-request-failed') {
      return NetworkFailure(error: exception, stackTrace: st);
    }
    return AuthFailure(error: exception, stackTrace: st);
  }

  if (exception is FirebaseException) {
    // generic Firebase exceptions, map by plugin
    switch (exception.plugin) {
      case 'cloud_firestore':
        return FirestoreFailure(error: exception, stackTrace: st);
      case 'firebase_storage':
        return StorageFailure(error: exception, stackTrace: st);
      default:
        return UnknownFailure(error: exception, stackTrace: st);
    }
  }

  if (exception is TimeoutException || exception is SocketException) {
    return NetworkFailure(error: exception, stackTrace: st);
  }
  if (exception is FormatException || exception is ArgumentError) {
    return ValidationFailure(error: exception, stackTrace: st);
  }

  return UnknownFailure(error: exception, stackTrace: st);
}

/// Legacy helper to map an exception into a localized, user-facing message.
String mapErrorMessage(Object exception, {StackTrace? stackTrace}) {
  final failure = mapExceptionToFailure(exception, stackTrace);
  return mapFailureToMessage(failure);
}
