import 'package:easy_localization/easy_localization.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

List<Property> placeholderProperties({int count = 6}) {
  return List.generate(count, (i) => placeholderProperty(index: i));
}

Property placeholderProperty({int index = 0}) {
  return Property(
    id: 'placeholder-$index',
    title: 'loading_property'.tr(),
    description: 'loading_description'.tr(),
    price: 120000 + (index * 5000),
    purpose: index.isEven ? PropertyPurpose.sale : PropertyPurpose.rent,
    rooms: 3 + (index % 2),
    kitchens: 1,
    floors: 2,
    hasPool: index.isEven,
    locationAreaId: 'area-$index',
    locationUrl: 'https://maps.example.com/$index',
    coverImageUrl: null,
    imageUrls: const [],
    ownerPhoneEncryptedOrHiddenStored: '',
    isImagesHidden: false,
    status: PropertyStatus.active,
    isDeleted: false,
    createdBy: 'placeholder',
    ownerScope: PropertyOwnerScope.company,
    brokerId: null,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
