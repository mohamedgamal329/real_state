import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/presentation/flows/property_flow.dart';
import 'package:real_state/core/utils/property_placeholders.dart';
import 'package:real_state/core/widgets/property_share_progress_overlay.dart';

import 'property_detail_bloc_provider.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_event.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';
import 'property_view.dart';

class PropertyPageBody extends StatefulWidget {
  final String id;
  final bool readOnly;
  const PropertyPageBody({super.key, required this.id, this.readOnly = false});

  @override
  State<PropertyPageBody> createState() => _PropertyPageBodyState();
}

class _PropertyPageBodyState extends State<PropertyPageBody> {
  final ScrollController _imagesCtrl = ScrollController();
  final int _imagesBatch = 5;
  static const double _imagesScrollThreshold = 100;

  late final PropertyFlow _flow;
  bool _snackbarsAttached = false;

  int _currentImagesToShow = 0;
  int _totalImages = 0;
  int _lastLoadMoreTriggerCount = -1;
  VoidCallback? _onImagesEndReached;
  PropertyShareProgress? _currentShareProgress;

  @override
  void initState() {
    super.initState();
    _flow = PropertyFlow();
    _imagesCtrl.addListener(_onImagesScroll);
  }

  @override
  void dispose() {
    _flow.dispose();
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
    return PropertyDetailBlocProvider(
      propertyId: widget.id,
      child: Builder(
        builder: (context) {
          if (!_snackbarsAttached) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _flow.startSnackbars(context);
              _snackbarsAttached = true;
            });
          }
          return BlocListener<PropertyDetailBloc, PropertyDetailState>(
            listenWhen: (prev, curr) =>
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
                AppSnackbar.show(
                  context,
                  state.message,
                  type: AppSnackbarType.error,
                );
                return;
              }
            },
            child: BlocBuilder<PropertyDetailBloc, PropertyDetailState>(
              builder: (context, state) {
                final bool isLoading =
                    state is PropertyDetailInitial ||
                    state is PropertyDetailLoading;
                final loaded = _loadedFrom(state);
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
                final securityGuardPhoneAccessible =
                    loaded?.securityGuardPhoneVisible ?? false;
                final canRequestAccess = loaded?.canRequestAccess ?? false;
                final canRequestImages =
                    canRequestAccess &&
                    !imagesAccessible &&
                    property.imageUrls.isNotEmpty;
                final canRequestPhone =
                    canRequestAccess &&
                    ((loaded?.hasPhone ?? false) ||
                        (loaded?.hasSecurityGuardPhone ?? false)) &&
                    !phoneAccessible &&
                    !securityGuardPhoneAccessible;
                final canRequestLocation =
                    canRequestAccess &&
                    (loaded?.hasLocationUrl ?? false) &&
                    !(loaded?.locationVisible ?? false);
                final failureMessage = state is PropertyDetailFailure
                    ? state.message
                    : null;
                final showNotFound = failureMessage != null;

                _syncImagesPagination(
                  imagesToShow:
                      loaded?.imagesToShow ?? property.imageUrls.length,
                  totalImages: property.imageUrls.length,
                  onLoadMoreRequested: loaded != null
                      ? () => context.read<PropertyDetailBloc>().add(
                          PropertyImagesLoadMoreRequested(_imagesBatch),
                        )
                      : null,
                );

                final view = PropertyPageView(
                  property: property,
                  imagesController: _imagesCtrl,
                  imagesToShow:
                      loaded?.imagesToShow ?? property.imageUrls.length,
                  imagesAccessible: imagesAccessible,
                  phoneAccessible: phoneAccessible,
                  securityGuardPhoneAccessible: securityGuardPhoneAccessible,
                  locationAccessible: loaded?.locationVisible ?? false,
                  creatorName: loaded?.creatorName,
                  isSkeleton: isLoading,
                  canShare: canShare,
                  canModify: canModify,
                  canArchiveOrDelete: canArchiveOrDelete,
                  mutationGuard: _flow.mutationGuard,
                  showError: showNotFound,
                  errorMessage: failureMessage,
                  notFound: notFound,
                  onRetry: () => context.read<PropertyDetailBloc>().add(
                    PropertyDetailStarted(widget.id),
                  ),
                  onShare: canShare
                      ? () => _flow.openShareSheet(context)
                      : null,
                  onEdit: canModify
                      ? () async {
                          await context.push(
                            '/property/${property.id}/edit',
                            extra: property,
                          );
                        }
                      : null,
                  onArchive: canArchiveOrDelete
                      ? () => _flow.archiveProperty(context)
                      : null,
                  onDelete: canArchiveOrDelete
                      ? () => _flow.deleteProperty(context)
                      : null,
                  onRequestImages: canRequestImages
                      ? () => _flow.requestAccess(
                          context,
                          widget.id,
                          AccessRequestType.images,
                        )
                      : null,
                  onRequestPhone: canRequestPhone
                      ? () => _flow.requestAccess(
                          context,
                          widget.id,
                          AccessRequestType.phone,
                        )
                      : null,
                  onRequestLocation: canRequestLocation
                      ? () => _flow.requestAccess(
                          context,
                          widget.id,
                          AccessRequestType.location,
                        )
                      : null,
                );

                return PropertyPageBodyView(
                  view: view,
                  shareProgress: _currentShareProgress,
                );
              },
            ),
          );
        },
      ),
    );
  }

  PropertyDetailLoaded? _loadedFrom(PropertyDetailState state) {
    if (state is PropertyDetailLoaded) return state;
    if (state is PropertyDetailActionSuccess) return state.data;
    if (state is PropertyDetailShareInProgress) return state.data;
    if (state is PropertyDetailShareSuccess) return state.data;
    if (state is PropertyDetailShareFailure) return state.data;
    return null;
  }

  void _syncImagesPagination({
    required int imagesToShow,
    required int totalImages,
    VoidCallback? onLoadMoreRequested,
  }) {
    _currentImagesToShow = imagesToShow;
    _totalImages = totalImages;
    _onImagesEndReached = onLoadMoreRequested;
    if (_currentImagesToShow >= _totalImages) {
      _lastLoadMoreTriggerCount = -1;
    }
  }
}

class PropertyPageBodyView extends StatelessWidget {
  final Widget view;
  final PropertyShareProgress? shareProgress;

  const PropertyPageBodyView({
    super.key,
    required this.view,
    required this.shareProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        view,
        if (shareProgress != null)
          PropertyShareProgressOverlay(progress: shareProgress!),
      ],
    );
  }
}
