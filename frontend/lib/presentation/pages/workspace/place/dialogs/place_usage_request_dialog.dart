import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../providers/place_provider.dart';

/// Dialog for requesting place usage permission
///
/// Allows a group to request permission to use a place managed by another group.
class PlaceUsageRequestDialog extends ConsumerStatefulWidget {
  final int groupId;

  const PlaceUsageRequestDialog({
    required this.groupId,
    super.key,
  });

  @override
  ConsumerState<PlaceUsageRequestDialog> createState() =>
      _PlaceUsageRequestDialogState();
}

class _PlaceUsageRequestDialogState
    extends ConsumerState<PlaceUsageRequestDialog> {
  int? _selectedPlaceId;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placesProvider(widget.groupId));

    return AlertDialog(
      title: Text(
        '장소 예약 권한 신청',
        style: AppTheme.titleLarge.copyWith(
          color: AppColors.neutral900,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Place selection dropdown
              placesAsync.when(
                data: (places) {
                  // Filter out places managed by this group
                  final availablePlaces = places
                      .where((p) => p.managingGroupId != widget.groupId)
                      .toList();

                  if (availablePlaces.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.neutral600,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              '신청 가능한 장소가 없습니다',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.neutral700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: '장소 선택',
                      labelStyle: AppTheme.bodyMedium.copyWith(
                        color: AppColors.neutral700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: AppColors.neutral300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: AppColors.neutral300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        borderSide: BorderSide(color: AppColors.brand, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _selectedPlaceId,
                    items: availablePlaces
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.displayName,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppColors.neutral900,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPlaceId = value),
                  );
                },
                loading: () => Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ),
                error: (e, _) => Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '장소 목록을 불러올 수 없습니다',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Reason input (optional)
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: '신청 사유 (선택)',
                  labelStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: 정기 회의를 위해 사용하고자 합니다',
                  hintStyle: AppTheme.bodySmall.copyWith(
                    color: AppColors.neutral500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.neutral300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(color: AppColors.brand, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '${_reasonController.text.length}/500',
                ),
                maxLines: 3,
                maxLength: 500,
                onChanged: (value) => setState(() {}), // Refresh counter
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            '취소',
            style: AppTheme.titleLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedPlaceId != null && !_isLoading
              ? _handleSubmit
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            disabledBackgroundColor: AppColors.neutral300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  '신청',
                  style: AppTheme.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedPlaceId == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(placeServiceProvider).createUsageRequest(
            placeId: _selectedPlaceId!,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('권한 신청이 완료되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '신청 실패: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
