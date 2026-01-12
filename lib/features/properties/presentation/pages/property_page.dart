import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';
import 'package:real_state/features/properties/domain/usecases/share_property_pdf_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_detail_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_detail_event.dart';
import 'package:real_state/features/properties/presentation/bloc/property_detail_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/utils/property_placeholders.dart';
import 'package:real_state/features/properties/presentation/widgets/property_detail_view.dart';
import 'package:real_state/features/properties/presentation/widgets/property_request_dialog.dart';
import 'package:real_state/features/properties/presentation/widgets/property_share_progress_overlay.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';

class PropertyPage extends StatefulWidget {
  final String id;
  final bool readOnly;
  const PropertyPage({super.key, required this.id, this.readOnly = false});

  @override
  State<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends State<PropertyPage> {
  final ScrollController _imagesCtrl = ScrollController();
  final int _imagesBatch = 5;
  static const double _imagesScrollThreshold = 100;

  VoidCallback? _onImagesEndReached;
  int _currentImagesToShow = 0;
  int _totalImages = 0;
  int _lastLoadMoreTriggerCount = -1;
  PropertyShareProgress? _currentShareProgress;

  @override
  void initState() {
    super.initState();
    _imagesCtrl.addListener(_onImagesScroll);
  }

  @override
  void dispose() {
    _imagesCtrl.removeListener(_onImagesScroll);
    _imagesCtrl.dispose();
    super.dispose();
  }

  void _onImagesScroll() {
    if (!_imagesCtrl.hasClients || _onImagesEndReached == null) return;
    if (_totalImages == 0 || _currentImagesToShow >= _totalImages) return;
    final max = _imagesCtrl.position.maxScrollExtent;
    final pos = _imagesCtrl.position.pixels;
    final isNearEnd = pos >= max - _imagesScrollThreshold;
    if (!isNearEnd) return;
    if (_lastLoadMoreTriggerCount == _currentImagesToShow) return;
    _lastLoadMoreTriggerCount = _currentImagesToShow;
    _onImagesEndReached?.call();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertyDetailBloc(
        context.read<PropertiesRepository>(),
        context.read<AccessRequestsRepository>(),
        context.read<AuthRepositoryDomain>(),
        context.read<NotificationsRepository>(),
        context.read<PropertyShareService>(),
        context.read<UsersRepository>(),
        context.read<PropertyMutationsBloc>(),
        sharePropertyPdfUseCase: context.read<SharePropertyPdfUseCase>(),
      )..add(PropertyDetailStarted(widget.id)),
      child: BlocListener<PropertyDetailBloc, PropertyDetailState>(
        listenWhen: (prev, curr) =>
            curr is PropertyDetailActionSuccess ||
            curr is PropertyDetailFailure ||
            curr is PropertyDetailShareInProgress ||
            curr is PropertyDetailShareSuccess ||
            curr is PropertyDetailShareFailure,
        listener: (context, state) {
          if (state is PropertyDetailShareInProgress) {
            if (!mounted) return;
            setState(() => _currentShareProgress = state.progress);
            return;
          }
          if (state is PropertyDetailShareSuccess) {
            if (!mounted) return;
            setState(() => _currentShareProgress = null);
            return;
          }
          if (state is PropertyDetailShareFailure) {
            if (!mounted) return;
            setState(() => _currentShareProgress = null);
            AppSnackbar.show(context, state.message, isError: true);
            return;
          }
          if (state is PropertyDetailActionSuccess && state.message != null) {
            AppSnackbar.show(context, state.message!, isError: state.isError);
          }
          if (state is PropertyDetailFailure) {
            AppSnackbar.show(context, state.message, isError: true);
          }
        },
        child: BlocBuilder<PropertyDetailBloc, PropertyDetailState>(
          builder: (context, state) {
            final bool isLoading =
                state is PropertyDetailInitial ||
                state is PropertyDetailLoading;
            final loaded = state is PropertyDetailLoaded
                ? state
                : state is PropertyDetailActionSuccess
                ? state.data
                : state is PropertyDetailShareInProgress
                ? state.data
                : state is PropertyDetailShareSuccess
                ? state.data
                : state is PropertyDetailShareFailure
                ? state.data
                : null;
            final property = loaded?.property ?? placeholderProperty();
            final notFound =
                loaded != null && loaded.property.createdBy == 'unknown';
            final allowActions = !widget.readOnly;
            final canModify = allowActions && (loaded?.canModify ?? false);
            final canArchiveOrDelete =
                allowActions && (loaded?.canArchiveOrDelete ?? false);
            final canShare = allowActions && (loaded?.canShare ?? false);
            final imagesAccessible = loaded?.imagesVisible ?? false;
            final phoneAccessible = loaded?.phoneVisible ?? false;
            final canRequestAccess = loaded?.canRequestAccess ?? false;
            final canRequestImages =
                canRequestAccess &&
                !imagesAccessible &&
                property.imageUrls.isNotEmpty;
            final canRequestPhone =
                canRequestAccess &&
                (loaded?.hasPhone ?? false) &&
                !phoneAccessible;
            final canRequestLocation =
                canRequestAccess &&
                (loaded?.hasLocationUrl ?? false) &&
                !(loaded?.locationVisible ?? false);
            final showNotFound = state is PropertyDetailFailure;
            _syncImagesPagination(
              imagesToShow: loaded?.imagesToShow ?? property.imageUrls.length,
              totalImages: property.imageUrls.length,
              onLoadMoreRequested: loaded != null
                  ? () => context.read<PropertyDetailBloc>().add(
                      PropertyImagesLoadMoreRequested(_imagesBatch),
                    )
                  : null,
            );
            final scaffold = Scaffold(
              appBar: CustomAppBar(
                title: 'property',
                actions: [
                  if (loaded != null && canShare)
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _showShareSheet(context, loaded),
                    ),
                  if (loaded != null && canModify)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await context.push(
                          '/property/${property.id}/edit',
                          extra: property,
                        );
                      },
                    ),
                  if (loaded != null && canArchiveOrDelete)
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'archive') _archive(context);
                        if (v == 'delete') _delete(context);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('archive'.tr()),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('delete'.tr()),
                        ),
                      ],
                    ),
                ],
              ),
              body: BaseGradientPage(
                child: (showNotFound || notFound)
                    ? AppErrorView(
                        message: showNotFound
                            ? (state).message
                            : 'property_not_found'.tr(),
                        onRetry: () => context.read<PropertyDetailBloc>().add(
                          PropertyDetailStarted(widget.id),
                        ),
                      )
                    : AppSkeletonizer(
                        enabled: isLoading,
                        child: PropertyDetailView(
                          property: property,
                          imagesController: _imagesCtrl,
                          imagesToShow:
                              loaded?.imagesToShow ?? property.imageUrls.length,
                          imagesAccessible: imagesAccessible,
                          phoneAccessible: phoneAccessible,
                          locationAccessible: loaded?.locationVisible ?? false,
                          onRequestImages: canRequestImages
                              ? () => _showRequestDialog(
                                  context,
                                  AccessRequestType.images,
                                )
                              : null,
                          onRequestPhone: canRequestPhone
                              ? () => _showRequestDialog(
                                  context,
                                  AccessRequestType.phone,
                                )
                              : null,
                          onRequestLocation: canRequestLocation
                              ? () => _showRequestDialog(
                                  context,
                                  AccessRequestType.location,
                                )
                              : null,
                          creatorName: loaded?.creatorName,
                          isSkeleton: isLoading,
                        ),
                      ),
              ),
            );

            return Stack(
              children: [
                scaffold,
                if (_currentShareProgress != null)
                  PropertyShareProgressOverlay(progress: _currentShareProgress!),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showRequestDialog(
    BuildContext context,
    AccessRequestType type,
  ) async {
    final loaded = context.read<PropertyDetailBloc>().state;
    final prop = loaded is PropertyDetailLoaded
        ? loaded.property
        : loaded is PropertyDetailActionSuccess
        ? loaded.data.property
        : null;
    final result = await PropertyRequestDialog.show(
      context,
      type,
      property: prop,
    );
    if (result == null) return;
    await LoadingDialog.show(
      context,
      Future.sync(() {
        context.read<PropertyDetailBloc>().add(
          PropertyAccessRequested(
            propertyId: widget.id,
            type: type,
            message: result,
          ),
        );
      }),
    );
  }

  Future<void> _showShareSheet(
    BuildContext context,
    PropertyDetailLoaded loaded,
  ) async {
    if (!loaded.canShare) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('share_images_only'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () {
                  context.pop();
                  context.read<PropertyDetailBloc>().add(
                        PropertyShareImagesRequested(context),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text('share_details_pdf'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () {
                  context.pop();
                  context.read<PropertyDetailBloc>().add(
                    PropertySharePdfRequested(context),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _archive(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'archive_property_title',
      descriptionKey: 'archive_property_confirm',
      confirmLabelKey: 'archive',
      cancelLabelKey: 'cancel',
    );
    if (result != AppConfirmResult.confirmed) return;
    context.read<PropertyDetailBloc>().add(const PropertyArchiveRequested());
  }

  Future<void> _delete(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_property_title',
      descriptionKey: 'delete_property_confirm',
      confirmLabelKey: 'delete',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result != AppConfirmResult.confirmed) return;
    context.read<PropertyDetailBloc>().add(const PropertyDeleteRequested());
    final state = context.read<PropertyDetailBloc>().state;
    final wasSuccess = state is PropertyDetailActionSuccess && !state.isError;
    if (wasSuccess && mounted) {
      context.pop();
    }
  }

  void _syncImagesPagination({
    required int imagesToShow,
    required int totalImages,
    required VoidCallback? onLoadMoreRequested,
  }) {
    _currentImagesToShow = imagesToShow;
    _totalImages = totalImages;
    _onImagesEndReached = onLoadMoreRequested;
    if (_currentImagesToShow >= _totalImages) {
      _lastLoadMoreTriggerCount = -1;
    }
  }

}
