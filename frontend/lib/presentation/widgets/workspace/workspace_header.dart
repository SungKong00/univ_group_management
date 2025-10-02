import 'package:flutter/material.dart';
import '../../../core/models/page_breadcrumb.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// 워크스페이스 전용 헤더 위젯
///
/// 워크스페이스 페이지의 상단 제목 영역을 담당합니다.
/// 일반 브레드크럼과 달리, 그룹 전환 드롭다운, 추가 액션 버튼 등
/// 워크스페이스 전용 기능을 지원합니다.
///
/// **구성:**
/// - 주제목: "워크스페이스" (headlineMedium: 20px/600/neutral900)
/// - 경로: 그룹명 + 드롭다운 버튼 (향후 확장)
/// - 채널명: 옵션 (있을 경우 표시)
///
/// **향후 확장 계획:**
/// - 그룹명 옆 드롭다운 버튼으로 워크스페이스 전환
/// - 채널명 옆 추가 액션 버튼 (설정, 알림 등)
///
/// **사용 예시:**
/// ```dart
/// WorkspaceHeader(
///   breadcrumb: PageBreadcrumb(
///     title: "워크스페이스",
///     path: ["워크스페이스", "컴퓨터공학과", "공지사항"],
///   ),
/// )
/// ```
class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.breadcrumb,
    this.onGroupDropdownTap,
    this.onChannelActionTap,
  });

  final PageBreadcrumb breadcrumb;

  /// 그룹 드롭다운 버튼 클릭 핸들러 (향후 구현)
  final VoidCallback? onGroupDropdownTap;

  /// 채널 액션 버튼 클릭 핸들러 (향후 구현)
  final VoidCallback? onChannelActionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 주제목: "워크스페이스"
        Text(
          breadcrumb.title,
          style: AppTheme.headlineMedium.copyWith(
            color: AppColors.neutral900,
            height: 1.2,
          ),
        ),

        // 경로 (그룹명 + 채널명)
        if (breadcrumb.hasPath) ...[
          const SizedBox(height: 2),
          _buildPathRow(),
        ],
      ],
    );
  }

  /// 워크스페이스 경로 행 (그룹 + 드롭다운 + 채널)
  Widget _buildPathRow() {
    final path = breadcrumb.path!;
    final widgets = <Widget>[];

    for (int i = 0; i < path.length; i++) {
      // 첫 번째 항목("워크스페이스")는 건너뜀
      if (i == 0) continue;

      // 구분자 (첫 항목 앞에는 표시)
      if (widgets.isNotEmpty) {
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

      // 그룹명 (두 번째 항목) - 향후 드롭다운 버튼 추가 예정
      if (i == 1) {
        widgets.add(_buildGroupNameSection(path[i]));
      }
      // 채널명 (세 번째 항목) - 향후 액션 버튼 추가 예정
      else if (i == 2) {
        widgets.add(_buildChannelNameSection(path[i]));
      }
      // 기타 경로
      else {
        widgets.add(
          Text(
            path[i],
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.neutral600,
              height: 1.3,
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

  /// 그룹명 섹션 (향후 드롭다운 버튼 추가 예정)
  Widget _buildGroupNameSection(String groupName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          groupName,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
            height: 1.3,
          ),
        ),
        // TODO: 드롭다운 버튼 추가
        // if (onGroupDropdownTap != null) ...[
        //   const SizedBox(width: 4),
        //   IconButton(
        //     icon: const Icon(Icons.arrow_drop_down, size: 20),
        //     onPressed: onGroupDropdownTap,
        //     padding: EdgeInsets.zero,
        //     constraints: const BoxConstraints(),
        //   ),
        // ],
      ],
    );
  }

  /// 채널명 섹션 (향후 액션 버튼 추가 예정)
  Widget _buildChannelNameSection(String channelName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          channelName,
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
            height: 1.3,
          ),
        ),
        // TODO: 채널 액션 버튼 추가
        // if (onChannelActionTap != null) ...[
        //   const SizedBox(width: 4),
        //   IconButton(
        //     icon: const Icon(Icons.settings_outlined, size: 16),
        //     onPressed: onChannelActionTap,
        //     padding: EdgeInsets.zero,
        //     constraints: const BoxConstraints(),
        //   ),
        // ],
      ],
    );
  }
}
