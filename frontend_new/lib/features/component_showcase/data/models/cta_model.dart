/// CTA - Call To Action 버튼
class CTA {
  final String text;
  final String variant; // 'primary', 'secondary'

  const CTA({required this.text, this.variant = 'primary'});

  /// Copy with
  CTA copyWith({String? text, String? variant}) {
    return CTA(text: text ?? this.text, variant: variant ?? this.variant);
  }
}
