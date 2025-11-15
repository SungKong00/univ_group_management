/// Web implementation for JS interop
/// This file is only imported on web platforms where package:web is available
library;

import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('globalThis')
external JSObject get _globalThis;

extension on JSObject {
  external set _readPositionCache(JSAny? value);
}

void updateReadPositionCache({
  required String channelId,
  required int postId,
  required String apiBaseUrl,
}) {
  // ✅ 동기적으로 localStorage에서 토큰 가져오기
  // SharedPreferences는 웹에서 'flutter.' prefix 자동 추가
  // 'access_token' (언더스코어) 형태로 저장됨
  final token = web.window.localStorage.getItem('flutter.access_token');
  if (token == null || token.isEmpty) {
    return;
  }

  // ✅ 동기적으로 즉시 JS 전역 변수 업데이트
  final cache = {
    'channelId': channelId,
    'postId': postId,
    'token': token,
    'apiBaseUrl': apiBaseUrl,
  }.jsify();

  _globalThis._readPositionCache = cache;
}
