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
-- H2 AUTO_INCREMENT Sequence Initialization
-- =====================================================================
-- Since we explicitly inserted IDs above, we must reset the sequence
-- to avoid PRIMARY KEY violations when new rows are inserted.
-- Users table: max ID = 1, so next ID should be 2
-- Groups table: max ID = 13, so next ID should be 14
-- Personal Schedules table: max ID = 8, so next ID should be 9
-- Personal Events table: max ID = 7, so next ID should be 8
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;
ALTER TABLE personal_schedules ALTER COLUMN id RESTART WITH 9;
ALTER TABLE personal_events ALTER COLUMN id RESTART WITH 8;
