/// Customer - Customer Card의 고객 정보
class Customer {
  final String company;
  final String title;
  final bool hasImage;
  final String ctaText;

  const Customer({
    required this.company,
    required this.title,
    this.hasImage = false,
    this.ctaText = 'Read story',
  });

  /// Copy with
  Customer copyWith({
    String? company,
    String? title,
    bool? hasImage,
    String? ctaText,
  }) {
    return Customer(
      company: company ?? this.company,
      title: title ?? this.title,
      hasImage: hasImage ?? this.hasImage,
      ctaText: ctaText ?? this.ctaText,
    );
  }
}
