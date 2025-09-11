import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_button.dart';
import '../../widgets/common_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            message: '회원가입 중...',
            child: SafeArea(
              child: Padding(
                padding: AppStyles.paddingL,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppStyles.spacingL),

                              // 제목
                              Text(
                                '계정 만들기',
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppStyles.spacingS),
                              Text(
                                '그룹 관리를 시작하기 위해\n기본 정보를 입력해주세요',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppStyles.spacingXL),

                              // 이름 입력
                              CommonTextField(
                                label: '이름',
                                hint: '이름을 입력해주세요',
                                controller: _nameController,
                                prefixIcon: Icons.person_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력해주세요';
                                  }
                                  if (value.length < 2) {
                                    return '이름은 2자 이상 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppStyles.spacingL),

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
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(value)) {
                                    return '비밀번호는 대소문자, 숫자, 특수문자를 포함한 8자 이상이어야 합니다';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppStyles.spacingM),

                              // 비밀번호 규칙 안내
                              Container(
                                padding: AppStyles.paddingM,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: AppStyles.radiusM,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '비밀번호 조건:',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: AppStyles.spacingXS),
                                    ...const [
                                      '• 8자 이상',
                                      '• 대문자 포함',
                                      '• 소문자 포함',
                                      '• 숫자 포함',
                                      '• 특수문자 포함 (@\$!%*?&)',
                                    ].map((rule) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            rule,
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppStyles.spacingL),

                              // 비밀번호 확인 입력
                              CommonTextField(
                                label: '비밀번호 확인',
                                hint: '비밀번호를 다시 입력해주세요',
                                controller: _confirmPasswordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '비밀번호를 다시 입력해주세요';
                                  }
                                  if (value != _passwordController.text) {
                                    return '비밀번호가 일치하지 않습니다';
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

                              // 회원가입 버튼
                              CommonButton(
                                text: '회원가입',
                                onPressed: _handleRegister,
                                width: double.infinity,
                                height: 56,
                              ),
                              const SizedBox(height: AppStyles.spacingL),

                              // 로그인 링크
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '이미 계정이 있나요? ',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  CommonButton(
                                    text: '로그인',
                                    type: ButtonType.text,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
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

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      authProvider.clearError();

      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null && !user.profileCompleted) {
          // 신규 사용자: 역할 선택부터 진행
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/role-selection',
            (route) => false,
          );
        } else {
          // 프로필 완료 사용자: 홈으로 이동
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      }
    }
  }
}
