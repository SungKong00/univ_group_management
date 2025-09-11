# TASK

## 작업 목표
- [ ] 목표 요약: 회원가입 플로우 개선 - 역할선택 및 프로필설정 기능 구현
- [ ] 성공 기준: Google OAuth 후 역할선택 → 프로필설정 플로우 완성, 테스트 통과

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: auth, user-profile, signup-flow, role-selection
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend, frontend/lib
- 참고 문서: context/feature-specifications.md, context/database-design.md, context/frontend-architecture.md

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-11 18:30 [Claude] 작업 패키지 생성 및 컨텍스트 분석 완료.
- 2025-09-11 18:35 [Claude] 백엔드 User 엔티티 확장 완료 (nickname, profileImageUrl, bio, profileCompleted, emailVerified 필드 추가)
- 2025-09-11 18:37 [Claude] UserService 업데이트 완료 (convertToUserResponse, completeProfile 메서드 추가)
- 2025-09-11 18:40 [Claude] UserController 생성 완료 (프로필 완성, 내 정보 조회 API 구현)
- 2025-09-11 18:45 [Claude] 프론트엔드 UserModel 업데이트 완료 (새 필드 추가, refreshToken 제거)
- 2025-09-11 18:50 [Claude] RoleSelectionScreen 구현 완료 (학생/교수 역할 선택 UI)
- 2025-09-11 18:55 [Claude] ProfileSetupScreen 구현 완료 (닉네임, 프로필사진, 자기소개 입력)
- 2025-09-11 19:00 [Claude] 라우팅 시스템 업데이트 완료 (새 화면들 연결)
- 2025-09-11 19:05 [Claude] AuthService, Repository, Provider 프로필 완성 기능 추가
- 2025-09-11 19:10 [Claude] 회원가입 플로우 통합 완료 (Google OAuth → 역할선택 → 프로필설정)

## 변경 사항 요약
- 생성/수정 파일:
  ### 백엔드 (Kotlin)
  - backend/src/main/kotlin/org/castlekong/backend/entity/User.kt (수정) - 새 필드 추가
  - backend/src/main/kotlin/org/castlekong/backend/dto/AuthDto.kt (수정) - UserResponse, ProfileUpdateRequest 추가
  - backend/src/main/kotlin/org/castlekong/backend/service/UserService.kt (수정) - completeProfile 메서드 추가
  - backend/src/main/kotlin/org/castlekong/backend/controller/UserController.kt (신규) - 프로필 완성 API
  
  ### 프론트엔드 (Dart)
  - frontend/lib/data/models/user_model.dart (수정) - 새 필드, ProfileUpdateRequest 추가
  - frontend/lib/presentation/screens/auth/role_selection_screen.dart (신규) - 역할 선택 화면
  - frontend/lib/presentation/screens/auth/profile_setup_screen.dart (신규) - 프로필 설정 화면
  - frontend/lib/main.dart (수정) - 새 라우트 추가
  - frontend/lib/presentation/screens/auth/login_screen.dart (수정) - 회원가입 플로우 연결
  - frontend/lib/data/services/auth_service.dart (수정) - completeProfile API 추가
  - frontend/lib/domain/repositories/auth_repository.dart (수정) - 추상 메서드 추가
  - frontend/lib/data/repositories/auth_repository_impl.dart (수정) - completeProfile 구현
  - frontend/lib/presentation/providers/auth_provider.dart (수정) - completeProfile 상태관리

- 핵심 로직:
  - Google OAuth 후 역할 선택 → 프로필 설정 플로우 완성
  - User 엔티티 확장 (nickname, profileImageUrl, bio, profileCompleted, emailVerified)
  - 프로필 완성 API 및 상태 관리 시스템 구현
  - 회원가입 단계별 라우팅 시스템 완성
  - 교수 선택 시 승인 필요 안내 UI 포함

## 컨텍스트 업데이트 요청
- context/feature-specifications.md 업데이트:
  - "1. Sign-up / Login" 섹션에 역할 선택 및 프로필 설정 단계 추가
  - 구현 완료된 회원가입 플로우 반영 (Google OAuth → 역할선택 → 프로필설정)
  
- context/database-design.md 업데이트:
  - User 엔티티 스키마에 새 필드들 반영 (nickname, profileImageUrl, bio, profileCompleted, emailVerified)
  - 실제 구현된 컬럼 정보로 업데이트
  
- context/frontend-architecture.md 업데이트:
  - 새로운 화면들 추가 (RoleSelectionScreen, ProfileSetupScreen)
  - 회원가입 플로우 아키텍처 업데이트
  - 프로필 완성 API 연동 정보 추가
  
- .gemini/metadata.json 업데이트:
  - recent_tasks에 현재 작업 추가
  - last_updated 갱신
  - user-profile, signup-flow, role-selection 태그 추가

