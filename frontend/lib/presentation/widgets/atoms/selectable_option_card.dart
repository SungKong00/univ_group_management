import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// Selectable Option Card
///
/// 클릭 가능한 선택 카드 컴포넌트. Title + Description 패턴을 따르며,
/// 선택 상태를 시각적으로 표시합니다.
///
/// **디자인 원칙:**
/// - Title + Description 패턴: 명확한 위계 구조
/// - 선택 상태: Border, Elevation, Check Icon으로 시각화
/// - 접근성: Material InkWell 리플 효과
///
/// **사용 예시:**
/// ```dart
/// SelectableOptionCard(
///   title: '공식 일정',
///   description: '그룹 전체 공지',
///   icon: Icon(Icons.event, size: 32, color: AppColors.brand),
///   isSelected: true,
///   onTap: () => print('선택됨'),
/// )
/// ```
class SelectableOptionCard extends StatelessWidget {
  /// 카드 제목 (짧고 명확한 동사/명사 표현)
  final String title;

  /// 카드 설명 (친근하고 설명적인 안내 문구)
  final String description;

  /// 카드 아이콘 (좌측 상단)
  final Widget icon;

  /// 선택 상태
  final bool isSelected;

  /// 탭 콜백
  final VoidCallback onTap;

  /// 강조 색상 (선택 시 border/check icon 색상, 기본값: AppColors.brand)
  final Color? accentColor;

  const SelectableOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.brand;

    return Material(
      color: isSelected
          ? effectiveAccentColor.withValues(alpha: 0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      elevation: isSelected ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? effectiveAccentColor : AppColors.neutral300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아이콘
              icon,
              const SizedBox(width: AppSpacing.xs),
              // 텍스트 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (강조)
                    Text(
                      title,
                      style: AppTheme.titleMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description (부드러운 안내)
                    Text(
                      description,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              // 선택 체크 아이콘
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: effectiveAccentColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
