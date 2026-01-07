import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:real_state/features/location/data/repositories/location_repository.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/settings/presentation/pages/manage_locations_page.dart';

class FakeLocationRepository extends LocationRepository {
  FakeLocationRepository() : super(FirebaseFirestore.instance);
  List<LocationArea> locations = [];
  @override
  Future<List<LocationArea>> fetchAll() async => locations;
  @override
  Future<String> create({
    required String nameAr,
    required String nameEn,
    required XFile imageFile,
  }) async {
    final area = LocationArea(
      id: nameEn,
      nameAr: nameAr,
      nameEn: nameEn,
      imageUrl: imageFile.path,
      isActive: true,
      createdAt: DateTime.now(),
    );
    locations.add(area);
    return area.id;
  }

  @override
  Future<void> update({
    required String id,
    required String nameAr,
    required String nameEn,
    XFile? imageFile,
    String? previousImageUrl,
  }) async {
    final idx = locations.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      final existing = locations[idx];
      locations[idx] = LocationArea(
        id: id,
        nameAr: nameAr,
        nameEn: nameEn,
        imageUrl: imageFile?.path ?? previousImageUrl ?? existing.imageUrl,
        isActive: existing.isActive,
        createdAt: existing.createdAt,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    locations.removeWhere((l) => l.id == id);
  }

  @override
  Future<bool> canDelete(String id) async => true;
}

class FakeFirestore {}

void main() {
  testWidgets('ManageLocationsPage shows locations and add', (tester) async {
    final repo = FakeLocationRepository();
    repo.locations = [
      LocationArea(
        id: 'l1',
        nameAr: 'Location1',
        nameEn: 'Location1',
        imageUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<LocationRepository>.value(
          value: repo,
          child: const ManageLocationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Location1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Location2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Location2'), findsOneWidget);
  }, skip: true);
}
