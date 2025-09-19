import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/google_signin_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/auth/google_sign_in_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _working = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAFBFC),
              Color(0xFFF8F9FA),
              Color(0xFFE5E7EB),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Consumer<AuthProvider>(builder: (context, auth, _) {
          return LoadingOverlay(
            isLoading: auth.isLoading || _working,
            message: '로그인 중...',
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isSmallScreen ? size.width - 48 : 440,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            blurRadius: 64,
                            offset: const Offset(0, 32),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Icon
                          Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primary,
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),

                          // Title
                          Text(
                            '대학 그룹 관리',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onTextPrimary,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            '학교 계정으로 로그인하세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.onTextSecondary,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            '(hs.ac.kr)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 32 : 40),

                          // Error Message
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.errorColor.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Google Sign In Button
                          GoogleSignInButton(
                            onPressed: _working ? null : _handleGoogleSignIn,
                            isLoading: _working,
                            height: isSmallScreen ? 56 : 60,
                          ),

                          SizedBox(height: isSmallScreen ? 24 : 32),

                          // Footer
                          Text(
                            '안전하고 편리한 그룹 관리',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.onTextSecondary.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
