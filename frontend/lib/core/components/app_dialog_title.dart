import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 다이얼로그 타이틀 바 컴포넌트
///
/// 토스 디자인 원칙:
/// - 단순함: 타이틀과 닫기 버튼만
/// - 위계: 타이틀 텍스트 강조 (18px, w600)
/// - 여백: 적절한 간격
/// - 피드백: 닫기 버튼 인터랙션
///
/// 접근성:
/// - Semantics header: true (스크린 리더에서 헤딩으로 인식)
/// - 닫기 버튼 tooltip 제공
///
/// 사용 예시:
/// ```dart
/// AppDialogTitle(
///   title: '로그아웃',
///   onClose: () => Navigator.pop(context),
/// )
/// ```
class AppDialogTitle extends StatelessWidget {
  /// 다이얼로그 타이틀 텍스트 (필수)
  final String title;

  /// 닫기 버튼 콜백 (선택, null이면 버튼 표시 안 함)
  final VoidCallback? onClose;

  const AppDialogTitle({super.key, required this.title, this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Semantics(
      header: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                height: 1.35,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDark
                    ? AppColors.darkOnSurface
                    : AppColors.lightOnSurface,
                size: 24,
              ),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: '닫기',
            ),
        ],
      ),
    );
  }
}
