import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_breadcrumb.dart';
import '../../../../core/widgets/app_navbar.dart';
import '../../../../core/widgets/app_navigation_rail.dart';

/// Phase 4 네비게이션 & 레이아웃 컴포넌트 쇼케이스 페이지
///
/// 다음 컴포넌트들을 시연합니다:
/// - AppBottomSheet (바텀시트)
/// - AppDrawer (드로어)
/// - AppSidebar (사이드바)
/// - AppBottomNav (하단 네비게이션)
/// - AppBreadcrumb (브레드크럼)
/// - AppNavbar (상단 네비게이션)
/// - AppNavigationRail (네비게이션 레일)
class NavigationComponentsPage extends StatefulWidget {
  const NavigationComponentsPage({super.key});

  @override
  State<NavigationComponentsPage> createState() =>
      _NavigationComponentsPageState();
}

class _NavigationComponentsPageState extends State<NavigationComponentsPage> {
  // BottomNav state
  int _bottomNavIndex = 0;

  // NavigationRail state
  int _railIndex = 0;
  bool _railExtended = false;

  // Sidebar state
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        title: const Text('네비게이션 컴포넌트 (Phase 4)'),
        backgroundColor: colorExt.surfaceSecondary,
        foregroundColor: colorExt.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingExt.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===========================================
            // AppBreadcrumb 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppBreadcrumb - 브레드크럼'),
            SizedBox(height: spacingExt.medium),

            Container(
              padding: EdgeInsets.all(spacingExt.medium),
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기본 스타일 (Chevron)',
                    style: TextStyle(
                      color: colorExt.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: spacingExt.small),
                  AppBreadcrumb(
                    items: [
                      AppBreadcrumbItem(
                        label: '홈',
                        icon: Icons.home,
                        onTap: () {},
                      ),
                      AppBreadcrumbItem(label: '제품', onTap: () {}),
                      AppBreadcrumbItem(label: '카테고리', onTap: () {}),
                      const AppBreadcrumbItem(label: '상세'),
                    ],
                  ),
                  SizedBox(height: spacingExt.large),

                  Text(
                    'Slash 구분자',
                    style: TextStyle(
                      color: colorExt.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: spacingExt.small),
                  AppBreadcrumb(
                    separator: AppBreadcrumbSeparator.slash,
                    items: [
                      AppBreadcrumbItem(label: '대시보드', onTap: () {}),
                      AppBreadcrumbItem(label: '설정', onTap: () {}),
                      const AppBreadcrumbItem(label: '프로필'),
                    ],
                  ),
                  SizedBox(height: spacingExt.large),

                  Text(
                    '최대 개수 제한 (maxItems: 3)',
                    style: TextStyle(
                      color: colorExt.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: spacingExt.small),
                  AppBreadcrumb(
                    maxItems: 3,
                    items: [
                      AppBreadcrumbItem(label: '홈', onTap: () {}),
                      AppBreadcrumbItem(label: '제품', onTap: () {}),
                      AppBreadcrumbItem(label: '카테고리', onTap: () {}),
                      AppBreadcrumbItem(label: '서브카테고리', onTap: () {}),
                      const AppBreadcrumbItem(label: '상세'),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppBottomNav 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppBottomNav - 하단 네비게이션'),
            SizedBox(height: spacingExt.medium),

            Container(
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(spacingExt.medium),
                    child: Text(
                      'Standard 스타일',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  AppBottomNav(
                    currentIndex: _bottomNavIndex,
                    onTap: (index) => setState(() => _bottomNavIndex = index),
                    showShadow: false,
                    items: const [
                      AppBottomNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: '홈',
                      ),
                      AppBottomNavItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search,
                        label: '검색',
                      ),
                      AppBottomNavItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: '알림',
                        badge: 5,
                      ),
                      AppBottomNavItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: '프로필',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.medium),

            Container(
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(spacingExt.medium),
                    child: Text(
                      'Shifting 스타일',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  AppBottomNav(
                    currentIndex: _bottomNavIndex,
                    onTap: (index) => setState(() => _bottomNavIndex = index),
                    style: AppBottomNavStyle.shifting,
                    showShadow: false,
                    items: const [
                      AppBottomNavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: '홈',
                      ),
                      AppBottomNavItem(
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search,
                        label: '검색',
                      ),
                      AppBottomNavItem(
                        icon: Icons.add_circle_outline,
                        activeIcon: Icons.add_circle,
                        label: '추가',
                      ),
                      AppBottomNavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: '설정',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppNavigationRail 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppNavigationRail - 네비게이션 레일'),
            SizedBox(height: spacingExt.medium),

            Container(
              height: 400,
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AppNavigationRail(
                    selectedIndex: _railIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _railIndex = index),
                    extended: _railExtended,
                    leading: IconButton(
                      icon: Icon(
                        _railExtended ? Icons.menu_open : Icons.menu,
                        color: colorExt.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _railExtended = !_railExtended),
                      tooltip: _railExtended ? '축소' : '확장',
                    ),
                    items: const [
                      AppNavigationRailItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: '홈',
                      ),
                      AppNavigationRailItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: '대시보드',
                      ),
                      AppNavigationRailItem(
                        icon: Icons.analytics_outlined,
                        activeIcon: Icons.analytics,
                        label: '분석',
                        badge: 3,
                      ),
                      AppNavigationRailItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: '설정',
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '선택된 메뉴: ${['홈', '대시보드', '분석', '설정'][_railIndex]}',
                        style: TextStyle(color: colorExt.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppBottomSheet 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppBottomSheet - 바텀시트'),
            SizedBox(height: spacingExt.medium),

            Wrap(
              spacing: spacingExt.medium,
              runSpacing: spacingExt.medium,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBasicBottomSheet(context),
                  icon: const Icon(Icons.expand_less),
                  label: const Text('기본 바텀시트'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorExt.brandPrimary,
                    foregroundColor: colorExt.textOnBrand,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDraggableBottomSheet(context),
                  icon: const Icon(Icons.drag_handle),
                  label: const Text('드래그 가능 바텀시트'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorExt.surfaceTertiary,
                    foregroundColor: colorExt.textPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppDrawer 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppDrawer - 드로어'),
            SizedBox(height: spacingExt.medium),

            Wrap(
              spacing: spacingExt.medium,
              runSpacing: spacingExt.medium,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showLeftDrawer(context),
                  icon: const Icon(Icons.menu),
                  label: const Text('좌측 드로어'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorExt.brandPrimary,
                    foregroundColor: colorExt.textOnBrand,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRightDrawer(context),
                  icon: const Icon(Icons.menu_open),
                  label: const Text('우측 드로어'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorExt.surfaceTertiary,
                    foregroundColor: colorExt.textPrimary,
                  ),
                ),
              ],
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppSidebar 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppSidebar - 사이드바'),
            SizedBox(height: spacingExt.medium),

            Container(
              height: 400,
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AppSidebar(
                    style: AppSidebarStyle.expandable,
                    isExpanded: _sidebarExpanded,
                    onExpandedChanged: (expanded) =>
                        setState(() => _sidebarExpanded = expanded),
                    header: _sidebarExpanded
                        ? Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: colorExt.brandPrimary,
                              ),
                              SizedBox(width: spacingExt.small),
                              Text(
                                'My App',
                                style: TextStyle(
                                  color: colorExt.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Icon(
                            Icons.workspace_premium,
                            color: colorExt.brandPrimary,
                          ),
                    groups: [
                      AppSidebarGroup(
                        title: '메인 메뉴',
                        items: [
                          AppSidebarItem(
                            title: '대시보드',
                            icon: Icons.dashboard,
                            isActive: true,
                          ),
                          AppSidebarItem(
                            title: '프로젝트',
                            icon: Icons.folder,
                            badge: '12',
                          ),
                          AppSidebarItem(title: '팀', icon: Icons.people),
                          AppSidebarItem(
                            title: '캘린더',
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                      AppSidebarGroup(
                        title: '설정',
                        items: [
                          AppSidebarItem(title: '계정', icon: Icons.person),
                          AppSidebarItem(title: '보안', icon: Icons.security),
                          AppSidebarItem(
                            title: '알림',
                            icon: Icons.notifications,
                            badge: '3',
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '사이드바 ${_sidebarExpanded ? '확장됨' : '축소됨'}',
                        style: TextStyle(color: colorExt.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppNavbar 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppNavbar - 상단 네비게이션'),
            SizedBox(height: spacingExt.medium),

            Container(
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(spacingExt.medium),
                    child: Text(
                      'Standard 스타일',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  AppNavbar(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flutter_dash,
                          color: colorExt.brandPrimary,
                          size: 28,
                        ),
                        SizedBox(width: spacingExt.small),
                        Text(
                          'Logo',
                          style: TextStyle(
                            color: colorExt.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    items: const [
                      AppNavbarItem(label: '홈', isActive: true),
                      AppNavbarItem(label: '제품'),
                      AppNavbarItem(label: '서비스'),
                      AppNavbarItem(label: '가격'),
                      AppNavbarItem(label: '문의'),
                    ],
                    trailing: [
                      IconButton(
                        icon: Icon(Icons.search, color: colorExt.textSecondary),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: colorExt.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorExt.brandPrimary,
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: colorExt.textOnBrand,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.huge),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorExt = context.appColors;
    return Text(
      title,
      style: TextStyle(
        color: colorExt.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showBasicBottomSheet(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    showAppBottomSheet(
      context: context,
      child: Padding(
        padding: EdgeInsets.all(spacingExt.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '바텀시트 제목',
              style: TextStyle(
                color: colorExt.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacingExt.medium),
            Text(
              '바텀시트 내용입니다. 여기에 다양한 콘텐츠를 배치할 수 있습니다.',
              style: TextStyle(color: colorExt.textSecondary, fontSize: 14),
            ),
            SizedBox(height: spacingExt.large),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('공유하기'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('편집'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.delete, color: colorExt.stateErrorText),
              title: Text(
                '삭제',
                style: TextStyle(color: colorExt.stateErrorText),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDraggableBottomSheet(BuildContext context) {
    final colorExt = context.appColors;

    showAppDraggableBottomSheet(
      context: context,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ListView.builder(
        controller: scrollController,
        itemCount: 30,
        itemBuilder: (context, index) => ListTile(
          leading: CircleAvatar(
            backgroundColor: colorExt.brandPrimary,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: colorExt.textOnBrand),
            ),
          ),
          title: Text('아이템 ${index + 1}'),
          subtitle: Text('드래그하여 더 많은 항목을 볼 수 있습니다'),
        ),
      ),
    );
  }

  void _showLeftDrawer(BuildContext context) {
    showAppDrawer(
      context: context,
      position: AppDrawerPosition.left,
      drawer: AppDrawer(
        header: AppDrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                '사용자 이름',
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'user@example.com',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        items: [
          AppDrawerItem(
            title: '홈',
            icon: Icons.home,
            isActive: true,
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '프로필',
            icon: Icons.person,
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '설정',
            icon: Icons.settings,
            children: [
              AppDrawerItem(title: '계정', onTap: () => Navigator.pop(context)),
              AppDrawerItem(title: '알림', onTap: () => Navigator.pop(context)),
              AppDrawerItem(title: '개인정보', onTap: () => Navigator.pop(context)),
            ],
          ),
          AppDrawerItem(
            title: '도움말',
            icon: Icons.help,
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '로그아웃',
            icon: Icons.logout,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showRightDrawer(BuildContext context) {
    showAppDrawer(
      context: context,
      position: AppDrawerPosition.right,
      drawer: AppDrawer(
        position: AppDrawerPosition.right,
        items: [
          AppDrawerItem(
            title: '알림',
            icon: Icons.notifications,
            badge: '5',
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '메시지',
            icon: Icons.message,
            badge: '12',
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '작업',
            icon: Icons.task,
            onTap: () => Navigator.pop(context),
          ),
          AppDrawerItem(
            title: '캘린더',
            icon: Icons.calendar_today,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
