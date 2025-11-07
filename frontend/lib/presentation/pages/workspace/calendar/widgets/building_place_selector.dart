import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';

/// Building and place selector widget
/// Allows users to select buildings and places, displaying selected places as chips
class BuildingPlaceSelector extends ConsumerStatefulWidget {
  const BuildingPlaceSelector({super.key});

  @override
  ConsumerState<BuildingPlaceSelector> createState() =>
      _BuildingPlaceSelectorState();
}

class _BuildingPlaceSelectorState
    extends ConsumerState<BuildingPlaceSelector> {
  String? _selectedBuilding;
  int? _selectedPlaceId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final buildings = state.buildings.toList()..sort();
    final selectedPlaces = state.selectedPlaces;

    // Get places for selected building
    final placesForBuilding = _selectedBuilding != null
        ? state.getPlacesForBuilding(_selectedBuilding!)
        : <Place>[];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdowns and Add button
          Row(
            children: [
              // Building dropdown
              Expanded(
                flex: 2,
                child: _buildBuildingDropdown(buildings),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Place dropdown
              Expanded(
                flex: 3,
                child: _buildPlaceDropdown(placesForBuilding),
              ),
              const SizedBox(width: AppSpacing.xs),

              // Add button
              ElevatedButton.icon(
                onPressed: _canAddPlace() ? _handleAddPlace : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('추가'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: const Size(80, 44),
                ),
              ),
            ],
          ),

          // Selected places chips
          if (selectedPlaces.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: selectedPlaces.map((place) {
                final color = state.getColorForPlace(place.id);
                return _buildPlaceChip(place, color);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBuildingDropdown(List<String> buildings) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBuilding,
      decoration: InputDecoration(
        labelText: '건물',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      items: buildings.isEmpty
          ? []
          : buildings.map((building) {
              return DropdownMenuItem<String>(
                value: building,
                child: Text(
                  building,
                  style: AppTheme.bodyMedium,
                ),
              );
            }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedBuilding = value;
          _selectedPlaceId = null; // Reset place selection
        });
      },
      hint: Text(
        buildings.isEmpty ? '장소 없음' : '건물 선택',
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, size: 20),
    );
  }

  Widget _buildPlaceDropdown(List<Place> places) {
    final isEnabled = _selectedBuilding != null && places.isNotEmpty;

    return DropdownButtonFormField<int>(
      initialValue: _selectedPlaceId,
      decoration: InputDecoration(
        labelText: '장소',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      items: !isEnabled
          ? []
          : places.map((place) {
              return DropdownMenuItem<int>(
                value: place.id,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.displayName,
                        style: AppTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (place.capacity != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${place.capacity}명)',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
      onChanged: isEnabled
          ? (value) {
              setState(() {
                _selectedPlaceId = value;
              });
            }
          : null,
      hint: Text(
        !isEnabled
            ? (_selectedBuilding == null ? '건물을 먼저 선택하세요' : '장소 없음')
            : '장소 선택',
        style: AppTheme.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
      ),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, size: 20),
    );
  }

  Widget _buildPlaceChip(Place place, Color color) {
    return Chip(
      label: Text(
        place.displayName,
        style: AppTheme.bodySmall.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      deleteIconColor: Colors.white,
      onDeleted: () {
        ref.read(placeCalendarProvider.notifier).deselectPlace(place.id);
      },
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: 2,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  bool _canAddPlace() {
    if (_selectedPlaceId == null) return false;

    // Check if the place is already selected
    final state = ref.read(placeCalendarProvider);
    return !state.selectedPlaceIds.contains(_selectedPlaceId);
  }

  void _handleAddPlace() {
    if (_selectedPlaceId == null) return;

    ref.read(placeCalendarProvider.notifier).selectPlace(_selectedPlaceId!);

    // Reset selections
    setState(() {
      _selectedBuilding = null;
      _selectedPlaceId = null;
    });
  }
}
