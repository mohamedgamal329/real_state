import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_state.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';

class MockPropertiesRepository extends Mock implements PropertiesRepository {}

class MockLocationAreasRepository extends Mock
    implements LocationAreasRepository {}

void main() {
  late MockPropertiesRepository repo;
  late MockLocationAreasRepository areaRepo;
  late PropertyMutationsBloc mutations;
  const filter = PropertyFilter.empty;
  final now = DateTime(2024);

  Property _prop(String id, {String area = 'a1'}) => Property(
    id: id,
    title: 'Property $id',
    purpose: PropertyPurpose.sale,
    locationAreaId: area,
    createdBy: 'u1',
    ownerScope: PropertyOwnerScope.company,
    createdAt: now,
    updatedAt: now,
  );

  LocationArea _area(String id, String name) => LocationArea(
    id: id,
    nameAr: name,
    nameEn: name,
    imageUrl: '',
    isActive: true,
    createdAt: now,
  );

  PageResult<Property> _page(
    List<Property> items, {
    bool hasMore = false,
    Object? lastDoc,
  }) => PageResult(
    items: items,
    hasMore: hasMore,
    lastDocument: lastDoc as dynamic,
  );

  setUpAll(() => registerFallbackValue(filter));

  setUp(() {
    repo = MockPropertiesRepository();
    areaRepo = MockLocationAreasRepository();
    mutations = PropertyMutationsBloc();
    when(() => areaRepo.fetchNamesByIds(any())).thenAnswer(
      (_) async => {'a1': _area('a1', 'Area 1'), 'a2': _area('a2', 'Area 2')},
    );
  });

  tearDown(() async {
    await mutations.close();
  });

  blocTest<PropertiesBloc, PropertiesState>(
    'initial load success emits loading then loaded',
    build: () {
      when(
        () => repo.fetchPage(
          limit: any(named: 'limit'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
        ),
      ).thenAnswer((_) async => _page([_prop('p1')], hasMore: true));
      return PropertiesBloc(repo, areaRepo, mutations);
    },
    act: (bloc) => bloc.add(const PropertiesStarted(filter: filter)),
    expect: () => [
      isA<PropertiesLoading>(),
      isA<PropertiesLoaded>()
          .having((s) => s.items.length, 'items', 1)
          .having((s) => s.hasMore, 'hasMore', true)
          .having((s) => s.areaNames['a1']?.nameEn, 'area', 'Area 1')
          .having((s) => s.filter, 'filter', filter),
    ],
  );

  blocTest<PropertiesBloc, PropertiesState>(
    'initial load failure emits loading then failure with mapped message',
    build: () {
      when(
        () => repo.fetchPage(
          limit: any(named: 'limit'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
        ),
      ).thenThrow(Exception('boom'));
      return PropertiesBloc(repo, areaRepo, mutations);
    },
    act: (bloc) => bloc.add(const PropertiesStarted(filter: filter)),
    expect: () => [isA<PropertiesLoading>(), isA<PropertiesFailure>()],
  );

  blocTest<PropertiesBloc, PropertiesState>(
    'refresh from loaded emits action states then refreshed data',
    build: () {
      var call = 0;
      when(
        () => repo.fetchPage(
          limit: any(named: 'limit'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
        ),
      ).thenAnswer((_) async {
        call++;
        return call == 1
            ? _page([_prop('p1')], hasMore: true)
            : _page([_prop('p2', area: 'a2')], hasMore: false);
      });
      return PropertiesBloc(repo, areaRepo, mutations);
    },
    act: (bloc) async {
      bloc.add(const PropertiesStarted(filter: filter));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PropertiesRefreshed());
    },
    expect: () => [
      isA<PropertiesLoading>(),
      isA<PropertiesLoaded>().having((s) => s.items.first.id, 'first', 'p1'),
      isA<PropertiesActionInProgress>(),
      isA<PropertiesActionSuccess>(),
      isA<PropertiesLoaded>()
          .having((s) => s.items.first.id, 'first', 'p2')
          .having((s) => s.hasMore, 'hasMore', false)
          .having((s) => s.areaNames['a2']?.nameEn, 'area2', 'Area 2'),
    ],
  );

  blocTest<PropertiesBloc, PropertiesState>(
    'load more appends items and preserves pagination',
    build: () {
      var call = 0;
      when(
        () => repo.fetchPage(
          limit: any(named: 'limit'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
        ),
      ).thenAnswer((_) async {
        call++;
        return call == 1
            ? _page([_prop('p1')], hasMore: true)
            : _page([_prop('p2')], hasMore: false);
      });
      return PropertiesBloc(repo, areaRepo, mutations);
    },
    act: (bloc) async {
      bloc.add(const PropertiesStarted(filter: filter));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PropertiesLoadMoreRequested());
    },
    expect: () => [
      isA<PropertiesLoading>(),
      isA<PropertiesLoaded>()
          .having((s) => s.items.length, 'len', 1)
          .having((s) => s.hasMore, 'hasMore', true),
      isA<PropertiesLoaded>()
          .having((s) => s.items.length, 'len', 2)
          .having((s) => s.hasMore, 'hasMore', false),
    ],
  );

  blocTest<PropertiesBloc, PropertiesState>(
    'load more ignored when hasMore is false',
    build: () => PropertiesBloc(repo, areaRepo, mutations),
    seed: () => PropertiesLoaded(
      items: [_prop('p1')],
      lastDoc: null,
      hasMore: false,
      areaNames: {'a1': _area('a1', 'Area 1')},
    ),
    act: (bloc) => bloc.add(const PropertiesLoadMoreRequested()),
    expect: () => <PropertiesState>[],
  );

  blocTest<PropertiesBloc, PropertiesState>(
    'external mutation triggers refresh without flicker',
    build: () {
      var call = 0;
      when(
        () => repo.fetchPage(
          limit: any(named: 'limit'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
        ),
      ).thenAnswer((_) async {
        call++;
        return call == 1
            ? _page([_prop('p1')], hasMore: true)
            : _page([_prop('p1'), _prop('p3', area: 'a2')], hasMore: false);
      });
      return PropertiesBloc(repo, areaRepo, mutations);
    },
    act: (bloc) async {
      bloc.add(const PropertiesStarted(filter: filter));
      await Future<void>.delayed(Duration.zero);
      mutations.notify(
        PropertyMutationType.updated,
        propertyId: 'p1',
        ownerScope: PropertyOwnerScope.company,
      );
      await Future<void>.delayed(Duration.zero);
    },
    expect: () => [
      isA<PropertiesLoading>(),
      isA<PropertiesLoaded>().having((s) => s.items.first.id, 'first', 'p1'),
      isA<PropertiesActionInProgress>(),
      isA<PropertiesActionSuccess>(),
      isA<PropertiesLoaded>()
          .having((s) => s.items.length, 'len', 2)
          .having((s) => s.areaNames['a2']?.nameEn, 'area2', 'Area 2')
          .having((s) => s.hasMore, 'hasMore', false),
    ],
  );
}
