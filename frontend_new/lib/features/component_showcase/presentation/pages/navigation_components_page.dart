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
import '../../../../core/widgets/app_global_navigation.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/app_channel_nav.dart';
import '../../../../core/widgets/app_group_selector.dart';

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
/// - AppGlobalNavigation (글로벌 네비게이션)
/// - AppTopBar (상단 바)
/// - AppChannelNav (채널 네비게이션)
/// - AppGroupSelector (그룹 선택기)
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
  String _selectedSidebarId = 'dashboard';

  // GlobalNavigation state
  String _globalNavSelectedId = 'home';
  GlobalNavLayoutMode _globalNavLayoutMode = GlobalNavLayoutMode.expanded;

  // ChannelNav state
  String? _selectedChannelId = 'general';

  // TopBar state
  bool _canGoBack = true;

  // Navbar state
  String _selectedNavbarId = 'home';

  // GroupSelector state
  String? _selectedGroupId = '3';
  final GlobalKey _groupHeaderKey = GlobalKey();

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
                            isActive: _selectedSidebarId == 'dashboard',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'dashboard');
                            },
                          ),
                          AppSidebarItem(
                            title: '프로젝트',
                            icon: Icons.folder,
                            badge: '12',
                            isActive: _selectedSidebarId == 'projects',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'projects');
                            },
                          ),
                          AppSidebarItem(
                            title: '팀',
                            icon: Icons.people,
                            isActive: _selectedSidebarId == 'team',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'team');
                            },
                          ),
                          AppSidebarItem(
                            title: '캘린더',
                            icon: Icons.calendar_today,
                            isActive: _selectedSidebarId == 'calendar',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'calendar');
                            },
                          ),
                        ],
                      ),
                      AppSidebarGroup(
                        title: '설정',
                        items: [
                          AppSidebarItem(
                            title: '계정',
                            icon: Icons.person,
                            isActive: _selectedSidebarId == 'account',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'account');
                            },
                          ),
                          AppSidebarItem(
                            title: '보안',
                            icon: Icons.security,
                            isActive: _selectedSidebarId == 'security',
                            onTap: () {
                              setState(() => _selectedSidebarId = 'security');
                            },
                          ),
                          AppSidebarItem(
                            title: '알림',
                            icon: Icons.notifications,
                            badge: '3',
                            isActive: _selectedSidebarId == 'notifications',
                            onTap: () {
                              setState(
                                () => _selectedSidebarId = 'notifications',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '사이드바 ${_sidebarExpanded ? '확장됨' : '축소됨'}',
                            style: TextStyle(color: colorExt.textSecondary),
                          ),
                          SizedBox(height: spacingExt.small),
                          Text(
                            '선택된 메뉴: $_selectedSidebarId',
                            style: TextStyle(
                              color: colorExt.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                    items: [
                      AppNavbarItem(
                        label: '홈',
                        isActive: _selectedNavbarId == 'home',
                        onTap: () => setState(() => _selectedNavbarId = 'home'),
                      ),
                      AppNavbarItem(
                        label: '제품',
                        isActive: _selectedNavbarId == 'products',
                        onTap: () =>
                            setState(() => _selectedNavbarId = 'products'),
                      ),
                      AppNavbarItem(
                        label: '서비스',
                        isActive: _selectedNavbarId == 'services',
                        onTap: () =>
                            setState(() => _selectedNavbarId = 'services'),
                      ),
                      AppNavbarItem(
                        label: '가격',
                        isActive: _selectedNavbarId == 'pricing',
                        onTap: () =>
                            setState(() => _selectedNavbarId = 'pricing'),
                      ),
                      AppNavbarItem(
                        label: '문의',
                        isActive: _selectedNavbarId == 'contact',
                        onTap: () =>
                            setState(() => _selectedNavbarId = 'contact'),
                      ),
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

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppGlobalNavigation 섹션 (NEW)
            // ===========================================
            _buildSectionTitle(context, 'AppGlobalNavigation - 글로벌 네비게이션'),
            SizedBox(height: spacingExt.medium),

            // 레이아웃 모드 선택
            Wrap(
              spacing: spacingExt.small,
              children: [
                ChoiceChip(
                  label: const Text('하단 바'),
                  selected: _globalNavLayoutMode == GlobalNavLayoutMode.bottom,
                  onSelected: (_) => setState(
                    () => _globalNavLayoutMode = GlobalNavLayoutMode.bottom,
                  ),
                ),
                ChoiceChip(
                  label: const Text('축소 사이드바'),
                  selected:
                      _globalNavLayoutMode == GlobalNavLayoutMode.collapsed,
                  onSelected: (_) => setState(
                    () => _globalNavLayoutMode = GlobalNavLayoutMode.collapsed,
                  ),
                ),
                ChoiceChip(
                  label: const Text('확장 사이드바'),
                  selected:
                      _globalNavLayoutMode == GlobalNavLayoutMode.expanded,
                  onSelected: (_) => setState(
                    () => _globalNavLayoutMode = GlobalNavLayoutMode.expanded,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingExt.medium),

            Container(
              height: _globalNavLayoutMode == GlobalNavLayoutMode.bottom
                  ? 120
                  : 400,
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _globalNavLayoutMode == GlobalNavLayoutMode.bottom
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppGlobalNavigation(
                          layoutMode: _globalNavLayoutMode,
                          selectedId: _globalNavSelectedId,
                          onItemSelected: (id) =>
                              setState(() => _globalNavSelectedId = id),
                          items: _globalNavItems,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        AppGlobalNavigation(
                          layoutMode: _globalNavLayoutMode,
                          selectedId: _globalNavSelectedId,
                          onItemSelected: (id) =>
                              setState(() => _globalNavSelectedId = id),
                          items: _globalNavItems,
                          userInfo: CircleAvatar(
                            backgroundColor: colorExt.brandPrimary,
                            child: Text(
                              'U',
                              style: TextStyle(color: colorExt.textOnBrand),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '선택됨: $_globalNavSelectedId',
                              style: TextStyle(color: colorExt.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppTopBar 섹션 (NEW)
            // ===========================================
            _buildSectionTitle(context, 'AppTopBar - 상단 바'),
            SizedBox(height: spacingExt.medium),

            // 뒤로가기 토글
            Row(
              children: [
                const Text('뒤로가기 활성화: '),
                Switch(
                  value: _canGoBack,
                  onChanged: (v) => setState(() => _canGoBack = v),
                ),
              ],
            ),
            SizedBox(height: spacingExt.small),

            Container(
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppTopBar(
                canGoBack: _canGoBack,
                onBack: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('뒤로가기 클릭됨')));
                },
                title: Text(
                  '페이지 제목',
                  style: TextStyle(
                    color: colorExt.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: AppUserAvatar(
                  name: '홍길동',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('프로필 클릭됨')));
                  },
                ),
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppChannelNav 섹션 (NEW)
            // ===========================================
            _buildSectionTitle(context, 'AppChannelNav - 채널 네비게이션'),
            SizedBox(height: spacingExt.medium),

            Container(
              height: 500,
              decoration: BoxDecoration(
                color: colorExt.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AppChannelNav(
                    groupName: '컴퓨터공학과',
                    groupRole: '관리자',
                    sections: [
                      ChannelSection(
                        id: 'menu',
                        title: '그룹 메뉴',
                        items: [
                          const ChannelItem(
                            id: 'home',
                            name: '그룹 홈',
                            icon: Icons.home,
                          ),
                          const ChannelItem(
                            id: 'calendar',
                            name: '캘린더',
                            icon: Icons.calendar_today,
                          ),
                          const ChannelItem(
                            id: 'members',
                            name: '멤버',
                            icon: Icons.people,
                          ),
                        ],
                      ),
                      ChannelSection(
                        id: 'channels',
                        title: '채널',
                        collapsible: true,
                        items: [
                          const ChannelItem(
                            id: 'general',
                            name: '일반',
                            icon: Icons.tag,
                            unreadCount: 5,
                          ),
                          const ChannelItem(
                            id: 'notice',
                            name: '공지사항',
                            icon: Icons.campaign,
                          ),
                          const ChannelItem(
                            id: 'random',
                            name: '자유게시판',
                            icon: Icons.tag,
                            unreadCount: 12,
                          ),
                        ],
                      ),
                      ChannelSection(
                        id: 'admin',
                        title: '관리자 메뉴',
                        items: [
                          const ChannelItem(
                            id: 'settings',
                            name: '그룹 설정',
                            icon: Icons.settings,
                          ),
                          const ChannelItem(
                            id: 'permissions',
                            name: '권한 관리',
                            icon: Icons.admin_panel_settings,
                          ),
                        ],
                      ),
                    ],
                    selectedChannelId: _selectedChannelId,
                    onChannelSelected: (id) =>
                        setState(() => _selectedChannelId = id),
                    onGroupTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('그룹 헤더 클릭됨')),
                      );
                    },
                    enableSlideAnimation: false,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '선택된 채널: $_selectedChannelId',
                        style: TextStyle(color: colorExt.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),

            // ===========================================
            // AppGroupSelector 섹션 (NEW)
            // ===========================================
            _buildSectionTitle(context, 'AppGroupSelector - 그룹 선택기'),
            SizedBox(height: spacingExt.medium),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 인라인 표시
                AppGroupSelector(
                  groups: _sampleGroups,
                  selectedGroupId: _selectedGroupId,
                  onGroupSelected: (id) =>
                      setState(() => _selectedGroupId = id),
                ),
                SizedBox(width: spacingExt.large),

                // 오버레이 버튼
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오버레이로 표시:',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: spacingExt.small),
                    ElevatedButton.icon(
                      key: _groupHeaderKey,
                      onPressed: () {
                        showGroupSelector(
                          context: context,
                          anchorKey: _groupHeaderKey,
                          groups: _sampleGroups,
                          selectedGroupId: _selectedGroupId,
                          onGroupSelected: (id) =>
                              setState(() => _selectedGroupId = id),
                        );
                      },
                      icon: const Icon(Icons.arrow_drop_down),
                      label: Text(
                        _sampleGroups
                                .where((g) => g.id == _selectedGroupId)
                                .firstOrNull
                                ?.name ??
                            '그룹 선택',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorExt.surfaceTertiary,
                        foregroundColor: colorExt.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: spacingExt.huge),
          ],
        ),
      ),
    );
  }

  // 글로벌 네비게이션 아이템
  List<GlobalNavItem> get _globalNavItems => const [
    GlobalNavItem(
      id: 'home',
      title: '홈',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    GlobalNavItem(
      id: 'calendar',
      title: '캘린더',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    GlobalNavItem(
      id: 'workspace',
      title: '워크스페이스',
      description: '그룹 및 채널',
      icon: Icons.workspaces_outlined,
      activeIcon: Icons.workspaces,
    ),
    GlobalNavItem(
      id: 'activity',
      title: '활동',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
    ),
    GlobalNavItem(
      id: 'profile',
      title: '프로필',
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
    ),
  ];

  // 샘플 그룹 데이터
  List<GroupData> get _sampleGroups => const [
    GroupData(id: '1', name: '한신대학교', level: 0),
    GroupData(id: '2', name: 'AI/SW학부', parentId: '1', level: 1),
    GroupData(id: '3', name: '컴퓨터공학과', parentId: '2', level: 2),
    GroupData(id: '4', name: 'SW학과', parentId: '2', level: 2),
    GroupData(id: '5', name: '경영학부', parentId: '1', level: 1),
    GroupData(id: '6', name: '경영학과', parentId: '5', level: 2),
  ];

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
