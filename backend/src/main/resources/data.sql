-- =====================================================================
-- data.sql: Simplified initialization data
--
-- Only includes users and group basic information.
-- Roles, channels, and channel role bindings are automatically created
-- by GroupInitializationRunner on server startup.
-- =====================================================================

-- 1) Users
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active,
                   email_verified, nickname, department, student_no, academic_year, school_email, college)
VALUES (1, 'castlekong1019@gmail.com', '김성실', 'password', 'STUDENT', true, NOW(), NOW(), true, true, '모범생김씨',
        'AI/SW학과', '20210001', 4, '20210001@hanshin.ac.kr', 'AI/SW계열');




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
-- 5) Personal Schedules (주간 반복 시간표)
-- =====================================================================

-- User 1: 성실한 모범생
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (1, 1, '자료구조', '공학관 501호', 'MONDAY', '10:00:00', '11:50:00', '#4A90E2', NOW(), NOW());
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (2, 1, '알고리즘', '공학관 502호', 'TUESDAY', '13:00:00', '14:50:00', '#4A90E2', NOW(), NOW());
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (3, 1, '자료구조', '공학관 501호', 'WEDNESDAY', '10:00:00', '11:50:00', '#4A90E2', NOW(), NOW());
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (4, 1, '알고리즘', '공학관 502호', 'THURSDAY', '13:00:00', '14:50:00', '#4A90E2', NOW(), NOW());
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (5, 1, '코딩 테스트 스터디', '중앙도서관 스터디룸', 'FRIDAY', '14:00:00', '17:00:00', '#50E3C2', NOW(), NOW());
INSERT INTO personal_schedules (id, user_id, title, location, day_of_week, start_time, end_time, color, created_at, updated_at)
VALUES (6, 1, '중앙도서관에서 공부', '중앙도서관 2열람실', 'SATURDAY', '10:00:00', '18:00:00', '#B8E986', NOW(), NOW());

ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;
ALTER TABLE personal_schedules ALTER COLUMN id RESTART WITH 7;