import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';

class FilterBottomSheet extends StatefulWidget {
  final PropertyFilter currentFilter;
  final List<LocationArea> locationAreas;
  final Future<void> Function() onAddLocation;
  final Function(PropertyFilter) onApply;
  final VoidCallback? onClear;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.locationAreas,
    required this.onAddLocation,
    required this.onApply,
    this.onClear,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
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
    widget.onApply(newFilter);
    context.pop();
  }

  String _stripCurrency(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    return cleaned;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isApplyEnabled = (_priceError == null);
    final selectedExists = widget.locationAreas.any(
      (l) => l.id == _selectedLocationId,
    );
    if (!selectedExists) _selectedLocationId = null;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Material(
          color: colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'filter_properties'.tr(),
                          style: theme.textTheme.titleLarge,
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
                    if (widget.locationAreas.isEmpty)
                      _EmptyLocations(onAdd: widget.onAddLocation)
                    else ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedLocationId ?? 'none'),
                        initialValue:
                            widget.locationAreas.any(
                              (l) => l.id == _selectedLocationId,
                            )
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
                          ...widget.locationAreas.map(
                            (area) => DropdownMenuItem(
                              value: area.id,
                              child: Text(
                                area.localizedName(
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Text(
                                AED,
                                style: Theme.of(context).textTheme.labelMedium
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Text(
                                AED,
                                style: Theme.of(context).textTheme.labelMedium
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _SectionHeader(label: 'rooms_label'.tr()),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
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
                        DropdownMenuItem(
                          value: 1,
                          child: Text('room_option_1'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('room_option_2'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('room_option_3'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('room_option_4'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('room_option_5'.tr()),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedRooms = val),
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
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'has_pool'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Switch(
                            value: _hasPool,
                            onChanged: (val) => setState(() => _hasPool = val),
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
