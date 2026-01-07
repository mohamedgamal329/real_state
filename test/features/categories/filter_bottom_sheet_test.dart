import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/categories/presentation/widgets/filter_bottom_sheet.dart';
import 'package:real_state/features/models/entities/location_area.dart';

void main() {
  testWidgets(
    'shows validation error when min price > max price and disables Apply',
    (WidgetTester tester) async {
      final filter = PropertyFilter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet(
              onAddLocation: () async {},
              currentFilter: filter,
              locationAreas: [
                LocationArea(
                  id: '1',
                  nameAr: 'Area 1',
                  nameEn: 'Area 1',
                  imageUrl: '',
                  isActive: true,
                  createdAt: DateTime.now(),
                ),
              ],
              onApply: (_) {},
            ),
          ),
        ),
      );

      // Initially Apply is enabled
      expect(find.text('Apply Filters'), findsOneWidget);
      final applyButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Apply Filters'),
      );
      expect(applyButton.onPressed, isNotNull);

      // Enter invalid range: Min = 100, Max = 50
      await tester.enterText(
        find.widgetWithText(TextField, 'Min Price'),
        '100',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Max Price'), '50');
      await tester.pumpAndSettle();

      // Error message shown
      expect(
        find.text('Min price must be less than or equal to Max price'),
        findsOneWidget,
      );

      // Apply button is disabled
      final applyButtonAfter = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Apply Filters'),
      );
      expect(applyButtonAfter.onPressed, isNull);
    },
  );
}
