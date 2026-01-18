import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/core/widgets/app_dropdown.dart';
import 'package:real_state/core/widgets/app_select_item.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/controllers/property_filter_controller.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';
import 'package:real_state/core/widgets/property_filter/property_filter_form.dart';
import 'package:real_state/features/categories/presentation/pages/categories_filter_view.dart';
import 'package:real_state/features/notifications/presentation/widgets/notifications_icon_button.dart';
import 'package:real_state/core/widgets/clean_logo.dart';

class CategoriesFilterPage extends StatefulWidget {
  const CategoriesFilterPage({super.key});

  @override
  State<CategoriesFilterPage> createState() => _CategoriesFilterPageState();
}

class _CategoriesFilterPageState extends State<CategoriesFilterPage> {
  final _formKey = GlobalKey<FormState>();
  late final CategoriesFilterController _filterController;
  late String? _selectedLocationId;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;
  late int? _selectedRooms;
  late bool _hasPool;
  bool _formattingPrice = false;
  String? _validationErrorKey;

  @override
  void initState() {
    super.initState();
    _filterController = const CategoriesFilterController();
    final cubit = context.read<CategoriesCubit>();
    cubit.ensureLocationsLoaded();
    final core = cubit.state is CategoriesCoreState
        ? cubit.state as CategoriesCoreState
        : const CategoriesInitial();
    final f = core.filter;
    _selectedLocationId = f.locationAreaId;
    _minPriceCtrl = TextEditingController(
      text: f.minPrice != null
          ? PriceFormatter.format(f.minPrice!, currency: '').trim()
          : '',
    );
    _maxPriceCtrl = TextEditingController(
      text: f.maxPrice != null
          ? PriceFormatter.format(f.maxPrice!, currency: '').trim()
          : '',
    );
    _selectedRooms = f.rooms;
    _hasPool = f.hasPool ?? false;
    _minPriceCtrl.addListener(() => _formatPrice(_minPriceCtrl));
    _maxPriceCtrl.addListener(() => _formatPrice(_maxPriceCtrl));
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _onApply() {
    final candidate = _buildCandidateFilter();
    final validation = _filterController.validate(candidate);
    setState(() {
      _validationErrorKey = validation.error?.messageKey;
    });
    _formKey.currentState?.validate();
    if (!validation.isSuccess) return;
    final cubit = context.read<CategoriesCubit>();
    cubit.applyFilter(validation.filter!);
    context.push('/filters/results', extra: validation.filter!);
  }

  Future<void> _onClear() async {
    _clearValidationError();
    context.read<CategoriesCubit>().clearFilters();
    final didPop = await Navigator.of(context).maybePop();
    if (didPop || !context.mounted) return;
    context.go('/categories');
  }

  String _stripCurrency(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned;
  }

  void _formatPrice(TextEditingController controller) {
    if (_formattingPrice) return;
    _formattingPrice = true;
    final cleaned = _stripCurrency(controller.text);
    if (cleaned.isEmpty) {
      controller.text = '';
      _formattingPrice = false;
      setState(() {});
      return;
    }
    final value = double.tryParse(cleaned);
    if (value != null) {
      final formatted = PriceFormatter.format(value, currency: '').trim();
      if (formatted != controller.text) {
        controller.text = formatted;
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      }
    }
    _clearValidationError();
    _formattingPrice = false;
    setState(() {});
  }

  PropertyFilter _buildCandidateFilter() {
    final minP = Validators.parsePrice(_minPriceCtrl.text);
    final maxP = Validators.parsePrice(_maxPriceCtrl.text);
    return PropertyFilter(
      locationAreaId: _selectedLocationId,
      minPrice: minP,
      maxPrice: maxP,
      rooms: _selectedRooms,
      hasPool: _hasPool ? true : null,
    );
  }

  void _clearValidationError() {
    if (_validationErrorKey == null) return;
    setState(() {
      _validationErrorKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'filter',
        actions: const [
          NotificationsIconButton(),
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CleanLogo(size: 32),
          ),
        ],
      ),
      body: BaseGradientPage(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            final core = state as CategoriesCoreState;
            final candidateFilter = _buildCandidateFilter();
            final validation = _filterController.validate(candidateFilter);
            final isApplyEnabled = validation.isSuccess;
            final selectedExists = core.locationAreas.any(
              (l) => l.id == _selectedLocationId,
            );
            if (_selectedLocationId != null &&
                core.locationAreas.isNotEmpty &&
                !selectedExists) {
              _selectedLocationId = null;
            }

            return CategoriesFilterView(
              form: PropertyFilterForm(
                formKey: _formKey,
                locationField: core.locationAreas.isEmpty
                    ? const SizedBox.shrink()
                    : AppDropdown<String?>(
                        key: ValueKey(_selectedLocationId ?? 'none'),
                        value:
                            core.locationAreas.any(
                              (l) => l.id == _selectedLocationId,
                            )
                            ? _selectedLocationId
                            : null,
                        labelText: 'filter_location_label'.tr(),
                        hintText: 'all_locations'.tr(),
                        items: [
                          AppSelectItem(
                            value: null,
                            label: 'all_locations'.tr(),
                          ),
                          ...core.locationAreas.map(
                            (area) =>
                                AppSelectItem(value: area.id, label: area.name),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedLocationId = val);
                          _clearValidationError();
                        },
                      ),
                roomsField: AppDropdown<int?>(
                  key: ValueKey(_selectedRooms ?? 'any'),
                  value: _selectedRooms,
                  labelText: 'rooms_label'.tr(),
                  hintText: 'any'.tr(),
                  items: [
                    AppSelectItem(value: null, label: 'any'.tr()),
                    AppSelectItem(value: 1, label: 'room_option_1'.tr()),
                    AppSelectItem(value: 2, label: 'room_option_2'.tr()),
                    AppSelectItem(value: 3, label: 'room_option_3'.tr()),
                    AppSelectItem(value: 4, label: 'room_option_4'.tr()),
                    AppSelectItem(value: 5, label: 'room_option_5'.tr()),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedRooms = val);
                    _clearValidationError();
                  },
                ),
                minPriceController: _minPriceCtrl,
                maxPriceController: _maxPriceCtrl,
                hasPool: _hasPool,
                onHasPoolChanged: (val) {
                  setState(() => _hasPool = val);
                  _clearValidationError();
                },
                onApply: _onApply,
                onClear: _onClear,
                isApplyEnabled: isApplyEnabled,
                showEmptyLocations: core.locationAreas.isEmpty,
                onAddLocation: () async {
                  await context.push('/settings/locations');
                  await context.read<CategoriesCubit>().ensureLocationsLoaded(
                    force: true,
                  );
                },
                validationErrorKey: _validationErrorKey,
              ),
            );
          },
        ),
      ),
    );
  }
}
