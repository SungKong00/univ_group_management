import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/bottom_sheet_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppBottomSheetType;

/// 바텀시트 컴포넌트
///
/// **용도**: 모바일 액션 메뉴, 상세 정보, 폼 입력
/// **접근성**: 스크린 리더 지원, 드래그 제스처
///
/// ```dart
/// // 모달 바텀시트
/// showAppBottomSheet(
///   context: context,
///   child: YourContent(),
/// );
///
/// // 지속 바텀시트 (Scaffold 내부)
/// AppBottomSheet(
///   type: AppBottomSheetType.persistent,
///   child: YourContent(),
/// );
/// ```
class AppBottomSheet extends StatefulWidget {
  /// 바텀시트 콘텐츠
  final Widget child;

  /// 바텀시트 타입
  final AppBottomSheetType type;

  /// 초기 높이 비율 (0.0 ~ 1.0)
  final double? initialHeightFactor;

  /// 최소 높이
  final double? minHeight;

  /// 최대 높이
  final double? maxHeight;

  /// 드래그 가능 여부
  final bool isDraggable;

  /// 드래그 핸들 표시 여부
  final bool showDragHandle;

  /// 외부 탭으로 닫기 가능 여부
  final bool isDismissible;

  /// 닫힘 콜백
  final VoidCallback? onClose;

  /// 헤더 위젯
  final Widget? header;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.type = AppBottomSheetType.modal,
    this.initialHeightFactor,
    this.minHeight,
    this.maxHeight,
    this.isDraggable = true,
    this.showDragHandle = true,
    this.isDismissible = true,
    this.onClose,
    this.header,
  });

  @override
  State<AppBottomSheet> createState() => _AppBottomSheetState();
}

class _AppBottomSheetState extends State<AppBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = BottomSheetColors.from(colorExt, widget.type);

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.minHeight ?? 0,
        maxHeight: widget.maxHeight ?? MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BorderTokens.radiusXL),
        ),
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDragHandle) _buildDragHandle(colors, spacingExt),
          if (widget.header != null) widget.header!,
          Flexible(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildDragHandle(
    BottomSheetColors colors,
    AppSpacingExtension spacing,
  ) {
    return Semantics(
      label: '드래그하여 시트 조절',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: spacing.small),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.dragHandle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 모달 바텀시트 표시 함수
///
/// ```dart
/// showAppBottomSheet(
///   context: context,
///   child: Column(
///     children: [
///       ListTile(title: Text('옵션 1')),
///       ListTile(title: Text('옵션 2')),
///     ],
///   ),
/// );
/// ```
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  AppBottomSheetType type = AppBottomSheetType.modal,
  double? initialHeightFactor,
  double? minHeight,
  double? maxHeight,
  bool isDraggable = true,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Widget? header,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  Color? backgroundColor,
}) {
  final colorExt = context.appColors;
  final colors = BottomSheetColors.from(colorExt, type);

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag && isDraggable,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: type == AppBottomSheetType.modal
        ? colors.overlay
        : Colors.transparent,
    transitionAnimationController: AnimationController(
      duration: AnimationTokens.durationSmooth,
      vsync: Navigator.of(context),
    ),
    builder: (context) => AppBottomSheet(
      type: type,
      initialHeightFactor: initialHeightFactor,
      minHeight: minHeight,
      maxHeight: maxHeight,
      isDraggable: isDraggable,
      showDragHandle: showDragHandle,
      isDismissible: isDismissible,
      header: header,
      child: child,
    ),
  );
}

/// 드래그 가능한 바텀시트 (DraggableScrollableSheet 래퍼)
///
/// 스크롤과 드래그를 동시에 지원하는 바텀시트입니다.
///
/// ```dart
/// showAppDraggableBottomSheet(
///   context: context,
///   builder: (context, scrollController) => ListView.builder(
///     controller: scrollController,
///     itemCount: 50,
///     itemBuilder: (context, index) => ListTile(title: Text('아이템 $index')),
///   ),
/// );
/// ```
Future<T?> showAppDraggableBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext, ScrollController) builder,
  double initialChildSize = 0.5,
  double minChildSize = 0.25,
  double maxChildSize = 0.9,
  bool isDismissible = true,
  bool showDragHandle = true,
  Widget? header,
  bool snap = false,
  List<double>? snapSizes,
}) {
  final colorExt = context.appColors;
  final spacingExt = context.appSpacing;
  final colors = BottomSheetColors.from(colorExt, AppBottomSheetType.modal);

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: colors.overlay,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: snap,
      snapSizes: snapSizes,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BorderTokens.radiusXL),
          ),
          border: Border(top: BorderSide(color: colors.border, width: 1)),
        ),
        child: Column(
          children: [
            if (showDragHandle)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: spacingExt.small),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.dragHandle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            if (header != null) header,
            Expanded(child: builder(context, scrollController)),
          ],
        ),
      ),
    ),
  );
}
