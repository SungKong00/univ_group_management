import 'dart:developer' as developer;
import '../../../core/utils/snack_bar_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/buttons/outlined_link_button.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;
  bool _showEntryAnimation = false;
  GoogleSignIn? _googleSignIn;

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
      if (AppConstants.googleServerClientId.isEmpty) {
        throw Exception(
          'GOOGLE_SERVER_CLIENT_ID가 설정되지 않았습니다. Google OAuth 클라이언트 정보를 입력해주세요.',
        );
      }

      if (kIsWeb && AppConstants.googleWebClientId.isEmpty) {
        throw Exception(
          '웹 환경에서는 GOOGLE_WEB_CLIENT_ID 값을 설정해야 Google 로그인을 사용할 수 있어요.',
        );
      }

      final googleSignIn = _googleSignIn ??= _createGoogleSignIn();

      // 이전 로그인 세션이 남아 있으면 초기화
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception(
          'Google에서 인증 토큰을 반환하지 않았습니다. OAuth 클라이언트 설정을 다시 확인해주세요.',
        );
      }

      final loginResponse = await ref
          .read(authProvider.notifier)
          .loginWithGoogle(
            idToken: (idToken != null && idToken.isNotEmpty) ? idToken : null,
            accessToken: (accessToken != null && accessToken.isNotEmpty)
                ? accessToken
                : null,
          );

      if (!mounted) {
        return;
      }

      await _handlePostLogin(loginResponse);
    } on PlatformException catch (error) {
      if (mounted) {
        final message = error.message ?? 'Google 로그인 초기화 중 오류가 발생했습니다.';
        AppSnackBar.error(context, '로그인 실패: $message');
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.error(context, '로그인 실패: $message');
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
      final loginResponse = await ref
          .read(authProvider.notifier)
          .loginWithTestAccount();

      if (!mounted) {
        return;
      }

      await _handlePostLogin(loginResponse);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '테스트 로그인 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  GoogleSignIn _createGoogleSignIn() {
    final platformClientId = _clientIdForPlatform();

    if (kIsWeb) {
      // 웹에서는 serverClientId 제외 (지원되지 않음)
      return GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: platformClientId,
      );
    } else {
      // 모바일에서는 serverClientId 포함
      return GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: platformClientId,
        serverClientId: AppConstants.googleServerClientId.isNotEmpty
            ? AppConstants.googleServerClientId
            : null,
      );
    }
  }

  String? _clientIdForPlatform() {
    if (kIsWeb) {
      return AppConstants.googleWebClientId.isNotEmpty
          ? AppConstants.googleWebClientId
          : null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return AppConstants.googleIosClientId.isNotEmpty
            ? AppConstants.googleIosClientId
            : null;
      case TargetPlatform.android:
        return AppConstants.googleAndroidClientId.isNotEmpty
            ? AppConstants.googleAndroidClientId
            : null;
      default:
        return null;
    }
  }

  Future<void> _handlePostLogin(LoginResponse loginResponse) async {
    final shouldCompleteProfile =
        !loginResponse.user.profileCompleted || loginResponse.firstLogin;

    final targetRoute = shouldCompleteProfile
        ? AppConstants.onboardingRoute
        : AppConstants.homeRoute;

    if (!mounted) {
      return;
    }

    context.go(targetRoute);
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
      backgroundColor: AppColors.surface,
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
                              onPressed: _isLoading
                                  ? null
                                  : _handleTestAccountLogin,
                              isLoading: _isLoading,
                              width: double.infinity,
                              variant: ButtonVariant.tonal,
                              semanticsLabel: '관리자 계정으로 로그인하기',
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: AppTheme.spacing8),
                              _buildTestLoginButtons(),
                            ],
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

  Widget _buildTestLoginButtons() {
    return Wrap(
      spacing: AppTheme.spacing8,
      runSpacing: AppTheme.spacing8,
      alignment: WrapAlignment.center,
      children: [
        _buildTestLoginButton('TestUser1', 'mock_google_token_for_testuser1'),
        _buildTestLoginButton('TestUser2', 'mock_google_token_for_testuser2'),
        _buildTestLoginButton('TestUser3', 'mock_google_token_for_testuser3'),
      ],
    );
  }

  Widget _buildTestLoginButton(String label, String mockToken) {
    return OutlinedButton(
      onPressed: _isLoading ? null : () => _handleMockLogin(mockToken),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neutral700,
        side: const BorderSide(color: AppColors.neutral300),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
      ),
      child: Text(label, style: AppTheme.bodySmall),
    );
  }

  Future<void> _handleMockLogin(String mockToken) async {
    setState(() => _isLoading = true);
    try {
      final loginResponse = await ref
          .read(authProvider.notifier)
          .loginWithMockToken(mockToken);
      if (!mounted) return;
      await _handlePostLogin(loginResponse);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '테스트 로그인 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLogo() {
    return Container(
      width: AppComponents.logoSize,
      height: AppComponents.logoSize,
      decoration: BoxDecoration(
        color: AppColors.brand, // 학교 공식 퍼플 #5C068C
        borderRadius: BorderRadius.circular(AppComponents.logoRadius),
      ),
      child: const Icon(
        Icons.school_rounded,
        size: AppComponents.logoIconSize,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Text(
      '대학 그룹 관리',
      style: AppTheme.displaySmallTheme(
        context,
      ).copyWith(fontWeight: FontWeight.w700, color: AppColors.neutral900),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubcopy(BuildContext context) {
    return Text(
      '우리 학과 학생들을 위한 똑똑한 협업 공간',
      style: AppTheme.bodyMediumTheme(context).copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.neutral600,
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
          color: AppColors.neutral200,
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: AppComponents.infoIconSize,
              color: AppColors.brand,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Text(
                '개발 단계에서는 관리자 계정으로 테스트해보세요.',
                style: AppTheme.bodySmallTheme(
                  context,
                ).copyWith(color: AppColors.neutral600, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
