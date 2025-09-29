import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/buttons/outlined_link_button.dart';
import '../../widgets/buttons/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showEntryAnimation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showEntryAnimation = true);
      }
    });
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Google 로그인 기능은 아직 구현 중입니다. 테스트 계정을 사용해주세요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTestAccountLogin() async {
    setState(() => _isLoading = true);

    try {
      final loginResponse = await _authService.loginWithTestAccount();

      if (!mounted) {
        return;
      }

      if (loginResponse.user.profileCompleted) {
        context.go(AppConstants.homeRoute);
      } else {
        context.go(AppConstants.homeRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 로그인 실패: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 768;

    final horizontalPadding = isWide ? AppTheme.spacing32 : AppTheme.spacing16;
    final verticalPadding = isWide ? AppTheme.spacing120 : AppTheme.spacing96;
    final cardPadding = EdgeInsets.symmetric(
      horizontal: isWide ? AppTheme.spacing32 : AppTheme.spacing24,
      vertical: AppTheme.spacing32,
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: AnimatedOpacity(
                duration: AppMotion.quick,
                curve: AppMotion.easing,
                opacity: _showEntryAnimation ? 1 : 0,
                child: AnimatedSlide(
                  duration: AppMotion.quick,
                  curve: AppMotion.easing,
                  offset: _showEntryAnimation
                      ? Offset.zero
                      : const Offset(0, 0.06),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppComponents.loginCardMaxWidth,
                    ),
                    child: Card(
                      child: Padding(
                        padding: cardPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildLogo(),
                            const SizedBox(height: AppTheme.spacing16),
                            _buildHeadline(context),
                            const SizedBox(height: AppTheme.spacing8),
                            _buildSubcopy(context),
                            const SizedBox(height: AppTheme.spacing24),
                            GoogleSignInButton(
                              onPressed: _isLoading ? null : _handleGoogleLogin,
                              isLoading: _isLoading,
                              width: double.infinity,
                              semanticsLabel: 'Google 계정으로 계속하기',
                            ),
                            const SizedBox(height: AppTheme.spacing12),
                            AdminLoginButton(
                              onPressed: _isLoading ? null : _handleTestAccountLogin,
                              isLoading: _isLoading,
                              width: double.infinity,
                              variant: ButtonVariant.tonal,
                              semanticsLabel: '관리자 계정으로 로그인하기',
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            _buildInfoCallout(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: AppComponents.logoSize,
      height: AppComponents.logoSize,
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary,
        borderRadius: BorderRadius.circular(AppComponents.logoRadius),
      ),
      child: const Icon(
        Icons.school_rounded,
        size: AppComponents.logoIconSize,
        color: AppTheme.onPrimary,
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Text(
      '대학 그룹 관리',
      style: AppTheme.displaySmallTheme(context).copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.gray900,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubcopy(BuildContext context) {
    return Text(
      '우리 학과 학생들을 위한 똑똑한 협업 공간',
      style: AppTheme.bodyMediumTheme(context).copyWith(
        fontWeight: FontWeight.w500,
        color: AppTheme.gray600,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoCallout(BuildContext context) {
    return Semantics(
      label: '안내: 개발 단계에서는 관리자 계정을 이용해 로그인할 수 있습니다.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: AppComponents.infoIconSize,
              color: AppTheme.brandPrimary,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                '개발 단계에서는 관리자 계정으로 테스트해보세요.',
                style: AppTheme.bodySmallTheme(context).copyWith(
                  color: AppTheme.gray600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
