import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/place_time_models.dart';
import '../../../../core/providers/place_time_providers.dart';
import '../../../../features/place_admin/presentation/widgets/place_operating_hours_editor.dart';
import '../../../../features/place_admin/presentation/widgets/place_closure_widgets.dart';

/// 장소 시간 관리 페이지 (workspace-level page without Scaffold)
///
/// 장소 설정 진입 시 바로 보이는 메인 페이지입니다.
/// - PlaceOperatingHoursEditor (운영시간 + 브레이크 타임 설정) - 전체 크기 표시
/// - PlaceClosureCalendarWidget (임시 휴무 캘린더) - 전체 크기 표시
/// - 전체 페이지를 하나의 스크롤로 이동
class PlaceTimeManagementPage extends ConsumerWidget {
  final int placeId;
  final String placeName;

  const PlaceTimeManagementPage({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operatingHoursAsync = ref.watch(operatingHoursProvider(placeId));
    final restrictedTimesAsync = ref.watch(restrictedTimesProvider(placeId));

    return operatingHoursAsync.when(
      data: (operatingHours) {
        return restrictedTimesAsync.when(
          data: (restrictedTimes) {
            return _buildContent(context, ref, operatingHours, restrictedTimes);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('제한시간 로드 오류: $error'),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('운영시간 로드 오류: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<OperatingHoursResponse> operatingHours,
    List<RestrictedTimeResponse> restrictedTimes,
  ) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 운영시간 에디터 (내용 크기만큼 표시)
          PlaceOperatingHoursEditor(
            placeId: placeId,
            initialOperatingHours: operatingHours,
            onSaveOperatingHours: (hours) async {
              try {
                final request = SetOperatingHoursRequest(operatingHours: hours);
                final params = SetOperatingHoursParams(
                  placeId: placeId,
                  request: request,
                );
                await ref.read(setOperatingHoursProvider(params).future);
                return true;
              } catch (e) {
                return false;
              }
            },
            onSaveCompleted: () {
              // 저장 성공 시 데이터 새로고침
              ref.invalidate(operatingHoursProvider(placeId));
              ref.invalidate(restrictedTimesProvider(placeId));
            },
          ),

          // 구분선
          const Divider(height: 1),

          // 임시 휴무 위젯 (내용 크기만큼 표시)
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: PlaceClosureCalendarWidget(placeId: placeId),
          ),
        ],
      ),
    );
  }
}
