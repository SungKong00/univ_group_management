import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/dialog_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';
import '../theme/responsive_tokens.dart';
import 'app_button.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppDialogType;

/// 모달 다이얼로그 컴포넌트
///
/// **용도**: 확인, 경고, 입력, 커스텀 콘텐츠 표시
/// **접근성**: ESC로 닫기, 포커스 트랩
///
/// ```dart
/// // 확인 다이얼로그
/// final result = await showAppDialog(
///   context,
///   title: '삭제 확인',
///   description: '정말 삭제하시겠습니까?',
///   type: AppDialogType.confirm,
///   isDestructive: true,
/// );
///
/// if (result == true) {
///   // 삭제 처리
/// }
///
/// // 알림 다이얼로그
/// await showAppDialog(
///   context,
///   title: '알림',
///   description: '저장되었습니다.',
///   type: AppDialogType.alert,
/// );
/// ```
class AppDialog extends StatelessWidget {
  /// 다이얼로그 제목
  final String title;

  /// 다이얼로그 설명 (선택)
  final String? description;

  /// 커스텀 콘텐츠 (선택)
  final Widget? content;

  /// 다이얼로그 타입
  final AppDialogType type;

  /// 확인 버튼 라벨
  final String confirmLabel;

  /// 취소 버튼 라벨
  final String cancelLabel;

  /// 확인 콜백
  final VoidCallback? onConfirm;

  /// 취소 콜백
  final VoidCallback? onCancel;

  /// 배경 탭으로 닫기 허용
  final bool isDismissible;

  /// 삭제 확인 등 위험 액션 여부
  final bool isDestructive;

  /// 닫기 버튼 표시 여부
  final bool showCloseButton;

  /// Prompt 타입용 텍스트 컨트롤러
  final TextEditingController? textController;

  /// Prompt 타입용 힌트 텍스트
  final String? hintText;

  const AppDialog({
    super.key,
    required this.title,
    this.description,
    this.content,
    this.type = AppDialogType.confirm,
    this.confirmLabel = '확인',
    this.cancelLabel = '취소',
    this.onConfirm,
    this.onCancel,
    this.isDismissible = true,
    this.isDestructive = false,
    this.showCloseButton = true,
    this.textController,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final colors = isDestructive
        ? DialogColors.destructive(colorExt)
        : DialogColors.standard(colorExt);

    final maxWidth = switch (ResponsiveTokens.getScreenSize(width)) {
      ScreenSize.xs => width - spacingExt.xl,
      ScreenSize.sm => width - spacingExt.large,
      ScreenSize.md => 420.0,
      ScreenSize.lg => 480.0,
      ScreenSize.xl => 520.0,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(spacingExt.xl),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: BorderTokens.widthThin),
          borderRadius: BorderTokens.largeRadius(),
          boxShadow: [
            BoxShadow(
              color: colorExt.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(spacingExt.large),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.title,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Icon(
                        Icons.close,
                        size: ResponsiveTokens.iconSize(width),
                        color: colors.closeButton,
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: colors.divider),

            // Content
            Padding(
              padding: EdgeInsets.all(spacingExt.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (description != null)
                    Text(
                      description!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.description,
                      ),
                    ),
                  if (description != null && content != null)
                    SizedBox(height: spacingExt.medium),
                  if (content != null) content!,
                  if (type == AppDialogType.prompt) ...[
                    if (description != null) SizedBox(height: spacingExt.medium),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: ResponsiveTokens.inputPaddingH(width),
                          vertical: ResponsiveTokens.inputPaddingV(width),
                        ),
                        hintText: hintText,
                        filled: true,
                        fillColor: colorExt.surfaceTertiary,
                        border: OutlineInputBorder(
                          borderRadius: BorderTokens.smallRadius(),
                          borderSide: BorderSide(color: colorExt.borderPrimary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderTokens.smallRadius(),
                          borderSide: BorderSide(color: colorExt.borderPrimary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderTokens.smallRadius(),
                          borderSide: BorderSide(
                            color: colorExt.borderFocus,
                            width: BorderTokens.widthFocus,
                          ),
                        ),
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorExt.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Divider
            Divider(height: 1, color: colors.divider),

            // Actions
            Padding(
              padding: EdgeInsets.all(spacingExt.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (type != AppDialogType.alert) ...[
                    AppButton(
                      text: cancelLabel,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.medium,
                      onPressed: () {
                        onCancel?.call();
                        Navigator.of(context).pop(false);
                      },
                    ),
                    SizedBox(width: spacingExt.small),
                  ],
                  AppButton(
                    text: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.primary
                        : AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: () {
                      onConfirm?.call();
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 전역 다이얼로그 표시 함수
///
/// ```dart
/// final result = await showAppDialog(
///   context,
///   title: '삭제 확인',
///   description: '이 항목을 삭제하시겠습니까?',
///   type: AppDialogType.confirm,
///   isDestructive: true,
/// );
/// ```
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  String? description,
  Widget? content,
  AppDialogType type = AppDialogType.confirm,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isDismissible = true,
  bool isDestructive = false,
  bool showCloseButton = true,
  TextEditingController? textController,
  String? hintText,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: context.appColors.overlayScrim,
    transitionDuration: AnimationTokens.durationSmooth,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AnimationTokens.curveSmooth,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: AnimationTokens.curveSmooth,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return AppDialog(
        title: title,
        description: description,
        content: content,
        type: type,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDismissible: isDismissible,
        isDestructive: isDestructive,
        showCloseButton: showCloseButton,
        textController: textController,
        hintText: hintText,
      );
    },
  );
}

/// Alert 다이얼로그 편의 함수
Future<void> showAppAlert(
  BuildContext context, {
  required String title,
  String? description,
  String confirmLabel = '확인',
}) {
  return showAppDialog(
    context,
    title: title,
    description: description,
    type: AppDialogType.alert,
    confirmLabel: confirmLabel,
    showCloseButton: false,
  );
}

/// Confirm 다이얼로그 편의 함수
Future<bool?> showAppConfirm(
  BuildContext context, {
  required String title,
  String? description,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool isDestructive = false,
}) {
  return showAppDialog(
    context,
    title: title,
    description: description,
    type: AppDialogType.confirm,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    isDestructive: isDestructive,
  );
}

/// Prompt 다이얼로그 편의 함수
Future<String?> showAppPrompt(
  BuildContext context, {
  required String title,
  String? description,
  String? hintText,
  String? initialValue,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
}) async {
  final controller = TextEditingController(text: initialValue);

  final result = await showAppDialog(
    context,
    title: title,
    description: description,
    type: AppDialogType.prompt,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    textController: controller,
    hintText: hintText,
  );

  if (result == true) {
    return controller.text;
  }
  return null;
}
