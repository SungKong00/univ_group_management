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
    final previewAsync = ref.watch(memberPreviewProvider((groupId, filter)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('저장 방식 선택'),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onPrimary,
      ),
      body: previewAsync.when(
        data: (preview) => _buildContent(context, ref, preview),
        loading: () => _buildSkeletonLoading(),
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
                  _getUserFriendlyErrorMessage(error),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(memberPreviewProvider((groupId, filter))),
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

  /// 사용자 친화적인 에러 메시지 생성
  String _getUserFriendlyErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return '네트워크 연결을 확인해주세요';
    }
    if (errorStr.contains('timeout')) {
      return '서버 응답 시간이 초과되었습니다';
    }
    return '일시적인 오류가 발생했습니다. 다시 시도해주세요.';
  }

  /// Skeleton 로딩 UI
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목 Skeleton
          Container(
            height: 24,
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 16,
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 카드 Skeleton (2개)
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.neutral300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    MemberPreviewResponse preview,
  ) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 영역: 제목 + 인원수 & 샘플 통합
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참여자를 어떻게 관리할지 선택하세요',
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 20,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.neutral600,
                          ),
                          children: [
                            const TextSpan(text: '지금 조건에 맞는 멤버: '),
                            if (preview.samples.length >= 2)
                              TextSpan(
                                text:
                                    '${preview.samples[0].name}, ${preview.samples[1].name} 외 ${preview.totalCount - 2}명 ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.action,
                                ),
                              ),
                            if (preview.samples.length < 2)
                              TextSpan(
                                text: '총 ',
                                style: const TextStyle(
                                  color: AppColors.neutral600,
                                ),
                              ),
                            TextSpan(
                              text: '(총 ${preview.totalCount}명)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.action,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 카드 레이아웃 (반응형)
            if (isWide)
              // 데스크톱: 좌우 배치
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildDynamicCard(context, preview)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildStaticCard(context, ref, preview)),
                  ],
                ),
              )
            else
              // 모바일/태블릿: 상하 배치
              Column(
                children: [
                  _buildDynamicCard(context, preview),
                  const SizedBox(height: AppSpacing.md),
                  _buildStaticCard(context, ref, preview),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCard(
    BuildContext context,
    MemberPreviewResponse preview,
  ) {
    return Semantics(
      label: '자동 업데이트 방식 선택',
      hint: '조건에 맞는 멤버를 자동으로 관리합니다. 현재 ${preview.totalCount}명이 해당됩니다.',
      button: true,
      child: Card(
        elevation: 4,
        color: AppColors.actionTonalBg.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () => _selectDynamic(context),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 블록 1: 헤더 (아이콘 + 제목 + 설명)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.action.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.autorenew,
                        color: AppColors.action,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '자동 업데이트',
                            style: AppTheme.titleLarge.copyWith(
                              color: AppColors.action,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '저장한 필터 조건에 맞는 멤버를 항상 최신 상태로 유지해요.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 하이라이트 영역 (체크리스트)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBenefitRow(
                        Icons.check_circle_outline,
                        '새로 합류한 멤버도 자동으로 포함돼요.',
                        AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _buildBenefitRow(
                        Icons.check_circle_outline,
                        '멤버 정보가 바뀌면 바로 반영돼요.',
                        AppColors.success,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // 추천 문장
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.actionTonalBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.action,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          '멤버 변동이 잦은 팀에 추천해요.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.action,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 선택 버튼
                ElevatedButton(
                  onPressed: () => _selectDynamic(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.action,
                  ),
                  child: const Text('이 방식으로 선택'),
                ),
              ],
            ),
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
    return Semantics(
      label: '직접 선택 방식',
      hint:
          '현재 인원 목록을 직접 편집합니다. 다음 단계에서 ${preview.totalCount}명의 멤버를 확인할 수 있습니다.',
      button: true,
      child: Card(
        elevation: 4,
        color: AppColors.brandLight.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => _selectStatic(context, ref, preview),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 블록 1: 헤더 (아이콘 + 제목 + 설명)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_note,
                        color: AppColors.brand,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '직접 선택',
                            style: AppTheme.titleLarge.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '현재 인원 목록을 직접 편집해서 고정할 수 있어요.',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.neutral600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 하이라이트 영역 (체크리스트)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBenefitRow(
                        Icons.edit_outlined,
                        '다음 단계에서 목록을 보고 수정할 수 있어요.',
                        AppColors.brand,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _buildBenefitRow(
                        Icons.lock_outline,
                        '확정 후에는 인원이 바뀌어도 명단이 그대로 유지돼요.',
                        AppColors.brand,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // 추천 문장
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.brandLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          '구성이 거의 바뀌지 않는 팀에 잘 맞아요.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 선택 버튼
                ElevatedButton(
                  onPressed: () => _selectStatic(context, ref, preview),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.brand,
                  ),
                  child: const Text('이 방식으로 선택'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(color: color, height: 1.5),
          ),
        ),
      ],
    );
  }

  void _selectDynamic(BuildContext context) {
    // DYNAMIC 선택 시 즉시 저장 (Step 3 건너뛰기)
    Navigator.pop(context, MemberSelectionResult.dynamic(filter));
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
