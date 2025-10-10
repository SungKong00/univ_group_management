import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// 모집 관리 페이지 (구현 예정)
///
/// Step 1: 워크스페이스 네비게이션 구조에 페이지를 연결하기 위한 기본 스켈레톤입니다.
/// 이후 단계에서 실제 UI와 기능을 채워 넣습니다.
class RecruitmentManagementPage extends ConsumerWidget {
  const RecruitmentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.neutral100,
      alignment: Alignment.center,
      child: Text(
        '모집 관리 페이지가 준비 중입니다.',
        style: AppTheme.bodyLarge.copyWith(color: AppColors.neutral600),
      ),
    );
  }
}
