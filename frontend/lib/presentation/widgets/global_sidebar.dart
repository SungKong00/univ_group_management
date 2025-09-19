import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class GlobalSidebar extends StatelessWidget {
  static const double width = 60.0;

  const GlobalSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 메인 네비게이션 메뉴들
          Expanded(
            child: Consumer<NavProvider>(
              builder: (context, navProvider, child) {
                return Column(
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home,
                      label: '홈',
                      index: 0,
                      isSelected: navProvider.index == 0,
                      onTap: () => navProvider.setIndex(0),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.workspaces_outline,
                      selectedIcon: Icons.workspaces,
                      label: '워크스페이스',
                      index: 1,
                      isSelected: navProvider.index == 1,
                      onTap: () => navProvider.setIndex(1),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.history,
                      selectedIcon: Icons.history,
                      label: '나의 활동',
                      index: 2,
                      isSelected: navProvider.index == 2,
                      onTap: () => navProvider.setIndex(2),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.person_outline,
                      selectedIcon: Icons.person,
                      label: '프로필',
                      index: 3,
                      isSelected: navProvider.index == 3,
                      onTap: () => navProvider.setIndex(3),
                    ),
                  ],
                );
              },
            ),
          ),

          // 하단 기능들
          const Divider(color: AppTheme.border),
          _buildBottomActions(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }


  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: Material(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppTheme.primary.withOpacity(0.3))
                    : null,
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 24,
                color: isSelected ? AppTheme.primary : AppTheme.onTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Tooltip(
            message: '로그아웃',
            preferBelow: false,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: authProvider.isLoading
                    ? null
                    : () => _showLogoutDialog(context, authProvider),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 20,
                    color: authProvider.isLoading
                        ? AppTheme.onTextSecondary.withOpacity(0.5)
                        : AppTheme.onTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await auth.logout();
              if (success && context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              } else if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.error ?? '로그아웃에 실패했습니다.'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}