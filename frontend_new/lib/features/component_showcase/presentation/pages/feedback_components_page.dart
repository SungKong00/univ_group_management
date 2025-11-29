import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/theme/enums.dart';

// Phase 1 컴포넌트
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_tooltip.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_dropdown.dart';

// Phase 2 컴포넌트
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_time_picker.dart';

// 공통 위젯
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_section.dart';
import '../../../../core/widgets/app_button.dart';

/// Phase 1, 2 피드백/유틸리티 컴포넌트 쇼케이스 페이지
///
/// **Phase 1 컴포넌트** (6개):
/// - AppBadge: 상태 표시 배지
/// - AppToast: 알림 토스트
/// - AppTooltip: 툴팁
/// - AppDialog: 다이얼로그
/// - AppChip: 태그/필터 칩
/// - AppDropdown: 드롭다운 메뉴
///
/// **Phase 2 컴포넌트** (6개):
/// - AppSkeleton: 로딩 스켈레톤
/// - AppEmptyState: 빈 상태
/// - AppErrorState: 에러 상태
/// - AppAvatar: 아바타
/// - AppDatePicker: 날짜 선택기
/// - AppTimePicker: 시간 선택기
class FeedbackComponentsPage extends StatefulWidget {
  const FeedbackComponentsPage({super.key});

  @override
  State<FeedbackComponentsPage> createState() => _FeedbackComponentsPageState();
}

class _FeedbackComponentsPageState extends State<FeedbackComponentsPage> {
  // Chip 선택 상태
  int? _selectedChipIndex;

  // Dropdown 선택 상태
  String? _selectedDropdownValue;

  // DatePicker 상태
  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // TimePicker 상태
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        title: const Text('피드백/유틸리티 컴포넌트'),
        backgroundColor: colorExt.surfaceSecondary,
        elevation: 0,
        leading: AppBackButton(),
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhase1Section(width),
                SizedBox(height: ResponsiveTokens.sectionVerticalGap(width)),
                _buildPhase2Section(width),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // Phase 1 섹션
  // ================================================================
  Widget _buildPhase1Section(double width) {
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 1: 피드백 컴포넌트',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.large),

        // Badge 섹션
        _buildBadgeSection(),
        SizedBox(height: spacing.xxl),

        // Toast 섹션
        _buildToastSection(),
        SizedBox(height: spacing.xxl),

        // Tooltip 섹션
        _buildTooltipSection(),
        SizedBox(height: spacing.xxl),

        // Dialog 섹션
        _buildDialogSection(),
        SizedBox(height: spacing.xxl),

        // Chip 섹션
        _buildChipSection(),
        SizedBox(height: spacing.xxl),

        // Dropdown 섹션
        _buildDropdownSection(),
      ],
    );
  }

  // ================================================================
  // Phase 2 섹션
  // ================================================================
  Widget _buildPhase2Section(double width) {
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase 2: 상태/유틸리티 컴포넌트',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.large),

        // Skeleton 섹션
        _buildSkeletonSection(),
        SizedBox(height: spacing.xxl),

        // EmptyState 섹션
        _buildEmptyStateSection(),
        SizedBox(height: spacing.xxl),

        // ErrorState 섹션
        _buildErrorStateSection(),
        SizedBox(height: spacing.xxl),

        // Avatar 섹션
        _buildAvatarSection(),
        SizedBox(height: spacing.xxl),

        // DatePicker 섹션
        _buildDatePickerSection(),
        SizedBox(height: spacing.xxl),

        // TimePicker 섹션
        _buildTimePickerSection(),
      ],
    );
  }

  // ================================================================
  // Badge 섹션
  // ================================================================
  Widget _buildBadgeSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppBadge',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color별 배지 (Prominent)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppBadge(label: 'Neutral', color: AppBadgeColor.neutral),
              AppBadge(label: 'Brand', color: AppBadgeColor.brand),
              AppBadge(label: 'Success', color: AppBadgeColor.success),
              AppBadge(label: 'Warning', color: AppBadgeColor.warning),
              AppBadge(label: 'Error', color: AppBadgeColor.error),
              AppBadge(label: 'Info', color: AppBadgeColor.info),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            'Subtle 스타일',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppBadge(label: 'Subtle', variant: AppBadgeVariant.subtle),
              AppBadge(
                label: 'Success',
                variant: AppBadgeVariant.subtle,
                color: AppBadgeColor.success,
              ),
              AppBadge(
                label: 'Error',
                variant: AppBadgeVariant.subtle,
                color: AppBadgeColor.error,
              ),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            'Size별 배지',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppBadge(label: 'Small', size: AppBadgeSize.small),
              AppBadge(label: 'Medium', size: AppBadgeSize.medium),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '아이콘 포함 & 카운트 배지',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppBadge(
                label: 'New',
                icon: Icons.star,
                color: AppBadgeColor.success,
              ),
              AppBadge(
                label: 'Pro',
                icon: Icons.workspace_premium,
                color: AppBadgeColor.brand,
              ),
              AppBadge.count(count: 5, color: AppBadgeColor.error),
              AppBadge.count(count: 150), // 99+로 표시
              AppBadge.dot(color: AppBadgeColor.error),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Toast 섹션
  // ================================================================
  Widget _buildToastSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppToast',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '토스트 트리거 버튼 (showAppToast 사용)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppButton(
                text: 'Info Toast',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  showAppToast(
                    context,
                    message: '정보 메시지입니다.',
                    type: AppToastType.info,
                  );
                },
              ),
              AppButton(
                text: 'Success Toast',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  showAppToast(
                    context,
                    message: '성공적으로 저장되었습니다!',
                    type: AppToastType.success,
                  );
                },
              ),
              AppButton(
                text: 'Warning Toast',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  showAppToast(
                    context,
                    message: '주의가 필요합니다.',
                    type: AppToastType.warning,
                  );
                },
              ),
              AppButton(
                text: 'Error Toast',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  showAppToast(
                    context,
                    message: '오류가 발생했습니다.',
                    type: AppToastType.error,
                  );
                },
              ),
              AppButton(
                text: 'Toast with Action',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  showAppToast(
                    context,
                    message: '파일이 삭제되었습니다.',
                    type: AppToastType.info,
                    actionLabel: '실행취소',
                    onAction: () {
                      debugPrint('Undo action');
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Tooltip 섹션
  // ================================================================
  Widget _buildTooltipSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppTooltip',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '호버하여 툴팁 확인',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.xl,
            runSpacing: spacing.medium,
            children: [
              AppTooltip(
                message: '이것은 기본 툴팁입니다.',
                child: AppButton(
                  text: '기본 툴팁',
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.ghost,
                  onPressed: () {},
                ),
              ),
              AppTooltip(
                message: '위쪽에 표시되는 툴팁',
                preferredPosition: AppTooltipPosition.top,
                child: Container(
                  padding: EdgeInsets.all(spacing.medium),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Top',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              AppTooltip(
                message: '오른쪽에 표시되는 툴팁',
                preferredPosition: AppTooltipPosition.right,
                child: Container(
                  padding: EdgeInsets.all(spacing.medium),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Right',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              AppTooltip(
                message: '왼쪽에 표시되는 툴팁',
                preferredPosition: AppTooltipPosition.left,
                child: Container(
                  padding: EdgeInsets.all(spacing.medium),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Left',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Dialog 섹션
  // ================================================================
  Widget _buildDialogSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppDialog',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '다이얼로그 타입별 샘플 (showAppDialog 사용)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppButton(
                text: '확인 다이얼로그',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final result = await showAppConfirm(
                    context,
                    title: '삭제 확인',
                    description: '이 항목을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                    confirmLabel: '삭제',
                    cancelLabel: '취소',
                    isDestructive: true,
                  );
                  debugPrint('Confirm result: $result');
                },
              ),
              AppButton(
                text: '알림 다이얼로그',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await showAppAlert(
                    context,
                    title: '알림',
                    description: '저장이 완료되었습니다.',
                  );
                },
              ),
              AppButton(
                text: '입력 다이얼로그',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final result = await showAppPrompt(
                    context,
                    title: '이름 입력',
                    hintText: '새 이름을 입력하세요',
                    confirmLabel: '저장',
                  );
                  debugPrint('Prompt result: $result');
                },
              ),
              AppButton(
                text: '커스텀 다이얼로그',
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () async {
                  await showAppDialog(
                    context,
                    title: '커스텀 다이얼로그',
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration,
                          size: 48,
                          color: context.appColors.brandPrimary,
                        ),
                        SizedBox(height: spacing.medium),
                        Text(
                          '축하합니다!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: spacing.small),
                        Text(
                          '모든 작업이 완료되었습니다.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    type: AppDialogType.alert,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Chip 섹션
  // ================================================================
  Widget _buildChipSection() {
    final spacing = context.appSpacing;
    final chipLabels = ['Flutter', 'Dart', 'Firebase', 'Android', 'iOS', 'Web'];

    return AppSection(
      title: 'AppChip',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type별 칩',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.small,
            runSpacing: spacing.small,
            children: [
              AppChip(label: 'Filter', type: AppChipType.filter),
              AppChip(label: 'Input', type: AppChipType.input, onDelete: () {}),
              AppChip(label: 'Suggestion', type: AppChipType.suggestion),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '선택 가능 칩 그룹 (선택: ${_selectedChipIndex != null ? chipLabels[_selectedChipIndex!] : "없음"})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          AppChipGroup(
            chips: chipLabels,
            selectedIndex: _selectedChipIndex,
            onSelected: (index) {
              setState(() => _selectedChipIndex = index);
            },
          ),
          SizedBox(height: spacing.large),
          Text(
            '삭제 가능 칩 (Input 타입)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.small,
            runSpacing: spacing.small,
            children: [
              AppChip(
                label: 'Tag 1',
                type: AppChipType.input,
                onDelete: () => debugPrint('Delete Tag 1'),
              ),
              AppChip(
                label: 'Tag 2',
                type: AppChipType.input,
                onDelete: () => debugPrint('Delete Tag 2'),
              ),
              AppChip(
                label: 'Icon Tag',
                type: AppChipType.input,
                leadingIcon: Icons.label,
                onDelete: () => debugPrint('Delete Tag 3'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Dropdown 섹션
  // ================================================================
  Widget _buildDropdownSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppDropdown',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 드롭다운 (선택: ${_selectedDropdownValue ?? "없음"})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          SizedBox(
            width: 300,
            child: AppDropdown<String>(
              items: const [
                AppDropdownItem(value: 'option1', label: '옵션 1'),
                AppDropdownItem(value: 'option2', label: '옵션 2'),
                AppDropdownItem(value: 'option3', label: '옵션 3'),
                AppDropdownItem(
                  value: 'option4',
                  label: '옵션 4 (비활성)',
                  isDisabled: true,
                ),
              ],
              value: _selectedDropdownValue,
              placeholder: '옵션을 선택하세요',
              onChanged: (value) {
                setState(() => _selectedDropdownValue = value);
              },
            ),
          ),
          SizedBox(height: spacing.large),
          Text(
            '아이콘 포함 드롭다운',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          SizedBox(
            width: 300,
            child: AppDropdown<String>(
              items: const [
                AppDropdownItem(value: 'home', label: '홈', icon: Icons.home),
                AppDropdownItem(
                  value: 'settings',
                  label: '설정',
                  icon: Icons.settings,
                ),
                AppDropdownItem(
                  value: 'profile',
                  label: '프로필',
                  icon: Icons.person,
                ),
              ],
              placeholder: '메뉴 선택',
              onChanged: (value) => debugPrint('Selected: $value'),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Skeleton 섹션
  // ================================================================
  Widget _buildSkeletonSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppSkeleton',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 스켈레톤 타입',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle
              Column(
                children: [
                  AppSkeleton.circle(size: 48),
                  SizedBox(height: spacing.small),
                  Text('Circle', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              SizedBox(width: spacing.xl),
              // Text lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.text(height: 20),
                    SizedBox(height: spacing.small),
                    AppSkeleton.text(width: 200, height: 16),
                    SizedBox(height: spacing.small),
                    Text('Text', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '사각형 스켈레톤',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          AppSkeleton.rectangle(height: 120),
          SizedBox(height: spacing.large),
          Text(
            '여러 줄 스켈레톤',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          const AppSkeletonLines(lines: 4),
          SizedBox(height: spacing.large),
          Text(
            '카드 스켈레톤',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Row(
            children: [
              Expanded(child: AppSkeletonCard.vertical()),
              SizedBox(width: spacing.large),
              Expanded(child: AppSkeletonCard.horizontal()),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EmptyState 섹션
  // ================================================================
  Widget _buildEmptyStateSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppEmptyState',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빈 상태 타입별 샘플',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppEmptyState.noData(
              title: '데이터가 없습니다',
              description: '새 항목을 추가하여 시작하세요.',
              actionLabel: '항목 추가',
              onAction: () => debugPrint('Add item'),
              isCompact: true,
            ),
          ),
          SizedBox(height: spacing.large),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppEmptyState.search(
              searchQuery: 'Flutter',
              onClearSearch: () => debugPrint('Clear search'),
              isCompact: true,
            ),
          ),
          SizedBox(height: spacing.large),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppEmptyState.noFavorites(
              onBrowse: () => debugPrint('Browse'),
              isCompact: true,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ErrorState 섹션
  // ================================================================
  Widget _buildErrorStateSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppErrorState',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '에러 상태 타입별 샘플',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppErrorState.network(
              onRetry: () => debugPrint('Retry'),
              isCompact: true,
            ),
          ),
          SizedBox(height: spacing.large),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppErrorState.server(
              onRetry: () => debugPrint('Retry'),
              isCompact: true,
            ),
          ),
          SizedBox(height: spacing.large),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppErrorState.notFound(
              onGoHome: () => debugPrint('Go home'),
              isCompact: true,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Avatar 섹션
  // ================================================================
  Widget _buildAvatarSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppAvatar',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '크기별 아바타',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppAvatar(name: 'XS', size: AppAvatarSize.xs),
              AppAvatar(name: 'SM', size: AppAvatarSize.sm),
              AppAvatar(name: 'MD', size: AppAvatarSize.md),
              AppAvatar(name: 'LG', size: AppAvatarSize.lg),
              AppAvatar(name: 'XL', size: AppAvatarSize.xl),
              AppAvatar(name: 'XXL', size: AppAvatarSize.xxl),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '이름 기반 색상 (자동 할당)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppAvatar.initials(name: '홍길동', size: AppAvatarSize.lg),
              AppAvatar.initials(name: 'John Doe', size: AppAvatarSize.lg),
              AppAvatar.initials(name: 'Alice', size: AppAvatarSize.lg),
              AppAvatar.initials(name: 'Bob', size: AppAvatarSize.lg),
              AppAvatar.initials(name: '김철수', size: AppAvatarSize.lg),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '상태 표시기',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Wrap(
            spacing: spacing.medium,
            runSpacing: spacing.medium,
            children: [
              AppAvatar(
                name: 'Online',
                size: AppAvatarSize.lg,
                showStatus: true,
                status: AppAvatarStatus.online,
              ),
              AppAvatar(
                name: 'Away',
                size: AppAvatarSize.lg,
                showStatus: true,
                status: AppAvatarStatus.away,
              ),
              AppAvatar(
                name: 'Busy',
                size: AppAvatarSize.lg,
                showStatus: true,
                status: AppAvatarStatus.busy,
              ),
              AppAvatar(
                name: 'Offline',
                size: AppAvatarSize.lg,
                showStatus: true,
                status: AppAvatarStatus.offline,
              ),
            ],
          ),
          SizedBox(height: spacing.large),
          Text(
            '아바타 그룹',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          AppAvatarGroup(
            avatars: const [
              AvatarData(name: 'User 1'),
              AvatarData(name: 'User 2'),
              AvatarData(name: 'User 3'),
              AvatarData(name: 'User 4'),
              AvatarData(name: 'User 5'),
              AvatarData(name: 'User 6'),
            ],
            maxDisplay: 4,
            size: AppAvatarSize.md,
            onMoreTap: () => debugPrint('Show all'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DatePicker 섹션
  // ================================================================
  Widget _buildDatePickerSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppDatePicker',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택된 날짜: ${_selectedDate?.toString().split(' ')[0] ?? "없음"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Row(
            children: [
              AppButton(
                text: '날짜 선택',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: SizedBox(
                        width: 320,
                        child: AppDatePicker(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() => _selectedDate = date);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(width: spacing.medium),
              AppButton(
                text: '범위 선택',
                size: AppButtonSize.small,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: SizedBox(
                        width: 320,
                        child: AppDatePicker.range(
                          startDate: _rangeStart,
                          endDate: _rangeEnd,
                          onRangeSelected: (start, end) {
                            setState(() {
                              _rangeStart = start;
                              _rangeEnd = end;
                            });
                            if (start != null && end != null) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (_rangeStart != null || _rangeEnd != null) ...[
            SizedBox(height: spacing.small),
            Text(
              '범위: ${_rangeStart?.toString().split(' ')[0] ?? "?"} ~ ${_rangeEnd?.toString().split(' ')[0] ?? "?"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: spacing.large),
          Text(
            '인라인 날짜 선택기',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppDatePicker.inline(
              selectedDate: _selectedDate ?? DateTime.now(),
              onDateSelected: (date) {
                setState(() => _selectedDate = date);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // TimePicker 섹션
  // ================================================================
  Widget _buildTimePickerSection() {
    final spacing = context.appSpacing;

    return AppSection(
      title: 'AppTimePicker',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택된 시간: ${_selectedTime?.format(context) ?? "없음"}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          AppButton(
            text: '시간 선택',
            size: AppButtonSize.small,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: SizedBox(
                    width: 300,
                    child: AppTimePicker(
                      selectedTime: _selectedTime ?? TimeOfDay.now(),
                      onTimeSelected: (time) {
                        setState(() => _selectedTime = time);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.large),
          Text(
            '인라인 시간 선택기',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: spacing.medium),
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppTimePicker.inline(
              selectedTime: _selectedTime ?? TimeOfDay.now(),
              onTimeSelected: (time) {
                setState(() => _selectedTime = time);
              },
            ),
          ),
        ],
      ),
    );
  }
}
