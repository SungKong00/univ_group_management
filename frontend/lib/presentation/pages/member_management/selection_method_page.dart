/// Step 2: 저장 방식 선택 페이지
///
/// DYNAMIC (조건 저장) / STATIC (명단 저장) 방식을 선택하는 두 번째 단계
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/member_filter.dart';
import '../../../core/models/member_selection_result.dart';
import '../../../core/models/member_preview_response.dart';
import '../../../core/providers/member/member_preview_provider.dart';
import 'member_edit_page.dart';

/// Step 2: 저장 방식 선택 페이지
class SelectionMethodPage extends ConsumerWidget {
  final int groupId;
  final MemberFilter filter;

  const SelectionMethodPage({
    super.key,
    required this.groupId,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(
      memberPreviewProvider((groupId, filter)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('저장 방식 선택'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: previewAsync.when(
        data: (preview) => _buildContent(context, ref, preview),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('멤버 정보를 불러오는 중...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '데이터를 불러올 수 없습니다',
                  style: AppTheme.titleMedium.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  error.toString(),
                  style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(memberPreviewProvider((groupId, filter))),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MemberPreviewResponse preview,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 안내 텍스트
          Text(
            '참여자를 어떻게 관리할지 선택하세요',
            style: AppTheme.headlineSmall.copyWith(
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '총 ${preview.totalCount}명의 멤버가 조건에 해당합니다',
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // DYNAMIC 카드
          _buildDynamicCard(context, preview),
          const SizedBox(height: AppSpacing.md),

          // STATIC 카드
          _buildStaticCard(context, ref, preview),
        ],
      ),
    );
  }

  Widget _buildDynamicCard(
    BuildContext context,
    MemberPreviewResponse preview,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectDynamic(context),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.action.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.autorenew,
                      color: AppColors.action,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '조건으로 저장 (DYNAMIC)',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.action,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '총 ${preview.totalCount}명',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (preview.samples.isNotEmpty)
                Text(
                  '${preview.samples.map((s) => s.name).join(", ")}${preview.totalCount > preview.samples.length ? " ..." : ""}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _buildBenefitRow(
                Icons.check_circle,
                '신규 멤버 자동 포함',
                AppColors.success,
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.check_circle,
                '조건 변경 시 자동 업데이트',
                AppColors.success,
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.check_circle,
                '실시간 동기화',
                AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticCard(
    BuildContext context,
    WidgetRef ref,
    MemberPreviewResponse preview,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectStatic(context, ref, preview),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.list_alt,
                      color: AppColors.brand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '명단으로 저장 (STATIC)',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '총 ${preview.totalCount}명',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (preview.samples.isNotEmpty)
                Text(
                  '${preview.samples.map((s) => s.name).join(", ")}${preview.totalCount > preview.samples.length ? " ..." : ""}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              _buildBenefitRow(
                Icons.warning_amber,
                '고정 명단 (수동 관리)',
                AppColors.warning,
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.arrow_forward,
                '다음 단계에서 편집 가능',
                AppColors.neutral600,
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.info_outline,
                '특정 인원만 선택 시 유용',
                AppColors.neutral600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  void _selectDynamic(BuildContext context) {
    // DYNAMIC 선택 시 즉시 저장 (Step 3 건너뛰기)
    Navigator.pop(
      context,
      MemberSelectionResult.dynamic(filter),
    );
  }

  void _selectStatic(
    BuildContext context,
    WidgetRef ref,
    MemberPreviewResponse preview,
  ) {
    // STATIC 선택 시 Step 3으로 이동
    final memberIds = preview.samples.map((s) => s.id).toList();

    Navigator.push<MemberSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberEditPage(
          groupId: groupId,
          initialFilter: filter,
          initialSelectedIds: memberIds,
        ),
      ),
    ).then((result) {
      if (result != null && context.mounted) {
        // Step 3에서 결과가 반환되면 Step 1로 돌아가며 전달
        Navigator.pop(context, result);
      }
    });
  }
}
