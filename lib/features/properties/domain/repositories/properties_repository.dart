import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';

/// Simple container to hold paginated results coming from the repository.
class PageResult<T> {
  final List<T> items;
  final PageToken? lastDocument;
  final bool hasMore;

  const PageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}

abstract class PropertiesRepository {
  Future<Property?> getById(String id);

  Future<Map<String, Property?>> fetchByIds(List<String> ids);

  String generateId();

  Future<PageResult<Property>> fetchPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  });

  Future<PageResult<Property>> fetchCompanyPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  });

  Future<PageResult<Property>> fetchBrokerPage({
    required String brokerId,
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
    UserRole? role,
  });

  Future<PageResult<Property>> fetchArchivedPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  });

  Future<Set<String>> fetchBrokerAreaIds(String brokerId, {UserRole? role});

  Future<Property> createProperty({
    String? id,
    required String userId,
    required UserRole userRole,
    String? title,
    String? description,
    PropertyPurpose purpose = PropertyPurpose.sale,
    int? rooms,
    int? kitchens,
    int? floors,
    bool hasPool = false,
    String? locationAreaId,
    String? locationUrl,
    double? price,
    String? ownerPhoneEncryptedOrHiddenStored,
    String? securityNumberEncryptedOrHiddenStored,
    bool isImagesHidden = false,
    List<String> imageUrls = const [],
    String? coverImageUrl,
  });

  Future<Property> updateProperty({
    required String id,
    required String userId,
    required UserRole userRole,
    String? title,
    String? description,
    PropertyPurpose? purpose,
    int? rooms,
    int? kitchens,
    int? floors,
    bool? hasPool,
    String? locationAreaId,
    String? locationUrl,
    double? price,
    String? ownerPhoneEncryptedOrHiddenStored,
    String? securityNumberEncryptedOrHiddenStored,
    bool? isImagesHidden,
    List<String>? imageUrls,
    String? coverImageUrl,
    PropertyStatus? status,
  });

  Future<Property> archiveProperty({
    required String id,
    required String userId,
    required UserRole userRole,
  });

  Future<void> deleteProperty({
    required String id,
    required String userId,
    required UserRole userRole,
  });

  static bool requiresPriceOrder(PropertyFilter? filter) {
    return (filter?.minPrice != null) || (filter?.maxPrice != null);
  }
}
