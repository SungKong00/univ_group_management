import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/auth/google_sign_in_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _working = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _working = true);
    try {
      final google = GoogleSignInService(webClientId: AppConstants.googleWebClientId);
      final tokens = await google.signInAndGetTokens();
      if (!mounted) return;
      if (tokens == null) {
        // user canceled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 인증을 완료해 주세요')),
        );
        return;
      }
      final ok = await context.read<AuthProvider>().loginWithGoogleTokens(
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          );
      if (!mounted) return;
      if (ok) {
        final state = context.read<AuthProvider>().state;
        if (state == AuthState.needsOnboarding) {
          Navigator.pushReplacementNamed(context, '/register');
        } else if (state == AuthState.authenticated) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        final msg = context.read<AuthProvider>().error ?? '로그인에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(builder: (context, auth, _) {
        return LoadingOverlay(
          isLoading: auth.isLoading || _working,
          message: '로그인 중...',
          child: SafeArea(
            child: Padding(
              padding: AppStyles.paddingL,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('대학 그룹 관리',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('학교 계정으로 로그인하세요 (hs.ac.kr)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 32),
                      if (auth.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.08),
                            borderRadius: AppStyles.radiusM,
                            border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                          ),
                          child: Text(auth.error!, style: const TextStyle(color: AppTheme.errorColor)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CommonButton(
                        text: 'Google로 계속하기',
                        icon: Icons.login,
                        onPressed: _working ? null : _handleGoogleSignIn,
                        height: 52,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
