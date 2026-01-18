import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/widgets/property_filter/filter_bottom_sheet.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';

Future<void> showPropertyFilterBottomSheet(
  BuildContext context, {
  required PropertyFilter initialFilter,
  List<LocationArea>? locationAreas,
  required ValueChanged<PropertyFilter> onApply,
  VoidCallback? onClear,
  Future<void> Function()? onAddLocation,
}) async {
  final cubit = context.read<CategoriesCubit>();
  await cubit.ensureLocationsLoaded();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: FilterBottomSheet(
        currentFilter: initialFilter,
        locationAreas: locationAreas,
        onAddLocation: onAddLocation ?? () async {},
        onApply: onApply,
        onClear: onClear,
      ),
    ),
  );
}
