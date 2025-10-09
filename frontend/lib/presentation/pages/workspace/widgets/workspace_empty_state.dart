import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// 워크스페이스 빈 상태 표시 타입
enum WorkspaceEmptyType {
  /// 그룹 홈 (준비 중)
  groupHome,

  /// 캘린더 (준비 중)
  calendar,

  /// 그룹 관리 (준비 중)
  groupAdmin,

  /// 채널 미선택
  noChannelSelected,
}

/// 워크스페이스 빈 상태 위젯
///
/// 그룹 홈, 캘린더, 그룹 관리 등 준비 중인 페이지 또는 채널 미선택 상태 표시
class WorkspaceEmptyState extends StatelessWidget {
  final WorkspaceEmptyType type;

  const WorkspaceEmptyState({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIcon(), size: 64, color: AppColors.brand),
          const SizedBox(height: 16),
          Text(_getTitle(), style: AppTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            _getSubtitle(),
            style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case WorkspaceEmptyType.groupHome:
        return Icons.home_outlined;
      case WorkspaceEmptyType.calendar:
        return Icons.calendar_today_outlined;
      case WorkspaceEmptyType.groupAdmin:
        return Icons.settings_outlined;
      case WorkspaceEmptyType.noChannelSelected:
        return Icons.forum_outlined;
    }
  }

  String _getTitle() {
    switch (type) {
      case WorkspaceEmptyType.groupHome:
        return '그룹 홈';
      case WorkspaceEmptyType.calendar:
        return '캘린더';
      case WorkspaceEmptyType.groupAdmin:
        return '그룹 관리';
      case WorkspaceEmptyType.noChannelSelected:
        return '채널을 선택하세요';
    }
  }

  String _getSubtitle() {
    switch (type) {
      case WorkspaceEmptyType.groupHome:
        return '그룹 홈 (준비 중)';
      case WorkspaceEmptyType.calendar:
        return '캘린더 (준비 중)';
      case WorkspaceEmptyType.groupAdmin:
        return '그룹 관리 페이지 (준비 중)';
      case WorkspaceEmptyType.noChannelSelected:
        return '왼쪽 사이드바에서 채널을 선택해주세요';
    }
  }
}
