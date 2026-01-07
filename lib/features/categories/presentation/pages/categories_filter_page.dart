import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/core/widgets/app_dropdown.dart';
import 'package:real_state/core/widgets/app_select_item.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';

class CategoriesFilterPage extends StatefulWidget {
  const CategoriesFilterPage({super.key});

  @override
  State<CategoriesFilterPage> createState() => _CategoriesFilterPageState();
}

class _CategoriesFilterPageState extends State<CategoriesFilterPage> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedLocationId;
  late TextEditingController _minPriceCtrl;
  late TextEditingController _maxPriceCtrl;
  late int? _selectedRooms;
  late bool _hasPool;
  bool _formattingPrice = false;
  String? _priceError;

  @override
  void initState() {
    super.initState();
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
    _validatePriceRange();
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _onApply() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final minP = Validators.parsePrice(_minPriceCtrl.text);
    final maxP = Validators.parsePrice(_maxPriceCtrl.text);
    final newFilter = PropertyFilter(
      locationAreaId: _selectedLocationId,
      minPrice: minP,
      maxPrice: maxP,
      rooms: _selectedRooms,
      hasPool: _hasPool ? true : null,
    );
    final cubit = context.read<CategoriesCubit>();
    cubit.applyFilter(newFilter);
    context.push('/categories', extra: cubit);
  }

  void _onClear() {
    context.read<CategoriesCubit>().clearFilters();
    context.pop();
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
    _validatePriceRange();
    _formattingPrice = false;
    setState(() {});
  }

  void _validatePriceRange() {
    final minP = Validators.parsePrice(_minPriceCtrl.text);
    final maxP = Validators.parsePrice(_maxPriceCtrl.text);
    if (minP != null && maxP != null && minP > maxP) {
      _priceError = 'price_error_range'.tr();
    } else {
      _priceError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'filter',
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Image.asset('assets/images/logo.jpeg', height: 26),
          ),
        ],
      ),
      body: BaseGradientPage(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            final core = state as CategoriesCoreState;
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final isApplyEnabled = (_priceError == null);
            final selectedExists = core.locationAreas.any(
              (l) => l.id == _selectedLocationId,
            );
            if (!selectedExists) _selectedLocationId = null;

            return SafeArea(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'filter_properties'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: _onClear,
                              child: Text('clear'.tr()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _SectionHeader(label: 'filter_location_label'.tr()),
                        const SizedBox(height: 8),
                        if (core.locationAreas.isEmpty)
                          _EmptyLocations(
                            onAdd: () async {
                              await context.push('/settings/locations');
                              await context
                                  .read<CategoriesCubit>()
                                  .ensureLocationsLoaded(force: true);
                            },
                          )
                        else ...[
                          AppDropdown<String?>(
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
                                (area) => AppSelectItem(
                                  value: area.id,
                                  label: area.name,
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedLocationId = val),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _SectionHeader(label: 'price_range'.tr()),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'min_price'.tr(),
                                controller: _minPriceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    AED,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'AED',
                                        ),
                                  ),
                                ),
                                validator: (_) => _priceError,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'max_price'.tr(),
                                controller: _maxPriceCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    AED,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'AED',
                                        ),
                                  ),
                                ),
                                validator: (_) => _priceError,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).nextFocus(),
                              ),
                            ),
                          ],
                        ),
                        if (_priceError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _priceError!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _SectionHeader(label: 'rooms_label'.tr()),
                        const SizedBox(height: 8),
                        AppDropdown<int?>(
                          key: ValueKey(_selectedRooms ?? 'any'),
                          value: _selectedRooms,
                          labelText: 'rooms_label'.tr(),
                          hintText: 'any'.tr(),
                          items: [
                            AppSelectItem(value: null, label: 'any'.tr()),
                            AppSelectItem(
                              value: 1,
                              label: 'room_option_1'.tr(),
                            ),
                            AppSelectItem(
                              value: 2,
                              label: 'room_option_2'.tr(),
                            ),
                            AppSelectItem(
                              value: 3,
                              label: 'room_option_3'.tr(),
                            ),
                            AppSelectItem(
                              value: 4,
                              label: 'room_option_4'.tr(),
                            ),
                            AppSelectItem(
                              value: 5,
                              label: 'room_option_5'.tr(),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedRooms = val),
                        ),
                        const SizedBox(height: 16),
                        _SectionHeader(label: 'has_pool'.tr()),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'has_pool'.tr(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Switch(
                                value: _hasPool,
                                onChanged: (val) =>
                                    setState(() => _hasPool = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'apply_filters'.tr(),
                          onPressed: isApplyEnabled ? _onApply : null,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _onClear,
                          child: Text('clear_filters'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  final Future<void> Function() onAdd;

  const _EmptyLocations({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'locations_empty_title'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'filter_location_empty_hint'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await onAdd();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('locations_add_cta'.tr()),
          ),
        ],
      ),
    );
  }
}
