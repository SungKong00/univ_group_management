# TASK

## 작업 목표
- [x] 목표 요약: 그룹/워크스페이스 백엔드 엔티티 구현 및 확장
- [x] 성공 기준: 완전한 그룹/워크스페이스 엔티티 모델 구현 완료

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: entity, jpa, group, workspace, channel, permission
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend/entity
- 참고 문서: context/architecture-overview.md

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-12 09:00 [Claude] 작업 패키지 생성 및 컨텍스트 분석 완료
- 2025-09-12 09:05 [Claude] 기존 그룹 엔티티 구조 분석 완료
- 2025-09-12 09:10 [Claude] Group 엔티티 확장 (description, profileImageUrl, owner, visibility, isRecruiting, maxMembers, tags, timestamps)
- 2025-09-12 09:15 [Claude] Channel 엔티티 생성 (채널 타입, 프라이빗 채널, 표시 순서)
- 2025-09-12 09:20 [Claude] Post 엔티티 생성 (게시글 타입, 첨부파일, 조회수, 좋아요)
- 2025-09-12 09:25 [Claude] Comment 엔티티 생성 (대댓글 지원, 좋아요)
- 2025-09-12 09:30 [Claude] GroupInvite 엔티티 생성 (초대 코드, 만료시간, 상태)
- 2025-09-12 09:35 [Claude] GroupPermission 확장 (채널, 게시글, 댓글, 파일 관련 권한 추가)

## 변경 사항 요약
- 생성/수정 파일:
  - backend/src/main/kotlin/.../entity/Group.kt (수정)
  - backend/src/main/kotlin/.../entity/Channel.kt (신규)
  - backend/src/main/kotlin/.../entity/Post.kt (신규)
  - backend/src/main/kotlin/.../entity/Comment.kt (신규)
  - backend/src/main/kotlin/.../entity/GroupInvite.kt (신규)
  - backend/src/main/kotlin/.../entity/GroupPermission.kt (수정)
- 핵심 로직:
  - 그룹 프로필, 가시성, 모집 상태, 태그 시스템
  - 채널 기반 워크스페이스 구조
  - 게시글/댓글 시스템 with 대댓글 지원
  - 초대 코드 기반 그룹 초대 시스템
  - 세분화된 권한 체계 (37개 권한)

## 컨텍스트 업데이트 요청
- context/database-schema.md에 새로운 엔티티 스키마 추가 요청
- context/permission-system.md에 확장된 권한 체계 문서화 요청
- metadata.json에 group, channel, workspace 관련 태그 추가 요청

