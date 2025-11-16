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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Container(
            color: AppColors.lightBackground,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: isWide
                  ? _buildWideLayout(context)
                  : _buildNarrowLayout(context),
            ),
          );
        },
      ),
    );
  }

  /// Wide Layout (Desktop): 2-column layout
  Widget _buildWideLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, isWide: true),
        SizedBox(height: AppSpacing.lg),

        // Main content
        _buildMainContent(context),
      ],
    );
  }

  /// Narrow Layout (Mobile/Tablet): Single column layout
  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(context, isWide: false),
        SizedBox(height: AppSpacing.lg),

        // Main content
        _buildMainContent(context),
      ],
    );
  }

  /// 헤더 영역
  Widget _buildHeader(BuildContext context, {required bool isWide}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 600px를 기준으로 레이아웃 결정 (GroupHomeView와 동일)
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // 모바일: 세로 배치
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(),
              SizedBox(height: AppSpacing.sm),
              _buildHeaderActions(context),
            ],
          );
        } else {
          // 데스크톱: 가로 배치
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeaderTitle()),
              _buildHeaderActions(context),
            ],
          );
        }
      },
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
