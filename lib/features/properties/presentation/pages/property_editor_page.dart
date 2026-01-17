import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/location/domain/repositories/location_repository.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';
import 'package:real_state/features/location/presentation/widgets/location_area_form_dialog.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/usecases/create_property_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/update_property_usecase.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/properties/models/property_editor_models.dart';
import 'package:real_state/features/properties/domain/usecases/upload_property_images_usecase.dart';
import 'package:real_state/features/properties/domain/usecases/delete_property_images_usecase.dart';
import 'package:real_state/features/properties/presentation/widgets/property_editor_form.dart';
import 'package:real_state/core/widgets/property_editor_progress.dart';
import 'package:real_state/core/widgets/property_editor_progress_overlay.dart';

part 'property_editor_actions.dart';

class PropertyEditorPage extends StatefulWidget {
  final Property? property;
  const PropertyEditorPage({super.key, this.property});

  bool get isEditing => property != null;

  @override
  State<PropertyEditorPage> createState() => _PropertyEditorPageState();
}

class _PropertyEditorPageState extends State<PropertyEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationUrlCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _kitchensCtrl = TextEditingController();
  final _floorsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _securityGuardPhoneCtrl = TextEditingController();
  bool _formattingPrice = false;
  bool _loading = true;
  bool _hasPool = false;
  bool _isImagesHidden = false;
  bool _showSecurityGuardPhone = false;
  PropertyPurpose _purpose = PropertyPurpose.sale;
  String? _locationId;

  UserRole _userRole = UserRole.owner;
  String? _userId;

  List<LocationArea> _locations = [];

  final List<EditableImage> _images = [];
  final _picker = ImagePicker();
  final Set<String> _originalRemoteImages = {};

  @override
  void initState() {
    super.initState();
    _priceCtrl.addListener(_formatPriceInput);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  @override
  void dispose() {
    _priceCtrl.removeListener(_formatPriceInput);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _locationUrlCtrl.dispose();
    _roomsCtrl.dispose();
    _kitchensCtrl.dispose();
    _floorsCtrl.dispose();
    _phoneCtrl.dispose();
    _securityGuardPhoneCtrl.dispose();
    super.dispose();
  }

  void _formatPriceInput() {
    if (_formattingPrice) return;
    _formattingPrice = true;
    final cleaned = _stripCurrency(_priceCtrl.text);
    if (cleaned.isEmpty) {
      _formattingPrice = false;
      return;
    }
    final value = double.tryParse(cleaned);
    if (value == null) {
      _formattingPrice = false;
      return;
    }
    final formatted = PriceFormatter.format(value, currency: '').trim();
    if (formatted != _priceCtrl.text) {
      _priceCtrl.text = formatted;
      _priceCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _priceCtrl.text.length),
      );
    }
    _formattingPrice = false;
  }

  String _stripCurrency(String input) {
    return input.replaceAll(RegExp(r'[^\d.]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _loading;
    final canCreate = canCreateProperty(_userRole);
    final canEdit =
        widget.property == null ||
        (widget.property != null &&
            _userId != null &&
            canModifyProperty(
              property: widget.property!,
              userId: _userId!,
              role: _userRole,
            ));

    Widget body;
    if (!isLoading && !canCreate && !widget.isEditing) {
      body = Center(child: Text('access_denied_add'.tr()));
    } else if (!isLoading && !canEdit) {
      body = Center(child: Text('access_denied_edit'.tr()));
    } else {
      body = PropertyEditorForm(
        formKey: _formKey,
        titleCtrl: _titleCtrl,
        descCtrl: _descCtrl,
        priceCtrl: _priceCtrl,
        locationUrlCtrl: _locationUrlCtrl,
        roomsCtrl: _roomsCtrl,
        kitchensCtrl: _kitchensCtrl,
        floorsCtrl: _floorsCtrl,
        phoneCtrl: _phoneCtrl,
        securityGuardPhoneCtrl: _securityGuardPhoneCtrl,
        isEditing: widget.isEditing,
        showSkeleton: isLoading,
        hasPool: _hasPool,
        isImagesHidden: _isImagesHidden,
        showSecurityGuardPhone: _showSecurityGuardPhone,
        purpose: _purpose,
        locationId: _locationId,
        locations: isLoading ? _placeholderLocations() : _locations,
        images: _images,
        onSave: _save,
        onPickImages: _pickImages,
        onRemoveImage: _removeImage,
        onSetCover: _setCover,
        onTogglePool: (v) => setState(() => _hasPool = v),
        onToggleImagesHidden: (v) => setState(() => _isImagesHidden = v),
        onPurposeChanged: (p) => setState(() => _purpose = p),
        onLocationChanged: (v) => setState(() => _locationId = v),
        onAddLocation: _handleAddLocationTap,
        onShowSecurityGuardPhone: () =>
            setState(() => _showSecurityGuardPhone = true),
      );
    }

    return PropertyEditorView(
      titleKey: widget.isEditing ? 'edit_property' : 'add_property',
      body: body,
    );
  }

  List<LocationArea> _placeholderLocations() {
    return List.generate(
      3,
      (i) => LocationArea(
        id: 'loc-$i',
        nameAr: 'locations_loading'.tr(),
        nameEn: 'locations_loading'.tr(),
        imageUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _refreshLocations({bool force = false}) async {
    try {
      final getAreas = context.read<GetLocationAreasUseCase>();
      final latest = await getAreas.call(force: force);
      if (!mounted) return;
      setState(() {
        _locations = latest;
        if (_locationId != null &&
            !_locations.any((l) => l.id == _locationId)) {
          _locationId = null;
        }
      });
    } catch (e, st) {
      if (mounted) {
        AppSnackbar.show(
          context,
          mapErrorMessage(e, stackTrace: st),
          type: AppSnackbarType.error,
        );
      }
    }
  }

  Future<void> _handleAddLocationTap() async {
    // Unfocus to avoid crashes when dialog overlay appears
    FocusScope.of(context).unfocus();

    final res = await LocationAreaFormDialog.show(context);
    if (res == null || res.imageFile == null) return;

    // We need LocationRepository to create.
    // Assuming Clean Architecture, we should probably use a UseCase, but for "Reusing Logic",
    // ManageLocationsPage used the Cubit which used the Repository.
    // We will access the repository directly here as we don't have a specific UseCase for creation injected yet,
    // and we want to avoid creating new classes if possible, per instructions.
    // However, if CreateLocationAreaUseCase fits, we'd use it.
    // We'll use the repository from context.

    try {
      final repo = context.read<LocationRepository>();

      // Unfocus again before loading overlay to be safe
      FocusScope.of(context).unfocus();

      final newId = await LoadingDialog.show(
        context,
        repo.create(
          nameAr: res.nameAr,
          nameEn: res.nameEn,
          imageFile: res.imageFile!,
        ),
      );

      if (!mounted) return;

      // Refresh list
      await _refreshLocations(force: true);

      // Select the new one
      setState(() {
        _locationId = newId;
      });

      AppSnackbar.show(context, 'location_created_success'.tr());
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'generic_error'.tr(),
          type: AppSnackbarType.error,
        );
      }
    }
  }
}

class PropertyEditorView extends StatelessWidget {
  final String titleKey;
  final Widget body;

  const PropertyEditorView({
    super.key,
    required this.titleKey,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titleKey.tr())),
      body: body,
    );
  }
}
