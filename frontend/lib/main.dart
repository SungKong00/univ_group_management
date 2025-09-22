import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'domain/repositories/auth_repository.dart';
import 'data/services/workspace_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/group_provider.dart';
import 'presentation/providers/group_tree_provider.dart';
import 'presentation/providers/group_membership_provider.dart';
import 'presentation/providers/group_subgroups_provider.dart';
import 'presentation/providers/nav_provider.dart';
import 'presentation/providers/workspace_provider.dart';
import 'presentation/providers/channel_provider.dart';
import 'presentation/providers/ui_state_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main/main_nav_scaffold.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(locator<AuthRepository>())..check()),
        ChangeNotifierProvider(create: (_) => GroupProvider(
          locator<GroupTreeProvider>(),
          locator<GroupMembershipProvider>(),
          locator<GroupSubgroupsProvider>(),
        )),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider(locator<WorkspaceService>())),
        ChangeNotifierProvider(create: (_) => ChannelProvider(locator<WorkspaceService>())),
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
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
