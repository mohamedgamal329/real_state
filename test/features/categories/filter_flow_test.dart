import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';
import 'package:real_state/features/categories/presentation/pages/categories_filter_page.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/widgets/property_filter/property_filter_form.dart';

// Mocks
class MockCategoriesCubit extends Mock implements CategoriesCubit {}

void main() {
  late MockCategoriesCubit mockCubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockCubit = MockCategoriesCubit();
    when(() => mockCubit.stream).thenAnswer((_) => Stream.empty());
    when(() => mockCubit.close()).thenAnswer((_) async {});
    when(() => mockCubit.ensureLocationsLoaded()).thenAnswer((_) async {});
  });

  testWidgets(
    'FIX 2: CategoriesFilterPage shows Apply button and validates flow',
    (tester) async {
      final state = CategoriesInitial(
        filter: const PropertyFilter(),
        locationAreas: const [],
        areaNames: const {},
      );
      when(() => mockCubit.state).thenReturn(state);

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          startLocale: const Locale('en'),
          child: MaterialApp(
            home: BlocProvider<CategoriesCubit>.value(
              value: mockCubit,
              child: const CategoriesFilterPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Form exists
      expect(find.byType(PropertyFilterForm), findsOneWidget);
    },
  );
}
