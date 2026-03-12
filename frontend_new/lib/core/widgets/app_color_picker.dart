import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/color_picker_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';
import '../theme/enums.dart';

// Export enum for convenience
export '../theme/enums.dart' show AppColorPickerMode;

/// 색상 선택기
///
/// **용도**: 테마 색상 선택, 라벨 색상 지정, 배경 색상 설정
/// **접근성**: 키보드 네비게이션, Semantics 지원
/// **반응형**: 화면 크기에 맞게 자동 조정
///
/// ```dart
/// // 기본 프리셋 팔레트
/// AppColorPicker(
///   value: _selectedColor,
///   onChanged: (color) => setState(() => _selectedColor = color),
/// )
///
/// // 커스텀 팔레트
/// AppColorPicker(
///   value: _labelColor,
///   onChanged: (color) => setState(() => _labelColor = color),
///   palette: [Colors.red, Colors.blue, Colors.green, Colors.yellow],
/// )
///
/// // HEX 입력 모드
/// AppColorPicker(
///   value: _themeColor,
///   onChanged: (color) => setState(() => _themeColor = color),
///   mode: AppColorPickerMode.hex,
///   label: '테마 색상',
/// )
///
/// // 미리보기 표시
/// AppColorPicker(
///   value: _brandColor,
///   onChanged: (color) => setState(() => _brandColor = color),
///   showPreview: true,
///   label: '브랜드 색상',
/// )
/// ```
class AppColorPicker extends StatefulWidget {
  /// 현재 선택된 색상
  final Color? value;

  /// 색상 변경 콜백
  final ValueChanged<Color>? onChanged;

  /// 색상 선택기 모드
  final AppColorPickerMode mode;

  /// 프리셋 팔레트 색상
  final List<Color>? palette;

  /// 라벨 텍스트
  final String? label;

  /// 미리보기 표시 여부
  final bool showPreview;

  /// 비활성화 상태
  final bool isDisabled;

  /// 셀 크기
  final double? cellSize;

  /// 셀 간격
  final double? cellSpacing;

  /// 한 줄당 셀 수
  final int? cellsPerRow;

  const AppColorPicker({
    super.key,
    this.value,
    this.onChanged,
    this.mode = AppColorPickerMode.palette,
    this.palette,
    this.label,
    this.showPreview = false,
    this.isDisabled = false,
    this.cellSize,
    this.cellSpacing,
    this.cellsPerRow,
  });

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  late TextEditingController _hexController;
  Color? _selectedColor;

  // 기본 팔레트 색상
  static const List<Color> _defaultPalette = [
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFFEAB308), // Yellow
    Color(0xFF84CC16), // Lime
    Color(0xFF22C55E), // Green
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF3B82F6), // Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFA855F7), // Purple
    Color(0xFFD946EF), // Fuchsia
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFF78716C), // Gray
    Color(0xFF1C1917), // Black
    Color(0xFFFFFFFF), // White
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.value;
    _hexController = TextEditingController(text: _colorToHex(_selectedColor));
  }

  @override
  void didUpdateWidget(AppColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedColor = widget.value;
      _hexController.text = _colorToHex(_selectedColor);
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color? color) {
    if (color == null) return '';
    // ARGB32로 변환 후 alpha 제외한 RGB만 추출
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length != 6) return null;
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  void _selectColor(Color color) {
    if (widget.isDisabled) return;
    setState(() => _selectedColor = color);
    _hexController.text = _colorToHex(color);
    widget.onChanged?.call(color);
  }

  void _onHexChanged(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      setState(() => _selectedColor = color);
      widget.onChanged?.call(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = ColorPickerColors.from(colorExt);

    final palette = widget.palette ?? _defaultPalette;
    final cellSize = widget.cellSize ?? ComponentSizeTokens.boxSmall;
    final cellSpacing = widget.cellSpacing ?? spacingExt.small;
    final cellsPerRow = widget.cellsPerRow ?? 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: widget.isDisabled ? colors.disabledText : colors.labelText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: spacingExt.small),
        ],

        // 미리보기
        if (widget.showPreview) ...[
          _buildPreview(colors, spacingExt),
          SizedBox(height: spacingExt.medium),
        ],

        // 팔레트
        _buildPalette(palette, colors, cellSize, cellSpacing, cellsPerRow),

        // HEX 입력
        if (widget.mode == AppColorPickerMode.hex) ...[
          SizedBox(height: spacingExt.medium),
          _buildHexInput(colors, spacingExt),
        ],
      ],
    );
  }

  Widget _buildPreview(
    ColorPickerColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Row(
      children: [
        AnimatedContainer(
          duration: AnimationTokens.durationQuick,
          width: ComponentSizeTokens.boxLarge,
          height: ComponentSizeTokens.boxLarge,
          decoration: BoxDecoration(
            color: _selectedColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
            border: Border.all(
              color: colors.previewBorder,
              width: BorderTokens.widthThin,
            ),
          ),
          child: _selectedColor == null
              ? Icon(
                  Icons.palette_outlined,
                  color: colors.disabledText,
                  size: ComponentSizeTokens.iconMedium,
                )
              : null,
        ),
        SizedBox(width: spacingExt.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '선택된 색상',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.disabledText),
              ),
              Text(
                _selectedColor != null ? _colorToHex(_selectedColor) : '없음',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.labelText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPalette(
    List<Color> palette,
    ColorPickerColors colors,
    double cellSize,
    double cellSpacing,
    int cellsPerRow,
  ) {
    return Wrap(
      spacing: cellSpacing,
      runSpacing: cellSpacing,
      children: palette.map((color) {
        final isSelected = _selectedColor == color;
        return _ColorCell(
          color: color,
          isSelected: isSelected,
          isDisabled: widget.isDisabled,
          size: cellSize,
          colors: colors,
          onTap: () => _selectColor(color),
        );
      }).toList(),
    );
  }

  Widget _buildHexInput(
    ColorPickerColors colors,
    AppSpacingExtension spacingExt,
  ) {
    return Row(
      children: [
        Text(
          'HEX',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.disabledText,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: spacingExt.small),
        Expanded(
          child: Container(
            height: ComponentSizeTokens.boxSmall,
            decoration: BoxDecoration(
              color: colors.hexInputBackground,
              borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
            ),
            child: TextField(
              controller: _hexController,
              enabled: !widget.isDisabled,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.hexInputText,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: _onHexChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// 개별 색상 셀 위젯
class _ColorCell extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final bool isDisabled;
  final double size;
  final ColorPickerColors colors;
  final VoidCallback onTap;

  const _ColorCell({
    required this.color,
    required this.isSelected,
    required this.isDisabled,
    required this.size,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_ColorCell> createState() => _ColorCellState();
}

class _ColorCellState extends State<_ColorCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 밝은 색상에는 어두운 체크, 어두운 색상에는 밝은 체크
    final luminance = widget.color.computeLuminance();
    final colorExt = context.appColors;
    final checkColor = luminance > 0.5
        ? colorExt.surfacePrimary
        : colorExt.textOnBrand;

    return Semantics(
      selected: widget.isSelected,
      enabled: !widget.isDisabled,
      label: '색상',
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(BorderTokens.radiusSmall),
              border: Border.all(
                color: widget.isSelected
                    ? widget.colors.borderSelected
                    : _isHovered
                    ? widget.colors.border
                    : Colors.transparent,
                width: widget.isSelected
                    ? BorderTokens.widthFocus
                    : BorderTokens.widthThin,
              ),
              boxShadow: _isHovered && !widget.isDisabled
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: widget.isSelected
                ? Icon(Icons.check, color: checkColor, size: widget.size * 0.5)
                : null,
          ),
        ),
      ),
    );
  }
}
