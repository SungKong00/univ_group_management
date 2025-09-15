# TASK

## 작업 목표
- [x] 목표 요약: 그룹과 워크스페이스 백엔드 구현 - 엔티티 후 다음 단계 (Service, Controller, DTO, 테스트)
- [x] 성공 기준: 통합 테스트 통과, 컴파일 성공

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: group, workspace, service, controller, dto, test
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend
- 참고 문서: context/architecture-overview.md, SYNTHESIZED_CONTEXT.MD

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-12 09:30 [Claude] 초기 세팅 완료 및 컨텍스트 분석
- 2025-09-12 09:32 [Claude] GroupDto, GroupService, GroupRoleService 구현 완료
- 2025-09-12 09:34 [Claude] ErrorCode, BusinessException, GlobalExceptionHandler 구현 완료
- 2025-09-12 09:36 [Claude] GroupController, ApiResponse 구현 완료
- 2025-09-12 09:37 [Claude] 컴파일 오류 해결 (GroupRole priority 필드, GroupPermission 열거형 확장)
- 2025-09-12 09:38 [Claude] GroupServiceIntegrationTest 작성 및 테스트 통과 확인

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/kotlin/org/castlekong/backend/dto/GroupDto.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/dto/ApiResponse.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/service/GroupService.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/service/GroupRoleService.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/controller/GroupController.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/exception/ErrorCode.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/exception/BusinessException.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/exception/GlobalExceptionHandler.kt (신규)
  - backend/src/main/kotlin/org/castlekong/backend/entity/GroupRole.kt (priority 필드 추가)
  - backend/src/main/kotlin/org/castlekong/backend/entity/GroupPermission.kt (MEMBER_READ, ROLE_READ, POST_READ, COMMENT_CREATE, COMMENT_READ 추가)
  - backend/src/main/kotlin/org/castlekong/backend/repository/GroupRepositories.kt (추가 메서드들)
  - backend/src/main/kotlin/org/castlekong/backend/controller/UserController.kt (ApiResponse 형식 수정)
  - backend/src/test/kotlin/org/castlekong/backend/service/GroupServiceIntegrationTest.kt (신규)

- 핵심 로직:
  - 그룹 CRUD 연산 (생성, 조회, 수정, 삭제)
  - 그룹 가입/탈퇴 기능
  - 그룹 멤버 조회
  - 그룹 역할 관리 (생성, 조회, 수정, 삭제)
  - 권한 기반 접근 제어 (@PreAuthorize)
  - 표준 API 응답 형식 (ApiResponse wrapper)
  - 전역 예외 처리
  - 통합 테스트 (8개 테스트 케이스)

## 컨텍스트 업데이트 요청
- context/api-conventions.md에 새로운 Group API 엔드포인트 목록 추가 요청
- context/architecture-overview.md에 Group 서비스 계층 구현 완료 상태 업데이트 요청
- metadata.json에 group, workspace 관련 구현 완료 상태 반영 요청
- context/troubleshooting.md에 GroupPermission 열거형 확장 및 GroupRole priority 필드 추가 이슈 해결 방법 추가 요청

