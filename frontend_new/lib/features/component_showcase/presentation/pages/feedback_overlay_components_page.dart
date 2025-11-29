import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/widgets/app_section.dart';
import '../../../../core/widgets/app_spinner.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/app_notification_badge.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_popover.dart';
import '../../../../core/widgets/app_hover_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_command_palette.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/theme/enums.dart';

/// Phase 6: 고급 피드백 & 오버레이 컴포넌트 쇼케이스
class FeedbackOverlayComponentsPage extends StatefulWidget {
  const FeedbackOverlayComponentsPage({super.key});

  @override
  State<FeedbackOverlayComponentsPage> createState() =>
      _FeedbackOverlayComponentsPageState();
}

class _FeedbackOverlayComponentsPageState
    extends State<FeedbackOverlayComponentsPage> {
  // Alert states
  bool _showInfoAlert = true;
  bool _showSuccessAlert = true;
  bool _showWarningAlert = true;
  bool _showErrorAlert = true;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 6: 피드백 & 오버레이 컴포넌트'),
        backgroundColor: colorExt.surfaceSecondary,
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpinnerSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildAlertSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildNotificationBadgeSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildSheetSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildPopoverSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildHoverCardSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildConfirmDialogSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                _buildCommandPaletteSection(width),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================================
  // Section 1: Spinner
  // ========================================================
  Widget _buildSpinnerSection(double width) {
    return AppSection(
      title: 'AppSpinner - 스피너 로딩',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '크기별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLabeledWidget(
                'XS',
                const AppSpinner(size: AppSpinnerSize.xs),
              ),
              _buildLabeledWidget(
                'Small',
                const AppSpinner(size: AppSpinnerSize.small),
              ),
              _buildLabeledWidget(
                'Medium',
                const AppSpinner(size: AppSpinnerSize.medium),
              ),
              _buildLabeledWidget(
                'Large',
                const AppSpinner(size: AppSpinnerSize.large),
              ),
              _buildLabeledWidget(
                'XL',
                const AppSpinner(size: AppSpinnerSize.xl),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '스타일별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLabeledWidget(
                'Circular',
                const AppSpinner(
                  size: AppSpinnerSize.large,
                  style: AppSpinnerStyle.circular,
                ),
              ),
              _buildLabeledWidget(
                'Dots',
                const AppSpinner(
                  size: AppSpinnerSize.large,
                  style: AppSpinnerStyle.dots,
                ),
              ),
              _buildLabeledWidget(
                'Pulse',
                const AppSpinner(
                  size: AppSpinnerSize.large,
                  style: AppSpinnerStyle.pulse,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '색상 커스터마이징',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLabeledWidget(
                'Brand',
                AppSpinner(color: context.appColors.brandPrimary),
              ),
              _buildLabeledWidget(
                'Success',
                AppSpinner(color: context.appColors.stateSuccessText),
              ),
              _buildLabeledWidget(
                'Warning',
                AppSpinner(color: context.appColors.stateWarningText),
              ),
              _buildLabeledWidget(
                'Error',
                AppSpinner(color: context.appColors.stateErrorText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 2: Alert
  // ========================================================
  Widget _buildAlertSection(double width) {
    return AppSection(
      title: 'AppAlert - 알림 배너',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '타입별 (Subtle 스타일)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          if (_showInfoAlert)
            Padding(
              padding: EdgeInsets.only(bottom: context.appSpacing.small),
              child: AppAlert(
                type: AppAlertType.info,
                title: '정보',
                message: '새로운 업데이트가 있습니다.',
                isDismissible: true,
                onDismiss: () => setState(() => _showInfoAlert = false),
              ),
            ),
          if (_showSuccessAlert)
            Padding(
              padding: EdgeInsets.only(bottom: context.appSpacing.small),
              child: AppAlert(
                type: AppAlertType.success,
                title: '성공',
                message: '저장이 완료되었습니다.',
                isDismissible: true,
                onDismiss: () => setState(() => _showSuccessAlert = false),
              ),
            ),
          if (_showWarningAlert)
            Padding(
              padding: EdgeInsets.only(bottom: context.appSpacing.small),
              child: AppAlert(
                type: AppAlertType.warning,
                title: '주의',
                message: '이 작업은 되돌릴 수 없습니다.',
                isDismissible: true,
                onDismiss: () => setState(() => _showWarningAlert = false),
              ),
            ),
          if (_showErrorAlert)
            Padding(
              padding: EdgeInsets.only(bottom: context.appSpacing.small),
              child: AppAlert(
                type: AppAlertType.error,
                title: '오류',
                message: '저장에 실패했습니다. 다시 시도해주세요.',
                isDismissible: true,
                onDismiss: () => setState(() => _showErrorAlert = false),
                actionLabel: '다시 시도',
                onAction: () {},
              ),
            ),
          if (!_showInfoAlert &&
              !_showSuccessAlert &&
              !_showWarningAlert &&
              !_showErrorAlert)
            TextButton(
              onPressed: () => setState(() {
                _showInfoAlert = true;
                _showSuccessAlert = true;
                _showWarningAlert = true;
                _showErrorAlert = true;
              }),
              child: const Text('알림 초기화'),
            ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '스타일별 비교',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Column(
            children: [
              AppAlert(
                type: AppAlertType.info,
                style: AppAlertStyle.subtle,
                message: 'Subtle 스타일 - 배경색만',
              ),
              SizedBox(height: context.appSpacing.small),
              AppAlert(
                type: AppAlertType.info,
                style: AppAlertStyle.outlined,
                message: 'Outlined 스타일 - 테두리만',
              ),
              SizedBox(height: context.appSpacing.small),
              AppAlert(
                type: AppAlertType.info,
                style: AppAlertStyle.filled,
                message: 'Filled 스타일 - 채워진 배경',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 3: Notification Badge
  // ========================================================
  Widget _buildNotificationBadgeSection(double width) {
    return AppSection(
      title: 'AppNotificationBadge - 알림 배지',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '숫자 배지',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            children: [
              AppNotificationBadge(
                count: 1,
                child: Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
              AppNotificationBadge(
                count: 9,
                child: Icon(
                  Icons.mail_outlined,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
              AppNotificationBadge(
                count: 99,
                child: Icon(
                  Icons.inbox_outlined,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
              AppNotificationBadge(
                count: 150,
                maxCount: 99,
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '점 배지',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            children: [
              AppNotificationBadge(
                showDot: true,
                child: Icon(
                  Icons.person_outline,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
              AppNotificationBadge(
                showDot: true,
                badgeColor: AppBadgeColor.success,
                child: Icon(
                  Icons.wifi,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
              AppNotificationBadge(
                showDot: true,
                badgeColor: AppBadgeColor.warning,
                child: Icon(
                  Icons.warning_amber_outlined,
                  size: 28,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '색상별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            children: [
              _buildLabeledWidget(
                'Error',
                AppNotificationBadge(
                  count: 5,
                  badgeColor: AppBadgeColor.error,
                  child: const Icon(Icons.folder_outlined, size: 28),
                ),
              ),
              _buildLabeledWidget(
                'Success',
                AppNotificationBadge(
                  count: 5,
                  badgeColor: AppBadgeColor.success,
                  child: const Icon(Icons.folder_outlined, size: 28),
                ),
              ),
              _buildLabeledWidget(
                'Warning',
                AppNotificationBadge(
                  count: 5,
                  badgeColor: AppBadgeColor.warning,
                  child: const Icon(Icons.folder_outlined, size: 28),
                ),
              ),
              _buildLabeledWidget(
                'Info',
                AppNotificationBadge(
                  count: 5,
                  badgeColor: AppBadgeColor.info,
                  child: const Icon(Icons.folder_outlined, size: 28),
                ),
              ),
              _buildLabeledWidget(
                'Brand',
                AppNotificationBadge(
                  count: 5,
                  badgeColor: AppBadgeColor.brand,
                  child: const Icon(Icons.folder_outlined, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 4: Sheet
  // ========================================================
  Widget _buildSheetSection(double width) {
    return AppSection(
      title: 'AppSheet - 시트 패널',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '위치별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.small,
            children: [
              ElevatedButton.icon(
                onPressed: () => showAppSheet(
                  context: context,
                  title: '우측 시트',
                  position: AppSheetPosition.right,
                  child: _buildSheetContent(),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('우측'),
              ),
              ElevatedButton.icon(
                onPressed: () => showAppSheet(
                  context: context,
                  title: '좌측 시트',
                  position: AppSheetPosition.left,
                  child: _buildSheetContent(),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('좌측'),
              ),
              ElevatedButton.icon(
                onPressed: () => showAppSheet(
                  context: context,
                  title: '상단 시트',
                  position: AppSheetPosition.top,
                  child: _buildSheetContent(),
                ),
                icon: const Icon(Icons.arrow_upward),
                label: const Text('상단'),
              ),
              ElevatedButton.icon(
                onPressed: () => showAppSheet(
                  context: context,
                  title: '하단 시트',
                  position: AppSheetPosition.bottom,
                  child: _buildSheetContent(),
                ),
                icon: const Icon(Icons.arrow_downward),
                label: const Text('하단'),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '크기별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.small,
            children: [
              OutlinedButton(
                onPressed: () => showAppSheet(
                  context: context,
                  title: 'Small (320px)',
                  size: AppSheetSize.small,
                  child: _buildSheetContent(),
                ),
                child: const Text('Small'),
              ),
              OutlinedButton(
                onPressed: () => showAppSheet(
                  context: context,
                  title: 'Medium (480px)',
                  size: AppSheetSize.medium,
                  child: _buildSheetContent(),
                ),
                child: const Text('Medium'),
              ),
              OutlinedButton(
                onPressed: () => showAppSheet(
                  context: context,
                  title: 'Large (640px)',
                  size: AppSheetSize.large,
                  child: _buildSheetContent(),
                ),
                child: const Text('Large'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent() {
    return Padding(
      padding: EdgeInsets.all(context.appSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시트 콘텐츠',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          SizedBox(height: context.appSpacing.medium),
          Text(
            '여기에 상세 정보나 편집 폼을 표시할 수 있습니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          SizedBox(height: context.appSpacing.large),
          ...List.generate(
            5,
            (index) => ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text('항목 ${index + 1}'),
              subtitle: Text('설명 텍스트 ${index + 1}'),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 5: Popover
  // ========================================================
  Widget _buildPopoverSection(double width) {
    return AppSection(
      title: 'AppPopover - 팝오버',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '위치별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.large,
            runSpacing: context.appSpacing.medium,
            children: [
              AppPopover(
                position: AppPopoverPosition.top,
                triggerBuilder: (context, open) =>
                    OutlinedButton(onPressed: open, child: const Text('Top')),
                contentBuilder: (context, close) => _buildPopoverContent(close),
              ),
              AppPopover(
                position: AppPopoverPosition.bottom,
                triggerBuilder: (context, open) => OutlinedButton(
                  onPressed: open,
                  child: const Text('Bottom'),
                ),
                contentBuilder: (context, close) => _buildPopoverContent(close),
              ),
              AppPopover(
                position: AppPopoverPosition.left,
                triggerBuilder: (context, open) =>
                    OutlinedButton(onPressed: open, child: const Text('Left')),
                contentBuilder: (context, close) => _buildPopoverContent(close),
              ),
              AppPopover(
                position: AppPopoverPosition.right,
                triggerBuilder: (context, open) =>
                    OutlinedButton(onPressed: open, child: const Text('Right')),
                contentBuilder: (context, close) => _buildPopoverContent(close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopoverContent(VoidCallback close) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '팝오버 제목',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.appSpacing.small),
        Text(
          '팝오버 콘텐츠입니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        SizedBox(height: context.appSpacing.medium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: close, child: const Text('취소')),
            SizedBox(width: context.appSpacing.small),
            ElevatedButton(onPressed: close, child: const Text('확인')),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // Section 6: Hover Card
  // ========================================================
  Widget _buildHoverCardSection(double width) {
    return AppSection(
      title: 'AppHoverCard - 호버 카드',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마우스를 올려보세요',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            children: [
              AppHoverCard(
                size: AppHoverCardSize.small,
                triggerBuilder: (context) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.appSpacing.small,
                    vertical: context.appSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.brandPrimary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '@username',
                    style: TextStyle(
                      color: context.appColors.brandPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                contentBuilder: (context) => _buildUserCard(),
              ),
              AppHoverCard(
                size: AppHoverCardSize.medium,
                triggerBuilder: (context) => Text(
                  '프로젝트 이름',
                  style: TextStyle(
                    color: context.appColors.linkDefault,
                    decoration: TextDecoration.underline,
                  ),
                ),
                contentBuilder: (context) => _buildProjectCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: context.appColors.brandPrimary,
          child: const Text('JD', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: context.appSpacing.medium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'John Doe',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '@johndoe',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            SizedBox(height: context.appSpacing.xs),
            Text(
              'Software Engineer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 20,
              color: context.appColors.brandPrimary,
            ),
            SizedBox(width: context.appSpacing.small),
            Text(
              '프로젝트 이름',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.appSpacing.small),
        Text(
          '이 프로젝트는 Flutter 컴포넌트 라이브러리를 구축합니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        SizedBox(height: context.appSpacing.small),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 14,
              color: context.appColors.stateWarningText,
            ),
            SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(color: context.appColors.textTertiary),
            ),
            SizedBox(width: context.appSpacing.medium),
            Icon(Icons.people, size: 14, color: context.appColors.textTertiary),
            SizedBox(width: 4),
            Text(
              '12명',
              style: TextStyle(color: context.appColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // Section 7: Confirm Dialog
  // ========================================================
  Widget _buildConfirmDialogSection(double width) {
    return AppSection(
      title: 'AppConfirmDialog - 확인 다이얼로그',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 및 위험 모드',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.medium,
            runSpacing: context.appSpacing.small,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final confirmed = await showAppConfirmDialog(
                    context: context,
                    title: '저장하시겠습니까?',
                    message: '변경사항을 저장합니다.',
                    confirmLabel: '저장',
                  );
                  if (confirmed && mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
                  }
                },
                child: const Text('기본 다이얼로그'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appColors.stateErrorBg,
                ),
                onPressed: () async {
                  final confirmed = await showAppConfirmDialog(
                    context: context,
                    title: '삭제하시겠습니까?',
                    message: '이 작업은 되돌릴 수 없습니다. 모든 데이터가 영구적으로 삭제됩니다.',
                    confirmLabel: '삭제',
                    isDestructive: true,
                  );
                  if (confirmed && mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
                  }
                },
                child: const Text('위험 다이얼로그'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 8: Command Palette
  // ========================================================
  Widget _buildCommandPaletteSection(double width) {
    final commands = [
      const AppCommand(
        id: 'new_file',
        label: '새 파일',
        description: '새 파일을 생성합니다',
        icon: Icons.add,
        shortcut: '⌘N',
        category: '파일',
      ),
      const AppCommand(
        id: 'open_file',
        label: '파일 열기',
        description: '기존 파일을 엽니다',
        icon: Icons.folder_open,
        shortcut: '⌘O',
        category: '파일',
      ),
      const AppCommand(
        id: 'save',
        label: '저장',
        description: '현재 파일을 저장합니다',
        icon: Icons.save,
        shortcut: '⌘S',
        category: '파일',
      ),
      const AppCommand(
        id: 'settings',
        label: '설정',
        description: '환경설정을 엽니다',
        icon: Icons.settings,
        shortcut: '⌘,',
        category: '설정',
      ),
      const AppCommand(
        id: 'theme',
        label: '테마 변경',
        description: '다크/라이트 테마를 전환합니다',
        icon: Icons.palette,
        category: '설정',
      ),
      const AppCommand(
        id: 'search',
        label: '검색',
        description: '파일 내용을 검색합니다',
        icon: Icons.search,
        shortcut: '⌘F',
        category: '편집',
      ),
      const AppCommand(
        id: 'replace',
        label: '바꾸기',
        description: '텍스트를 찾아 바꿉니다',
        icon: Icons.find_replace,
        shortcut: '⌘H',
        category: '편집',
      ),
    ];

    return AppSection(
      title: 'AppCommandPalette - 커맨드 팔레트',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⌘K 스타일의 빠른 명령 검색',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          ElevatedButton.icon(
            onPressed: () async {
              final command = await showAppCommandPalette(
                context: context,
                commands: commands,
                placeholder: '명령어를 검색하세요...',
              );
              if (command != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('선택된 명령: ${command.label}')),
                );
              }
            },
            icon: const Icon(Icons.terminal),
            label: const Text('커맨드 팔레트 열기 (⌘K)'),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Helper Widget
  // ========================================================
  Widget _buildLabeledWidget(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        SizedBox(height: context.appSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.appColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
