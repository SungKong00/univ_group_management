import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/place/place.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/place_provider.dart';

class PlaceFormDialog extends ConsumerStatefulWidget {
  final int groupId;
  final Place? place; // null for creation, non-null for editing
  final VoidCallback? onSaved;

  const PlaceFormDialog({
    required this.groupId,
    this.place,
    this.onSaved,
    super.key,
  });

  @override
  ConsumerState<PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends ConsumerState<PlaceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _buildingController;
  late final TextEditingController _roomNumberController;
  late final TextEditingController _aliasController;
  late final TextEditingController _capacityController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _buildingController = TextEditingController(text: widget.place?.building ?? '');
    _roomNumberController = TextEditingController(text: widget.place?.roomNumber ?? '');
    _aliasController = TextEditingController(text: widget.place?.alias ?? '');
    _capacityController = TextEditingController(
      text: widget.place?.capacity?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _roomNumberController.dispose();
    _aliasController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.place != null;

    return AlertDialog(
      title: Text(
        isEditing ? '장소 수정' : '새 장소 추가',
        style: AppTheme.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Building field
              TextFormField(
                controller: _buildingController,
                decoration: InputDecoration(
                  labelText: '건물명',
                  labelStyle: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: 60주년 기념관',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
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
                    borderSide: BorderSide(
                      color: AppColors.brand,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '건물명을 입력해주세요';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSpacing.sm),

              // Room number field
              TextFormField(
                controller: _roomNumberController,
                decoration: InputDecoration(
                  labelText: '방 번호',
                  labelStyle: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: 18203',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
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
                    borderSide: BorderSide(
                      color: AppColors.brand,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '방 번호를 입력해주세요';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSpacing.sm),

              // Alias field (optional)
              TextFormField(
                controller: _aliasController,
                decoration: InputDecoration(
                  labelText: '별칭 (선택)',
                  labelStyle: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: AISC랩실',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
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
                    borderSide: BorderSide(
                      color: AppColors.brand,
                      width: 2,
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.sm),

              // Capacity field (optional)
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: '수용 인원 (선택)',
                  labelStyle: AppTheme.titleMedium.copyWith(
                    color: AppColors.neutral700,
                  ),
                  hintText: '예: 30',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  filled: true,
                  fillColor: AppColors.neutral100,
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
                    borderSide: BorderSide(
                      color: AppColors.brand,
                      width: 2,
                    ),
                  ),
                  suffixText: '명',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final capacity = int.tryParse(value);
                    if (capacity == null || capacity <= 0) {
                      return '유효한 수용 인원을 입력해주세요';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            '취소',
            style: AppTheme.titleLarge.copyWith(
              color: _isSubmitting ? AppColors.neutral400 : AppColors.neutral600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.neutral300,
            disabledForegroundColor: AppColors.neutral500,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEditing ? '수정' : '추가',
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final building = _buildingController.text.trim();
      final roomNumber = _roomNumberController.text.trim();
      final alias = _aliasController.text.trim();
      final capacityText = _capacityController.text.trim();
      final capacity = capacityText.isEmpty ? null : int.parse(capacityText);

      if (widget.place == null) {
        // Create new place
        final request = CreatePlaceRequest(
          managingGroupId: widget.groupId,
          building: building,
          roomNumber: roomNumber,
          alias: alias.isEmpty ? null : alias,
          capacity: capacity,
        );

        await ref.read(placeManagementProvider.notifier).createPlace(request);
      } else {
        // Update existing place
        final request = UpdatePlaceRequest(
          building: building,
          roomNumber: roomNumber,
          alias: alias.isEmpty ? null : alias,
          capacity: capacity,
        );

        await ref.read(placeManagementProvider.notifier).updatePlace(
              widget.place!.id,
              request,
            );
      }

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.place == null ? '장소가 추가되었습니다' : '장소가 수정되었습니다',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Call callback to refresh list
        widget.onSaved?.call();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.place == null ? '추가' : '수정'} 실패: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
