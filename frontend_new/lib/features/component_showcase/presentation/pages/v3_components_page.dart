import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/extensions/app_typography_extension.dart';
import '../../../../core/theme/enums.dart';
import '../../../../core/widgets/page_breadcrumb.dart';
import '../../../../core/widgets/issue_navigation_counter.dart';
import '../../../../core/widgets/issue_navigation_buttons.dart';
import '../../../../core/widgets/status_button.dart';
import '../../../../core/widgets/priority_button.dart';
import '../../../../core/widgets/assignee_button.dart';
import '../../../../core/widgets/issue_title_editor.dart';
import '../../../../core/widgets/issue_description_editor.dart';
import '../../../../core/widgets/comment_input.dart';
import '../../../../core/widgets/properties_sidebar.dart';
import '../../../../core/widgets/activity_section.dart';
import '../../../../core/widgets/labels_section.dart';
import '../../../../core/widgets/settings_sidebar.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_section.dart';

/// V3 컴포넌트 쇼케이스 페이지
///
/// Phase 4~7에서 구현한 모든 V3 컴포넌트의 통합 테스트 페이지
///
/// **포함 컴포넌트**:
/// - Phase 4: 네비게이션 (Breadcrumb, Counter, Navigation Buttons)
/// - Phase 5: 상태/액션 버튼 (Status, Priority, Assignee)
/// - Phase 6: 에디터 (Title, Description, Comment Input)
/// - Phase 7: 사이드바/섹션 (Properties, Activity, Labels, Settings)
class V3ComponentsPage extends StatefulWidget {
  const V3ComponentsPage({super.key});

  @override
  State<V3ComponentsPage> createState() => _V3ComponentsPageState();
}

class _V3ComponentsPageState extends State<V3ComponentsPage> {
  // Phase 5: 상태 변수
  late IssueStatus _status;
  late IssuePriority _priority;
  late AssigneeState _assigneeState;
  List<String> _assignees = ['John Doe'];

  // Phase 6: 에디터 변수
  late String _title;
  late String _description;

  // Phase 7: 레이블 변수
  final List<LabelItem> _labels = [
    const LabelItem(name: 'bug'),
    const LabelItem(name: 'high-priority'),
  ];

  @override
  void initState() {
    super.initState();
    _status = IssueStatus.inProgress;
    _priority = IssuePriority.high;
    _assigneeState = AssigneeState.assigned;
    _title = 'Login page not responding';
    _description = 'The login form freezes after 3 seconds...';
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacing = context.appSpacing;
    final typographyExt = context.appTypography;

    return Scaffold(
      backgroundColor: colorExt.surfacePrimary,
      appBar: AppBar(
        title: const Text('V3 Components Showcase'),
        backgroundColor: colorExt.surfaceSecondary,
        elevation: 0,
        leading: AppBackButton(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(spacing.xl),
          child: ResponsiveBuilder(
            builder: (context, screenSize, width) {
              if (screenSize == ScreenSize.desktop) {
                return _buildDesktopLayout(colorExt, typographyExt);
              } else if (screenSize == ScreenSize.tablet) {
                return _buildTabletLayout(colorExt, typographyExt);
              } else {
                return _buildMobileLayout(colorExt, typographyExt);
              }
            },
          ),
        ),
      ),
    );
  }

  // ========================================================
  // Mobile Layout
  // ========================================================
  Widget _buildMobileLayout(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'Phase 4: Navigation Components',
          variant: SectionVariant.standard,
          child: _buildNavigationSection(colorExt, typographyExt),
        ),
        AppSection(
          title: 'Phase 5: State/Action Buttons',
          variant: SectionVariant.standard,
          child: _buildButtonsSection(colorExt, typographyExt),
        ),
        AppSection(
          title: 'Phase 6: Editor Components',
          variant: SectionVariant.standard,
          child: _buildEditorsSection(colorExt, typographyExt),
        ),
        AppSection(
          title: 'Phase 7: Sidebar/Section Components',
          variant: SectionVariant.standard,
          child: _buildSidebarsSection(colorExt, typographyExt),
        ),
      ],
    );
  }

  // ========================================================
  // Tablet Layout
  // ========================================================
  Widget _buildTabletLayout(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'Phase 4: Navigation Components',
          variant: SectionVariant.standard,
          child: _buildNavigationSection(colorExt, typographyExt),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSection(
                title: 'Phase 5: State/Action Buttons',
                variant: SectionVariant.standard,
                child: _buildButtonsSection(colorExt, typographyExt),
              ),
            ),
            SizedBox(width: spacing.large),
            Expanded(
              child: AppSection(
                title: 'Phase 6: Editor Components',
                variant: SectionVariant.standard,
                child: _buildEditorsSection(colorExt, typographyExt),
              ),
            ),
          ],
        ),
        AppSection(
          title: 'Phase 7: Sidebar/Section Components',
          variant: SectionVariant.standard,
          child: _buildSidebarsSection(colorExt, typographyExt),
        ),
      ],
    );
  }

  // ========================================================
  // Desktop Layout
  // ========================================================
  Widget _buildDesktopLayout(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'Phase 4: Navigation Components',
          variant: SectionVariant.standard,
          child: _buildNavigationSection(colorExt, typographyExt),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  AppSection(
                    title: 'Phase 5: State/Action Buttons',
                    variant: SectionVariant.standard,
                    child: _buildButtonsSection(colorExt, typographyExt),
                  ),
                  AppSection(
                    title: 'Phase 6: Editor Components',
                    variant: SectionVariant.standard,
                    child: _buildEditorsSection(colorExt, typographyExt),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: AppSection(
                title: 'Phase 7: Sidebar/Section Components',
                variant: SectionVariant.standard,
                child: _buildSidebarsSection(colorExt, typographyExt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // Phase 4: Navigation Components
  // ========================================================
  Widget _buildNavigationSection(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumb
        PageBreadcrumb(
          items: const ['Issues', 'Project-001', 'Details'],
          style: BreadcrumbStyle.default_,
          onItemTap: (index) => debugPrint('Tapped: $index'),
        ),
        SizedBox(height: spacing.large),

        // Navigation Counter + Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IssueNavigationCounter(current: 5, total: 12),
            IssueNavigationButtons(
              hasPrevious: true,
              hasNext: true,
              onPrevious: () => debugPrint('Previous'),
              onNext: () => debugPrint('Next'),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // Phase 5: State/Action Buttons
  // ========================================================
  Widget _buildButtonsSection(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Button
        Text(
          'Status: ${_status.name}',
          style:
              Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorExt.textSecondary) ??
              TextStyle(color: colorExt.textSecondary),
        ),
        SizedBox(height: spacing.small),
        StatusButton(
          currentStatus: _status,
          onStatusChanged: (status) => setState(() => _status = status),
        ),
        SizedBox(height: spacing.large),

        // Priority Button
        Text(
          'Priority: ${_priority.name}',
          style:
              Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorExt.textSecondary) ??
              TextStyle(color: colorExt.textSecondary),
        ),
        SizedBox(height: spacing.small),
        PriorityButton(
          currentPriority: _priority,
          onPriorityChanged: (priority) => setState(() => _priority = priority),
        ),
        SizedBox(height: spacing.large),

        // Assignee Button
        Text(
          'Assignee: ${_assigneeState.name}',
          style:
              Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorExt.textSecondary) ??
              TextStyle(color: colorExt.textSecondary),
        ),
        SizedBox(height: spacing.small),
        AssigneeButton(
          state: _assigneeState,
          assignees: _assignees,
          onAssigneeSelected: (assignees) =>
              setState(() => _assignees = assignees),
        ),
      ],
    );
  }

  // ========================================================
  // Phase 6: Editor Components
  // ========================================================
  Widget _buildEditorsSection(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title Editor
        IssueTitleEditor(
          initialText: _title,
          onChanged: (text) => setState(() => _title = text),
        ),
        SizedBox(height: spacing.large),

        // Description Editor
        IssueDescriptionEditor(
          initialText: _description,
          onChanged: (text) => setState(() => _description = text),
        ),
        SizedBox(height: spacing.large),

        // Comment Input
        CommentInput(
          onSubmit: (text) {
            debugPrint('Comment: $text');
          },
        ),
      ],
    );
  }

  // ========================================================
  // Phase 7: Sidebar/Section Components
  // ========================================================
  Widget _buildSidebarsSection(
    AppColorExtension colorExt,
    AppTypographyExtension typographyExt,
  ) {
    final spacing = context.appSpacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Properties Sidebar
        PropertiesSidebar(
          style: SidebarStyle.default_,
          sectionTitle: 'Properties',
          properties: [
            SidebarProperty(
              label: 'Status',
              value: _status.name,
              icon: Icons.check_circle,
              onEdit: () => debugPrint('Edit status'),
            ),
            SidebarProperty(
              label: 'Priority',
              value: _priority.name,
              icon: Icons.priority_high,
              onEdit: () => debugPrint('Edit priority'),
            ),
          ],
        ),
        SizedBox(height: spacing.large),

        // Activity Section
        ActivitySection(
          sectionTitle: 'Activity',
          maxHeight: 250,
          activities: [
            ActivityItem(
              type: ActivityType.comment,
              title: 'John Doe added a comment',
              description: 'This is a test comment',
              time: '2 hours ago',
              author: 'John Doe',
              icon: Icons.comment,
            ),
            ActivityItem(
              type: ActivityType.statusChanged,
              title: 'Status changed to In Progress',
              description: 'Changed from Pending',
              time: '4 hours ago',
              author: 'System',
              icon: Icons.check_circle,
            ),
          ],
        ),
        SizedBox(height: spacing.large),

        // Labels Section
        LabelsSection(
          style: LabelsSectionStyle.default_,
          sectionTitle: 'Labels',
          labels: _labels,
          onAddLabel: () => debugPrint('Add label'),
        ),
        SizedBox(height: spacing.large),

        // Settings Sidebar
        SettingsSidebar(
          style: SidebarStyle.default_,
          sectionTitle: 'Settings',
          maxHeight: 200,
          settings: [
            SettingItem(
              label: 'Notifications',
              description: 'Receive notifications',
              icon: Icons.notifications,
              control: Switch(
                value: true,
                onChanged: (_) => debugPrint('Toggle notifications'),
              ),
            ),
            SettingItem(
              label: 'Archive',
              description: 'Move to archive',
              icon: Icons.archive,
              control: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => debugPrint('Archive'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
