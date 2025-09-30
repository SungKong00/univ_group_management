import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Google 공식 "G" 로고 위젯
///
/// Google 브랜드 가이드라인 준수:
/// - 24×24px 최적 크기
/// - 공식 컬러 팔레트 (#4285F4, #34A853, #FBBC05, #EA4335)
/// - 비율 유지, 변형 금지
///
/// 사용법:
/// ```dart
/// GoogleLogo(size: 24)
/// ```
class GoogleLogo extends StatelessWidget {
  /// 로고 크기 (기본값: 24px)
  final double size;

  /// 접근성 제외 여부 (기본값: true)
  /// 버튼 내부에서 사용 시 중복 레이블 방지를 위해 true 권장
  final bool excludeFromSemantics;

  const GoogleLogo({
    super.key,
    this.size = 24.0,
    this.excludeFromSemantics = true,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/google_logo_optimized.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: excludeFromSemantics,
      placeholderBuilder: (context) => SizedBox(
        width: size,
        height: size,
      ),
    );
  }
}