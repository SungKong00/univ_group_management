/// Feature - Pricing Card의 기능 항목
class Feature {
  final String text;
  final bool enabled;
  final String? link;

  const Feature({required this.text, this.enabled = true, this.link});

  /// Copy with
  Feature copyWith({String? text, bool? enabled, String? link}) {
    return Feature(
      text: text ?? this.text,
      enabled: enabled ?? this.enabled,
      link: link ?? this.link,
    );
  }
}
