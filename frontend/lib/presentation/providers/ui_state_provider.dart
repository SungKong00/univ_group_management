import 'package:flutter/foundation.dart';
import '../../data/models/workspace_models.dart';

class UIStateProvider extends ChangeNotifier {
  // Current tab index (0: 공지, 1: 채널, 2: 멤버)
  int _currentTabIndex = 0;

  // Sidebar visibility state
  bool _isSidebarVisible = true;

  // 기본 채널 자동 선택 여부 (첫 로드 한정)
  bool _didAutoSelectChannel = false;

  // 모바일 전용 상태
  bool _isMobileNavigatorVisible = false;

  // 반응형 전환 상태 관리
  bool _isInitialLoad = true;
  bool _isHandlingResponsiveTransition = false;

  // Comments sidebar state
  PostModel? _selectedPostForComments;
  bool _isCommentsSidebarVisible = false;

  // Getters
  int get currentTabIndex => _currentTabIndex;
  bool get isSidebarVisible => _isSidebarVisible;
  bool get isMobileNavigatorVisible => _isMobileNavigatorVisible;
  bool get isInitialLoad => _isInitialLoad;
  bool get didAutoSelectChannel => _didAutoSelectChannel;

  // Comments sidebar getters
  PostModel? get selectedPostForComments => _selectedPostForComments;
  bool get isCommentsSidebarVisible => _isCommentsSidebarVisible;

  /// 탭 변경
  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  /// 사이드바 토글
  void toggleSidebar() {
    _isSidebarVisible = !_isSidebarVisible;
    notifyListeners();
  }

  /// 사이드바 표시/숨김 설정
  void setSidebarVisible(bool visible) {
    if (_isSidebarVisible != visible) {
      _isSidebarVisible = visible;
      notifyListeners();
    }
  }

  /// 모바일 네비게이터 표시
  void showMobileNavigator() {
    if (!_isMobileNavigatorVisible) {
      _isMobileNavigatorVisible = true;
      notifyListeners();
    }
  }

  /// 모바일 네비게이터 표시/숨김 설정
  void setMobileNavigatorVisible(bool visible) {
    if (_isMobileNavigatorVisible != visible) {
      _isMobileNavigatorVisible = visible;
      notifyListeners();
    }
  }

  /// 댓글 사이드바 표시
  void showCommentsSidebar(PostModel post) {
    _selectedPostForComments = post;
    _isCommentsSidebarVisible = true;
    notifyListeners();
  }

  /// 댓글 사이드바 숨김
  void hideCommentsSidebar() {
    _selectedPostForComments = null;
    _isCommentsSidebarVisible = false;
    notifyListeners();
  }

  /// 댓글 토글 (이미 선택된 포스트면 숨김, 아니면 표시)
  void toggleCommentsSidebar(PostModel? post) {
    if (_isCommentsSidebarVisible && _selectedPostForComments?.id == post?.id) {
      hideCommentsSidebar();
    } else if (post != null) {
      showCommentsSidebar(post);
    } else {
      hideCommentsSidebar();
    }
  }

  /// 반응형 화면 전환 처리
  void handleResponsiveTransition(bool isNowMobile) {
    if (_isHandlingResponsiveTransition) return;

    if (_isInitialLoad) {
      // 초기 로드 시에는 상태만 업데이트하고 전환 로직 스킵
      _isInitialLoad = false;
      notifyListeners();
      return;
    }

    _isHandlingResponsiveTransition = true;

    try {
      if (isNowMobile) {
        // 웹 → 모바일 전환 시
        if (_isCommentsSidebarVisible && _selectedPostForComments != null) {
          // 댓글 보기 상태면 모바일 네비게이터는 숨김 유지
          _isMobileNavigatorVisible = false;
        } else {
          // 그 외에는 네비게이터 숨김
          _isMobileNavigatorVisible = false;
        }
      } else {
        // 모바일 → 웹 전환 시
        _isMobileNavigatorVisible = false;
      }

      notifyListeners();
    } finally {
      // 딜레이 후 플래그 해제
      Future.delayed(const Duration(milliseconds: 100), () {
        _isHandlingResponsiveTransition = false;
      });
    }
  }

  /// 초기 로드 완료 표시
  void markAsInitialLoadComplete() {
    if (_isHandlingResponsiveTransition) return;

    _isInitialLoad = false;
    notifyListeners();
  }

  /// 자동 채널 선택 완료 표시
  void markAutoSelectChannelComplete() {
    _didAutoSelectChannel = true;
    _isMobileNavigatorVisible = false;
    notifyListeners();
  }

  /// 상태 리셋
  void reset() {
    _currentTabIndex = 0;
    _isSidebarVisible = true;
    _selectedPostForComments = null;
    _isCommentsSidebarVisible = false;
    _didAutoSelectChannel = false;
    _isMobileNavigatorVisible = false;
    _isInitialLoad = true;
    _isHandlingResponsiveTransition = false;
    notifyListeners();
  }

  /// 선택된 포스트 업데이트 (워크스페이스에서 포스트가 업데이트될 때 사용)
  void updateSelectedPost(PostModel updatedPost) {
    if (_selectedPostForComments?.id == updatedPost.id) {
      _selectedPostForComments = updatedPost;
      notifyListeners();
    }
  }
}