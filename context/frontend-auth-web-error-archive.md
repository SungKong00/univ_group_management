# 프론트엔드 에러 해결 아카이브 — 웹 인증 상태 이슈 (뒤로가기/새로고침/로그아웃)

## 문제 요약
- 웹에서 첫 로그인은 성공하나, 메인 화면에서 브라우저 뒤로가기, 새로고침, 또는 로그아웃 시 인증 상태가 깨지거나 화면이 반응하지 않음.
- `flutter clean` 후 재실행/재로그인해야 정상화되는 현상 발생.

## 증상
- 뒤로가기: 로그인 페이지로 이동하지만 즉시 인증 상태가 반영되지 않거나 홈으로 복귀하지 않음.
- 새로고침: 홈에 머물러야 하는데 인증이 해제된 것처럼 보이거나, 반대로 인증이 없는데 홈에 남는 경우 발생.
- 로그아웃: 버튼을 눌러도 UI에 변화가 없거나, 네트워크 대기 때문에 반응이 매우 느림.

## 원인 분석
1. Web 환경에서의 토큰 저장소 선택 문제
   - 기본 `flutter_secure_storage`는 웹/로컬 환경에서 제약이 있어 새로고침/히스토리 이동 후 토큰을 신뢰성 있게 읽지 못할 수 있음.
   - 결과적으로 `isLoggedIn()` 판단이 불안정해 인증 상태가 교란됨.

2. 초기 라우트가 로그인 화면으로 고정됨
   - `initialRoute: '/login'`로 시작해 Splash(인증 점검 로직)를 우회.
   - 뒤로가기/새로고침 시 인증 실체와 화면 라우팅이 쉽게 불일치.

3. 로그아웃 동작이 네트워크 응답에 종속
   - 서버 `/auth/logout` 호출을 기다린 뒤 상태를 변경하므로, CORS/네트워크 지연 시 "아무 반응 없음"으로 체감.

4. 라우트 가드 부재
   - 로그인 페이지에서 이미 인증된 사용자를 홈으로 보내지 않음.
   - 홈에서 인증이 해제된 경우 로그인으로 강제 리다이렉트하지 않음.

## 해결 사항 (코드 변경)
1. Web 전용 토큰 저장소 스위칭
   - `kIsWeb ? SharedPrefsTokenStorage() : SecureTokenStorage()`
   - 파일: `frontend/lib/injection/injection.dart`

2. 앱 진입점을 Splash로 변경하여 인증 상태 기반 라우팅 일원화
   - `initialRoute: '/'` (Splash)
   - 파일: `frontend/lib/main.dart`

3. 로그인/홈 양방향 가드 추가
   - 로그인 화면: 이미 인증된 경우 `'/home'`으로 즉시 리다이렉트
   - 홈 화면: 비인증 상태(그리고 로딩 아님)면 `'/login'`으로 리다이렉트
   - 파일: `frontend/lib/presentation/screens/auth/login_screen.dart`, `frontend/lib/presentation/screens/home/home_screen.dart`

4. 로그아웃 UX를 즉시형으로 개선
   - 로컬 세션(토큰/유저) 즉시 클리어 → 상태 `unauthenticated` 반영 → UI/라우팅 즉시 전환
   - 서버 로그아웃과 Google Sign-Out은 백그라운드에서 처리 (실패 무시)
   - 파일: `frontend/lib/presentation/providers/auth_provider.dart`

## 변경 파일 목록
- `frontend/lib/injection/injection.dart`
- `frontend/lib/main.dart`
- `frontend/lib/presentation/screens/auth/login_screen.dart`
- `frontend/lib/presentation/screens/home/home_screen.dart`
- `frontend/lib/presentation/providers/auth_provider.dart`

## 재현 방지 검증 체크리스트
1. `flutter run -d chrome` 실행
2. Google 로그인 완료 → 홈 진입 확인
3. 브라우저 뒤로가기 → 로그인으로 갔다가 즉시 홈 복귀 확인
4. 홈에서 새로고침 → 로그인 유지 시 홈에 머무름 / 미인증 시 로그인으로 이동
5. 로그아웃 클릭 → 즉시 로그인 화면으로 이동, 재로그인 가능 (네트워크 상태와 무관)

## 회귀 및 부작용 고려
- 웹 환경에서 보안 스토리지가 필요한 경우, HTTPS 및 `flutter_secure_storage`의 웹 옵션을 충분히 검토해야 함. 개발/로컬에서는 `SharedPreferences`가 신뢰성과 DX를 보장.
- 서버 로그아웃 실패 시에도 클라이언트는 로그아웃으로 간주함. 보안 정책상 서버 세션 무효화 보장이 필요하면 API 성공 여부를 별도 로깅/모니터링하거나 재시도 큐 도입 고려.

## 향후 개선 제안
- `go_router`로 전역 라우트 가드 통합 및 상태 기반 리다이렉트 일관화.
- 토큰 자동 갱신(401 처리) 로직 구현 및 공통 재시도 핸들러 도입.
- 에러/이벤트 로깅(예: Sentry)으로 웹 환경 특이 이슈 추적 강화.

