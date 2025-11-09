import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/models/place/place.dart';
import '../../../../../core/services/place_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';

/// Dialog for selecting a place.
///
/// When [availablePlaces] is provided, they are shown as selectable options and
/// [unavailablePlaces] are listed for context. Otherwise, the dialog fetches
/// reservable places for the given [groupId].
Future<Place?> showPlacePickerDialog({
  required BuildContext context,
  required int groupId,
  DateTime? startTime,
  DateTime? endTime,
  List<Place>? availablePlaces,
  List<Place>? unavailablePlaces,
}) async {
  final navigator = Navigator.of(context);

  List<Place> resolvedAvailable = availablePlaces ?? [];
  List<Place> resolvedUnavailable = unavailablePlaces ?? [];

  if (availablePlaces == null) {
    try {
      resolvedAvailable = await PlaceService().getReservablePlaces(groupId);
    } catch (e) {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(content: Text('장소 목록을 불러오지 못했습니다: $e')),
        );
      }
      return null;
    }
  }

  if (resolvedAvailable.isEmpty) {
    if (navigator.mounted) {
      ScaffoldMessenger.of(navigator.context).showSnackBar(
        const SnackBar(content: Text('선택 가능한 장소가 없습니다')),
      );
    }
    return null;
  }

  return showDialog<Place>(
    context: context,
    builder: (dialogContext) {
      int selectedIndex = 0;
      final textTheme = Theme.of(dialogContext).textTheme;
      final showTimeInfo = startTime != null && endTime != null;

      String formatTimeRange() {
        final dateLabel =
            DateFormat('M월 d일 (E)', 'ko_KR').format(startTime!);
        final timeLabel =
            '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime!)}';
        return '$dateLabel · $timeLabel';
      }

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
          ),
          title: const Text('장소 선택'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTimeInfo)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Text(
                      formatTimeRange(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        '예약 가능 (${resolvedAvailable.length})',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...resolvedAvailable.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final place = entry.value;
                          return RadioListTile<int>(
                            value: index,
                            groupValue: selectedIndex,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedIndex = value);
                            },
                            title: Text(
                              place.displayName,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              place.fullLocation,
                              style: textTheme.bodySmall,
                            ),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                      if (resolvedUnavailable.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '예약 불가 (${resolvedUnavailable.length})',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...resolvedUnavailable.map(
                          (place) => ListTile(
                            leading: const Icon(
                              Icons.block,
                              color: AppColors.error,
                              size: 18,
                            ),
                            title: Text(
                              place.displayName,
                              style: textTheme.bodyMedium,
                            ),
                            subtitle: Text(
                              place.fullLocation,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                            dense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => navigator.pop(resolvedAvailable[selectedIndex]),
              child: const Text('선택'),
            ),
          ],
        ),
      );
    },
  );
}
