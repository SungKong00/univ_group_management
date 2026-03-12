import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group_models.dart';
import '../../services/group_service.dart';

/// 하위 그룹 목록 Provider
///
/// 멤버 필터링에서 소속 그룹 선택 시 사용됩니다.
/// API: GET /api/groups/{groupId}/sub-groups
final subGroupsProvider =
    FutureProvider.family<List<GroupSummaryResponse>, int>((
      ref,
      groupId,
    ) async {
      final service = GroupService();
      return service.getSubGroups(groupId);
    });

/// 학번 목록 Provider
///
/// 현재 DB에 존재하는 학번(입학년도) 목록을 반환합니다.
/// 백엔드 API가 없으므로, 2010~현재년도+1까지 생성합니다.
///
/// 예: 2025년이면 2010~2026 (신입생 고려)
final availableYearsProvider = Provider<List<int>>((ref) {
  final currentYear = DateTime.now().year;
  final startYear = 2010;
  final endYear = currentYear + 1; // 신입생 고려

  return List.generate(
    endYear - startYear + 1,
    (index) => endYear - index, // 최신 년도부터 내림차순
  );
});

/// 학년 목록 상수
///
/// 1~4학년, 졸업생(5), 기타(0)
const List<int> availableGrades = [1, 2, 3, 4, 5, 0];

/// 학년 레이블 맵
const Map<int, String> gradeLabels = {
  1: '1학년',
  2: '2학년',
  3: '3학년',
  4: '4학년',
  5: '졸업생',
  0: '기타',
};
