import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/stepper_colors.dart';
import '../theme/enums.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppStepperOrientation, AppStepStatus;

/// 스텝 데이터 모델
class AppStep {
  /// 스텝 제목
  final String title;

  /// 스텝 설명 (선택)
  final String? description;

  /// 스텝 아이콘 (선택, 기본은 숫자/체크)
  final IconData? icon;

  /// 스텝 상태
  final AppStepStatus status;

  /// 스텝 콘텐츠 (선택)
  final Widget? content;

  const AppStep({
    required this.title,
    this.description,
    this.icon,
    this.status = AppStepStatus.pending,
    this.content,
  });
}

/// 스테퍼 컴포넌트
///
/// **용도**: 단계별 진행 표시, 폼 위자드, 프로세스 안내
/// **접근성**: 스크린 리더 지원
///
/// ```dart
/// // 가로 스테퍼
/// AppStepper(
///   steps: [
///     AppStep(title: '정보 입력', status: AppStepStatus.completed),
///     AppStep(title: '확인', status: AppStepStatus.active),
///     AppStep(title: '완료', status: AppStepStatus.pending),
///   ],
/// )
///
/// // 세로 스테퍼
/// AppStepper.vertical(
///   steps: [...],
///   currentStep: 1,
/// )
/// ```
class AppStepper extends StatelessWidget {
  /// 스텝 목록
  final List<AppStep> steps;

  /// 스테퍼 방향
  final AppStepperOrientation orientation;

  /// 현재 스텝 인덱스 (0부터 시작)
  final int currentStep;

  /// 스텝 클릭 콜백
  final ValueChanged<int>? onStepTapped;

  /// 스텝 원 크기
  final double stepSize;

  /// 연결선 두께
  final double connectorThickness;

  const AppStepper({
    super.key,
    required this.steps,
    this.orientation = AppStepperOrientation.horizontal,
    this.currentStep = 0,
    this.onStepTapped,
    this.stepSize = 32,
    this.connectorThickness = 2,
  });

  /// 세로 스테퍼 팩토리
  factory AppStepper.vertical({
    Key? key,
    required List<AppStep> steps,
    int currentStep = 0,
    ValueChanged<int>? onStepTapped,
    double stepSize = 32,
    double connectorThickness = 2,
  }) {
    return AppStepper(
      key: key,
      steps: steps,
      orientation: AppStepperOrientation.vertical,
      currentStep: currentStep,
      onStepTapped: onStepTapped,
      stepSize: stepSize,
      connectorThickness: connectorThickness,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    if (orientation == AppStepperOrientation.horizontal) {
      return _buildHorizontal(context, colorExt, spacingExt);
    } else {
      return _buildVertical(context, colorExt, spacingExt);
    }
  }

  Widget _buildHorizontal(
    BuildContext context,
    AppColorExtension colorExt,
    AppSpacingExtension spacingExt,
  ) {
    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepIndicator(
            step: steps[i],
            index: i,
            size: stepSize,
            colorExt: colorExt,
            onTap: onStepTapped != null ? () => onStepTapped!(i) : null,
          ),
          if (i < steps.length - 1)
            Expanded(
              child: _Connector(
                thickness: connectorThickness,
                color: _getConnectorColor(colorExt, i),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildVertical(
    BuildContext context,
    AppColorExtension colorExt,
    AppSpacingExtension spacingExt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 스텝 인디케이터와 연결선
                Column(
                  children: [
                    _StepIndicator(
                      step: steps[i],
                      index: i,
                      size: stepSize,
                      colorExt: colorExt,
                      onTap: onStepTapped != null
                          ? () => onStepTapped!(i)
                          : null,
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: connectorThickness,
                          color: _getConnectorColor(colorExt, i),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: spacingExt.medium),
                // 제목, 설명, 콘텐츠
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: spacingExt.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            color: StepperColors.from(
                              colorExt,
                              steps[i].status,
                            ).titleText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (steps[i].description != null) ...[
                          SizedBox(height: spacingExt.xs),
                          Text(
                            steps[i].description!,
                            style: TextStyle(
                              color: StepperColors.from(
                                colorExt,
                                steps[i].status,
                              ).descriptionText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (steps[i].content != null) ...[
                          SizedBox(height: spacingExt.small),
                          steps[i].content!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getConnectorColor(AppColorExtension colorExt, int index) {
    final currentStatus = steps[index].status;

    if (currentStatus == AppStepStatus.completed) {
      return StepperColors.from(colorExt, AppStepStatus.completed).connector;
    }
    return StepperColors.from(colorExt, AppStepStatus.pending).connector;
  }
}

/// 스텝 인디케이터 위젯
class _StepIndicator extends StatefulWidget {
  final AppStep step;
  final int index;
  final double size;
  final AppColorExtension colorExt;
  final VoidCallback? onTap;

  const _StepIndicator({
    required this.step,
    required this.index,
    required this.size,
    required this.colorExt,
    this.onTap,
  });

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = StepperColors.from(widget.colorExt, widget.step.status);

    return Semantics(
      label: '${widget.step.title} - ${_getStatusLabel(widget.step.status)}',
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.stepBackground,
              boxShadow: _isHovered && widget.onTap != null
                  ? [
                      BoxShadow(
                        color: colors.stepBackground.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: _buildContent(colors)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(StepperColors colors) {
    if (widget.step.icon != null) {
      return Icon(
        widget.step.icon,
        size: widget.size * 0.5,
        color: colors.stepForeground,
      );
    }

    if (widget.step.status == AppStepStatus.completed) {
      return Icon(
        Icons.check,
        size: widget.size * 0.5,
        color: colors.stepForeground,
      );
    }

    if (widget.step.status == AppStepStatus.error) {
      return Icon(
        Icons.close,
        size: widget.size * 0.5,
        color: colors.stepForeground,
      );
    }

    return Text(
      '${widget.index + 1}',
      style: TextStyle(
        color: colors.stepForeground,
        fontSize: widget.size * 0.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _getStatusLabel(AppStepStatus status) {
    return switch (status) {
      AppStepStatus.completed => '완료',
      AppStepStatus.active => '진행 중',
      AppStepStatus.pending => '대기 중',
      AppStepStatus.error => '에러',
    };
  }
}

/// 연결선 위젯
class _Connector extends StatelessWidget {
  final double thickness;
  final Color color;

  const _Connector({required this.thickness, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: thickness, color: color);
  }
}

/// 간단한 진행 스테퍼 (숫자만 표시)
///
/// ```dart
/// AppSimpleStepper(
///   currentStep: 2,
///   totalSteps: 5,
/// )
/// ```
class AppSimpleStepper extends StatelessWidget {
  /// 현재 스텝 (1부터 시작)
  final int currentStep;

  /// 총 스텝 수
  final int totalSteps;

  /// 스텝 크기
  final double stepSize;

  /// 연결선 두께
  final double connectorThickness;

  const AppSimpleStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepSize = 28,
    this.connectorThickness = 2,
  });

  @override
  Widget build(BuildContext context) {
    final steps = List.generate(totalSteps, (index) {
      final stepNumber = index + 1;
      return AppStep(
        title: '$stepNumber',
        status: stepNumber < currentStep
            ? AppStepStatus.completed
            : stepNumber == currentStep
            ? AppStepStatus.active
            : AppStepStatus.pending,
      );
    });

    return AppStepper(
      steps: steps,
      stepSize: stepSize,
      connectorThickness: connectorThickness,
    );
  }
}
