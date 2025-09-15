import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  GoogleSignInService({required String webClientId})
      : _googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? webClientId : null,
          scopes: const ['email', 'profile', 'openid'],
        );

  Future<({String? idToken, String? accessToken})?> signInAndGetTokens() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user canceled
    // On mobile, both tokens may be available via authentication
    final auth = await account.authentication;
    String? idToken = auth.idToken;
    String? accessToken = auth.accessToken;
    // On web, idToken/accessToken may be null; try authHeaders for Bearer token
    if ((idToken == null || idToken.isEmpty) || (accessToken == null || accessToken.isEmpty)) {
      final headers = await account.authHeaders;
      final authHeader = headers['Authorization'] ?? headers['authorization'];
      if (authHeader is String && authHeader.startsWith('Bearer ')) {
        accessToken = authHeader.substring('Bearer '.length);
      }
    }
    return (idToken: idToken, accessToken: accessToken);
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
