# TASK

## 작업 목표
- [x] 목표 요약: 문서 기반 그룹 엔티티 정리 및 임의 구현 내용 제거
- [x] 성공 기준: 문서에 정의된 엔티티만 유지, 임의 추가 내용 제거 완료

## 컨텍스트 요청 (태그, 파일, 영역)
- 태그: entity, cleanup, group, channel, post, comment
- 관련 소스/디렉토리: backend/src/main/kotlin/org/castlekong/backend/entity
- 참고 문서: context/database-schema.md

## 개발 지시 (Claude Code용)
- SYNTHESIZED_CONTEXT.MD를 먼저 읽고 구현 순서를 제안하세요.
- 생성/수정 파일 목록을 제안한 뒤 합의된 순서대로 구현하세요.
- 모든 변경은 본 작업 폴더의 '작업 로그'에 요약을 남기세요.
- 실패/에러는 로그와 함께 Codex 호출을 요청하세요.

## 작업 로그
- 2025-09-12 09:45 [Claude] 문서 분석 완료 - 미구현 상태의 엔티티들 확인
- 2025-09-12 09:50 [Claude] GroupInvite 엔티티 삭제 (문서에 없음, JoinRequest만 계획됨)
- 2025-09-12 09:55 [Claude] GroupPermission을 원래 14개 권한으로 복구
- 2025-09-12 10:00 [Claude] Group 엔티티 추가 필드는 유지 (사용자 요청)

## 변경 사항 요약
- 삭제된 파일:
  - backend/src/main/kotlin/.../entity/GroupInvite.kt (삭제)
- 수정된 파일:
  - backend/src/main/kotlin/.../entity/GroupPermission.kt (원래 권한으로 복구)
- 유지된 파일:
  - backend/src/main/kotlin/.../entity/Group.kt (추가 필드 유지)
  - backend/src/main/kotlin/.../entity/Channel.kt (문서에 정의됨)
  - backend/src/main/kotlin/.../entity/Post.kt (문서에 정의됨)
  - backend/src/main/kotlin/.../entity/Comment.kt (문서에 정의됨)
- 핵심 변경:
  - 임의로 추가한 GroupInvite 엔티티 제거
  - 권한 시스템을 기존 14개 권한으로 축소
  - 문서에 정의된 Channel, Post, Comment 엔티티는 유지

## 컨텍스트 업데이트 요청
- context/database-schema.md에 현재 구현된 엔티티 상태 반영 요청
- metadata.json에 정리된 엔티티 목록 업데이트 요청

