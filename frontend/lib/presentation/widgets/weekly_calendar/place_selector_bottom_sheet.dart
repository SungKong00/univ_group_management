import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../../core/models/place/place.dart';
import '../../../core/services/place_service.dart';
import '../../../core/theme/app_theme.dart';
import '../common/app_empty_state.dart';

class PlaceSelectorBottomSheet extends StatefulWidget {
  final Function(List<Place>) onPlacesSelected;

  const PlaceSelectorBottomSheet({super.key, required this.onPlacesSelected});

  @override
  State<PlaceSelectorBottomSheet> createState() =>
      _PlaceSelectorBottomSheetState();
}

class _PlaceSelectorBottomSheetState extends State<PlaceSelectorBottomSheet> {
  final PlaceService _placeService = PlaceService();
  List<Place> _places = [];
  final Set<int> _selectedPlaceIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final places = await _placeService.getAllPlaces();

      if (mounted) {
        setState(() {
          _places = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Group places by building
  Map<String, List<Place>> _groupPlacesByBuilding() {
    final grouped = <String, List<Place>>{};
    for (final place in _places) {
      if (!grouped.containsKey(place.building)) {
        grouped[place.building] = [];
      }
      grouped[place.building]!.add(place);
    }

    // Sort by building name
    final sortedKeys = grouped.keys.toList()..sort();
    return {
      for (final key in sortedKeys)
        key: grouped[key]!
          ..sort((a, b) => a.displayName.compareTo(b.displayName)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.6; // 화면 높이의 60%로 제한

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '장소 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 0),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    '장소를 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _loadPlaces,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _places.isEmpty
                  ? AppEmptyState.noPlaces()
                  : ListView.builder(
                      itemCount: _groupPlacesByBuilding().length,
                      itemBuilder: (context, index) {
                        final buildings = _groupPlacesByBuilding();
                        final buildingName = buildings.keys.elementAt(index);
                        final places = buildings[buildingName]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Building header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                '📍 $buildingName (${places.length})',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            // Place items
                            ...places.map((place) {
                              final isSelected = _selectedPlaceIds.contains(
                                place.id,
                              );
                              return CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md + 16,
                                ),
                                title: Text(place.displayName),
                                subtitle: place.capacity != null
                                    ? Text('${place.capacity}명')
                                    : null,
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value ?? false) {
                                      _selectedPlaceIds.add(place.id);
                                    } else {
                                      _selectedPlaceIds.remove(place.id);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),

          // Footer buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                ),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedPlaces = _places
                          .where((p) => _selectedPlaceIds.contains(p.id))
                          .toList();
                      developer.log(
                        '✅ PlaceSelectorBottomSheet: 확인 버튼 클릭 - ${selectedPlaces.length}개 장소 선택됨',
                        name: 'PlaceSelectorBottomSheet',
                      );
                      for (final place in selectedPlaces) {
                        developer.log(
                          '  - ${place.displayName}',
                          name: 'PlaceSelectorBottomSheet',
                        );
                      }
                      Navigator.pop(context, selectedPlaces);
                    },
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
