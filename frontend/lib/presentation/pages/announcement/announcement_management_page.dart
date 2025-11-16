import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../widgets/common/app_empty_state.dart';

/// 공지 관리 페이지
///
/// 그룹의 공지사항을 관리하는 페이지
/// - 공지사항 목록 조회
/// - 공지사항 작성, 수정, 삭제
/// - 공지사항 검색 및 필터링
class AnnouncementManagementPage extends ConsumerStatefulWidget {
  final int groupId;

  const AnnouncementManagementPage({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<AnnouncementManagementPage> createState() =>
      _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState
    extends ConsumerState<AnnouncementManagementPage> {
  @override
  void initState() {
    super.initState();
    // TODO: 공지사항 목록 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isWide),
                  SizedBox(height: AppSpacing.lg),
                  _buildMainContent(context, isWide),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 헤더 영역
  Widget _buildHeader(BuildContext context, bool isWide) {
    if (isWide) {
      // 데스크톱: 가로 배치
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildHeaderTitle()),
          SizedBox(width: AppSpacing.md),
          _buildHeaderActions(),
        ],
      );
    } else {
      // 모바일: 세로 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTitle(),
          SizedBox(height: AppSpacing.sm),
          _buildHeaderActions(),
        ],
      );
    }
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
          style: AppTheme.bodyMedium.copyWith(
            color: AppColors.neutral600,
          ),
        ),
      ],
    );
  }

  /// 헤더 액션 버튼
  Widget _buildHeaderActions() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: 공지사항 작성 다이얼로그 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공지 작성 기능은 곧 추가될 예정입니다')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('공지 작성'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  /// 메인 콘텐츠 영역
  Widget _buildMainContent(BuildContext context, bool isWide) {
    // TODO: 공지사항 목록 표시
    // 현재는 빈 상태 표시
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg * 2),
        child: AppEmptyState.noData(
          message: '아직 작성된 공지사항이 없습니다',
        ),
      ),
    );
  }
}
