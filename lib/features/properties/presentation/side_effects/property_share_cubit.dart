import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/models/property_share_progress.dart';
import 'package:real_state/features/properties/domain/services/property_share_service.dart';
import 'package:real_state/features/properties/domain/usecases/share_property_pdf_usecase.dart';
import 'property_share_state.dart';

class PropertyShareCubit extends Cubit<PropertyShareState> {
  final PropertyShareService _shareService;
  final SharePropertyPdfUseCase _sharePdfUseCase;

  PropertyShareCubit(this._shareService, this._sharePdfUseCase)
    : super(const PropertyShareIdle());

  Future<void> shareImages({required Property property}) {
    return _performShare(
      (progressCallback) => _shareService.shareImagesOnly(
        property: property,
        onProgress: progressCallback,
      ),
    );
  }

  Future<void> sharePdf({
    required Property property,
    required String localeCode,
    required bool imagesVisible,
    required bool locationVisible,
    required UserRole? role,
    required String? userId,
  }) {
    return _performShare(
      (progressCallback) => _sharePdfUseCase(
        property: property,
        localeCode: localeCode,
        imagesVisible: imagesVisible,
        locationVisible: locationVisible,
        role: role,
        userId: userId,
        includeImages: imagesVisible,
        onProgress: progressCallback,
      ),
    );
  }

  Future<void> _performShare(
    Future<void> Function(PropertyShareProgressCallback?) job,
  ) async {
    emit(
      PropertyShareInProgress(
        PropertyShareProgress(
          stage: PropertyShareStage.preparingData,
          fraction: PropertyShareStage.preparingData.defaultFraction(),
        ),
      ),
    );
    try {
      await job(_handleProgress);
      emit(const PropertyShareSuccess());
    } catch (e, st) {
      emit(PropertyShareFailure(mapErrorMessage(e, stackTrace: st)));
    }
  }

  void _handleProgress(PropertyShareProgress progress) {
    emit(PropertyShareInProgress(progress.clamp()));
  }
}
