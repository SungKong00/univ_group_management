/// 멤버 선택 결과 모델
///
/// DYNAMIC 또는 STATIC 방식으로 멤버를 선택한 결과를 담는 모델
library;

import 'member_filter.dart';

/// 선택 방식 타입
enum SelectionType {
  /// 동적 필터링 (조건 저장)
  dynamic,

  /// 정적 명단 (ID 리스트 저장)
  static,
}

/// 멤버 선택 결과
class MemberSelectionResult {
  final SelectionType type;
  final MemberFilter? filter;      // DYNAMIC 선택 시
  final List<int>? memberIds;      // STATIC 선택 시

  MemberSelectionResult._({
    required this.type,
    this.filter,
    this.memberIds,
  });

  /// DYNAMIC 방식 선택 결과 생성
  factory MemberSelectionResult.dynamic(MemberFilter filter) {
    return MemberSelectionResult._(
      type: SelectionType.dynamic,
      filter: filter,
    );
  }

  /// STATIC 방식 선택 결과 생성
  factory MemberSelectionResult.static(List<int> memberIds) {
    return MemberSelectionResult._(
      type: SelectionType.static,
      memberIds: memberIds,
    );
  }

  @override
  String toString() {
    if (type == SelectionType.dynamic) {
      return 'MemberSelectionResult.dynamic(filter: $filter)';
    } else {
      return 'MemberSelectionResult.static(memberIds: $memberIds)';
    }
  }
}
