import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination.freezed.dart';
part 'pagination.g.dart';

/// 페이지네이션 정보를 나타내는 불변 Entity
///
/// 게시글, 공지, 댓글 등 다양한 목록에서 재사용 가능합니다.
@freezed
class Pagination with _$Pagination {
  const Pagination._();

  const factory Pagination({
    /// 전체 페이지 수
    required int totalPages,

    /// 현재 페이지 번호 (0부터 시작)
    required int currentPage,

    /// 전체 요소 수
    required int totalElements,

    /// 다음 페이지 존재 여부
    required bool hasMore,
  }) = _Pagination;

  /// JSON에서 Pagination 객체 생성
  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  /// 첫 번째 페이지 여부
  bool get isFirstPage => currentPage == 0;

  /// 마지막 페이지 여부
  bool get isLastPage => !hasMore;

  /// 다음 페이지 번호
  int get nextPage => currentPage + 1;

  /// 이전 페이지 번호 (첫 페이지면 0)
  int get previousPage => currentPage > 0 ? currentPage - 1 : 0;
}
