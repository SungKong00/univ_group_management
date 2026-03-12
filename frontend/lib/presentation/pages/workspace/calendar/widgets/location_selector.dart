import 'package:flutter/material.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import 'place_picker_dialog.dart';

/// Enum representing the three location input modes
enum LocationMode {
  none('장소 없음'),
  text('직접 입력'),
  place('장소 선택');

  const LocationMode(this.label);
  final String label;
}

/// Widget for selecting location in three modes:
/// - Mode A (none): No location
/// - Mode B (text): Manual text input
/// - Mode C (place): Select from available places
class LocationSelector extends StatefulWidget {
  const LocationSelector({
    super.key,
    required this.groupId,
    this.initialLocationText,
    this.initialPlace,
    required this.onLocationChanged,
    required this.startDateTime,
    required this.endDateTime,
  });

  final int groupId;
  final String? initialLocationText;
  final Place? initialPlace;
  final void Function(String? locationText, Place? place) onLocationChanged;
  final DateTime startDateTime;
  final DateTime endDateTime;

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late LocationMode _mode;
  late TextEditingController _textController;
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // Initialize mode based on initial values
    if (widget.initialPlace != null) {
      _mode = LocationMode.place;
      _selectedPlace = widget.initialPlace;
    } else if (widget.initialLocationText != null &&
        widget.initialLocationText!.isNotEmpty) {
      _mode = LocationMode.text;
      _textController.text = widget.initialLocationText!;
    } else {
      _mode = LocationMode.none;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleModeChanged(LocationMode newMode) {
    setState(() {
      _mode = newMode;

      // Reset values when mode changes
      if (_mode == LocationMode.none) {
        _textController.clear();
        _selectedPlace = null;
        widget.onLocationChanged(null, null);
      } else if (_mode == LocationMode.text) {
        _selectedPlace = null;
        widget.onLocationChanged(
          _textController.text.trim().isEmpty
              ? null
              : _textController.text.trim(),
          null,
        );
      } else if (_mode == LocationMode.place) {
        _textController.clear();
        widget.onLocationChanged(null, _selectedPlace);
      }
    });
  }

  void _handleTextChanged() {
    final text = _textController.text.trim();
    widget.onLocationChanged(text.isEmpty ? null : text, null);
  }

  void _handlePlaceSelected(Place? place) {
    setState(() {
      _selectedPlace = place;
      widget.onLocationChanged(null, place);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('장소', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<LocationMode>(
          segments: LocationMode.values.map((mode) {
            return ButtonSegment<LocationMode>(
              value: mode,
              label: Text(mode.label),
              icon: Icon(_getModeIcon(mode), size: 16),
            );
          }).toList(),
          selected: {_mode},
          onSelectionChanged: (Set<LocationMode> newSelection) {
            _handleModeChanged(newSelection.first);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSize(
          duration: AppMotion.standard,
          curve: AppMotion.easing,
          child: _buildModeContent(),
        ),
      ],
    );
  }

  Widget _buildModeContent() {
    switch (_mode) {
      case LocationMode.none:
        return _buildNoneModeContent();
      case LocationMode.text:
        return _buildTextModeContent();
      case LocationMode.place:
        return _buildPlaceModeContent();
    }
  }

  Widget _buildNoneModeContent() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          Icon(Icons.block, size: 16, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '장소가 지정되지 않습니다',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }

  Widget _buildTextModeContent() {
    return TextFormField(
      controller: _textController,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: '장소 직접 입력',
        hintText: '예: 중앙도서관 4층',
        helperText: '장소 이름을 자유롭게 입력하세요',
      ),
      onChanged: (_) => _handleTextChanged(),
    );
  }

  Widget _buildPlaceModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedPlace != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.brand, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.place, size: 20, color: AppColors.brand),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlace!.displayName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedPlace!.fullLocation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => _handlePlaceSelected(null),
                  tooltip: '선택 해제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: AppColors.neutral300,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.neutral600,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '장소를 선택해주세요',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => _showPlacePicker(),
          icon: const Icon(Icons.search, size: 16),
          label: Text(_selectedPlace != null ? '다른 장소 선택' : '장소 선택'),
        ),
      ],
    );
  }

  Future<void> _showPlacePicker() async {
    final selectedPlace = await showPlacePickerDialog(
      context: context,
      groupId: widget.groupId,
      startTime: widget.startDateTime,
      endTime: widget.endDateTime,
    );

    if (selectedPlace != null) {
      _handlePlaceSelected(selectedPlace);
    }
  }

  IconData _getModeIcon(LocationMode mode) {
    switch (mode) {
      case LocationMode.none:
        return Icons.block;
      case LocationMode.text:
        return Icons.edit;
      case LocationMode.place:
        return Icons.place;
    }
  }
}
