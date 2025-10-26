import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../demo_calendar/demo_calendar_page.dart';
import '../dev/selectable_option_card_demo.dart';
import '../member_management/member_filter_page.dart';
import '../../providers/my_groups_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64, color: AppColors.brand),
            const SizedBox(height: 16),
            Text('프로필', style: AppTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              '계정 설정 및 프로필 관리',
              style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
            ),
            // 개발 모드 전용: 컴포넌트 데모 버튼
            if (kDebugMode) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '개발자 도구',
                style: AppTheme.titleLarge.copyWith(color: AppColors.neutral700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SelectableOptionCardDemo(),
                    ),
                  );
                },
                icon: const Icon(Icons.widgets),
                label: const Text('SelectableOptionCard 데모'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DemoCalendarPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('주간 캘린더 데모'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // 한신대학교 그룹 조회
                    final myGroups = await ref.read(myGroupsProvider.future);
                    final hanshin = myGroups.firstWhere(
                      (g) => g.name == '한신대학교',
                      orElse: () => throw Exception('한신대학교 그룹을 찾을 수 없습니다'),
                    );

                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              MemberFilterPage(groupId: hanshin.id),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('에러 발생: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.filter_list),
                label: const Text('멤버 필터 데모 (Step 1-3)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
