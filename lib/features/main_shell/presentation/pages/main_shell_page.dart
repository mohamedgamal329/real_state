import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_bloc.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/pages/categories_filter_page.dart';
import 'package:real_state/features/company_areas/domain/usecases/get_company_areas_usecase.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_bloc.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_event.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';
import 'package:real_state/features/main_shell/presentation/widgets/liquid_glass_bottom_bar.dart';
import 'package:real_state/features/main_shell/presentation/widgets/liquid_glass_bottom_bar_tab.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/pages/properties_page.dart';
import 'package:real_state/features/settings/presentation/pages/settings_page.dart';

class BottomTabController {
  static late TabController _controller;
  static TabController get controller => _controller;

  static void animateTo(int value) => _controller.animateTo(value);
}

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.pageIndex = 0});
  final int pageIndex;
  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with SingleTickerProviderStateMixin {
  late final CompanyAreasBloc _companyAreasBloc;
  late final BrokerAreasBloc _brokerAreasBloc;
  late final CategoriesCubit _categoriesCubit;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _initializeTabController();
    _initializeCubits();
    _pages = const [
      HomePage(key: PageStorageKey('properties_page')),
      CategoriesFilterPage(key: PageStorageKey('categories_filter_page')),
      SettingsPage(key: PageStorageKey('settings_page')),
    ];
  }

  @override
  void dispose() {
    BottomTabController.controller.removeListener(_handleTabChange);
    _companyAreasBloc.close();
    _brokerAreasBloc.close();
    _categoriesCubit.close();
    super.dispose();
  }

  void _initializeTabController() {
    BottomTabController._controller = TabController(
      vsync: this,
      length: 3,
      initialIndex: widget.pageIndex,
    );
    BottomTabController.controller.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {});
  }

  void _initializeCubits() {
    _companyAreasBloc = CompanyAreasBloc(
      context.read<GetCompanyAreasUseCase>(),
      context.read<PropertyMutationsBloc>(),
    )..add(const CompanyAreasRequested());

    _brokerAreasBloc = BrokerAreasBloc(
      context.read<GetBrokerAreasUseCase>(),
      context.read<AuthRepositoryDomain>(),
      context.read<PropertyMutationsBloc>(),
    );

    _categoriesCubit =
        CategoriesCubit(
            context.read<PropertiesRepository>(),
            context.read<GetLocationAreasUseCase>(),
            context.read<PropertyMutationsBloc>(),
            context.read<AuthRepositoryDomain>(),
          )
          ..loadFirstPage()
          ..loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<CompanyAreasBloc>.value(value: _companyAreasBloc),
            BlocProvider<BrokerAreasBloc>.value(value: _brokerAreasBloc),
            BlocProvider<CategoriesCubit>.value(value: _categoriesCubit),
          ],
          child: Scaffold(
            body: Stack(
              children: [
                TabBarView(
                  controller: BottomTabController.controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _pages,
                ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: LiquidGlassBottomBar(
                      tabs: [
                        LiquidGlassTabItem(label: 'home'.tr(), icon: Icons.home_outlined),
                        LiquidGlassTabItem(label: 'filter'.tr(), icon: Icons.filter_alt_outlined),
                        LiquidGlassTabItem(label: 'settings'.tr(), icon: Icons.settings_outlined),
                      ],
                      indicatorColor: Colors.black.withValues(alpha: 0.04),
                      selectedIndex: BottomTabController.controller.index,
                      onTabSelected: (index) {
                        BottomTabController.animateTo(index);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
