import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  GoogleSignInService()
      : _googleSignIn = GoogleSignIn(
          // Web에서는 serverClientId 지원 안 함. 오류 회피를 위해 전달 금지.
          clientId: kIsWeb ? AppConstants.googleWebClientId : null,
          serverClientId: kIsWeb ? null : AppConstants.googleWebClientId,
          // People API 호출을 유발하는 'profile' 스코프 제거 (idToken만 필요)
          scopes: const ['email'],
        );

  Future<GoogleTokens?> signInAndGetTokens() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // 사용자가 팝업에서 취소
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken; // Web에서는 accessToken만 올 수 있음
    if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
      throw Exception(
        'Google 토큰을 받지 못했습니다.\n'
        '- Authorized JavaScript origins에 현재 호스트와 포트(예: http://localhost:5173)를 추가했는지 확인\n'
        '- 브라우저 팝업/서드파티 쿠키 허용 여부 확인\n'
        '- OAuth 동의화면에서 테스트 사용자 등록 여부 확인',
      );
    }
    return GoogleTokens(idToken: idToken, accessToken: accessToken);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

class GoogleTokens {
  final String? idToken;
  final String? accessToken;
  GoogleTokens({this.idToken, this.accessToken});
}
