import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school,
                    size: 64,
                    color: AppTheme.brandPrimary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '대학 그룹 관리',
                    style: AppTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '대학 내 그룹과 소통하세요',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement Google Sign In
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Google로 로그인'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}