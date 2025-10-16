-- =====================================================================
-- data.sql: Simplified initialization data
--
-- Only includes users and group basic information.
-- Roles, channels, and channel role bindings are automatically created
-- by GroupInitializationRunner on server startup.
-- =====================================================================

-- 1) Users
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active,
                   email_verified, nickname, department, student_no)
VALUES (1, 'castlekong1019@gmail.com', 'Castlekong', '', 'STUDENT', true, NOW(), NOW(), true, true, 'castlekong',
        'AI/SW계열', '20250001');


-- 2) Groups - University Level
INSERT INTO groups (id, name, owner_id, university, group_type, default_channels_created,
                    created_at, updated_at)
VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', false, NOW(), NOW());

-- 3) Groups - College Level
INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type,
                    default_channels_created, created_at, updated_at)
VALUES (2, 'AI/SW계열', 1, 1, '한신대학교', 'AI/SW계열', 'COLLEGE', false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type,
                    default_channels_created, created_at, updated_at)
VALUES (3, '경영/미디어계열', 1, 1, '한신대학교', '경영/미디어계열', 'COLLEGE', false, NOW(), NOW());

-- 4) Groups - Department Level
INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    default_channels_created, created_at, updated_at)
VALUES (11, 'AI시스템반도체학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI시스템반도체학과', 'DEPARTMENT', false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    default_channels_created, created_at, updated_at)
VALUES (12, '미디어영상광고홍보학과', 1, 3, '한신대학교', '경영/미디어계열', '미디어영상광고홍보학과', 'DEPARTMENT', false, NOW(),
        NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    default_channels_created, created_at, updated_at)
VALUES (13, 'AI/SW학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI/SW학과', 'DEPARTMENT', false, NOW(), NOW());

-- =====================================================================
-- Automatic Initialization by GroupInitializationRunner:
--
-- For each group with defaultChannelsCreated = false:
--   1. GroupRoleInitializationService creates 3 default roles:
--      - 그룹장: All permissions (priority 100)
--      - 교수: All permissions (priority 99)
--      - 멤버: No group-level permissions (priority 1)
--   1.5. Add group.owner as 그룹장 role member (GroupMember)
--   2. ChannelInitializationService creates 2 default channels:
--      - ANNOUNCEMENT channel (공지사항)
--      - TEXT channel (자유게시판)
--   3. ChannelRoleBinding: All roles bound to all channels
--   4. Group.defaultChannelsCreated = true
-- =====================================================================

-- Note: Test posts removed to avoid foreign key constraint violations.
-- Channels are created by GroupInitializationRunner after data.sql execution.
-- To add test posts, use the REST API or create a separate initialization runner.

-- =====================================================================
-- 5) Personal Schedules (주간 반복 시간표)
-- =====================================================================
-- 학업 관련 반복 일정
INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (1, 1, '알고리즘 스터디', 'TUESDAY', '19:00:00', '21:00:00', '도서관 3층', '#3B82F6', NOW(), NOW());

INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (2, 1, '프로젝트 팀 미팅', 'THURSDAY', '14:00:00', '16:00:00', '공학관 세미나실', '#3B82F6', NOW(), NOW());

-- 운동 반복 일정
INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (3, 1, '헬스장', 'MONDAY', '07:00:00', '08:00:00', '학교 체육관', '#10B981', NOW(), NOW());

INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (4, 1, '헬스장', 'WEDNESDAY', '07:00:00', '08:00:00', '학교 체육관', '#10B981', NOW(), NOW());

INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (5, 1, '헬스장', 'FRIDAY', '07:00:00', '08:00:00', '학교 체육관', '#10B981', NOW(), NOW());

-- 아르바이트 반복 일정
INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (6, 1, '카페 아르바이트', 'TUESDAY', '17:00:00', '20:00:00', '한신대 카페', '#F59E0B', NOW(), NOW());

INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (7, 1, '카페 아르바이트', 'THURSDAY', '17:00:00', '20:00:00', '한신대 카페', '#F59E0B', NOW(), NOW());

-- 동아리 반복 일정
INSERT INTO personal_schedules (id, user_id, title, day_of_week, start_time, end_time, location, color, created_at, updated_at)
VALUES (8, 1, 'SW 동아리 정기모임', 'WEDNESDAY', '18:00:00', '20:00:00', '공학관 211호', '#8B5CF6', NOW(), NOW());

-- =====================================================================
-- 6) Personal Events (개인 캘린더 이벤트)
-- =====================================================================
-- 과제 및 발표
INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (1, 1, '알고리즘 과제 제출', '그래프 탐색 알고리즘 구현 제출 마감', '2025-10-20 23:59:00', '2025-10-20 23:59:00', false, null, '#EF4444', NOW(), NOW());

INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (2, 1, '웹프로그래밍 발표 준비', '중간 프로젝트 발표 준비 및 리허설', '2025-10-18 14:00:00', '2025-10-18 17:00:00', false, '도서관 스터디룸', '#3B82F6', NOW(), NOW());

-- 시험 일정
INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (3, 1, '데이터베이스 중간고사', 'SQL, 정규화, 트랜잭션 범위', '2025-10-28 10:00:00', '2025-10-28 12:00:00', false, '본관 201호', '#DC2626', NOW(), NOW());

INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (4, 1, '운영체제 중간고사', '프로세스, 스레드, 동기화', '2025-10-30 13:00:00', '2025-10-30 15:00:00', false, '본관 301호', '#DC2626', NOW(), NOW());

-- 행사 및 개인 일정
INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (5, 1, '동아리 MT', 'SW 동아리 가을 멤버십 트레이닝', '2025-11-02 00:00:00', '2025-11-03 23:59:59', true, '강원도 펜션', '#8B5CF6', NOW(), NOW());

INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (6, 1, '병원 예약', '정기 건강검진', '2025-10-25 15:00:00', '2025-10-25 16:00:00', false, '한신대병원', '#6B7280', NOW(), NOW());

INSERT INTO personal_events (id, user_id, title, description, start_date_time, end_date_time, is_all_day, location, color, created_at, updated_at)
VALUES (7, 1, '프로젝트 최종 발표', '캡스톤 프로젝트 최종 발표 및 시연', '2025-11-15 10:00:00', '2025-11-15 12:00:00', false, '공학관 대강의실', '#3B82F6', NOW(), NOW());

-- =====================================================================
-- 7) Places (장소)
-- =====================================================================
-- managing_group_id: 장소를 관리하는 그룹 ID (FK to groups)
-- building: 건물명
-- room_number: 방 번호
-- alias: 장소 별칭 (선택)
-- capacity: 수용 인원 (선택)
-- deleted_at: NULL = 활성, NOT NULL = 삭제됨 (soft delete)

-- 공학관 강의실 (AI시스템반도체학과 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (1, 11, '공학관', '201호', '공학관 201호', 30, NOW(), NOW());

INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (2, 11, '공학관', '301호', '공학관 301호', 40, NOW(), NOW());

-- 공학관 세미나실 (AI/SW계열 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (3, 2, '공학관', '세미나실', '공학관 세미나실', 50, NOW(), NOW());

-- 학생회관 회의실 (한신대학교 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (4, 1, '학생회관', '301호', '학생회 회의실', 15, NOW(), NOW());

-- 중앙도서관 스터디룸 (한신대학교 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (5, 1, '중앙도서관', '스터디룸A', '도서관 스터디룸 A', 8, NOW(), NOW());

INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (6, 1, '중앙도서관', '스터디룸B', '도서관 스터디룸 B', 6, NOW(), NOW());

-- 체육관 (한신대학교 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (7, 1, '체육관', '1층', '체육관', 100, NOW(), NOW());

-- 대강당 (한신대학교 관리)
INSERT INTO places (id, managing_group_id, building, room_number, alias, capacity, created_at, updated_at)
VALUES (8, 1, '본관', '대강당', '대강당', 500, NOW(), NOW());

-- =====================================================================
-- 8) Place Availability (장소 운영 시간)
-- =====================================================================
-- 공학관 201호 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (1, 1, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (2, 1, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (3, 1, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (4, 1, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (5, 1, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- 세미나실 운영 시간 (평일 09:00-21:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (6, 3, 'MONDAY', '09:00:00', '21:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (7, 3, 'TUESDAY', '09:00:00', '21:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (8, 3, 'WEDNESDAY', '09:00:00', '21:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (9, 3, 'THURSDAY', '09:00:00', '21:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (10, 3, 'FRIDAY', '09:00:00', '21:00:00', 0, NOW());

-- 스터디룸 A 운영 시간 (매일 08:00-22:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (11, 5, 'MONDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (12, 5, 'TUESDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (13, 5, 'WEDNESDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (14, 5, 'THURSDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (15, 5, 'FRIDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (16, 5, 'SATURDAY', '08:00:00', '22:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at)
VALUES (17, 5, 'SUNDAY', '08:00:00', '22:00:00', 0, NOW());

-- =====================================================================
-- 8-1) Place Availability Backfill (운영 시간 없는 장소 기본값 설정)
-- =====================================================================
-- 공학관 301호 (ID: 2) 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (18, 2, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (19, 2, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (20, 2, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (21, 2, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (22, 2, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- 학생회관 301호 (ID: 4) 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (23, 4, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (24, 4, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (25, 4, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (26, 4, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (27, 4, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- 중앙도서관 스터디룸B (ID: 6) 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (28, 6, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (29, 6, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (30, 6, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (31, 6, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (32, 6, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- 체육관 (ID: 7) 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (33, 7, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (34, 7, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (35, 7, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (36, 7, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (37, 7, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- 본관 대강당 (ID: 8) 운영 시간 (평일 09:00-18:00)
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (38, 8, 'MONDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (39, 8, 'TUESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (40, 8, 'WEDNESDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (41, 8, 'THURSDAY', '09:00:00', '18:00:00', 0, NOW());
INSERT INTO place_availabilities (id, place_id, day_of_week, start_time, end_time, display_order, created_at) VALUES (42, 8, 'FRIDAY', '09:00:00', '18:00:00', 0, NOW());

-- =====================================================================
-- 9) Place Usage Group (장소 사용 가능 그룹)
-- =====================================================================
-- status: PENDING (대기), APPROVED (승인), REJECTED (거절)
-- 관리 그룹이 아닌 그룹이 장소를 사용하려면 승인 필요

-- 공학관 201호 사용 가능 그룹 (AI시스템반도체학과, AI/SW학과)
INSERT INTO place_usage_groups (id, place_id, group_id, status, created_at, updated_at)
VALUES (1, 1, 11, 'APPROVED', NOW(), NOW());
INSERT INTO place_usage_groups (id, place_id, group_id, status, created_at, updated_at)
VALUES (2, 1, 13, 'APPROVED', NOW(), NOW());

-- 세미나실 사용 가능 그룹 (AI/SW계열 전체)
INSERT INTO place_usage_groups (id, place_id, group_id, status, created_at, updated_at)
VALUES (3, 3, 2, 'APPROVED', NOW(), NOW());

-- 스터디룸 A 사용 가능 그룹 (AI시스템반도체학과)
INSERT INTO place_usage_groups (id, place_id, group_id, status, created_at, updated_at)
VALUES (4, 5, 11, 'APPROVED', NOW(), NOW());

-- =====================================================================
-- 10) Place Reservations (장소 예약 - 샘플 데이터)
-- =====================================================================
-- PlaceReservation은 GroupEvent와 1:1 관계입니다.
-- GroupEvent가 먼저 생성되어야 PlaceReservation을 생성할 수 있습니다.
-- 예약 샘플 데이터는 REST API를 통해 추가하거나, GroupEvent 테스트 데이터를 먼저 생성한 후 추가하세요.
--
-- 필수 필드 (PlaceReservation 엔티티 기준):
-- - group_event_id: GroupEvent FK (NOT NULL, UNIQUE)
-- - place_id: Place FK (NOT NULL)
-- - reserved_by: User FK (NOT NULL)
-- - version: 낙관적 락 버전 (0으로 시작)
--
-- 예시 (GroupEvent가 있다고 가정):
-- INSERT INTO place_reservations (id, group_event_id, place_id, reserved_by, version, created_at, updated_at)
-- VALUES (1, 1, 1, 1, 0, NOW(), NOW());

-- =====================================================================
-- H2 AUTO_INCREMENT Sequence Initialization
-- =====================================================================
-- Since we explicitly inserted IDs above, we must reset the sequence
-- to avoid PRIMARY KEY violations when new rows are inserted.
-- Users table: max ID = 1, so next ID should be 2
-- Groups table: max ID = 13, so next ID should be 14
-- Personal Schedules table: max ID = 8, so next ID should be 9
-- Personal Events table: max ID = 7, so next ID should be 8
-- Places table: max ID = 8, so next ID should be 9
-- Place Availabilities table: max ID = 42, so next ID should be 43
-- Place Usage Groups table: max ID = 4, so next ID should be 5
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;
ALTER TABLE personal_schedules ALTER COLUMN id RESTART WITH 9;
ALTER TABLE personal_events ALTER COLUMN id RESTART WITH 8;
ALTER TABLE places ALTER COLUMN id RESTART WITH 9;
ALTER TABLE place_availabilities ALTER COLUMN id RESTART WITH 43;
ALTER TABLE place_usage_groups ALTER COLUMN id RESTART WITH 5;