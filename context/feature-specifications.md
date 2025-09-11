# Application Feature Specifications

**⚠️ 현재 구현 상태**: 대부분의 기능이 미구현 상태입니다. 이 문서는 실제 구현 상태를 반영하여 업데이트되었습니다.

이 문서는 프로젝트의 계획된 기능 명세와 현재 구현 상태를 포함합니다.

---

## 1. Sign-up / Login (후햄드 구현 완료) ✅

### 1.1. Frontend + Backend 완전 구현됨

**✅ 완료된 기능:**
- **Google OAuth2 인증**: ID Token과 Access Token 모두 지원
- **사용자 자동 생성**: 백엔드에서 사용자 자동 생성/조회
- **JWT 기반 인증 시스템**: 완전한 end-to-end 구현
- **토큰 저장 및 관리**: Flutter Secure Storage 사용
- **자동 인증 상태 관리**: AuthProvider로 상태 관리
- **HTTP 인터셉터**: 자동 Authorization 헤더 주입
- **라우팅 가드**: 인증 상태 기반 화면 이동

### 1.2. 완전히 구현된 사용자 플로우 ✅

**신규 사용자 회원가입 플로우 (완전 구현됨):**
```
1. 사용자 -> Google Sign-In 버튼 클릭
2. GoogleSignInService -> Google OAuth 팝업 표시
3. Google OAuth -> ID Token/Access Token 반환
4. AuthService -> 백엔드 API 호출 (/api/auth/google)
5. Backend -> Google 토큰 검증 및 사용자 생성/조회
6. Backend -> JWT Access Token 반환 (profileCompleted: false)
7. TokenStorage -> JWT 암호화 저장
8. AuthProvider -> 인증 상태 업데이트
9. SplashScreen -> profileCompleted 확인 후 /role-selection으로 라우팅
10. 사용자 -> 역할 선택 (학생/교수)
11. Navigator -> ProfileSetupScreen으로 이동
12. 사용자 -> 닉네임, 프로필사진, 자기소개 입력
13. AuthService -> 프로필 완성 API 호출 (PUT /api/users/profile)
14. Backend -> 프로필 정보 업데이트 (profileCompleted: true)
15. Navigator -> HomeScreen으로 이동
```

**기존 사용자 로그인 플로우 (완전 구현됨):**
```
1-8. 위와 동일
9. SplashScreen -> profileCompleted가 true인 경우 /home으로 직접 라우팅
10. Navigator -> HomeScreen으로 직접 이동
```

### 1.3. 기술적 구현 상세

**Frontend 컴포넌트:**
- `GoogleSignInService`: Google OAuth SDK 래핑
- `AuthService`: HTTP 통신 서비스 (프로필 완성 API 포함)
- `AuthProvider`: 인증 상태 관리 (ChangeNotifier)
- `AuthRepository`: 비즈니스 로직 레이어 (프로필 완성 기능 포함)
- `TokenStorage`: Secure Storage 추상화
- `RoleSelectionScreen`: 학생/교수 역할 선택 화면
- `ProfileSetupScreen`: 닉네임, 프로필사진, 자기소개 입력 화면

**Error Handling:**
- Google OAuth 오류 처리
- 네트워크 오류 처리
- 토큰 만료/무효 처리
- 사용자 치화 오류 메시지

**✅ 추가로 구현된 기능:**
- **역할 선택 UI**: 학생/교수 선택 화면 구현
- **프로필 설정 화면**: 닉네임, 프로필사진, 자기소개 입력
- **단계별 회원가입 플로우**: Google OAuth → 역할선택 → 프로필설정
- **User 엔티티 확장**: nickname, profileImageUrl, bio, profileCompleted, emailVerified 필드 추가
- **프로필 완성 API**: 백엔드 API 및 프론트엔드 연동 완료

**❌ 여전히 미구현:**
- 학교 이메일 인증
- 교수 승인 프로세스

---

## 2. Group / Workspace Management (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- **2.1. Overview:** 사용자가 커뮤니티(그룹)를 형성하고 전용 협업 공간(워크스페이스)을 운영
- **2.2. Roles & Permissions:**
    - **System Admin:** 최상위 그룹 생성 및 그룹 리더 부재 시 개입
    - **Group Leader (Student Rep):** 하위그룹 생성/멤버 가입 승인/거부, 지도교수 임명/해제, 리더십 위임, 그룹 삭제
    - **Supervising Professor (Faculty):** 그룹 리더가 임명, 그룹 리더와 동일한 권한 (다른 리더/교수 관리 제외)
    - **Group Member:** 그룹 내 일반 사용자
    - **General User:** 그룹 검색 및 가입 신청 가능

**미구현 사유:**
- Group, Member, Role, Permission 등 관련 엔티티가 모두 미구현
- 그룹 관리 API 전체 미구현
- 권한 시스템 미구현

---

## 3. Permissions / Member Management (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 역할 기반 권한 시스템
- 커스텀 역할 생성 및 권한 할당
- 멤버 관리 화면

**미구현 사유:**
- Role, Permission, RolePermission 엔티티 미구현
- 권한 검증 시스템 미구현
- 멤버 관리 UI 미구현

---

## 4. Promotion / Recruitment (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 전용 모집 게시판
- 모집 공고 작성, 수정, 삭제
- 태그 기반 검색
- 자동 마감 처리

**미구현 사유:**
- RecruitmentPost, Tag, PostTag 엔티티 미구현
- 모집 관련 API 전체 미구현
- 모집 게시판 UI 미구현

---

## 5. Posts / Comments (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 실시간 채팅 형태의 게시글/댓글 시스템
- 단일 레벨 댓글 (대댓글 없음)
- 게시글/댓글 CRUD

**미구현 사유:**
- Channel, Post, Comment 엔티티 미구현
- 게시글/댓글 관련 API 전체 미구현
- 실시간 채팅 UI 미구현

---

## 6. Notification System (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 구조화된 알림 시스템
- 90일 자동 삭제 정책
- 실시간 알림 UI
- 그룹 가입/역할 변경 알림

**미구현 사유:**
- Notification 엔티티 미구현
- 알림 관련 API 전체 미구현
- 알림 UI 미구현

---

## 7. Admin Page (미구현) ❌

**⚠️ 전체 기능이 미구현 상태입니다.**

**계획된 기능:**
- 권한 기반 관리자 페이지
- 멤버/역할/채널 관리
- 아이콘 기반 UI

**미구현 사유:**
- 관리자 권한 시스템 미구현
- 관리 기능 API 전체 미구현
- 관리자 UI 미구현

---

## 8. User Profile & Account Management (부분 구현) ⚠️

**✅ 구현 완료된 기능:**
- **프로필 초기 설정**: 회원가입 시 닉네임, 프로필사진, 자기소개 입력
- **User 엔티티 확장**: nickname, profileImageUrl, bio, profileCompleted, emailVerified 필드 추가
- **프로필 완성 API**: `PUT /api/users/profile` 엔드포인트 구현 (프론트엔드와 연동 완료)

### 1.4. UI 표시 규칙 업데이트 (닉네임)
- 홈 화면 상단 인사말은 사용자 `nickname`이 존재하면 닉네임을 우선 표시하고, 없으면 `name`으로 폴백합니다.
- 아바타 이니셜도 동일한 규칙을 따릅니다: `nickname[0]` → 없을 때 `name[0]` → 최종 폴백 `U`.
- **내 정보 조회 API**: `/api/users/me` 엔드포인트 구현
- **프로필 완성 상태 관리**: profileCompleted 플래그를 통한 회원가입 플로우 제어

**❌ 여전히 미구현:**
- 마이페이지 (프로필 조회/편집 화면)
- 프로필 편집 기능 (가입 후 수정)
- 서비스 탈퇴
- 계정 설정
- 프로필 이미지 업로드 기능 (현재는 URL만 저장)

**현재 구현된 것:**
- 확장된 사용자 정보 (id, name, email, nickname, profileImageUrl, bio, globalRole, profileCompleted, emailVerified, isActive, createdAt, updatedAt) 저장
- 회원가입 시 프로필 완성 플로우
