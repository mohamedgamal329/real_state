import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:real_state/features/models/entities/access_request.dart';

abstract class PropertyDetailEvent extends Equatable {
  const PropertyDetailEvent();

  @override
  List<Object?> get props => [];
}

class PropertyDetailStarted extends PropertyDetailEvent {
  final String propertyId;
  const PropertyDetailStarted(this.propertyId);

  @override
  List<Object?> get props => [propertyId];
}

class PropertyAccessRequested extends PropertyDetailEvent {
  final String propertyId;
  final AccessRequestType type;
  final String? message;
  const PropertyAccessRequested({
    required this.propertyId,
    required this.type,
    this.message,
  });

  @override
  List<Object?> get props => [propertyId, type, message];
}

class PropertyArchiveRequested extends PropertyDetailEvent {
  const PropertyArchiveRequested();
}

class PropertyDeleteRequested extends PropertyDetailEvent {
  const PropertyDeleteRequested();
}

class PropertyShareImagesRequested extends PropertyDetailEvent {
  final BuildContext context;
  const PropertyShareImagesRequested(this.context);

  @override
  List<Object?> get props => [context];
}

class PropertySharePdfRequested extends PropertyDetailEvent {
  final BuildContext context;
  const PropertySharePdfRequested(this.context);

  @override
  List<Object?> get props => [context];
}

class PropertyImagesLoadMoreRequested extends PropertyDetailEvent {
  final int batch;
  const PropertyImagesLoadMoreRequested(this.batch);

  @override
  List<Object?> get props => [batch];
}

class PropertyInfoCleared extends PropertyDetailEvent {
  const PropertyInfoCleared();
}

class PropertyExternalMutationReceived extends PropertyDetailEvent {
  final String propertyId;
  const PropertyExternalMutationReceived(this.propertyId);

  @override
  List<Object?> get props => [propertyId];
}

class PropertyAccessRequestUpdated extends PropertyDetailEvent {
  final AccessRequestType type;
  final AccessRequest? request;

  const PropertyAccessRequestUpdated({
    required this.type,
    required this.request,
  });

  @override
  List<Object?> get props => [type, request];
}
