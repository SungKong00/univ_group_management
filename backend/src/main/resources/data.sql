-- =====================================================================
-- data.sql: 애플리케이션 시작 시 실행되어 초기 데이터를 삽입합니다.
-- 기본 데이터는 유지하되 H2 IDENTITY 충돌을 피하도록 시퀀스를 재시작합니다.
-- =====================================================================

-- 1) 사용자 (Users)
-- castlekong1019@gmail.com을 기본 사용자로 설정
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active, email_verified, nickname, department, student_no)
VALUES (1, 'castlekong1019@gmail.com', 'Castlekong', '', 'STUDENT', true, NOW(), NOW(), true, true, 'castlekong', 'AI/SW계열', '20250001');

-- 2) 최상위 그룹: 대학교 (University)
INSERT INTO groups (id, name, owner_id, university, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', 'PUBLIC', false, NOW(), NOW());

-- 3) 단과대학/계열 (College Level)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (2, 'AI/SW계열', 1, 1, '한신대학교', 'AI/SW계열', 'COLLEGE', 'PUBLIC', false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (3, '경영/미디어계열', 1, 1, '한신대학교', '경영/미디어계열', 'COLLEGE', 'PUBLIC', false, NOW(), NOW());

-- 4) 학과 (Department)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (11, 'AI시스템반도체학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI시스템반도체학과', 'DEPARTMENT', 'PUBLIC', false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (12, '미디어영상광고홍보학과', 1, 3, '한신대학교', '경영/미디어계열', '미디어영상광고홍보학과', 'DEPARTMENT', 'PUBLIC', false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, created_at, updated_at)
VALUES (13, 'AI/SW학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI/SW학과', 'DEPARTMENT', 'PUBLIC', false, NOW(), NOW());

-- 5) H2 IDENTITY 시퀀스 재시작 (중요: 명시적 ID 삽입 후 자동 증가 키 충돌 방지)
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;

-- 6) 기본 채널 생성 (모든 초기 그룹에 공지/자유톡 2개 채널 자동 생성)
--    Channel 스키마: id, group_id, name, description, type(ENUM), is_private, display_order, created_by, created_at, updated_at
--    type 값: 'ANNOUNCEMENT', 'TEXT', 'VOICE', 'FILE_SHARE'

-- 한신대학교 (id=1)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (1, 1, '공지사항', '대학 전체 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (2, 1, '자유톡', '대학 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- AI/SW계열 (id=2)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (3, 2, '공지사항', '계열 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (4, 2, '자유톡', '계열 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- 경영/미디어계열 (id=3)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (5, 3, '공지사항', '계열 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (6, 3, '자유톡', '계열 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- AI시스템반도체학과 (id=11)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (7, 11, '공지사항', '학과 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (8, 11, '자유톡', '학과 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- 미디어영상광고홍보학과 (id=12)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (9, 12, '공지사항', '학과 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (10, 12, '자유톡', '학과 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- AI/SW학과 (id=13)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (11, 13, '공지사항', '학과 공지사항', 'ANNOUNCEMENT', false, false, 1, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (12, 13, '자유톡', '학과 자유 대화', 'TEXT', false, false, 2, 1, NOW(), NOW());

-- channels 테이블 시퀀스 재시작
ALTER TABLE channels ALTER COLUMN id RESTART WITH 13;
