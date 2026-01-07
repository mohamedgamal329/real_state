enum AppCollections {
  notifications,
  users,
  properties,
  accessRequests,
  locationAreas,
  fcmTokens,
}

extension AppCollectionsX on AppCollections {
  String get path {
    switch (this) {
      case AppCollections.notifications:
        return 'notifications';
      case AppCollections.users:
        return 'users';
      case AppCollections.properties:
        return 'properties';
      case AppCollections.accessRequests:
        return 'access_requests';
      case AppCollections.locationAreas:
        return 'location_areas';
      case AppCollections.fcmTokens:
        return 'fcmTokens';
    }
  }
}
