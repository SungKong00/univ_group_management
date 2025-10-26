/// 멤버 선택 Preview API 응답 모델
///
/// Step 2에서 DYNAMIC/STATIC 선택 카드를 표시하기 위한 미리보기 데이터
library;

/// Preview API 응답 모델
class MemberPreviewResponse {
  final int totalCount;                 // 필터 조건에 해당하는 전체 멤버 수
  final List<MemberPreviewDto> samples; // 샘플 멤버 목록 (최대 3명)

  MemberPreviewResponse({
    required this.totalCount,
    required this.samples,
  });

  factory MemberPreviewResponse.fromJson(Map<String, dynamic> json) {
    return MemberPreviewResponse(
      totalCount: (json['totalCount'] as num).toInt(),
      samples: (json['samples'] as List<dynamic>)
          .map((item) => MemberPreviewDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'samples': samples.map((s) => s.toJson()).toList(),
    };
  }
}

/// 샘플 멤버 정보
class MemberPreviewDto {
  final int id;
  final String name;
  final int grade;
  final int year;
  final String roleName;

  MemberPreviewDto({
    required this.id,
    required this.name,
    required this.grade,
    required this.year,
    required this.roleName,
  });

  factory MemberPreviewDto.fromJson(Map<String, dynamic> json) {
    return MemberPreviewDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      grade: (json['grade'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      roleName: json['roleName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'year': year,
      'roleName': roleName,
    };
  }
}
