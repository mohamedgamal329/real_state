import 'package:equatable/equatable.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';

abstract class PropertyDetailState extends Equatable {
  const PropertyDetailState();

  @override
  List<Object?> get props => [];
}

class PropertyDetailInitial extends PropertyDetailState {
  const PropertyDetailInitial();
}

class PropertyDetailLoading extends PropertyDetailState {
  const PropertyDetailLoading();
}

class PropertyDetailLoaded extends PropertyDetailState {
  final Property property;
  final String? userId;
  final UserRole? userRole;
  final AccessRequest? imagesAccessRequest;
  final AccessRequest? phoneAccessRequest;
  final AccessRequest? locationAccessRequest;
  final int imagesToShow;
  final String? infoMessage;
  final bool imagesAccessGranted;
  final bool phoneAccessGranted;
  final bool locationAccessGranted;
  final String? creatorName;

  const PropertyDetailLoaded({
    required this.property,
    required this.imagesToShow,
    this.imagesAccessGranted = false,
    this.phoneAccessGranted = false,
    this.locationAccessGranted = false,
    this.userId,
    this.userRole,
    this.imagesAccessRequest,
    this.phoneAccessRequest,
    this.locationAccessRequest,
    this.infoMessage,
    this.creatorName,
  });

  bool get canModify {
    if (userId == null || userRole == null) return false;
    return canModifyProperty(
      property: property,
      userId: userId!,
      role: userRole!,
    );
  }

  bool get canArchiveOrDelete {
    if (userId == null || userRole == null) return false;
    return canArchiveOrDeleteProperty(
      property: property,
      userId: userId!,
      role: userRole!,
    );
  }

  bool get canShare => canShareProperty(userRole);

  bool get canRequestAccess => canRequestSensitiveInfo(userRole);

  bool get hasPhone =>
      property.ownerPhoneEncryptedOrHiddenStored != null &&
      property.ownerPhoneEncryptedOrHiddenStored!.trim().isNotEmpty;

  bool get hasLocationUrl =>
      property.locationUrl != null &&
      Validators.isValidUrl(property.locationUrl);

  bool get _hasIntrinsicAccess => hasIntrinsicPropertyAccess(
    property: property,
    userRole: userRole,
    userId: userId,
  );

  bool get _ownerRequiresBrokerImagesAccess =>
      userRole == UserRole.owner &&
      property.ownerScope == PropertyOwnerScope.broker &&
      !_isRequestGranted(imagesAccessRequest) &&
      !imagesAccessGranted;

  bool get _ownerRequiresBrokerPhoneAccess =>
      userRole == UserRole.owner &&
      property.ownerScope == PropertyOwnerScope.broker &&
      !_isRequestGranted(phoneAccessRequest) &&
      !phoneAccessGranted;

  PropertyDetailLoaded copyWith({
    Property? property,
    String? userId,
    UserRole? userRole,
    AccessRequest? imagesAccessRequest,
    AccessRequest? phoneAccessRequest,
    AccessRequest? locationAccessRequest,
    int? imagesToShow,
    String? infoMessage,
    bool? imagesAccessGranted,
    bool? phoneAccessGranted,
    bool? locationAccessGranted,
    String? creatorName,
  }) {
    return PropertyDetailLoaded(
      property: property ?? this.property,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      imagesAccessRequest: imagesAccessRequest ?? this.imagesAccessRequest,
      phoneAccessRequest: phoneAccessRequest ?? this.phoneAccessRequest,
      locationAccessRequest:
          locationAccessRequest ?? this.locationAccessRequest,
      imagesToShow: imagesToShow ?? this.imagesToShow,
      infoMessage: infoMessage,
      imagesAccessGranted: imagesAccessGranted ?? this.imagesAccessGranted,
      phoneAccessGranted: phoneAccessGranted ?? this.phoneAccessGranted,
      locationAccessGranted:
          locationAccessGranted ?? this.locationAccessGranted,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  @override
  List<Object?> get props => [
    property,
    userId,
    userRole,
    imagesAccessRequest,
    phoneAccessRequest,
    locationAccessRequest,
    imagesToShow,
    infoMessage,
    imagesAccessGranted,
    phoneAccessGranted,
    locationAccessGranted,
    creatorName,
  ];

  bool get imagesVisible {
    if (_ownerRequiresBrokerImagesAccess) {
      return imagesAccessGranted || _isRequestGranted(imagesAccessRequest);
    }
    if (_hasIntrinsicAccess || canBypassImageRestrictions(userRole))
      return true;
    if (!property.isImagesHidden) return true;
    return imagesAccessGranted || _isRequestGranted(imagesAccessRequest);
  }

  bool get phoneVisible {
    if (!hasPhone) return false;
    if (_ownerRequiresBrokerPhoneAccess) {
      return phoneAccessGranted || _isRequestGranted(phoneAccessRequest);
    }
    if (_hasIntrinsicAccess || canBypassPhoneRestrictions(userRole))
      return true;
    return phoneAccessGranted || _isRequestGranted(phoneAccessRequest);
  }

  bool get locationVisible {
    if (!hasLocationUrl) return false;
    if (_hasIntrinsicAccess || canBypassLocationRestrictions(userRole))
      return true;
    return locationAccessGranted || _isRequestGranted(locationAccessRequest);
  }

  bool get canSharePdf {
    if (!canShare) return false;
    return true; // PDF sharing allowed; image inclusion governed downstream
  }

  bool _isRequestGranted(AccessRequest? request) {
    if (request == null) return false;
    if (request.status != AccessRequestStatus.accepted) return false;
    return true;
  }
}

class PropertyDetailActionInProgress extends PropertyDetailState {
  final PropertyDetailLoaded data;
  const PropertyDetailActionInProgress(this.data);

  @override
  List<Object?> get props => [data];
}

class PropertyDetailActionSuccess extends PropertyDetailState {
  final PropertyDetailLoaded data;
  final String? message;
  final bool isError;
  const PropertyDetailActionSuccess(
    this.data, {
    this.message,
    this.isError = false,
  });

  @override
  List<Object?> get props => [data, message, isError];
}

class PropertyDetailShareInProgress extends PropertyDetailState {
  final PropertyDetailLoaded data;
  final PropertyShareProgress progress;

  const PropertyDetailShareInProgress(this.data, this.progress);

  @override
  List<Object?> get props => [data, progress];
}

class PropertyDetailShareSuccess extends PropertyDetailState {
  final PropertyDetailLoaded data;
  const PropertyDetailShareSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

class PropertyDetailShareFailure extends PropertyDetailState {
  final PropertyDetailLoaded data;
  final String message;
  const PropertyDetailShareFailure(this.data, {required this.message});

  @override
  List<Object?> get props => [data, message];
}

class PropertyDetailFailure extends PropertyDetailState {
  final String message;
  const PropertyDetailFailure(this.message);

  @override
  List<Object?> get props => [message];
}
