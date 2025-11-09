import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// 컴팩트 탭 바 위젯
///
/// 높이 최적화된 탭 바로, 원래 TabBar보다 약 20% 작습니다.
/// Toss 디자인 원칙의 "단순함(Simplicity)"과 "여백(Space)"을 적용하여
/// 공간 효율성을 극대화합니다.
///
/// **특징:**
/// - 아이콘 크기: 19px
/// - 텍스트 크기: titleMedium (14px)
/// - 세로 패딩 최적화: 4px
/// - 높이: 52dp (적절한 터치 영역 + 여유 공간)
/// - 간편한 커스터마이징 옵션
///
/// **사용 예시:**
/// ```dart
/// CompactTabBar(
///   controller: _tabController,
///   tabs: const [
///     CompactTab(icon: Icons.people_outline, label: '멤버 목록'),
///     CompactTab(icon: Icons.admin_panel_settings_outlined, label: '역할 관리'),
///     CompactTab(icon: Icons.inbox_outlined, label: '가입 신청'),
///   ],
///   onTap: (index) {
///     // 탭 변경 로직
///   },
/// )
/// ```
///
/// **커스터마이징:**
/// ```dart
/// CompactTabBar(
///   controller: _tabController,
///   tabs: [...],
///   labelColor: Colors.blue,
///   unselectedLabelColor: Colors.grey,
///   backgroundColor: Colors.white,
/// )
/// ```
class CompactTabBar extends StatelessWidget {
  const CompactTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.labelColor = const Color(0xFF5C068C), // AppColors.brand
    this.unselectedLabelColor = const Color(0xFF6C757D), // AppColors.neutral600
    this.backgroundColor = Colors.white,
    this.indicatorColor = const Color(0xFF5C068C), // AppColors.brand
    this.dividerColor,
  });

  /// 탭 컨트롤러
  final TabController controller;

  /// 탭 목록
  final List<CompactTab> tabs;

  /// 탭 변경 콜백
  final Function(int)? onTap;

  /// 선택된 탭의 텍스트 색상
  final Color labelColor;

  /// 미선택 탭의 텍스트 색상
  final Color unselectedLabelColor;

  /// 배경색
  final Color backgroundColor;

  /// 하단 인디케이터 색상
  final Color indicatorColor;

  /// 하단 분할선 색상 (null이면 비표시)
  final Color? dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52, // 적절한 높이 (44dp 최소 + 여유 공간)
            child: TabBar(
              controller: controller,
              onTap: onTap,
              labelColor: labelColor,
              unselectedLabelColor: unselectedLabelColor,
              indicatorColor: indicatorColor,
              indicatorWeight: 2,
              // 세로 패딩 최소화 (위아래 2px씩)
              labelPadding: EdgeInsets.zero,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: indicatorColor,
                  width: 2,
                ),
              ),
              tabs: tabs
                  .map((tab) => _buildCompactTabContent(tab))
                  .toList(),
            ),
          ),
          // 하단 분할선 (선택사항)
          if (dividerColor != null)
            Divider(
              height: 1,
              color: dividerColor,
              thickness: 1,
            ),
        ],
      ),
    );
  }

  /// 컴팩트 탭 콘텐츠 구성
  Widget _buildCompactTabContent(CompactTab tab) {
    return Padding(
      // 상하 패딩 최적화 (4px)
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: AppSpacing.sm, // 좌우 16px (표준)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tab.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                tab.icon,
                size: 19, // 19px
              ),
            ),
          Text(
            tab.label,
            style: AppTheme.titleMedium.copyWith(
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트 탭 데이터 모델
///
/// CompactTabBar에서 사용할 탭의 정보를 정의합니다.
class CompactTab {
  const CompactTab({
    required this.label,
    this.icon,
  });

  /// 탭 레이블 (필수)
  final String label;

  /// 탭 아이콘 (선택사항)
  final IconData? icon;
}
