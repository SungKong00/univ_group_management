import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';

/// Compact version of building and place selector for header integration
/// Displays dropdowns without labels, uses icons for visual identification
class CompactBuildingPlaceSelector extends ConsumerStatefulWidget {
  const CompactBuildingPlaceSelector({super.key});

  @override
  ConsumerState<CompactBuildingPlaceSelector> createState() =>
      _CompactBuildingPlaceSelectorState();
}

class _CompactBuildingPlaceSelectorState
    extends ConsumerState<CompactBuildingPlaceSelector> {
  String? _selectedBuilding;
  int? _selectedPlaceId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final buildings = state.buildings.toList()..sort();

    // Get places for selected building
    final placesForBuilding = _selectedBuilding != null
        ? state.getPlacesForBuilding(_selectedBuilding!)
        : <Place>[];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Building dropdown (compact)
        _buildBuildingDropdown(buildings),
        const SizedBox(width: AppSpacing.xs),

        // Place dropdown (compact)
        _buildPlaceDropdown(placesForBuilding),
      ],
    );
  }

  Widget _buildBuildingDropdown(List<String> buildings) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 120),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedBuilding,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.business, size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          isDense: true,
        ),
        items: buildings.isEmpty
            ? []
            : buildings.map((building) {
                return DropdownMenuItem<String>(
                  value: building,
                  child: Text(
                    building,
                    style: AppTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedBuilding = value;
            _selectedPlaceId = null; // Reset place selection
          });

          // Auto-select place if building is chosen
          if (value != null) {
            _autoSelectPlace();
          }
        },
        hint: Text(
          buildings.isEmpty ? '없음' : '건물',
          style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
        ),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18),
      ),
    );
  }

  Widget _buildPlaceDropdown(List<Place> places) {
    final isEnabled = _selectedBuilding != null && places.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedPlaceId,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.place, size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          isDense: true,
        ),
        items: !isEnabled
            ? []
            : places.map((place) {
                return DropdownMenuItem<int>(
                  value: place.id,
                  child: Text(
                    place.displayName,
                    style: AppTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
        onChanged: isEnabled
            ? (value) {
                setState(() {
                  _selectedPlaceId = value;
                });

                // Auto-add place when selected
                if (value != null) {
                  _handleAddPlace();
                }
              }
            : null,
        hint: Text(
          !isEnabled ? (_selectedBuilding == null ? '건물 먼저' : '없음') : '장소',
          style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
        ),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, size: 18),
      ),
    );
  }

  void _autoSelectPlace() {
    // If only one place exists for the building, auto-select it
    if (_selectedBuilding != null) {
      final state = ref.read(placeCalendarProvider);
      final places = state.getPlacesForBuilding(_selectedBuilding!);
      if (places.length == 1) {
        setState(() {
          _selectedPlaceId = places.first.id;
        });
      }
    }
  }

  void _handleAddPlace() {
    if (_selectedPlaceId == null) return;

    final state = ref.read(placeCalendarProvider);

    // Check if the place is already selected
    if (!state.selectedPlaceIds.contains(_selectedPlaceId)) {
      ref.read(placeCalendarProvider.notifier).selectPlace(_selectedPlaceId!);
    }

    // Reset selections for next addition
    setState(() {
      _selectedBuilding = null;
      _selectedPlaceId = null;
    });
  }
}
