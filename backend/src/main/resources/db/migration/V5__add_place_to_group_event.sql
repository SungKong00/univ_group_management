-- V5: GroupEvent에 Place 연동 추가 (3가지 장소 모드 지원)
-- 작성일: 2025-10-18
-- 작성자: Backend Architect Agent
-- 참조: docs/features/group-event-place-integration.md

-- 1. 기존 location 컬럼을 location_text로 이름 변경
-- (기존 데이터 호환성 유지: location → locationText)
ALTER TABLE group_events RENAME COLUMN location TO location_text;

-- 2. place_id 외래키 컬럼 추가
-- (nullable: Mode A/B에서는 null, Mode C에서만 값 존재)
ALTER TABLE group_events ADD COLUMN place_id BIGINT;

-- 3. places 테이블에 대한 외래키 제약조건 추가
ALTER TABLE group_events ADD CONSTRAINT fk_group_event_place
    FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE SET NULL;

-- 4. place_id 인덱스 추가 (조회 성능 최적화)
CREATE INDEX idx_group_event_place ON group_events(place_id);

-- 주의사항:
-- - location_text와 place_id는 상호 배타적 (둘 다 값이 있으면 안 됨)
-- - 엔티티 레벨에서 init 블록으로 검증
-- - 기존 location 데이터는 location_text로 자동 마이그레이션됨 (Mode B)
