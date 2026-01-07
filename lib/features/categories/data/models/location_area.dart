import 'package:meta/meta.dart';

/// Simple model for location area dropdown items.
@immutable
class LocationArea {
  final String id;
  final String name;

  const LocationArea({required this.id, required this.name});
}
