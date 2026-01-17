import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/widgets/property_filter/filter_bottom_sheet.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';

import '../../helpers/pump_test_app.dart';

class MockCategoriesCubit extends Mock implements CategoriesCubit {}

void main() {
  late MockCategoriesCubit mockCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCubit = MockCategoriesCubit();
    when(() => mockCubit.close()).thenAnswer((_) async {});
    when(() => mockCubit.ensureLocationsLoaded()).thenAnswer((_) async {});
  });

  testWidgets(
    'shows validation error when min price > max price and disables Apply',
    (WidgetTester tester) async {
      const filter = PropertyFilter();
      final locations = [
        LocationArea(
          id: '1',
          nameAr: 'Area 1',
          nameEn: 'Area 1',
          imageUrl: '',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      final state = CategoriesLoadSuccess(
        locationAreas: locations,
        filter: filter,
        areaNames: const {},
        items: const [],
        lastDoc: null,
        hasMore: false,
      );

      when(() => mockCubit.state).thenReturn(state);
      when(() => mockCubit.stream).thenAnswer((_) => Stream.value(state));

      await pumpTestApp(
        tester,
        Scaffold(
          body: BlocProvider<CategoriesCubit>.value(
            value: mockCubit,
            child: FilterBottomSheet(
              onAddLocation: () async {},
              currentFilter: filter,
              onApply: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final applyFinder = find.byKey(filterApplyButtonKey);
      expect(applyFinder, findsOneWidget);

      final applyButton = tester.widget<PrimaryButton>(applyFinder);
      expect(applyButton.onPressed, isNotNull);

      await tester.enterText(find.byKey(filterMinPriceInputKey), '100');
      await tester.enterText(find.byKey(filterMaxPriceInputKey), '50');

      // Give time for text changes to be processed and validation to run
      await tester.pumpAndSettle();

      expect(find.text('price_error_range'.tr()), findsOneWidget);

      final applyButtonAfter = tester.widget<PrimaryButton>(applyFinder);
      expect(applyButtonAfter.onPressed, isNull);
    },
  );
}
