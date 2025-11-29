import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/widgets/app_menu.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_accordion.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/app_divider.dart';

/// Phase 3 고급 UI 컴포넌트 쇼케이스 페이지
///
/// 다음 컴포넌트들을 시연합니다:
/// - AppMenu (컨텍스트 메뉴)
/// - AppPagination (페이지네이션)
/// - AppAccordion (아코디언)
/// - AppStepper (스테퍼)
/// - AppProgressBar (진행률 표시)
/// - AppDivider (구분선)
class AdvancedUIComponentsPage extends StatefulWidget {
  const AdvancedUIComponentsPage({super.key});

  @override
  State<AdvancedUIComponentsPage> createState() =>
      _AdvancedUIComponentsPageState();
}

class _AdvancedUIComponentsPageState extends State<AdvancedUIComponentsPage> {
  // Pagination state
  int _currentPage = 1;
  final int _totalPages = 10;

  // Progress state
  double _progressValue = 0.65;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        title: const Text('고급 UI 컴포넌트 (Phase 3)'),
        backgroundColor: colorExt.surfaceSecondary,
        foregroundColor: colorExt.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingExt.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===========================================
            // AppMenu 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppMenu - 컨텍스트 메뉴'),
            SizedBox(height: spacingExt.medium),

            Row(
              children: [
                // 메뉴 트리거 버튼
                AppMenuTrigger(
                  items: _buildMenuItems(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacingExt.medium,
                      vertical: spacingExt.small,
                    ),
                    decoration: BoxDecoration(
                      color: colorExt.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorExt.borderSecondary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          color: colorExt.textSecondary,
                          size: 20,
                        ),
                        SizedBox(width: spacingExt.xs),
                        Text(
                          '우클릭 또는 롱프레스',
                          style: TextStyle(
                            color: colorExt.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: spacingExt.medium),
                // 버튼으로 메뉴 표시
                ElevatedButton(
                  onPressed: () {
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final Offset offset = button.localToGlobal(Offset.zero);
                    showAppMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        offset.dx + 200,
                        offset.dy + 100,
                        0,
                        0,
                      ),
                      items: _buildMenuItems(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorExt.brandPrimary,
                    foregroundColor: colorExt.textOnBrand,
                  ),
                  child: const Text('메뉴 열기'),
                ),
              ],
            ),

            _buildDivider(spacingExt),

            // ===========================================
            // AppPagination 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppPagination - 페이지네이션'),
            SizedBox(height: spacingExt.medium),

            // Numbered style
            _buildSubsectionTitle(context, 'Numbered 스타일'),
            SizedBox(height: spacingExt.small),
            AppPagination(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              showFirstLast: true,
            ),
            SizedBox(height: spacingExt.medium),

            // Simple style
            _buildSubsectionTitle(context, 'Simple 스타일'),
            SizedBox(height: spacingExt.small),
            AppPagination.simple(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              showFirstLast: true,
            ),
            SizedBox(height: spacingExt.medium),

            // Compact style
            _buildSubsectionTitle(context, 'Compact 스타일'),
            SizedBox(height: spacingExt.small),
            AppPagination.compact(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),

            _buildDivider(spacingExt),

            // ===========================================
            // AppAccordion 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppAccordion - 아코디언'),
            SizedBox(height: spacingExt.medium),

            // Bordered style
            _buildSubsectionTitle(context, 'Bordered 스타일'),
            SizedBox(height: spacingExt.small),
            AppAccordion(
              style: AppAccordionStyle.bordered,
              items: [
                AppAccordionItem(
                  title: '섹션 1: 소개',
                  subtitle: '프로젝트 개요',
                  icon: Icons.info_outline,
                  initiallyExpanded: true,
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                    child: Text(
                      '이것은 첫 번째 섹션의 내용입니다. 아코디언 컴포넌트는 접힘/펼침이 가능한 콘텐츠 영역을 제공합니다.',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                AppAccordionItem(
                  title: '섹션 2: 기능',
                  subtitle: '주요 기능 설명',
                  icon: Icons.settings_outlined,
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                    child: Text(
                      '두 번째 섹션의 내용입니다. 다중 펼침 모드와 단일 펼침 모드를 지원합니다.',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                AppAccordionItem(
                  title: '섹션 3: FAQ',
                  icon: Icons.help_outline,
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                    child: Text(
                      '자주 묻는 질문에 대한 답변입니다.',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingExt.large),

            // Separated style
            _buildSubsectionTitle(context, 'Separated 스타일'),
            SizedBox(height: spacingExt.small),
            AppAccordion(
              style: AppAccordionStyle.separated,
              allowMultiple: false,
              items: [
                AppAccordionItem(
                  title: '항목 1',
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                    child: Text(
                      '단일 펼침 모드에서는 하나의 항목만 펼쳐집니다.',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                AppAccordionItem(
                  title: '항목 2',
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                    child: Text(
                      '다른 항목을 클릭하면 이전 항목은 자동으로 접힙니다.',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            _buildDivider(spacingExt),

            // ===========================================
            // AppStepper 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppStepper - 단계 표시기'),
            SizedBox(height: spacingExt.medium),

            // Horizontal stepper
            _buildSubsectionTitle(context, '가로 스테퍼'),
            SizedBox(height: spacingExt.small),
            AppStepper(
              steps: [
                const AppStep(title: '정보 입력', status: AppStepStatus.completed),
                const AppStep(title: '확인', status: AppStepStatus.active),
                const AppStep(title: '결제', status: AppStepStatus.pending),
                const AppStep(title: '완료', status: AppStepStatus.pending),
              ],
            ),
            SizedBox(height: spacingExt.large),

            // Simple stepper
            _buildSubsectionTitle(context, '간단한 스테퍼'),
            SizedBox(height: spacingExt.small),
            const AppSimpleStepper(currentStep: 2, totalSteps: 5),
            SizedBox(height: spacingExt.large),

            // Vertical stepper
            _buildSubsectionTitle(context, '세로 스테퍼'),
            SizedBox(height: spacingExt.small),
            AppStepper.vertical(
              steps: [
                AppStep(
                  title: '주문 접수',
                  description: '주문이 접수되었습니다',
                  status: AppStepStatus.completed,
                  content: Text(
                    '2024-01-15 10:30',
                    style: TextStyle(
                      color: colorExt.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
                AppStep(
                  title: '배송 준비',
                  description: '상품을 준비하고 있습니다',
                  status: AppStepStatus.completed,
                  content: Text(
                    '2024-01-15 14:00',
                    style: TextStyle(
                      color: colorExt.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const AppStep(
                  title: '배송 중',
                  description: '상품이 배송 중입니다',
                  status: AppStepStatus.active,
                ),
                const AppStep(title: '배송 완료', status: AppStepStatus.pending),
              ],
            ),

            _buildDivider(spacingExt),

            // ===========================================
            // AppProgressBar 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppProgressBar - 진행률 표시'),
            SizedBox(height: spacingExt.medium),

            // Linear progress
            _buildSubsectionTitle(context, '선형 프로그레스'),
            SizedBox(height: spacingExt.small),
            AppProgressBar(
              value: _progressValue,
              label: '업로드 중...',
              showPercentage: true,
              color: AppProgressBarColor.brand,
            ),
            SizedBox(height: spacingExt.medium),

            // Different colors
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '성공',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      AppProgressBar(
                        value: 0.8,
                        color: AppProgressBarColor.success,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacingExt.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '경고',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      AppProgressBar(
                        value: 0.5,
                        color: AppProgressBarColor.warning,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacingExt.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '에러',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      AppProgressBar(
                        value: 0.3,
                        color: AppProgressBarColor.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingExt.large),

            // Circular progress
            _buildSubsectionTitle(context, '원형 프로그레스'),
            SizedBox(height: spacingExt.small),
            Row(
              children: [
                AppProgressBar.circular(
                  value: _progressValue,
                  showPercentage: true,
                  size: 64,
                  strokeWidth: 6,
                ),
                SizedBox(width: spacingExt.large),
                AppProgressBar.circular(
                  value: 0.8,
                  showPercentage: true,
                  color: AppProgressBarColor.success,
                  size: 48,
                ),
                SizedBox(width: spacingExt.large),
                AppProgressBar.circular(isIndeterminate: true, size: 48),
              ],
            ),
            SizedBox(height: spacingExt.large),

            // Semicircular progress
            _buildSubsectionTitle(context, '반원형 프로그레스'),
            SizedBox(height: spacingExt.small),
            Row(
              children: [
                AppProgressBar.semicircular(
                  value: _progressValue,
                  showPercentage: true,
                  label: '완료율',
                  size: 120,
                  strokeWidth: 8,
                ),
                SizedBox(width: spacingExt.xl),
                AppProgressBar.semicircular(
                  value: 0.9,
                  showPercentage: true,
                  color: AppProgressBarColor.success,
                  size: 100,
                ),
              ],
            ),
            SizedBox(height: spacingExt.medium),

            // Progress slider
            Slider(
              value: _progressValue,
              onChanged: (value) => setState(() => _progressValue = value),
              activeColor: colorExt.brandPrimary,
            ),

            _buildDivider(spacingExt),

            // ===========================================
            // AppDivider 섹션
            // ===========================================
            _buildSectionTitle(context, 'AppDivider - 구분선'),
            SizedBox(height: spacingExt.medium),

            // Solid divider
            _buildSubsectionTitle(context, '실선'),
            const AppDivider(),

            // Dashed divider
            _buildSubsectionTitle(context, '점선'),
            const AppDivider(style: AppDividerStyle.dashed),

            // Dotted divider
            _buildSubsectionTitle(context, '도트'),
            const AppDivider(style: AppDividerStyle.dotted),

            // With label
            _buildSubsectionTitle(context, '라벨 포함'),
            AppDivider.withLabel(label: '또는'),

            // Thickness variants
            _buildSubsectionTitle(context, '두께 변형'),
            SizedBox(height: spacingExt.small),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'thin',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      const AppDivider(thickness: AppDividerThickness.thin),
                    ],
                  ),
                ),
                SizedBox(width: spacingExt.large),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'medium',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      const AppDivider(thickness: AppDividerThickness.medium),
                    ],
                  ),
                ),
                SizedBox(width: spacingExt.large),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'thick',
                        style: TextStyle(
                          color: colorExt.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: spacingExt.xs),
                      const AppDivider(thickness: AppDividerThickness.thick),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingExt.large),

            // Vertical dividers
            _buildSubsectionTitle(context, '세로 구분선'),
            SizedBox(height: spacingExt.small),
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('항목 1', style: TextStyle(color: colorExt.textSecondary)),
                  SizedBox(width: spacingExt.medium),
                  AppDivider.vertical(height: 24),
                  SizedBox(width: spacingExt.medium),
                  Text('항목 2', style: TextStyle(color: colorExt.textSecondary)),
                  SizedBox(width: spacingExt.medium),
                  AppDivider.vertical(
                    height: 24,
                    style: AppDividerStyle.dashed,
                  ),
                  SizedBox(width: spacingExt.medium),
                  Text('항목 3', style: TextStyle(color: colorExt.textSecondary)),
                ],
              ),
            ),

            SizedBox(height: spacingExt.xxl),
          ],
        ),
      ),
    );
  }

  List<AppMenuItem> _buildMenuItems() {
    return [
      AppMenuItem.header('편집'),
      AppMenuItem(
        label: '복사',
        icon: Icons.copy,
        shortcut: '⌘C',
        onTap: () => debugPrint('복사'),
      ),
      AppMenuItem(
        label: '붙여넣기',
        icon: Icons.paste,
        shortcut: '⌘V',
        onTap: () => debugPrint('붙여넣기'),
      ),
      AppMenuItem(
        label: '잘라내기',
        icon: Icons.cut,
        shortcut: '⌘X',
        onTap: () => debugPrint('잘라내기'),
      ),
      AppMenuItem.divider(),
      AppMenuItem.header('작업'),
      AppMenuItem(
        label: '공유',
        icon: Icons.share,
        onTap: () => debugPrint('공유'),
      ),
      AppMenuItem(
        label: '다운로드',
        icon: Icons.download,
        onTap: () => debugPrint('다운로드'),
      ),
      AppMenuItem(label: '비활성화 항목', icon: Icons.block, isDisabled: true),
      AppMenuItem.divider(),
      AppMenuItem(
        label: '삭제',
        icon: Icons.delete,
        isDestructive: true,
        onTap: () => debugPrint('삭제'),
      ),
    ];
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorExt = context.appColors;
    return Text(
      title,
      style: TextStyle(
        color: colorExt.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubsectionTitle(BuildContext context, String title) {
    final colorExt = context.appColors;
    return Text(
      title,
      style: TextStyle(
        color: colorExt.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDivider(AppSpacingExtension spacing) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xl),
      child: const AppDivider(),
    );
  }
}
