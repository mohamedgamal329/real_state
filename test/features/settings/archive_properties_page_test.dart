import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_state.dart';
import 'package:real_state/features/settings/presentation/pages/archive_properties/archive_properties_page.dart';
import 'package:real_state/core/widgets/property_filter/filter_bottom_sheet.dart';

import '../../fakes/fake_repositories.dart';
import '../../fakes/fake_services.dart';
import '../../helpers/pump_test_app.dart';
import '../fake_auth_repo/fake_auth_repo.dart';

class MockCategoriesCubit extends Mock implements CategoriesCubit {}

class _FakeArchivedPropertiesRepository extends FakePropertiesRepository {
  _FakeArchivedPropertiesRepository(this._items);

  final List<Property> _items;

  @override
  Future<PageResult<Property>> fetchArchivedPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) async {
    final filtered = _items.where((property) {
      if (property.isDeleted) return false;
      if (property.status != PropertyStatus.archived) return false;
      if (filter == null) return true;
      if (filter.locationAreaId != null &&
          property.locationAreaId != filter.locationAreaId) {
        return false;
      }
      if (filter.rooms != null && property.rooms != filter.rooms) return false;
      if (filter.hasPool == true && property.hasPool != true) return false;
      if (filter.createdBy != null && property.createdBy != filter.createdBy) {
        return false;
      }
      if (filter.minPrice != null) {
        final price = property.price;
        if (price == null || price < filter.minPrice!) return false;
      }
      if (filter.maxPrice != null) {
        final price = property.price;
        if (price == null || price > filter.maxPrice!) return false;
      }
      return true;
    }).toList();
    return PageResult(
      items: filtered.take(limit).toList(),
      lastDocument: null,
      hasMore: false,
    );
  }
}

void main() {
  testWidgets('ArchivePropertiesPage applies and clears filters', (
    tester,
  ) async {
    final archived1 = Property(
      id: 'a1',
      title: 'Archived 1',
      description: 'desc',
      purpose: PropertyPurpose.sale,
      price: 100,
      rooms: 1,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: 'area1',
      coverImageUrl: null,
      imageUrls: const [],
      ownerPhoneEncryptedOrHiddenStored: null,
      isImagesHidden: false,
      status: PropertyStatus.archived,
      isDeleted: false,
      createdBy: 'owner1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );
    final archived2 = Property(
      id: 'a2',
      title: 'Archived 2',
      description: 'desc',
      purpose: PropertyPurpose.sale,
      price: 1000,
      rooms: 3,
      kitchens: null,
      floors: null,
      hasPool: true,
      locationAreaId: 'area2',
      coverImageUrl: null,
      imageUrls: const [],
      ownerPhoneEncryptedOrHiddenStored: null,
      isImagesHidden: false,
      status: PropertyStatus.archived,
      isDeleted: false,
      createdBy: 'owner1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );
    final repo = _FakeArchivedPropertiesRepository([archived1, archived2]);
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: repo,
      authRepositoryOverride: FakeAuthRepo(
        const UserEntity(id: 'owner1', email: 'o@x', role: UserRole.owner),
      ),
      locationAreaDataSourceOverride: FakeLocationAreaRemoteDataSource(
        names: {
          'area1': LocationArea(
            id: 'area1',
            nameAr: 'Area 1',
            nameEn: 'Area 1',
            imageUrl: '',
            isActive: true,
            createdAt: DateTime.now(),
          ),
          'area2': LocationArea(
            id: 'area2',
            nameAr: 'Area 2',
            nameEn: 'Area 2',
            imageUrl: '',
            isActive: true,
            createdAt: DateTime.now(),
          ),
        },
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    final archiveBloc = ArchivePropertiesBloc(
      deps.propertiesRepository,
      deps.locationAreasRepository,
      deps.propertyMutationsBloc,
    );
    addTearDown(archiveBloc.close);

    // Create mock CategoriesCubit for filter bottom sheet
    final mockCategoriesCubit = MockCategoriesCubit();
    final categoriesState = CategoriesLoadSuccess(
      filter: const PropertyFilter(),
      locationAreas: [
        LocationArea(
          id: 'area1',
          nameAr: 'Area 1',
          nameEn: 'Area 1',
          imageUrl: '',
          isActive: true,
          createdAt: DateTime.now(),
        ),
        LocationArea(
          id: 'area2',
          nameAr: 'Area 2',
          nameEn: 'Area 2',
          imageUrl: '',
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ],
      areaNames: const {},
      items: const [],
      lastDoc: null,
      hasMore: false,
    );
    when(() => mockCategoriesCubit.state).thenReturn(categoriesState);
    when(
      () => mockCategoriesCubit.stream,
    ).thenAnswer((_) => Stream.value(categoriesState));
    when(
      () => mockCategoriesCubit.ensureLocationsLoaded(),
    ).thenAnswer((_) async {});
    when(() => mockCategoriesCubit.close()).thenAnswer((_) async {});
    addTearDown(mockCategoriesCubit.close);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: archiveBloc),
              BlocProvider<CategoriesCubit>.value(value: mockCategoriesCubit),
            ],
            child: const ArchivePropertiesPage(),
          ),
        ),
      ],
    );
    await pumpTestApp(
      tester,
      const SizedBox.shrink(),
      dependencies: deps,
      disableAnimations: false,
      router: router,
    );

    await tester.pumpAndSettle();
    expect(find.text('Archived 1'), findsOneWidget);
    expect(find.text('Archived 2'), findsOneWidget);

    final filterIcon = find.byWidgetPredicate(
      (widget) => widget is AppSvgIcon && widget.asset == AppSVG.filter,
    );
    await tester.tap(filterIcon);
    await tester.pumpAndSettle();
    expect(find.byKey(filterMinPriceInputKey), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Area 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(filterApplyButtonKey));
    await tester.pumpAndSettle();

    final filteredState = archiveBloc.state;
    expect(filteredState, isA<ArchivePropertiesLoaded>());
    if (filteredState is ArchivePropertiesLoaded) {
      expect(filteredState.filter.locationAreaId, 'area2');
    }
    expect(find.text('Archived 1'), findsNothing);
    expect(find.text('Archived 2'), findsOneWidget);

    await tester.tap(filterIcon);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(filterClearButtonKey));
    await tester.tap(find.byKey(filterClearButtonKey), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Archived 1'), findsOneWidget);
    expect(find.text('Archived 2'), findsOneWidget);
  });
}
