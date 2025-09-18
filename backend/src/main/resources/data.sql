-- =====================================================================
-- data.sql: 애플리케이션 시작 시 실행되어 초기 데이터를 삽입합니다.
-- 기본 데이터는 유지하되 H2 IDENTITY 충돌을 피하도록 시퀀스를 재시작합니다.
-- =====================================================================

-- 1) 사용자 (Users)
-- castlekong1019@gmail.com을 기본 사용자로 설정
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active, email_verified, nickname, department, student_no)
VALUES (1, 'castlekong1019@gmail.com', 'Castlekong', '', 'STUDENT', true, NOW(), NOW(), true, true, 'castlekong', 'AI/SW계열', '20250001');

-- 2) 최상위 그룹: 대학교 (University)
INSERT INTO groups (id, name, owner_id, university, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', 'PUBLIC', false, false, NOW(), NOW());

-- 3) 단과대학/계열 (College Level)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (2, 'AI/SW계열', 1, 1, '한신대학교', 'AI/SW계열', 'COLLEGE', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (3, '경영/미디어계열', 1, 1, '한신대학교', '경영/미디어계열', 'COLLEGE', 'PUBLIC', false, false, NOW(), NOW());

-- 4) 학과 (Department)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (11, 'AI시스템반도체학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI시스템반도체학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (12, '미디어영상광고홍보학과', 1, 3, '한신대학교', '경영/미디어계열', '미디어영상광고홍보학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (13, 'AI/SW학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI/SW학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

-- 5) H2 IDENTITY 시퀀스 재시작 (중요: 명시적 ID 삽입 후 자동 증가 키 충돌 방지)
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;

-- 기본 채널 데이터는 애플리케이션 로직에서 필요 시 생성됩니다.
