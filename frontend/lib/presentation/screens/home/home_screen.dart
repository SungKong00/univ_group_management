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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // 뒤로가기 버튼을 눌렀을 때 앱 종료 확인
          final shouldExit = await _showExitDialog(context);
          if (shouldExit) {
            SystemNavigator.pop();
          }
        }
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
          
          return SingleChildScrollView(
            child: Padding(
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
                            ((user?.nickname?.isNotEmpty ?? false)
                                    ? user!.nickname!.substring(0, 1)
                                    : (user?.name ?? 'U').substring(0, 1))
                                .toUpperCase(),
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
                                '안녕하세요, ${(user?.nickname != null && user!.nickname!.isNotEmpty) ? user.nickname : (user?.name ?? '사용자')}님!',
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

                // My Activities 섹션
                _buildMyActivitiesSection(context),
                const SizedBox(height: AppStyles.spacingL),

                // 모집 중인 그룹 섹션
                _buildRecruitmentSection(context),
                const SizedBox(height: AppStyles.spacingL),

                // 빠른 접근 기능들
                Text(
                  '빠른 접근',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppStyles.spacingM),

                // 빠른 접근 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      context,
                      icon: Icons.group_add,
                      label: '그룹 생성',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('그룹 생성 기능은 곧 추가될 예정입니다.')),
                        );
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.search,
                      label: '그룹 검색',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('그룹 검색 기능은 곧 추가될 예정입니다.')),
                        );
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.groups,
                      label: '내 그룹',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('내 그룹 기능은 곧 추가될 예정입니다.')),
                        );
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      icon: Icons.settings,
                      label: '설정',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('설정 기능은 곧 추가될 예정입니다.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingM),

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

  Widget _buildMyActivitiesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Activities',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          '내가 참여한 그룹의 활동을 한눈에 확인하세요',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: AppStyles.spacingM),
        Card(
          child: Padding(
            padding: AppStyles.paddingM,
            child: Column(
              children: [
                _buildActivityItem(
                  context,
                  icon: Icons.notifications_active,
                  title: '새로운 공지사항',
                  subtitle: '컴퓨터공학과 동아리에서 새로운 공지가 있습니다',
                  time: '2시간 전',
                ),
                const Divider(height: AppStyles.spacingM),
                _buildActivityItem(
                  context,
                  icon: Icons.event,
                  title: 'RSVP 응답 필요',
                  subtitle: '네트워킹 모임 참석 여부를 확인해주세요',
                  time: '5시간 전',
                ),
                const Divider(height: AppStyles.spacingM),
                _buildActivityItem(
                  context,
                  icon: Icons.group_add,
                  title: '새로운 멤버 가입 승인',
                  subtitle: '데이터 사이언스 스터디에 2명이 가입 신청했습니다',
                  time: '1일 전',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: AppStyles.radiusM,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppStyles.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildRecruitmentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '모집 중인 그룹',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모집 게시판 기능은 곧 추가될 예정입니다.')),
                );
              },
              child: const Text('전체보기'),
            ),
          ],
        ),
        const SizedBox(height: AppStyles.spacingM),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRecruitmentCard(
                context,
                groupName: '웹 개발 스터디',
                department: '컴퓨터공학과',
                description: 'React와 Node.js를 함께 배워봐요',
                recruitUntil: '2025.09.20',
                memberCount: 12,
                maxMembers: 20,
              ),
              _buildRecruitmentCard(
                context,
                groupName: '데이터 사이언스 연구회',
                department: '통계학과',
                description: 'Python과 R을 활용한 데이터 분석',
                recruitUntil: '2025.09.25',
                memberCount: 8,
                maxMembers: 15,
              ),
              _buildRecruitmentCard(
                context,
                groupName: 'AI/ML 프로젝트팀',
                department: '인공지능학과',
                description: '실제 프로젝트로 경험을 쌓아요',
                recruitUntil: '2025.09.30',
                memberCount: 6,
                maxMembers: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecruitmentCard(
    BuildContext context, {
    required String groupName,
    required String department,
    required String description,
    required String recruitUntil,
    required int memberCount,
    required int maxMembers,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: AppStyles.spacingM),
      child: Card(
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('그룹 상세 정보 기능은 곧 추가될 예정입니다.')),
            );
          },
          borderRadius: AppStyles.radiusL,
          child: Padding(
            padding: AppStyles.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        groupName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: AppStyles.radiusS,
                      ),
                      child: Text(
                        '모집중',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  department,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: AppStyles.spacingS),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppStyles.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '마감: $recruitUntil',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    Text(
                      '$memberCount/$maxMembers명',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.radiusM,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingS),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: AppStyles.radiusM,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppStyles.spacingXS),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
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
