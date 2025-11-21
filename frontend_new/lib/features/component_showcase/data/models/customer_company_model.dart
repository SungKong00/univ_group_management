/// CustomerCompany - Customer Logo Grid의 회사 정보
class CustomerCompany {
  final String name;
  final List<String> categories;
  final String ctaText;
  final bool isExternal;

  const CustomerCompany({
    required this.name,
    this.categories = const [],
    this.ctaText = 'Visit site',
    this.isExternal = false,
  });

  /// Copy with
  CustomerCompany copyWith({
    String? name,
    List<String>? categories,
    String? ctaText,
    bool? isExternal,
  }) {
    return CustomerCompany(
      name: name ?? this.name,
      categories: categories ?? this.categories,
      ctaText: ctaText ?? this.ctaText,
      isExternal: isExternal ?? this.isExternal,
    );
  }
}
