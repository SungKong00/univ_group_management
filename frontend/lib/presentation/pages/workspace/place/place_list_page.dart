import 'package:flutter/material.dart';
import '../../../../core/utils/snack_bar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/place/place.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/place_provider.dart';
import '../../../providers/group_permission_provider.dart';
import '../../../widgets/place/place_card.dart';
import 'place_form_dialog.dart';
import 'dialogs/place_usage_request_dialog.dart';
import '../../../../features/place_admin/presentation/widgets/place_operating_hours_dialog.dart';
import '../../../../core/providers/place_time_providers.dart';

class PlaceListPage extends ConsumerStatefulWidget {
  final int groupId;

  const PlaceListPage({required this.groupId, super.key});

  @override
  ConsumerState<PlaceListPage> createState() => _PlaceListPageState();
}

class _PlaceListPageState extends ConsumerState<PlaceListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(placesProvider(widget.groupId));
    final permissionsAsync = ref.watch(
      groupPermissionsProvider(widget.groupId),
    );

    final hasCalendarManage = permissionsAsync.when(
      data: (perms) => perms.contains('CALENDAR_MANAGE'),
      loading: () => false,
      error: (_, __) => false,
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('장소 관리'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTheme.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
        actions: [
          // Request permission button
          IconButton(
            icon: const Icon(Icons.request_page),
            tooltip: '예약 권한 신청',
            onPressed: () => _showUsageRequestDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(AppSpacing.sm),
            child: TextField(
              decoration: InputDecoration(
                hintText: '건물명, 방 번호, 별칭 검색',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppColors.neutral500,
                ),
                prefixIcon: Icon(Icons.search, color: AppColors.neutral600),
                filled: true,
                fillColor: AppColors.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Place list
          Expanded(
            child: placesAsync.when(
              data: (places) => _buildPlaceList(places),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '오류가 발생했습니다',
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      error.toString(),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.neutral600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // FAB (only shown if has CALENDAR_MANAGE permission)
      floatingActionButton: hasCalendarManage
          ? FloatingActionButton.extended(
              onPressed: () => _showPlaceFormDialog(),
              backgroundColor: AppColors.brand,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                '새 장소 추가',
                style: AppTheme.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPlaceList(List<Place> places) {
    // Filter places by search query
    final filteredPlaces = places.where((place) {
      final query = _searchQuery.toLowerCase();
      return place.building.toLowerCase().contains(query) ||
          place.roomNumber.toLowerCase().contains(query) ||
          (place.alias?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (filteredPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.location_off : Icons.search_off,
              size: 64,
              color: AppColors.neutral400,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              _searchQuery.isEmpty ? '등록된 장소가 없습니다' : '검색 결과가 없습니다',
              style: AppTheme.titleLarge.copyWith(color: AppColors.neutral600),
            ),
            if (_searchQuery.isEmpty) ...[
              SizedBox(height: AppSpacing.xxs),
              Text(
                '새 장소를 추가해보세요',
                style: AppTheme.bodySmall.copyWith(color: AppColors.neutral500),
              ),
            ],
          ],
        ),
      );
    }

    // Group places by building
    final groupedPlaces = <String, List<Place>>{};
    for (final place in filteredPlaces) {
      groupedPlaces.putIfAbsent(place.building, () => []).add(place);
    }

    // Sort buildings alphabetically
    final sortedBuildings = groupedPlaces.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.sm),
      itemCount: sortedBuildings.length,
      itemBuilder: (context, index) {
        final building = sortedBuildings[index];
        final buildingPlaces = groupedPlaces[building]!;

        // Sort places by room number
        buildingPlaces.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: AppColors.neutral300, width: 1),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            childrenPadding: EdgeInsets.only(bottom: AppSpacing.xxs),
            title: Text(
              building,
              style: AppTheme.headlineSmall.copyWith(
                color: AppColors.neutral900,
              ),
            ),
            subtitle: Text(
              '${buildingPlaces.length}개 장소',
              style: AppTheme.bodySmall.copyWith(color: AppColors.neutral600),
            ),
            children: buildingPlaces.map((place) {
              return PlaceCard(
                place: place,
                groupId: widget.groupId,
                onEdit: () => _showPlaceFormDialog(place: place),
                onDelete: () => _deletePlace(place.id),
                onManageAvailability: () => _showOperatingHoursDialog(place.id),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPlaceFormDialog({Place? place}) {
    showDialog(
      context: context,
      builder: (context) => PlaceFormDialog(
        groupId: widget.groupId,
        place: place,
        onSaved: () {
          // Refresh place list
          ref.invalidate(placesProvider);
        },
      ),
    );
  }

  Future<void> _deletePlace(int placeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '장소 삭제',
          style: AppTheme.titleLarge.copyWith(color: AppColors.neutral900),
        ),
        content: Text(
          '이 장소를 삭제하시겠습니까?\n기존 예약은 유지되지만 신규 예약은 불가능합니다.',
          style: AppTheme.bodyMedium.copyWith(color: AppColors.neutral700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTheme.titleLarge.copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              '삭제',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(placeManagementProvider.notifier).deletePlace(placeId);

        if (mounted) {
          AppSnackBar.success(context, '장소가 삭제되었습니다');
        }

        // Refresh place list
        ref.invalidate(placesProvider);
      } catch (e) {
        if (mounted) {
          AppSnackBar.error(
            context,
            '삭제 실패: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  void _showOperatingHoursDialog(int placeId) async {
    // 기존 운영시간 로드 (비동기 대기)
    List<OperatingHoursResponse>? existingHours;
    try {
      existingHours = await ref.read(operatingHoursProvider(placeId).future);
    } catch (e) {
      // 로드 실패 시 null로 진행 (기본값 사용)
      existingHours = null;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PlaceOperatingHoursDialog(
        placeId: placeId,
        initialHours: existingHours,
      ),
    );

    if (result == true) {
      // 성공 시 데이터 새로고침
      ref.invalidate(operatingHoursProvider(placeId));
      ref.invalidate(placeDetailProvider(placeId));
    }
  }

  void _showUsageRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => PlaceUsageRequestDialog(groupId: widget.groupId),
    );
  }
}
