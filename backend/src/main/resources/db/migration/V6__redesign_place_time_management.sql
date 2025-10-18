-- V6: 장소 시간 관리 시스템 재설계
-- 작성일: 2025-10-19
-- 작성자: Backend Architect Agent
-- 참조: docs/features/place-time-management-redesign.md
--
-- 변경 사항:
-- 1. PlaceOperatingHours (운영시간): 요일별 단일 시간대, 매주 반복
-- 2. PlaceRestrictedTime (금지시간): 운영시간 내 예약 불가 시간대, 매주 반복
-- 3. PlaceClosure (임시 휴무): 특정 날짜의 전일/부분 휴무
--
-- 마이그레이션 전략:
-- - 기존 place_availabilities, place_blocked_times 테이블 백업
-- - 새 테이블 생성
-- - 데이터 변환은 수동 진행 (별도 스크립트)

-- ====================================
-- 1. 새 테이블 생성
-- ====================================

-- 1.1. PlaceOperatingHours (운영시간)
CREATE TABLE place_operating_hours (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,  -- MONDAY, TUESDAY, etc.
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT false,  -- 해당 요일 휴무
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_operating_hours_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT uk_operating_hours UNIQUE (place_id, day_of_week)
);

CREATE INDEX idx_operating_place ON place_operating_hours(place_id);
CREATE INDEX idx_operating_day ON place_operating_hours(place_id, day_of_week);

-- 1.2. PlaceRestrictedTime (금지시간)
CREATE TABLE place_restricted_times (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL,  -- MONDAY, TUESDAY, etc.
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    reason VARCHAR(100),  -- 예: "점심시간", "시설 휴게시간"
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_restricted_time_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE INDEX idx_restricted_place ON place_restricted_times(place_id);
CREATE INDEX idx_restricted_day ON place_restricted_times(place_id, day_of_week);

-- 1.3. PlaceClosure (임시 휴무)
CREATE TABLE place_closures (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    closure_date DATE NOT NULL,
    is_full_day BOOLEAN NOT NULL DEFAULT true,
    start_time TIME,             -- 부분 시간 휴무 시작
    end_time TIME,               -- 부분 시간 휴무 종료
    reason VARCHAR(200),         -- 휴무 사유
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_closure_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT fk_closure_created_by FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE INDEX idx_closure_place ON place_closures(place_id);
CREATE INDEX idx_closure_date ON place_closures(place_id, closure_date);

-- ====================================
-- 2. 기존 테이블 백업 (안전)
-- ====================================

-- 기존 PlaceAvailability 테이블을 백업 테이블로 이름 변경
-- 주의: 데이터 손실 방지를 위해 검증 완료 후에만 백업 테이블 삭제
RENAME TABLE place_availabilities TO place_availabilities_backup;
RENAME TABLE place_blocked_times TO place_blocked_times_backup;

-- ====================================
-- 3. 데이터 마이그레이션 (수동)
-- ====================================

-- 참고: 실제 데이터 변환은 다음 단계에서 수동으로 진행
-- 이유: 복잡한 비즈니스 로직 (여러 시간대 → 단일 시간대 변환)

-- 예시: 각 요일의 첫 번째 시간대만 운영시간으로 변환
-- INSERT INTO place_operating_hours (place_id, day_of_week, start_time, end_time, created_at, updated_at)
-- SELECT
--     pa.place_id,
--     pa.day_of_week,
--     pa.start_time,
--     pa.end_time,
--     NOW(),
--     NOW()
-- FROM place_availabilities_backup pa
-- INNER JOIN (
--     SELECT place_id, day_of_week, MIN(display_order) as min_order
--     FROM place_availabilities_backup
--     GROUP BY place_id, day_of_week
-- ) first_slot
-- ON pa.place_id = first_slot.place_id
--    AND pa.day_of_week = first_slot.day_of_week
--    AND pa.display_order = first_slot.min_order;

-- ====================================
-- 4. 검증 및 정리 (추후)
-- ====================================

-- 검증 완료 후 백업 테이블 삭제 (추후 수동 실행)
-- DROP TABLE IF EXISTS place_availabilities_backup;
-- DROP TABLE IF EXISTS place_blocked_times_backup;
