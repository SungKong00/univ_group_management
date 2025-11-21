import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_typography_extension.dart';
import '../theme/colors/labels_section_colors.dart';
import '../theme/responsive_tokens.dart';

// Export style for convenience
export '../theme/colors/labels_section_colors.dart' show LabelsSectionStyle;

/// 레이블 아이템 모델
class LabelItem {
  final String name;
  final Color? customColor;
  final Function()? onRemove;

  const LabelItem({required this.name, this.customColor, this.onRemove});
}

/// 레이블 섹션 (Labels Management)
///
/// **기능**:
/// - 레이블 표시 및 관리
/// - 레이블 추가/제거
/// - 색상 커스터마이징
/// - 반응형 레이아웃
///
/// **사용 예시**:
/// ```dart
/// LabelsSection(
///   style: LabelsSectionStyle.default_,
///   labels: [
///     LabelItem(name: 'bug', customColor: Colors.red),
///     LabelItem(name: 'enhancement', customColor: Colors.green),
///   ],
///   onAddLabel: () => showLabelPicker(),
/// )
/// ```
class LabelsSection extends StatefulWidget {
  /// 섹션 스타일
  final LabelsSectionStyle style;

  /// 레이블 리스트
  final List<LabelItem> labels;

  /// 레이블 추가 콜백
  final Function()? onAddLabel;

  /// 섹션 제목
  final String? sectionTitle;

  /// 읽기 전용 모드
  final bool isReadOnly;

  const LabelsSection({
    super.key,
    required this.style,
    required this.labels,
    this.onAddLabel,
    this.sectionTitle,
    this.isReadOnly = false,
  });

  @override
  State<LabelsSection> createState() => _LabelsSectionState();
}

class _LabelsSectionState extends State<LabelsSection> {
  late List<LabelItem> _labels;

  @override
  void initState() {
    super.initState();
    _labels = widget.labels;
  }

  @override
  void didUpdateWidget(covariant LabelsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels != widget.labels) {
      _labels = widget.labels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final typographyExt = context.appTypography;
    final width = MediaQuery.sizeOf(context).width;

    // ========================================================
    // Step 1: 스타일에 따른 색상 결정
    // ========================================================
    final labelsColors = switch (widget.style) {
      LabelsSectionStyle.default_ => LabelsSectionColors.default_(colorExt),
      LabelsSectionStyle.dark => LabelsSectionColors.dark(colorExt),
      LabelsSectionStyle.colorful => LabelsSectionColors.colorful(colorExt),
    };

    final itemSpacing = ResponsiveTokens.cardPadding(width);
    final borderRadius = ResponsiveTokens.componentBorderRadius(width);

    // ========================================================
    // Step 2: 레이블 아이템 빌드
    // ========================================================
    return Container(
      decoration: BoxDecoration(
        color: labelsColors.sectionBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: labelsColors.labelBorder, width: 1),
      ),
      padding: EdgeInsets.all(itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 섹션 제목
          if (widget.sectionTitle != null)
            Padding(
              padding: EdgeInsets.only(bottom: itemSpacing),
              child: Text(
                widget.sectionTitle!,
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorExt.textPrimary,
                    ) ??
                    TextStyle(color: colorExt.textPrimary),
              ),
            ),

          // 레이블들
          if (_labels.isNotEmpty)
            Wrap(
              spacing: itemSpacing / 2,
              runSpacing: itemSpacing / 2,
              children: _labels.map((label) {
                return Container(
                  decoration: BoxDecoration(
                    color: labelsColors.labelBg,
                    border: Border.all(
                      color: labelsColors.labelBorder,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius / 2),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: itemSpacing / 2,
                    vertical: itemSpacing / 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 레이블 색상 (옵션)
                      if (label.customColor != null)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: label.customColor,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.only(right: itemSpacing / 4),
                        ),

                      // 레이블 텍스트
                      Text(
                        label.name,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: labelsColors.labelText,
                            ) ??
                            TextStyle(color: labelsColors.labelText),
                      ),

                      // 제거 버튼
                      if (!widget.isReadOnly && label.onRemove != null)
                        Padding(
                          padding: EdgeInsets.only(left: itemSpacing / 4),
                          child: GestureDetector(
                            onTap: label.onRemove,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: labelsColors.removeIcon,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),

          // 추가 버튼
          if (!widget.isReadOnly && widget.onAddLabel != null) ...[
            SizedBox(height: itemSpacing),
            Container(
              decoration: BoxDecoration(
                color: labelsColors.addButtonBg,
                border: Border.all(color: labelsColors.labelBorder, width: 1),
                borderRadius: BorderRadius.circular(borderRadius / 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onAddLabel,
                  borderRadius: BorderRadius.circular(borderRadius / 2),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: itemSpacing / 2,
                      vertical: itemSpacing / 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 14,
                          color: labelsColors.addButtonText,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Add label',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: labelsColors.addButtonText,
                              ) ??
                              TextStyle(color: labelsColors.addButtonText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
