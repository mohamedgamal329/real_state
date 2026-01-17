import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/controllers/property_filter_controller.dart';
import 'package:real_state/core/widgets/property_filter/filter_bottom_sheet_view.dart';
import 'package:real_state/core/widgets/property_filter/property_filter_form.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';

const filterApplyButtonKey = ValueKey('filter_apply_btn');
const filterClearButtonKey = ValueKey('filter_clear_btn');
const filterMinPriceInputKey = ValueKey('filter_min_price_input');
const filterMaxPriceInputKey = ValueKey('filter_max_price_input');

class FilterBottomSheet extends StatefulWidget {
  final PropertyFilter currentFilter;
  final Future<void> Function() onAddLocation;
  final Function(PropertyFilter) onApply;
  final VoidCallback? onClear;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onAddLocation,
    required this.onApply,
    this.onClear,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final CategoriesFilterController _filterController;
  late String? _selectedLocationId;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;
  late int? _selectedRooms;
  late bool _hasPool;
  bool _formattingPrice = false;

  @override
  void initState() {
    super.initState();
    _filterController = const CategoriesFilterController();
    context.read<CategoriesCubit>().ensureLocationsLoaded();
    final f = widget.currentFilter;
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
    if (!validation.isSuccess) {
      setState(() {});
      return;
    }
    widget.onApply(validation.filter!);
    context.pop();
  }

  String _stripCurrency(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned;
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

  void _onClear() {
    widget.onClear?.call();
    context.pop();
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
    _formattingPrice = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final core = state is CategoriesCoreState
            ? state
            : const CategoriesInitial();
        final locationAreas = core.locationAreas;
        final candidateFilter = _buildCandidateFilter();
        final validation = _filterController.validate(candidateFilter);
        final isApplyEnabled = validation.isSuccess;
        final validationErrorKey = validation.error?.messageKey;
        final selectedExists = locationAreas.any(
          (l) => l.id == _selectedLocationId,
        );
        if (_selectedLocationId != null &&
            locationAreas.isNotEmpty &&
            !selectedExists) {
          _selectedLocationId = null;
        }

        return FilterBottomSheetView(
          form: PropertyFilterForm(
            formKey: _formKey,
            locationField: locationAreas.isEmpty
                ? (state is CategoriesLoadInProgress ||
                          state is CategoriesInitial
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink())
                : DropdownButtonFormField<String>(
                    key: ValueKey(_selectedLocationId ?? 'none'),
                    initialValue:
                        locationAreas.any((l) => l.id == _selectedLocationId)
                        ? _selectedLocationId
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('all_locations'.tr()),
                      ),
                      ...locationAreas.map(
                        (area) => DropdownMenuItem(
                          value: area.id,
                          child: Text(
                            area
                                    .localizedName(
                                      localeCode: context.locale.toString(),
                                    )
                                    .isNotEmpty
                                ? area.localizedName(
                                    localeCode: context.locale.toString(),
                                  )
                                : 'placeholder_dash'.tr(),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedLocationId = val);
                    },
                  ),
            roomsField: DropdownButtonFormField<int>(
              key: ValueKey(_selectedRooms ?? 'any'),
              initialValue: _selectedRooms,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text('any'.tr())),
                DropdownMenuItem(value: 1, child: Text('room_option_1'.tr())),
                DropdownMenuItem(value: 2, child: Text('room_option_2'.tr())),
                DropdownMenuItem(value: 3, child: Text('room_option_3'.tr())),
                DropdownMenuItem(value: 4, child: Text('room_option_4'.tr())),
                DropdownMenuItem(value: 5, child: Text('room_option_5'.tr())),
              ],
              onChanged: (val) {
                setState(() => _selectedRooms = val);
              },
            ),
            minPriceController: _minPriceCtrl,
            maxPriceController: _maxPriceCtrl,
            hasPool: _hasPool,
            onHasPoolChanged: (val) {
              setState(() => _hasPool = val);
            },
            onApply: _onApply,
            onClear: _onClear,
            isApplyEnabled: isApplyEnabled,
            showEmptyLocations:
                locationAreas.isEmpty && state is! CategoriesLoadInProgress,
            onAddLocation: widget.onAddLocation,
            validationErrorKey: validationErrorKey,
            minPriceFieldKey: filterMinPriceInputKey,
            maxPriceFieldKey: filterMaxPriceInputKey,
            applyButtonKey: filterApplyButtonKey,
            clearButtonKey: filterClearButtonKey,
          ),
        );
      },
    );
  }
}
