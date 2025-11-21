import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/tab_colors.dart';
import '../theme/responsive_tokens.dart';
import '../theme/animation_tokens.dart';
import 'app_tabs.dart';

/// Linear 스타일 Controlled Content Tabs
///
/// TabController를 부모로부터 받아 상태를 동기화하는 컴포넌트입니다.
/// Flutter 공식 권장 TabController 패턴을 따릅니다.
///
/// **주요 특징:**
/// - TabController 기반: 부모가 탭 상태를 관리
/// - TabBarView 연동: controller를 통한 자동 동기화
/// - 프로그래밍 제어: controller.animateTo()로 외부에서 탭 전환 가능
/// - Smooth animation: TweenAnimationBuilder로 스무스한 indicator 이동
///
/// **사용 예시:**
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage>
///     with SingleTickerProviderStateMixin {
///   late TabController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = TabController(length: 3, vsync: this);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ControlledAppTabs(
///           controller: _controller,
///           tabs: [
///             AppTabItem(label: 'All'),
///             AppTabItem(label: 'Active'),
///             AppTabItem(label: 'Done'),
///           ],
///         ),
///         Expanded(
///           child: TabBarView(
///             controller: _controller,
///             children: [...],
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
class ControlledAppTabs extends StatefulWidget {
  /// TabController (부모로부터 전달받음)
  final TabController controller;

  /// 탭 아이템 목록
  final List<AppTabItem> tabs;

  /// 탭 변경 시 추가 콜백 (선택 사항)
  final ValueChanged<int>? onTabChanged;

  /// Indicator 높이
  final double indicatorHeight;

  /// 애니메이션 Duration (기본: AnimationTokens.durationSmooth)
  final Duration animationDuration;

  /// 애니메이션 Curve (기본: AnimationTokens.curveSlide)
  final Curve animationCurve;

  const ControlledAppTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTabChanged,
    this.indicatorHeight = 2.0,
    this.animationDuration = AnimationTokens.durationSmooth,
    this.animationCurve = AnimationTokens.curveSlide,
  });

  @override
  State<ControlledAppTabs> createState() => _ControlledAppTabsState();
}

class _ControlledAppTabsState extends State<ControlledAppTabs> {
  final List<GlobalKey> _tabKeys = [];
  Rect _indicatorRect = Rect.zero;

  @override
  void initState() {
    super.initState();

    // 1. TabKey 초기화
    _tabKeys.addAll(List.generate(widget.tabs.length, (_) => GlobalKey()));

    // 2. Controller 변경 감지
    widget.controller.addListener(_onControllerChanged);

    // 3. 초기 indicator 위치 설정 (첫 프레임 이후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorRect(widget.controller.index);
    });
  }

  @override
  void didUpdateWidget(covariant ControlledAppTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller 교체 감지
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);

      // 새 controller의 indicator 위치 업데이트
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateIndicatorRect(widget.controller.index);
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Controller의 index 변경 감지
  void _onControllerChanged() {
    _updateIndicatorRect(widget.controller.index);
    widget.onTabChanged?.call(widget.controller.index);
  }

  /// Indicator 위치 계산 및 업데이트
  void _updateIndicatorRect(int index) {
    if (index < 0 || index >= _tabKeys.length) return;

    final RenderBox? renderBox =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final parentRenderBox = context.findRenderObject() as RenderBox?;
    if (parentRenderBox == null) return;

    final parentPosition = parentRenderBox.localToGlobal(Offset.zero);
    final left = position.dx - parentPosition.dx;
    final width = renderBox.size.width;

    setState(() {
      _indicatorRect = Rect.fromLTWH(left, 0, width, widget.indicatorHeight);
    });
  }

  /// 탭 버튼 클릭 핸들러
  void _selectTab(int index) {
    if (widget.controller.index == index) return;
    widget.controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final tabColors = TabColors.standard(colorExt);

    return SizedBox(
      height: 50 + widget.indicatorHeight,
      child: Stack(
        children: [
          // 탭 버튼들
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.tabs.length; i++)
                _TabButton(
                  key: _tabKeys[i],
                  label: widget.tabs[i].label,
                  isActive: widget.controller.index == i,
                  onTap: () => _selectTab(i),
                ),
            ],
          ),
          // 슬라이딩 Indicator (TweenAnimationBuilder 사용)
          Positioned(
            bottom: 0,
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(begin: _indicatorRect, end: _indicatorRect),
              duration: widget.animationDuration,
              curve: widget.animationCurve,
              builder: (context, Rect? rect, child) {
                if (rect == null || rect == Rect.zero) {
                  return const SizedBox.shrink();
                }
                return Transform.translate(
                  offset: Offset(rect.left, 0),
                  child: Container(
                    width: rect.width,
                    height: rect.height,
                    decoration: BoxDecoration(
                      color: tabColors.indicator,
                      borderRadius: BorderRadius.circular(rect.height / 2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭 버튼 위젯 (AppTabs에서 복사)
class _TabButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final tabColors = TabColors.standard(colorExt);
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;

    final textColor = widget.isActive
        ? tabColors.textActive
        : (_isHovered ? colorExt.textSecondary : tabColors.text);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveTokens.cardGap(width),
            vertical: ResponsiveTokens.cardGap(width) * 0.75,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AnimationTokens.durationQuick,
            style: textTheme.bodyLarge!.copyWith(
              color: textColor,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
