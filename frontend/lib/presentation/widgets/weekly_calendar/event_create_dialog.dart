import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/place/place.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';

/// Result data returned from EventCreateDialog
class EventCreateResult {
  final String title;
  final LocationSelection locationSelection;

  const EventCreateResult({
    required this.title,
    required this.locationSelection,
  });
}

/// Location selection type and value
class LocationSelection {
  final LocationType type;
  final String? customLocation; // For custom text input
  final int? selectedPlaceId; // For place selection

  const LocationSelection({
    required this.type,
    this.customLocation,
    this.selectedPlaceId,
  });

  const LocationSelection.none() : type = LocationType.none, customLocation = null, selectedPlaceId = null;

  const LocationSelection.custom(String location)
      : type = LocationType.custom,
        customLocation = location,
        selectedPlaceId = null;

  const LocationSelection.place(int placeId)
      : type = LocationType.place,
        customLocation = null,
        selectedPlaceId = placeId;
}

enum LocationType { none, custom, place }

/// Dialog for creating a new event with place selection support
///
/// Features:
/// - Title input
/// - Time display (read-only)
/// - Location selection:
///   - Radio 1: None (no location)
///   - Radio 2: Custom text input
///   - Radio 3: Place dropdown (filtered by availability)
///
/// Design Pattern:
/// - RadioListTile for clear selection options
/// - Conditional rendering based on selected radio
/// - Dropdown with disabled styling for unavailable places
class EventCreateDialog extends StatefulWidget {
  /// Start time of the event
  final DateTime startTime;

  /// End time of the event
  final DateTime endTime;

  /// Available places from filter selection
  final List<Place> availablePlaces;

  /// Map of place ID to disabled slots for that specific place
  /// Used to check if a place is available for the selected time range
  final Map<int, Set<DateTime>> disabledSlotsByPlace;

  /// Pre-selected place ID (auto-fill from filter selection)
  final int? preSelectedPlaceId;

  const EventCreateDialog({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.availablePlaces,
    required this.disabledSlotsByPlace,
    this.preSelectedPlaceId,
  });

  @override
  State<EventCreateDialog> createState() => _EventCreateDialogState();
}

class _EventCreateDialogState extends State<EventCreateDialog> {
  final _titleController = TextEditingController();
  final _customLocationController = TextEditingController();

  late LocationType _selectedLocationType;
  int? _selectedPlaceId;

  @override
  void initState() {
    super.initState();

    // Auto-fill from filter selection
    if (widget.preSelectedPlaceId != null) {
      _selectedLocationType = LocationType.place;
      _selectedPlaceId = widget.preSelectedPlaceId;
    } else {
      _selectedLocationType = LocationType.none;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  /// Check if a place is available for the selected time
  bool _isPlaceAvailable(int placeId) {
    final placeDisabledSlots = widget.disabledSlotsByPlace[placeId];
    if (placeDisabledSlots == null || placeDisabledSlots.isEmpty) {
      return true; // No disabled slots for this place
    }

    // Calculate all 15-minute slots within the event time range
    final eventSlots = <DateTime>{};
    DateTime currentSlot = widget.startTime;

    while (currentSlot.isBefore(widget.endTime)) {
      eventSlots.add(currentSlot);
      currentSlot = currentSlot.add(const Duration(minutes: 15));
    }

    // If any event slot is in this place's disabledSlots, it's unavailable
    return !eventSlots.any((slot) => placeDisabledSlots.contains(slot));
  }

  /// Build location selection section (Radio + Conditional UI)
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '장소',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.lightOnSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Radio 1: None
        RadioListTile<LocationType>(
          title: const Text('선택 안함'),
          value: LocationType.none,
          groupValue: _selectedLocationType,
          onChanged: (value) {
            setState(() {
              _selectedLocationType = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // Radio 2: Custom text input
        RadioListTile<LocationType>(
          title: const Text('직접 입력'),
          value: LocationType.custom,
          groupValue: _selectedLocationType,
          onChanged: (value) {
            setState(() {
              _selectedLocationType = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // Conditional: TextField for custom location
        if (_selectedLocationType == LocationType.custom)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xs),
            child: TextField(
              controller: _customLocationController,
              decoration: const InputDecoration(
                hintText: '장소 입력',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),

        // Radio 3: Place selection
        RadioListTile<LocationType>(
          title: const Text('장소 선택'),
          value: LocationType.place,
          groupValue: _selectedLocationType,
          onChanged: widget.availablePlaces.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedLocationType = value!;
                  });
                },
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),

        // Conditional: Dropdown for place selection
        if (_selectedLocationType == LocationType.place)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md, top: AppSpacing.xs),
            child: widget.availablePlaces.isEmpty
                ? const Text(
                    '선택 가능한 장소가 없습니다',
                    style: TextStyle(color: AppColors.lightSecondary, fontSize: 13),
                  )
                : DropdownButtonFormField<int>(
                    value: _selectedPlaceId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    hint: const Text('장소를 선택하세요'),
                    items: widget.availablePlaces.map((place) {
                      final isAvailable = _isPlaceAvailable(place.id);
                      return DropdownMenuItem<int>(
                        value: place.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${place.building} ${place.roomNumber}',
                                style: TextStyle(
                                  color: isAvailable
                                      ? AppColors.lightOnSurface
                                      : AppColors.lightSecondary,
                                  fontWeight: isAvailable ? FontWeight.normal : FontWeight.w300,
                                ),
                              ),
                            ),
                            if (!isAvailable)
                              Flexible(
                                child: const Text(
                                  '(예약 불가)',
                                  style: TextStyle(
                                    color: AppColors.neutral500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlaceId = value;
                      });
                    },
                  ),
          ),
      ],
    );
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목을 입력해주세요'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build location selection result
    LocationSelection locationSelection;
    switch (_selectedLocationType) {
      case LocationType.none:
        locationSelection = const LocationSelection.none();
        break;
      case LocationType.custom:
        final customLoc = _customLocationController.text.trim();
        if (customLoc.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('장소를 입력해주세요'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        locationSelection = LocationSelection.custom(customLoc);
        break;
      case LocationType.place:
        if (_selectedPlaceId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('장소를 선택해주세요'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        locationSelection = LocationSelection.place(_selectedPlaceId!);
        break;
    }

    final result = EventCreateResult(
      title: title,
      locationSelection: locationSelection,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('일정 생성'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time display (read-only)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightOutline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.lightSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '시작: ${DateFormat('M/d (E) HH:mm', 'ko_KR').format(widget.startTime)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 24), // Align with icon
                      Text(
                        '종료: ${DateFormat('M/d (E) HH:mm', 'ko_KR').format(widget.endTime)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Location selection section
            _buildLocationSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _handleSave,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
