import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_button.dart';
import '../../widgets/common_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
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
                          child: Form(
                            key: _formKey,
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

                                // 이메일 입력
                                CommonTextField(
                                  label: '이메일',
                                  hint: '이메일을 입력해주세요',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '이메일을 입력해주세요';
                                    }
                                    if (!value.contains('@')) {
                                      return '올바른 이메일 형식을 입력해주세요';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppStyles.spacingL),

                                // 비밀번호 입력
                                CommonTextField(
                                  label: '비밀번호',
                                  hint: '비밀번호를 입력해주세요',
                                  controller: _passwordController,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '비밀번호를 입력해주세요';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppStyles.spacingXL),

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

                                // 로그인 버튼
                                CommonButton(
                                  text: '로그인',
                                  onPressed: _handleLogin,
                                  width: double.infinity,
                                  height: 56,
                                ),
                                const SizedBox(height: AppStyles.spacingL),

                                // 회원가입 링크
                                CommonButton(
                                  text: '회원가입',
                                  type: ButtonType.text,
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                                ),
                              ],
                            ),
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

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      authProvider.clearError();

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}