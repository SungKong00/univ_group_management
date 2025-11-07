-- Check existing GroupEvents in the database
SELECT id, title, group_id, start_date, end_date, event_type
FROM group_events
ORDER BY id
LIMIT 10;
