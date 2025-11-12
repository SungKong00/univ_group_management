/// Web implementation for JS interop
/// This file is only imported on web platforms where dart:html is available

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void updateReadPositionCache({
  required String channelId,
  required int postId,
  required String apiBaseUrl,
}) {
  // ✅ 동기적으로 localStorage에서 토큰 가져오기
  // SharedPreferences는 웹에서 'flutter.' prefix 자동 추가
  // 'access_token' (언더스코어) 형태로 저장됨
  final token = html.window.localStorage['flutter.access_token'];
  if (token == null || token.isEmpty) {
    return;
  }

  // ✅ 동기적으로 즉시 JS 전역 변수 업데이트
  js.context['_readPositionCache'] = js.JsObject.jsify({
    'channelId': channelId,
    'postId': postId,
    'token': token,
    'apiBaseUrl': apiBaseUrl,
  });
}
