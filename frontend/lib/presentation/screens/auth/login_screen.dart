import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../theme/app_theme.dart';
import '../../../core/auth/google_signin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _google = GoogleSignInService();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // 이미 인증된 상태로 로그인 페이지에 진입한 경우 홈으로 리다이렉트
          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final user = authProvider.currentUser;
              if (user != null && !user.profileCompleted) {
                // 프로필 미완성 사용자는 역할 선택으로
                Navigator.pushReplacementNamed(context, '/role-selection');
              } else {
                // 프로필 완료 사용자는 홈으로
                Navigator.pushReplacementNamed(context, '/home');
              }
            });
          }
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            message: '로그인 중...',
            child: SafeArea(
              child: Padding(
                padding: AppStyles.paddingL,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 로고/제목
                                Text(
                                  '대학 그룹 관리',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppStyles.spacingS),
                                Text(
                                  '로그인하여 그룹을 관리해보세요',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppStyles.spacingXXL),

                                // 에러 메시지
                                if (authProvider.errorMessage != null) ...[
                                  Container(
                                    padding: AppStyles.paddingM,
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: AppStyles.radiusM,
                                      border: Border.all(
                                        color: AppTheme.errorColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppTheme.errorColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppStyles.spacingS),
                                        Expanded(
                                          child: Text(
                                            authProvider.errorMessage!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.errorColor,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => authProvider.clearError(),
                                          icon: Icon(
                                            Icons.close,
                                            color: AppTheme.errorColor,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppStyles.spacingL),
                                ],

                                // Google 로그인 버튼
                                CommonButton(
                                  text: 'Google로 계속하기',
                                  onPressed: _handleGoogleLogin,
                                  width: double.infinity,
                                  height: 56,
                                  icon: Icons.login,
                                ),
                              ],
                            ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    try {
      final tokens = await _google.signInAndGetTokens();
      if (tokens == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 취소되었습니다.')),
          );
        }
        return;
      }
      final success = await authProvider.loginWithGoogleTokens(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null && !user.profileCompleted) {
          // 프로필이 완성되지 않은 새 사용자의 경우 역할 선택으로 이동
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/role-selection',
            (route) => false,
          );
        } else {
          // 기존 사용자는 홈으로 이동
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${e.toString()}')),
        );
      }
    }
  }
}
