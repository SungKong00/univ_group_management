# Frontend Maintenance Guide

이 문서는 인증/라우팅/프로필 관련 프런트엔드 유지보수 시 주의사항과 공통 패턴을 정리합니다.

## 1) 라우팅 가드와 네비게이션 레이스 방지
- Splash(`/`)에서만 최초 인증 판별을 수행하고, 상태 변화 리스너는 네비게이션 직후 제거합니다.
- 네비게이션은 다음 프레임에서 실행하세요:
  - `SchedulerBinding.instance.addPostFrameCallback((_) { /* Navigator... */ });`
- 로그인/회원가입 화면에서 `isAuthenticated`일 때는 `currentUser.profileCompleted`로 분기:
  - `false` → `'/role-selection'`
  - `true` → `'/home'`
- 스택 충돌/중복 콜 백 방지를 위해 `Navigator.pushNamedAndRemoveUntil(context, route, (r) => false)`를 우선 사용합니다.

## 2) 엔드포인트와 `baseUrl` 결합 규칙
- 항상 `ApiEndpoints` 상수를 사용하고 상대 경로(`/users/profile`)만 기입합니다.
- `DioClient`의 `BaseOptions.baseUrl`은 `http://<host>:<port>/api` 형태를 유지합니다.
- 플랫폼별 로컬 백엔드 접속:
  - Web/iOS 시뮬레이터: `http://localhost:8080/api`
  - Android 에뮬레이터: `http://10.0.2.2:8080/api`
  - 물리 디바이스: 동일 네트워크 호스트 IP (예: `http://192.168.x.x:8080/api`)

## 3) 토큰 저장 및 인터셉터
- Web: `SharedPrefsTokenStorage`, Mobile: `SecureTokenStorage` 사용 (DI로 자동 선택)
- 모든 요청은 인터셉터에서 `Authorization: Bearer <token>` 자동 주입
- 401 처리 및 토큰 갱신 로직은 추후 `Dio` 인터셉터 레벨에서 구현 예정

## 4) 프로필 완성 및 닉네임 표시 규칙
- 프로필 완성 API: `PUT /api/users/profile`
- 홈 화면 인사말/아바타 규칙:
  - 인사말: `nickname` 존재 시 닉네임, 없으면 `name`, 최종 폴백 `'사용자'`
  - 아바타 이니셜: `nickname[0]` → `name[0]` → `'U'`, 모두 대문자 변환

## 5) 디버깅 팁
- `DioClient` 인터셉터 로그로 경로/헤더/바디를 즉시 확인
- Splash/로그인에서 상태 전이 로그(`AuthState`)를 남겨 레이스 여부 판단
- 문제 발생 시 레이어별(서비스/레포/프로바이더)로 로그를 최소 1개씩 남기되, 프로덕션에서는 로그 레벨 제어

## 6) 체크리스트 (새 기능/수정 배포 전)
- [ ] 엔드포인트 상수 사용 여부 확인
- [ ] `pushNamedAndRemoveUntil`로 네비게이션 스택 정리 검토
- [ ] `profileCompleted` 기반 분기 누락 여부 확인
- [ ] `baseUrl` 환경(웹/에뮬레이터/실기기) 문서화 및 설정 반영
- [ ] 사용자 표시(닉네임/이름) 폴백 로직 일관성 확인

