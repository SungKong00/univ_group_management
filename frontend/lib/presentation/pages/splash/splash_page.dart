import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 앱 시작 시 표시되는 스플래시 페이지
///
/// 역할:
/// - 앱 초기화 중 사용자에게 로딩 상태 안내
/// - 브랜드 아이덴티티 표시 (로고, 앱 이름)
/// - 최소 표시 시간 보장 (깜빡임 방지)
///
/// 디자인 시스템 준수:
/// - 브랜드 컬러 (#5C068C - 학교 공식 퍼플)
/// - 간결한 레이아웃 (Simplicity First)
/// - 명확한 로딩 안내 (Easy to Answer)
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand, // 브랜드 메인 컬러 배경
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 영역
            _buildLogo(),

            const SizedBox(height: 48), // xl spacing
            // 로딩 인디케이터
            _buildLoadingIndicator(),

            const SizedBox(height: 16), // sm spacing
            // 로딩 안내 문구
            _buildLoadingText(),
          ],
        ),
      ),
    );
  }

  /// 로고 위젯
  ///
  /// 디자인 시스템 규격:
  /// - logoSize: 56px
  /// - logoRadius: 16px
  /// - logoIconSize: 28px
  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.school, size: 28, color: AppColors.brand),
    );
  }

  /// 로딩 인디케이터
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  /// 로딩 안내 문구
  ///
  /// 디자인 원칙:
  /// - Easy to Answer: 사용자가 현재 상태를 즉시 이해
  /// - Simplicity First: 간결하고 명확한 메시지
  Widget _buildLoadingText() {
    return const Text(
      '초기화 중...',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14, // bodyMedium
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
      ),
    );
  }
}
