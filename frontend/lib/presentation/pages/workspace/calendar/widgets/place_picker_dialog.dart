import 'package:flutter/material.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/services/group_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../widgets/dialogs/confirm_cancel_actions.dart';

/// Dialog for selecting a place from available places for a group
Future<Place?> showPlacePickerDialog(
  BuildContext context, {
  required int groupId,
}) {
  return showDialog<Place?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PlacePickerDialog(groupId: groupId),
  );
}

class _PlacePickerDialog extends StatefulWidget {
  const _PlacePickerDialog({
    required this.groupId,
  });

  final int groupId;

  @override
  State<_PlacePickerDialog> createState() => _PlacePickerDialogState();
}

class _PlacePickerDialogState extends State<_PlacePickerDialog> {
  final _groupService = GroupService();
  final _searchController = TextEditingController();

  List<Place>? _places;
  Place? _selectedPlace;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch places with 10-second timeout
      final places = await _groupService
          .getAvailablePlaces(widget.groupId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('장소 목록을 불러오는 데 시간이 초과되었습니다. 다시 시도해주세요.'),
          );

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e);
      });
    }
  }

  /// Format error messages for user display
  String _formatErrorMessage(Object error) {
    final errorStr = error.toString();
    if (errorStr.contains('초과')) {
      return errorStr;
    }
    if (errorStr.contains('Connection')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
      return '인증 정보가 만료되었습니다. 다시 로그인해주세요.';
    }
    if (errorStr.contains('403') || errorStr.contains('Forbidden')) {
      return '이 그룹의 장소에 접근할 수 없습니다.';
    }
    return '장소 목록을 불러올 수 없습니다';
  }

  List<Place> get _filteredPlaces {
    if (_places == null) return [];
    if (_searchQuery.isEmpty) return _places!;

    final query = _searchQuery.toLowerCase();
    return _places!.where((place) {
      return place.displayName.toLowerCase().contains(query) ||
          place.building.toLowerCase().contains(query) ||
          place.roomNumber.toLowerCase().contains(query) ||
          (place.alias?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Map<String, List<Place>> get _placesByBuilding {
    final filtered = _filteredPlaces;
    final grouped = <String, List<Place>>{};

    for (final place in filtered) {
      grouped.putIfAbsent(place.building, () => []).add(place);
    }

    // Sort buildings alphabetically
    final sortedKeys = grouped.keys.toList()..sort();
    final sorted = <String, List<Place>>{};
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final maxHeight = screenSize.height * 0.6; // 화면 높이의 60%
    final maxWidth = (screenSize.width * 0.9).clamp(300.0, 500.0);

    return AlertDialog(
      title: Text('장소 선택', style: textTheme.titleLarge),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '검색',
                hintText: '장소 이름, 건물, 호수로 검색',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      actions: [
        ConfirmCancelActions(
          confirmText: '선택',
          onConfirm: _selectedPlace != null
              ? () => Navigator.of(context).pop(_selectedPlace)
              : null,
          confirmSemanticsLabel: '장소 선택 완료',
          onCancel: () => Navigator.of(context).pop(),
          cancelSemanticsLabel: '장소 선택 취소',
          confirmVariant: PrimaryButtonVariant.brand,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '장소 목록을 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadPlaces,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_places == null || _places!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 48, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '예약 가능한 장소가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '관리자에게 문의하세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    final placesByBuilding = _placesByBuilding;

    if (placesByBuilding.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '검색 결과가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: placesByBuilding.entries.map((entry) {
          final building = entry.key;
          final places = entry.value;
          final index = placesByBuilding.keys.toList().indexOf(building);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const Divider(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.domain, size: 16, color: AppColors.neutral600),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      building,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.neutral700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${places.length}개',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.neutral700,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              ...places.map((place) => _buildPlaceItem(place)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceItem(Place place) {
    final isSelected = _selectedPlace?.id == place.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlace = isSelected ? null : place;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) {
                setState(() {
                  _selectedPlace = isSelected ? null : place;
                });
              },
              activeColor: AppColors.brand,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.displayName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isSelected ? AppColors.brand : AppColors.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${place.building} ${place.roomNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral600,
                        ),
                  ),
                  if (place.capacity != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 12, color: AppColors.neutral500),
                        const SizedBox(width: 4),
                        Text(
                          '수용 인원: ${place.capacity}명',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
