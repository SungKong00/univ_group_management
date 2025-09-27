# 프론트엔드 구현 가이드 (Frontend Implementation Guide)

## 아키텍처 개요

### 현재 (Flutter) + 미래 (React)
```
Flutter (Mobile + Web) → React (Web 전용)
├── Provider 패턴 → Redux/Zustand
├── GetIt DI → React Context
└── Dio HTTP Client → Axios
```

## Flutter 아키텍처 (현재)

### 디렉토리 구조
```
lib/
├── core/
│   ├── di/              # 의존성 주입 (GetIt)
│   ├── http/            # HTTP 클라이언트 (Dio)
│   └── constants/       # 상수 정의
├── models/              # 데이터 모델
├── providers/           # 상태 관리 (Provider)
├── services/            # 비즈니스 로직
├── repositories/        # 데이터 레이어
├── screens/             # 화면 위젯
├── widgets/             # 재사용 컴포넌트
└── utils/               # 유틸리티 함수
```

### 상태 관리 패턴 (Provider)
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> login(String idToken) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.googleLogin(idToken);
      _user = response.user;
      await _secureStorage.write(key: 'token', value: response.accessToken);
    } catch (e) {
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### HTTP 클라이언트 (Dio)
```dart
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ));

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path);
      return ApiResponse.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
```

### 반응형 레이아웃
```dart
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveBuilder({
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 900) {
      return mobile;
    } else {
      return desktop;
    }
  }
}

// 사용 예시
ResponsiveBuilder(
  mobile: MobileWorkspaceLayout(),
  desktop: DesktopWorkspaceLayout(),
)
```

## React 아키텍처 (미래)

### 디렉토리 구조
```
src/
├── components/          # 재사용 컴포넌트
├── pages/              # 페이지 컴포넌트
├── hooks/              # 커스텀 훅
├── services/           # API 서비스
├── store/              # 상태 관리 (Redux/Zustand)
├── types/              # TypeScript 타입 정의
├── utils/              # 유틸리티 함수
└── styles/             # 스타일 파일
```

### 상태 관리 (Zustand)
```typescript
interface AuthState {
  user: User | null;
  isLoading: boolean;
  login: (idToken: string) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  isLoading: false,

  login: async (idToken: string) => {
    set({ isLoading: true });
    try {
      const response = await authService.googleLogin(idToken);
      set({ user: response.user });
      localStorage.setItem('token', response.accessToken);
    } finally {
      set({ isLoading: false });
    }
  },

  logout: () => {
    set({ user: null });
    localStorage.removeItem('token');
  },
}));
```

### HTTP 클라이언트 (Axios)
```typescript
class ApiClient {
  private axios: AxiosInstance;

  constructor() {
    this.axios = axios.create({
      baseURL: 'http://localhost:8080/api',
      timeout: 5000,
    });

    this.axios.interceptors.request.use(this.addAuthHeader);
    this.axios.interceptors.response.use(
      response => response,
      this.handleError
    );
  }

  async get<T>(url: string): Promise<ApiResponse<T>> {
    const response = await this.axios.get<ApiResponse<T>>(url);
    return response.data;
  }

  private addAuthHeader = (config: AxiosRequestConfig) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  };
}
```

### 커스텀 훅
```typescript
export function usePermission(groupId: number, permission: string) {
  const [hasPermission, setHasPermission] = useState(false);

  useEffect(() => {
    const checkPermission = async () => {
      try {
        const result = await permissionService.hasPermission(groupId, permission);
        setHasPermission(result);
      } catch (error) {
        setHasPermission(false);
      }
    };

    checkPermission();
  }, [groupId, permission]);

  return hasPermission;
}

// 사용 예시
function GroupManageButton({ groupId }: { groupId: number }) {
  const canManage = usePermission(groupId, 'GROUP_MANAGE');

  if (!canManage) return null;

  return <button>그룹 관리</button>;
}
```

## 공통 패턴

### 권한 기반 컴포넌트 렌더링

#### Flutter
```dart
class PermissionBuilder extends StatelessWidget {
  final String permission;
  final int groupId;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: context.read<PermissionProvider>().hasPermission(groupId, permission),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return child;
        }
        return fallback ?? SizedBox.shrink();
      },
    );
  }
}
```

#### React
```typescript
interface PermissionGuardProps {
  permission: string;
  groupId: number;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

function PermissionGuard({ permission, groupId, children, fallback }: PermissionGuardProps) {
  const hasPermission = usePermission(groupId, permission);

  if (!hasPermission) {
    return fallback || null;
  }

  return <>{children}</>;
}
```

### API 에러 처리

#### Flutter
```dart
class ApiException implements Exception {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  factory ApiException.fromDioError(DioException error) {
    if (error.response?.statusCode == 403) {
      return ApiException('PERMISSION_DENIED', '권한이 없습니다');
    }
    return ApiException('UNKNOWN_ERROR', '알 수 없는 오류가 발생했습니다');
  }
}

// 사용
try {
  await groupService.createGroup(request);
} on ApiException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
}
```

#### React
```typescript
class ApiError extends Error {
  constructor(public code: string, message: string) {
    super(message);
  }

  static fromAxiosError(error: AxiosError): ApiError {
    if (error.response?.status === 403) {
      return new ApiError('PERMISSION_DENIED', '권한이 없습니다');
    }
    return new ApiError('UNKNOWN_ERROR', '알 수 없는 오류가 발생했습니다');
  }
}

// 사용 (with react-query)
const { mutate: createGroup } = useMutation({
  mutationFn: groupService.createGroup,
  onError: (error: ApiError) => {
    toast.error(error.message);
  },
});
```

## 라우팅

### Flutter (go_router)
```dart
final router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    final isProfileCompleted = context.read<AuthProvider>().user?.profileCompleted ?? false;

    if (!isAuthenticated) return '/login';
    if (!isProfileCompleted) return '/profile-setup';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(
      path: '/workspace/:id',
      builder: (context, state) => WorkspaceScreen(
        groupId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
```

### React (react-router)
```typescript
function App() {
  const { user } = useAuthStore();

  return (
    <Router>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={
          <ProtectedRoute>
            <HomePage />
          </ProtectedRoute>
        } />
        <Route path="/workspace/:id" element={
          <ProtectedRoute>
            <WorkspacePage />
          </ProtectedRoute>
        } />
      </Routes>
    </Router>
  );
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuthStore();

  if (!user) return <Navigate to="/login" />;
  if (!user.profileCompleted) return <Navigate to="/profile-setup" />;

  return <>{children}</>;
}
```

## 성능 최적화

### Flutter
```dart
// 메모이제이션
class GroupListItem extends StatelessWidget {
  final Group group;

  const GroupListItem({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, child) {
        // child는 변경되지 않는 부분을 캐시
        return ListTile(
          title: Text(group.name),
          trailing: child,
        );
      },
      child: Icon(Icons.arrow_forward), // 캐시됨
    );
  }
}
```

### React
```typescript
// React.memo로 불필요한 리렌더링 방지
const GroupListItem = React.memo(({ group }: { group: Group }) => {
  const handleClick = useCallback(() => {
    navigate(`/workspace/${group.id}`);
  }, [group.id, navigate]);

  return (
    <div onClick={handleClick}>
      <h3>{group.name}</h3>
      <p>{group.description}</p>
    </div>
  );
});

// useMemo로 비싼 계산 캐시
function GroupList({ groups }: { groups: Group[] }) {
  const sortedGroups = useMemo(() => {
    return groups.sort((a, b) => a.name.localeCompare(b.name));
  }, [groups]);

  return (
    <div>
      {sortedGroups.map(group => (
        <GroupListItem key={group.id} group={group} />
      ))}
    </div>
  );
}
```

## 관련 문서

### UI/UX 설계
- **디자인 시스템**: [../ui-ux/design-system.md](../ui-ux/design-system.md)
- **레이아웃 가이드**: [../ui-ux/layout-guide.md](../ui-ux/layout-guide.md)
- **컴포넌트 가이드**: [../ui-ux/component-guide.md](../ui-ux/component-guide.md)

### 백엔드 연동
- **API 참조**: [api-reference.md](api-reference.md)
- **백엔드 가이드**: [backend-guide.md](backend-guide.md)

### 개념 참조
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **워크스페이스**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)