import 'package:flutter/material.dart';
import '../../widgets/atoms/atoms.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// SelectableOptionCard 컴포넌트 데모 페이지
///
/// Phase 1 Atoms 구현 검증용 데모 페이지.
/// 다양한 상태(선택됨/선택 안됨)와 아이콘 조합을 시각적으로 확인할 수 있습니다.
///
/// **개발 모드 전용**: 프로덕션 빌드에서는 제외됩니다.
class SelectableOptionCardDemo extends StatefulWidget {
  const SelectableOptionCardDemo({super.key});

  @override
  State<SelectableOptionCardDemo> createState() =>
      _SelectableOptionCardDemoState();
}

class _SelectableOptionCardDemoState extends State<SelectableOptionCardDemo> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SelectableOptionCard Demo'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              'Phase 1: Atoms 구현',
              style: AppTheme.displayMedium.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '다단계 선택 UI의 기본 빌딩 블록',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 섹션 1: 공식/비공식 일정 선택
            _buildSectionTitle('1. 공식/비공식 일정 선택 (캘린더)'),
            const SizedBox(height: AppSpacing.sm),
            SelectableOptionCard(
              title: '공식 일정',
              description: '그룹 전체 공지 - 캘린더 관리 권한 필요',
              icon: const Icon(
                Icons.event_note,
                size: 32,
                color: AppColors.brand,
              ),
              isSelected: _selectedOption == 1,
              onTap: () => setState(() => _selectedOption = 1),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableOptionCard(
              title: '비공식 일정',
              description: '개인 메모 - 누구나 생성 가능',
              icon: const Icon(
                Icons.edit_note,
                size: 32,
                color: AppColors.action,
              ),
              isSelected: _selectedOption == 2,
              onTap: () => setState(() => _selectedOption = 2),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 섹션 2: 일정 유형 선택
            _buildSectionTitle('2. 일정 유형 선택 (Phase 2 예정)'),
            const SizedBox(height: AppSpacing.sm),
            SelectableOptionCard(
              title: '일반 일정',
              description: '모든 멤버에게 표시',
              icon: const Icon(
                Icons.public,
                size: 32,
                color: AppColors.success,
              ),
              isSelected: _selectedOption == 3,
              onTap: () => setState(() => _selectedOption = 3),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableOptionCard(
              title: '대상 지정 일정',
              description: '특정 멤버만 참여',
              icon: const Icon(
                Icons.people,
                size: 32,
                color: AppColors.warning,
              ),
              isSelected: _selectedOption == 4,
              onTap: () => setState(() => _selectedOption = 4),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableOptionCard(
              title: '참여 신청 일정',
              description: '선착순 참여 신청',
              icon: const Icon(
                Icons.check_circle,
                size: 32,
                color: AppColors.action,
              ),
              isSelected: _selectedOption == 5,
              onTap: () => setState(() => _selectedOption = 5),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 현재 선택된 옵션 표시
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.brandLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: AppColors.brand),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.brand),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _selectedOption != null
                          ? '선택됨: 옵션 $_selectedOption'
                          : '옵션을 선택해주세요',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleLarge.copyWith(
        color: AppColors.neutral900,
      ),
    );
  }
}
