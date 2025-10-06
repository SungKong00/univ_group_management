-- 성능 최적화를 위한 인덱스 추가
-- 프로덕션 환경에서 사용할 인덱스들

-- Groups 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_groups_parent_id ON groups (parent_id);
CREATE INDEX IF NOT EXISTS idx_groups_owner_id ON groups (owner_id);
CREATE INDEX IF NOT EXISTS idx_groups_deleted_at ON groups (deleted_at);
CREATE INDEX IF NOT EXISTS idx_groups_university_college_dept ON groups (university, college, department);
CREATE INDEX IF NOT EXISTS idx_groups_visibility_recruiting ON groups (visibility, is_recruiting);
CREATE INDEX IF NOT EXISTS idx_groups_group_type ON groups (group_type);
CREATE INDEX IF NOT EXISTS idx_groups_created_at ON groups (created_at);

-- Group Members 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_group_members_group_user ON group_members(group_id, user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_role_id ON group_members(role_id);
CREATE INDEX IF NOT EXISTS idx_group_members_joined_at ON group_members(joined_at);

-- Group Roles 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_group_roles_group_name ON group_roles(group_id, name);
CREATE INDEX IF NOT EXISTS idx_group_roles_system_role ON group_roles(is_system_role);
CREATE INDEX IF NOT EXISTS idx_group_roles_priority ON group_roles(priority DESC);

-- Group Join Requests 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_group_join_requests_group_user ON group_join_requests(group_id, user_id);
CREATE INDEX IF NOT EXISTS idx_group_join_requests_status ON group_join_requests(status);
CREATE INDEX IF NOT EXISTS idx_group_join_requests_created_at ON group_join_requests(created_at);

-- Group Member Permission Overrides 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_group_member_overrides_group_user ON group_member_overrides(group_id, user_id);

-- Channels 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_channels_group_id ON channels(group_id);
CREATE INDEX IF NOT EXISTS idx_channels_workspace_id ON channels(workspace_id);
CREATE INDEX IF NOT EXISTS idx_channels_type ON channels(type);
CREATE INDEX IF NOT EXISTS idx_channels_display_order ON channels(display_order);
CREATE INDEX IF NOT EXISTS idx_channels_created_at ON channels(created_at);

-- Posts 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_posts_channel_id ON posts(channel_id);
CREATE INDEX IF NOT EXISTS idx_posts_author_id ON posts(author_id);
CREATE INDEX IF NOT EXISTS idx_posts_type ON posts(type);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_pinned_created ON posts(is_pinned DESC, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_view_count ON posts(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_posts_like_count ON posts(like_count DESC);

-- Comments 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_comment_id ON comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at);

-- Workspaces 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_workspaces_group_id ON workspaces(group_id);
CREATE INDEX IF NOT EXISTS idx_workspaces_created_at ON workspaces(created_at);

-- Users 테이블 인덱스 (추가적으로 필요한 경우)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_global_role ON users(global_role);
CREATE INDEX IF NOT EXISTS idx_users_university_dept ON users(university, department);
CREATE INDEX IF NOT EXISTS idx_users_academic_year ON users(academic_year);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Email Verifications 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_email_verifications_token ON email_verifications(token);
CREATE INDEX IF NOT EXISTS idx_email_verifications_email ON email_verifications(email);
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON email_verifications(expires_at);

-- Sub Group Requests 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_sub_group_requests_parent_group_id ON sub_group_requests(parent_group_id);
CREATE INDEX IF NOT EXISTS idx_sub_group_requests_requester_id ON sub_group_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_sub_group_requests_status ON sub_group_requests(status);
CREATE INDEX IF NOT EXISTS idx_sub_group_requests_created_at ON sub_group_requests(created_at);

-- 복합 인덱스 (자주 함께 사용되는 컬럼들)
CREATE INDEX IF NOT EXISTS idx_groups_deleted_type_visibility ON groups (deleted_at, group_type, visibility) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_group_members_group_role_joined ON group_members(group_id, role_id, joined_at);
CREATE INDEX IF NOT EXISTS idx_posts_channel_created_pinned ON posts(channel_id, created_at DESC, is_pinned DESC);
CREATE INDEX IF NOT EXISTS idx_comments_post_created ON comments(post_id, created_at);

-- 텍스트 검색을 위한 인덱스 (PostgreSQL에서 사용 가능)
-- H2에서는 지원하지 않으므로 프로덕션 환경에서만 사용
-- CREATE INDEX IF NOT EXISTS idx_groups_name_trgm ON groups USING gin(name gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_groups_description_trgm ON groups USING gin(description gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_posts_title_trgm ON posts USING gin(title gin_trgm_ops);
-- CREATE INDEX IF NOT EXISTS idx_posts_content_trgm ON posts USING gin(content gin_trgm_ops);