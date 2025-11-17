import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/post.dart';

part 'post_list_state.freezed.dart';

/// 게시글 목록 상태
///
/// 무한 스크롤을 지원하는 목록 상태를 관리합니다.
@freezed
class PostListState with _$PostListState {
  const factory PostListState({
    /// 게시글 목록
    @Default([]) List<Post> posts,

    /// 로딩 중 여부
    @Default(false) bool isLoading,

    /// 다음 페이지 존재 여부
    @Default(false) bool hasMore,

    /// 현재 페이지 번호 (다음 로드할 페이지)
    @Default(0) int currentPage,

    /// 에러 메시지 (에러 발생 시)
    String? errorMessage,
  }) = _PostListState;
}
