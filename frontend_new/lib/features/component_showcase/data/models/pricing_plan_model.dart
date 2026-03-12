import 'feature_model.dart';
import 'cta_model.dart';

/// PricingPlan - Pricing Card의 가격 정보
class PricingPlan {
  final String tier; // 'standard', 'premium', 'enterprise'
  final String price;
  final String priceFormat; // '/month', '/year'
  final List<Feature> features;
  final List<CTA> ctas;

  const PricingPlan({
    required this.tier,
    required this.price,
    this.priceFormat = '',
    this.features = const [],
    this.ctas = const [],
  });

  /// Copy with
  PricingPlan copyWith({
    String? tier,
    String? price,
    String? priceFormat,
    List<Feature>? features,
    List<CTA>? ctas,
  }) {
    return PricingPlan(
      tier: tier ?? this.tier,
      price: price ?? this.price,
      priceFormat: priceFormat ?? this.priceFormat,
      features: features ?? this.features,
      ctas: ctas ?? this.ctas,
    );
  }
}
