import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'injection/injection.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/webview/webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 의존성 주입 설정
  await setupDependencyInjection();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => getIt<AuthProvider>()..checkAuthStatus(),
        ),
      ],
      child: MaterialApp(
        title: '대학 그룹 관리',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        // 항상 Splash에서 인증 상태를 판별하여 라우팅
        initialRoute: '/',
        routes: {
          '/webview': (context) => const WebViewScreen(),
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VoidCallback? _authListener;
  
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    if (_authListener != null) {
      final authProvider = context.read<AuthProvider>();
      authProvider.removeListener(_authListener!);
    }
    super.dispose();
  }

  void _checkAuthStatus() {
    // AuthProvider의 checkAuthStatus가 완료되기를 기다림
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      
      // AuthProvider 상태 변화 감지
      _authListener = () {
        if (authProvider.state != AuthState.loading) {
          if (mounted) {
            if (authProvider.isAuthenticated) {
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        }
      };
      authProvider.addListener(_authListener!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고 또는 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.groups,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '대학 그룹 관리',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '함께 만들어가는 대학 생활',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
