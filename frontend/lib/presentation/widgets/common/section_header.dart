import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 섹션 헤더 컴포넌트
///
/// 페이지 내 섹션 제목을 일관되게 표시하는 재사용 가능한 컴포넌트입니다.
///
/// **기본 사용 예시**:
/// ```dart
/// SectionHeader(title: '빠른 실행')
/// ```
///
/// **부제목 추가**:
/// ```dart
/// SectionHeader(
///   title: '모집 중인 그룹',
///   subtitle: '현재 가입 신청을 받고 있는 그룹입니다',
/// )
/// ```
///
/// **오른쪽 위젯 추가** (예: "더보기" 버튼):
/// ```dart
/// SectionHeader(
///   title: '내 그룹',
///   trailing: TextButton(
///     onPressed: () {},
///     child: Text('전체보기'),
///   ),
/// )
/// ```
///
/// **커스텀 스타일**:
/// ```dart
/// SectionHeader(
///   title: '공지사항',
///   titleStyle: AppTheme.headlineMediumTheme(context),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// 섹션 제목 (필수)
  final String title;

  /// 부제목 (선택)
  final String? subtitle;

  /// 오른쪽에 표시할 위젯 (예: "더보기" 버튼)
  final Widget? trailing;

  /// 제목 스타일 (기본값: headlineSmall - 18px, w600)
  final TextStyle? titleStyle;

  /// 부제목 스타일 (기본값: bodyMedium - 14px, w400)
  final TextStyle? subtitleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: titleStyle ?? AppTheme.headlineSmallTheme(context),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: subtitleStyle ?? AppTheme.bodyMediumTheme(context),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
