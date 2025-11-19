-- =====================================================================
-- V6: 채널 읽음 위치 추적 테이블 생성
-- =====================================================================
-- 용도: 채널별 사용자의 마지막 읽은 게시글 위치 저장
-- 기능: 읽지 않은 글 개수 계산, "여기부터 읽지 않은 글" 구분선 표시
-- =====================================================================

CREATE TABLE IF NOT EXISTS channel_read_positions
(
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id            BIGINT       NOT NULL,
    channel_id         BIGINT       NOT NULL,
    last_read_post_id  BIGINT       NOT NULL,
    updated_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 복합 유니크 제약: 한 사용자는 채널당 하나의 읽음 위치만 가짐
    CONSTRAINT uk_user_channel UNIQUE (user_id, channel_id),

    -- 외래 키 제약
    CONSTRAINT fk_read_position_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_read_position_channel FOREIGN KEY (channel_id)
        REFERENCES channels (id) ON DELETE CASCADE
);

-- 성능 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_channel_read_positions_user_id
    ON channel_read_positions (user_id);

CREATE INDEX IF NOT EXISTS idx_channel_read_positions_channel_id
    ON channel_read_positions (channel_id);

-- =====================================================================
-- 사용 예시:
-- =====================================================================
-- 1. 읽음 위치 조회:
--    SELECT last_read_post_id FROM channel_read_positions
--    WHERE user_id = ? AND channel_id = ?;
--
-- 2. 읽지 않은 글 개수:
--    SELECT COUNT(*) FROM posts
--    WHERE channel_id = ? AND id > ?;
--
-- 3. 읽음 위치 업데이트:
--    INSERT INTO channel_read_positions (user_id, channel_id, last_read_post_id)
--    VALUES (?, ?, ?)
--    ON DUPLICATE KEY UPDATE last_read_post_id = ?, updated_at = NOW();
-- =====================================================================
