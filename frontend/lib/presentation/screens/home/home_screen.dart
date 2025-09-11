import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_button.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼을 눌렀을 때 앱 종료 확인
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
        return false; // 기본 뒤로가기 동작 방지
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('대학 그룹 관리'),
          automaticallyImplyLeading: false, // 뒤로가기 버튼 숨기기
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                // 프로필 화면으로 이동 (향후 구현)
              },
            ),
          ],
        ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 인증되지 않은 상태에서 홈에 접근 시 로그인으로 리다이렉트 (웹 새로고침 포함)
          if (!authProvider.isAuthenticated && !authProvider.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          }
          final user = authProvider.currentUser;
          
          return Padding(
            padding: AppStyles.paddingL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 환영 메시지
                Card(
                  child: Padding(
                    padding: AppStyles.paddingL,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppStyles.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '안녕하세요, ${user?.name ?? '사용자'}님!',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppStyles.spacingXS),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppStyles.spacingL),

                // 메인 기능들
                Text(
                  '그룹 관리',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppStyles.spacingM),

                // 그룹 관련 기능 카드들
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppStyles.spacingM,
                    mainAxisSpacing: AppStyles.spacingM,
                    children: [
                      _buildFeatureCard(
                        context,
                        icon: Icons.group_add,
                        title: '그룹 생성',
                        subtitle: '새로운 그룹을\n만들어보세요',
                        onTap: () {
                          // 그룹 생성 화면으로 이동 (향후 구현)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('그룹 생성 기능은 곧 추가될 예정입니다.')),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.groups,
                        title: '내 그룹',
                        subtitle: '참여 중인 그룹을\n확인해보세요',
                        onTap: () {
                          // 내 그룹 목록 화면으로 이동 (향후 구현)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('내 그룹 기능은 곧 추가될 예정입니다.')),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.search,
                        title: '그룹 검색',
                        subtitle: '원하는 그룹을\n찾아보세요',
                        onTap: () {
                          // 그룹 검색 화면으로 이동 (향후 구현)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('그룹 검색 기능은 곧 추가될 예정입니다.')),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        context,
                        icon: Icons.settings,
                        title: '설정',
                        subtitle: '앱 설정을\n관리해보세요',
                        onTap: () {
                          // 설정 화면으로 이동 (향후 구현)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('설정 기능은 곧 추가될 예정입니다.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 로그아웃 버튼
                CommonButton(
                  text: '로그아웃',
                  type: ButtonType.secondary,
                  onPressed: () => _handleLogout(context),
                  width: double.infinity,
                  icon: Icons.logout,
                ),
                const SizedBox(height: AppStyles.spacingL),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 종료'),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('종료'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.radiusL,
        child: Padding(
          padding: AppStyles.paddingM,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppStyles.spacingM),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacingS),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await context.read<AuthProvider>().logout();
        if (context.mounted) {
          // 모든 이전 화면을 제거하고 로그인 화면으로 이동
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false,
          );
        }
      } catch (e) {
        // 에러가 발생해도 로그인 화면으로 이동
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }
}
