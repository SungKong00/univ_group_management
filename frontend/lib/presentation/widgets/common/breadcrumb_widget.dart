import 'package:flutter/material.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// 페이지 브레드크럼 위젯
///
/// 상단바에 표시되는 계층적 페이지 제목 컴포넌트입니다.
/// Toss 디자인 원칙의 "위계(Hierarchy)"를 적용하여 시각적 계층을 명확히 구분합니다.
///
/// **구성:**
/// - 주제목: 진하고 큰 글씨 (headlineMedium: 20px/600/neutral900)
/// - 경로: 옅고 작은 글씨 (bodyMedium: 14px/400/neutral600)
/// - 구분자: ">" (neutral500)
///
/// **사용 예시:**
/// ```dart
/// // 단순 제목만
/// BreadcrumbWidget(
///   breadcrumb: PageBreadcrumb(title: "홈"),
/// )
///
/// // 계층 경로 포함
/// BreadcrumbWidget(
///   breadcrumb: PageBreadcrumb(
///     title: "워크스페이스",
///     path: ["워크스페이스", "컴퓨터공학과", "공지사항"],
///   ),
/// )
/// ```
class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({
    super.key,
    required this.breadcrumb,
  });

  final PageBreadcrumb breadcrumb;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 주제목 (진하고 크게)
        Text(
          breadcrumb.title,
          style: AppTheme.headlineMedium.copyWith(
            color: AppColors.neutral900,
            height: 1.2,
          ),
        ),

        // 경로 (있을 경우만 표시)
        if (breadcrumb.hasPath) ...[
          const SizedBox(height: 2),
          _buildPathRow(),
        ],
      ],
    );
  }

  /// 경로를 ">" 구분자로 연결하여 표시
  Widget _buildPathRow() {
    final path = breadcrumb.path!;
    final widgets = <Widget>[];

    for (int i = 0; i < path.length; i++) {
      // 경로 항목
      widgets.add(
        Text(
          path[i],
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
            height: 1.3,
          ),
        ),
      );

      // 구분자 (마지막 항목이 아닐 때만)
      if (i < path.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              '>',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral500,
                height: 1.3,
              ),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
