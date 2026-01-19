part of 'property_editor_page.dart';

extension _PropertyEditorActions on _PropertyEditorPageState {
  Future<void> _initData() async {
    try {
      final auth = context.read<AuthRepositoryDomain>();
      final user = await auth.userChanges.first;
      if (!mounted) return;
      _userRole = user?.role ?? UserRole.owner;
      _userId = user?.id;

      final prop = widget.property;
      if (prop != null) {
        _titleCtrl.text = prop.title ?? '';
        _descCtrl.text = prop.description ?? '';
        _priceCtrl.text = prop.price != null
            ? PriceFormatter.format(prop.price!, currency: '').trim()
            : '';
        _locationUrlCtrl.text = prop.locationUrl ?? '';
        _roomsCtrl.text = prop.rooms?.toString() ?? '';
        _kitchensCtrl.text = prop.kitchens?.toString() ?? '';
        _floorsCtrl.text = prop.floors?.toString() ?? '';
        _phoneCtrl.text = prop.ownerPhoneEncryptedOrHiddenStored ?? '';
        _securityNumberCtrl.text =
            prop.securityNumberEncryptedOrHiddenStored ?? '';
        _showSecurityNumber = _securityNumberCtrl.text.trim().isNotEmpty;
        _hasPool = prop.hasPool;
        _isImagesHidden = prop.isImagesHidden;
        _purpose = prop.purpose;
        _locationId = prop.locationAreaId;
        for (final url in prop.imageUrls) {
          _images.add(
            EditableImage(remoteUrl: url, isCover: url == prop.coverImageUrl),
          );
          _originalRemoteImages.add(url);
        }
        if (_images.isNotEmpty && !_images.any((e) => e.isCover)) {
          _images.first.isCover = true;
        }
      }

      if (!mounted) return;
      final getAreas = context.read<GetLocationAreasUseCase>();
      final locations = await getAreas.call(force: true);
      if (!mounted) return;
      _locations = locations;
      if (_locationId != null && !_locations.any((l) => l.id == _locationId)) {
        _locationId = null;
      }
    } catch (e, st) {
      AppSnackbar.show(
        context,
        mapErrorMessage(e, stackTrace: st),
        type: AppSnackbarType.error,
      );
    } finally {
      if (mounted)
        // ignore: invalid_use_of_protected_member
        setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    await LoadingDialog.show(context, () async {
      try {
        final picked = await _picker.pickMultiImage();
        if (picked.isEmpty) return;
        for (final f in picked) {
          final bytes = await f.readAsBytes();
          _images.add(EditableImage(file: f, preview: bytes));
        }
        if (_images.isNotEmpty && !_images.any((e) => e.isCover)) {
          _images.first.isCover = true;
        }
        // ignore: invalid_use_of_protected_member
        setState(() {});
      } catch (e) {
        AppSnackbar.show(
          context,
          'image_pick_failed'.tr(args: ['$e']),
          type: AppSnackbarType.error,
        );
      }
    }());
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) return;
    final removedWasCover = _images[index].isCover;
    _images.removeAt(index);
    if (_images.isNotEmpty && removedWasCover) {
      _images.first.isCover = true;
    }
    // ignore: invalid_use_of_protected_member
    setState(() {});
  }

  void _setCover(int index) {
    if (index < 0 || index >= _images.length) return;
    for (final imgItem in _images) {
      imgItem.isCover = false;
    }
    _images[index].isCover = true;
    // ignore: invalid_use_of_protected_member
    setState(() {});
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;

    // Unfocus to dismiss keyboard and prevent focus-related crashes during transition
    FocusScope.of(context).unfocus();

    if (_images.isEmpty) {
      AppSnackbar.show(
        context,
        'images_required'.tr(),
        type: AppSnackbarType.error,
      );
      return;
    }
    if (_locations.isEmpty) {
      AppSnackbar.show(
        context,
        'no_locations_description'.tr(),
        type: AppSnackbarType.error,
      );
      return;
    }
    if (_locationId == null) {
      AppSnackbar.show(
        context,
        'location_required'.tr(),
        type: AppSnackbarType.error,
      );
      return;
    }
    if (_userId == null) {
      AppSnackbar.show(
        context,
        'missing_user_context'.tr(),
        type: AppSnackbarType.error,
      );
      return;
    }

    final repo = context.read<PropertiesRepository>();
    final propertyId = widget.property?.id ?? repo.generateId();

    final overlayController = PropertyEditorProgressOverlayController(
      const PropertyEditorProgress(
        stage: PropertyEditorStage.uploadingImages,
        fraction: 0,
      ),
    );
    overlayController.show(context);

    try {
      await _performSave(repo, propertyId, overlayController);
    } finally {
      overlayController.hide();
    }
  }

  Future<void> _performSave(
    PropertiesRepository repo,
    String propertyId,
    PropertyEditorProgressOverlayController overlayController,
  ) async {
    try {
      final createUseCase = context.read<CreatePropertyUseCase>();
      final updateUseCase = context.read<UpdatePropertyUseCase>();
      final notificationsRepo = context.read<NotificationsRepository>();
      if (!_images.any((e) => e.isCover) && _images.isNotEmpty) {
        _images.first.isCover = true;
      }

      // Stage 1: Uploading images
      overlayController.update(
        const PropertyEditorProgress(
          stage: PropertyEditorStage.uploadingImages,
          fraction: 0.2,
        ),
      );

      final upload = await context.read<UploadPropertyImagesUseCase>().call(
        _images,
        propertyId,
      );

      // Stage 2: Saving details
      overlayController.update(
        const PropertyEditorProgress(
          stage: PropertyEditorStage.savingDetails,
          fraction: 0.6,
        ),
      );
      final nowCover = upload.coverUrl;
      final description = _descCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();
      final phoneValue = phone.isEmpty ? null : phone;
      final securityNumber = _securityNumberCtrl.text.trim();
      final securityNumberValue = securityNumber.isEmpty
          ? null
          : securityNumber;
      final locationUrl = _locationUrlCtrl.text.trim();
      final locationValue = locationUrl.isEmpty ? null : locationUrl;
      final price = Validators.parsePrice(_priceCtrl.text);
      if (price == null || price <= 0) {
        AppSnackbar.show(
          context,
          'price_invalid'.tr(),
          type: AppSnackbarType.error,
        );
        return;
      }

      if (widget.property == null) {
        final created = await createUseCase(
          id: propertyId,
          userId: _userId!,
          userRole: _userRole,
          title: _titleCtrl.text.trim(),
          description: description,
          purpose: _purpose,
          rooms: int.tryParse(_roomsCtrl.text),
          kitchens: int.tryParse(_kitchensCtrl.text),
          floors: int.tryParse(_floorsCtrl.text),
          hasPool: _hasPool,
          locationAreaId: _locationId,
          price: price,
          locationUrl: locationValue,
          ownerPhoneEncryptedOrHiddenStored: phoneValue,
          securityNumberEncryptedOrHiddenStored: securityNumberValue,
          isImagesHidden: _isImagesHidden,
          imageUrls: upload.urls,
          coverImageUrl: nowCover,
        );
        await _sendPropertyAddedNotification(notificationsRepo, created);
        context.read<PropertyMutationsBloc>().notify(
          PropertyMutationType.added,
          propertyId: created.id,
          ownerScope: created.ownerScope,
          locationAreaId: created.locationAreaId,
        );
      } else {
        final updated = await updateUseCase(
          existing: widget.property!,
          userId: _userId!,
          userRole: _userRole,
          title: _titleCtrl.text.trim(),
          description: description,
          purpose: _purpose,
          rooms: int.tryParse(_roomsCtrl.text),
          kitchens: int.tryParse(_kitchensCtrl.text),
          floors: int.tryParse(_floorsCtrl.text),
          hasPool: _hasPool,
          locationAreaId: _locationId,
          price: price,
          locationUrl: locationValue,
          ownerPhoneEncryptedOrHiddenStored: phoneValue,
          securityNumberEncryptedOrHiddenStored: securityNumberValue,
          isImagesHidden: _isImagesHidden,
          imageUrls: upload.urls,
          coverImageUrl: nowCover,
        );
        await context.read<DeletePropertyImagesUseCase>().call(
          removedUrls: _originalRemoteImages
              .difference(upload.urls.toSet())
              .toList(),
        );
        context.read<PropertyMutationsBloc>().notify(
          PropertyMutationType.updated,
          propertyId: widget.property!.id,
          ownerScope: updated.ownerScope,
          locationAreaId: updated.locationAreaId,
        );
      }

      if (mounted) context.pop();
    } catch (e, st) {
      AppSnackbar.show(
        context,
        mapErrorMessage(e, stackTrace: st),
        type: AppSnackbarType.error,
      );
    }
  }

  Future<void> _sendPropertyAddedNotification(
    NotificationsRepository notificationsRepository,
    Property property,
  ) async {
    try {
      final brief = _buildPropertyBrief(property);
      await notificationsRepository.sendPropertyAdded(
        property: property,
        brief: brief,
      );
    } catch (_) {
      // Notifications should not block property creation; log silently.
    }
  }

  String _buildPropertyBrief(Property property) {
    final purposeLabel = property.purpose == PropertyPurpose.sale
        ? 'purpose.sale'.tr()
        : 'purpose.rent'.tr();
    final locationName = _locations
        .firstWhere(
          (l) => l.id == property.locationAreaId,
          orElse: () => LocationArea(
            id: '',
            nameAr: '',
            nameEn: '',
            imageUrl: '',
            isActive: true,
            createdAt: DateTime.now(),
          ),
        )
        .name;
    if (locationName.isNotEmpty) {
      return '$purposeLabel • $locationName';
    }
    if (property.rooms != null) {
      return '$purposeLabel • ${property.rooms} rooms';
    }
    return purposeLabel;
  }
}
