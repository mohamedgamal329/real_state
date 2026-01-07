class NotificationPropertySummary {
  final String title;
  final String? areaName;
  final String? purposeKey;
  final String? coverImageUrl;
  final bool isMissing;
  final double? price;
  final String? formattedPrice;

  const NotificationPropertySummary({
    required this.title,
    this.areaName,
    this.purposeKey,
    this.coverImageUrl,
    this.isMissing = false,
    this.price,
    this.formattedPrice,
  });

  NotificationPropertySummary copyWith({
    String? title,
    String? areaName,
    String? purposeKey,
    String? coverImageUrl,
    bool? isMissing,
    double? price,
    String? formattedPrice,
  }) {
    return NotificationPropertySummary(
      title: title ?? this.title,
      areaName: areaName ?? this.areaName,
      purposeKey: purposeKey ?? this.purposeKey,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isMissing: isMissing ?? this.isMissing,
      price: price ?? this.price,
      formattedPrice: formattedPrice ?? this.formattedPrice,
    );
  }
}
