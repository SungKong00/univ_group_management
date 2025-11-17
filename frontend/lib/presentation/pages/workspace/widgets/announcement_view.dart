import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme.dart';
import '../../../widgets/common/app_empty_state.dart';

/// 공지 관리 뷰
///
/// 그룹의 공지사항을 관리하는 뷰 (그룹홈, 캘린더와 동일한 레벨)
/// - 공지사항 목록 조회
/// - 공지사항 작성, 수정, 삭제
/// - 공지사항 검색 및 필터링
class AnnouncementView extends ConsumerWidget {
  const AnnouncementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // 고정 헤더 (흰색 배경, 그림자)
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildHeader(context),
          ),

          // 스크롤 가능한 컨텐츠
          Expanded(
            child: Container(
              color: AppColors.lightBackground,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.md),
                child: _buildMainContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 헤더 영역
  /// 제목과 버튼을 항상 가로로 배치
  /// - 제목은 Expanded로 남은 공간을 차지
  /// - 버튼은 고정 너비(110px)로 오른쪽에 배치
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildHeaderTitle()),
        SizedBox(width: AppSpacing.md),
        _buildHeaderActions(context),
      ],
    );
  }

  /// 헤더 제목
  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '공지 관리',
          style: AppTheme.displaySmall.copyWith(
            color: AppColors.lightOnSurface,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          '그룹의 공지사항을 작성하고 관리하세요',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }

  /// 헤더 액션 버튼
  Widget _buildHeaderActions(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 44,
      child: FilledButton.icon(
        onPressed: () {
          // TODO: 공지사항 작성 다이얼로그 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공지 작성 기능은 곧 추가될 예정입니다')),
          );
        },
        icon: Icon(Icons.add, size: 16),
        label: Text(
          '공지 작성',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: AppColors.brand,
        ),
      ),
    );
  }

  /// 메인 콘텐츠 영역
  Widget _buildMainContent(BuildContext context) {
    // TODO: 공지사항 목록 표시
    // 현재는 빈 상태 표시
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg * 2),
        child: AppEmptyState.noData(message: '아직 작성된 공지사항이 없습니다'),
      ),
    );
  }
}
