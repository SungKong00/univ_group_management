import 'package:flutter/material.dart';

/// 오른쪽에서 슬라이드되는 패널 위젯
///
/// 디자인 시스템 표준 애니메이션 적용:
/// - Duration: 160ms
/// - Easing: easeOutCubic
/// - Backdrop: 반투명 검정 오버레이 (선택적)
///
/// Usage:
/// ```dart
/// SlidePanel(
///   isVisible: state.showPanel,
///   onDismiss: () => hidePanel(),
///   showBackdrop: true,
///   child: YourContentWidget(),
/// )
/// ```
class SlidePanel extends StatefulWidget {
  /// 패널 표시 여부
  final bool isVisible;

  /// 패널 내용 위젯
  final Widget child;

  /// 패널 닫기 콜백 (백드롭 클릭 또는 뒤로가기 시 호출)
  final VoidCallback onDismiss;

  /// 백드롭 표시 여부 (기본값: true)
  final bool showBackdrop;

  /// 패널 너비 (기본값: null = child의 고유 너비 사용)
  final double? width;

  /// 애니메이션 지속 시간 (기본값: 160ms)
  final Duration duration;

  /// 애니메이션 커브 (기본값: easeOutCubic)
  final Curve curve;

  const SlidePanel({
    super.key,
    required this.isVisible,
    required this.child,
    required this.onDismiss,
    this.showBackdrop = true,
    this.width,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlidePanel> createState() => _SlidePanelState();
}

class _SlidePanelState extends State<SlidePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backdropAnimation;
  bool _isAnimatingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // 초기 상태가 visible이면 애니메이션 시작
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
      });
    }
  }

  void _initializeAnimations() {
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // 오른쪽 밖에서 시작
      end: Offset.zero, // 제자리로 이동
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _backdropAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // 애니메이션 완료 리스너
    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _isAnimatingOut) {
      setState(() {
        _isAnimatingOut = false;
      });
      widget.onDismiss();
    }
  }

  @override
  void didUpdateWidget(SlidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // isVisible 상태 변경 감지
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        setState(() {
          _isAnimatingOut = true;
        });
        _controller.reverse();
      }
    }

    // 애니메이션 설정 변경 감지
    if (widget.duration != oldWidget.duration ||
        widget.curve != oldWidget.curve) {
      _controller.dispose();
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 패널이 보이지 않고 애니메이션도 진행 중이 아니면 렌더링하지 않음
    if (!widget.isVisible && !_isAnimatingOut) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 백드롭 오버레이
        if (widget.showBackdrop)
          GestureDetector(
            onTap: () {
              if (!_isAnimatingOut) {
                setState(() {
                  _isAnimatingOut = true;
                });
                _controller.reverse();
              }
            },
            child: FadeTransition(
              opacity: _backdropAnimation,
              child: Container(color: Colors.black54),
            ),
          ),

        // 슬라이드 패널
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.width != null
                ? SizedBox(width: widget.width, child: widget.child)
                : widget.child,
          ),
        ),
      ],
    );
  }
}
