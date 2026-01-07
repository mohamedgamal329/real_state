import 'package:easy_localization/easy_localization.dart';

import '../errors/localized_exception.dart';
import '../failure/auth_failure.dart';
import '../failure/failure.dart';
import '../failure/firestore_failure.dart';
import '../failure/network_failure.dart';
import '../failure/storage_failure.dart';
import '../failure/validation_failure.dart';

String mapFailureToMessage(Failure f) {
  final error = f.error;
  if (error is LocalizedException) {
    return error.key.tr(args: error.args);
  }
  if (f is AuthFailure) {
    final code = f.error;
    if (code is String) {
      switch (code) {
        case 'inactive_user':
          return 'inactive_user'.tr();
        case 'profile_missing':
          return 'profile_missing'.tr();
        case 'invalid_role':
          return 'invalid_role'.tr();
      }
    }
    return 'auth_failed'.tr();
  }
  if (f is NetworkFailure) return 'network_error'.tr();
  if (f is FirestoreFailure) return 'data_error'.tr();
  if (f is StorageFailure) return 'storage_error'.tr();
  if (f is ValidationFailure) return 'validation_error'.tr();
  return 'unexpected_error'.tr();
}
