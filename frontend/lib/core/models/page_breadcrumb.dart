import 'package:equatable/equatable.dart';

/// 페이지 브레드크럼 모델
///
/// 상단바에 표시될 계층적 페이지 정보를 나타냅니다.
/// - 주제목: 진하고 큰 글씨로 표시되는 현재 페이지 이름
/// - 경로: 옅고 작은 글씨로 표시되는 페이지 계층 (선택 사항)
///
/// 예시:
/// ```dart
/// // 단순 제목만 있는 경우
/// PageBreadcrumb(title: "홈")
///
/// // 계층 경로가 있는 경우
/// PageBreadcrumb(
///   title: "워크스페이스",
///   path: ["워크스페이스", "컴퓨터공학과", "공지사항"],
/// )
/// ```
class PageBreadcrumb extends Equatable {
  const PageBreadcrumb({required this.title, this.path});

  /// 페이지의 주제목 (상단바 좌측에 크게 표시)
  final String title;

  /// 페이지의 계층 경로 (선택 사항, ">" 구분자로 표시)
  /// 예: ["워크스페이스", "컴퓨터공학과", "공지사항"]
  final List<String>? path;

  /// 경로가 있는지 확인
  bool get hasPath => path != null && path!.isNotEmpty;

  /// 경로를 ">" 구분자로 연결한 문자열
  /// 예: "워크스페이스 > 컴퓨터공학과 > 공지사항"
  String get pathString => path?.join(' > ') ?? '';

  PageBreadcrumb copyWith({String? title, List<String>? path}) {
    return PageBreadcrumb(title: title ?? this.title, path: path ?? this.path);
  }

  @override
  List<Object?> get props => [title, path];
}
