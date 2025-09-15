import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/token_storage.dart';
import 'core/network/dio_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/group_repository_impl.dart';
import 'data/services/auth_service.dart';
import 'data/services/workspace_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/group_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/group_provider.dart';
import 'presentation/providers/nav_provider.dart';
import 'presentation/providers/workspace_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main/main_nav_scaffold.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Manual DI wiring
  final TokenStorage storage = SharedPrefsTokenStorage();
  final DioClient apiClient = DioClient(storage); // Use DioClient directly
  final authService = AuthService(apiClient);
  final workspaceService = WorkspaceService(apiClient);
  final AuthRepository authRepo = AuthRepositoryImpl(authService, storage);
  final GroupRepository groupRepo = GroupRepositoryImpl(apiClient);

  runApp(MyApp(
    authRepo: authRepo,
    groupRepo: groupRepo,
    workspaceService: workspaceService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepo;
  final GroupRepository groupRepo;
  final WorkspaceService workspaceService;

  const MyApp({
    super.key,
    required this.authRepo,
    required this.groupRepo,
    required this.workspaceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)..check()),
        ChangeNotifierProvider(create: (_) => GroupProvider(groupRepo)),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider(workspaceService)),
      ],
      child: MaterialApp(
        title: '대학 그룹 관리',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          // Main bottom navigation scaffold (web + mobile)
          '/home': (context) => const MainNavScaffold(),
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
  AuthProvider? _authProvider;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _authListener = () {
        if (!mounted) return;
        switch (_authProvider!.state) {
          case AuthState.authenticated:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case AuthState.unauthenticated:
            Navigator.pushReplacementNamed(context, '/login');
            break;
          case AuthState.needsOnboarding:
            Navigator.pushReplacementNamed(context, '/register');
            break;
          default:
            break;
        }
      };
      _authProvider!.addListener(_authListener!);
    });
  }

  @override
  void dispose() {
    if (_authProvider != null && _authListener != null) {
      _authProvider!.removeListener(_authListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
