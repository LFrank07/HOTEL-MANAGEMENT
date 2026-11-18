USE Hotel_Management_Group3;

-- Index for queries that search stays by hotel and check-in date.
SET @has_index = (
    SELECT COUNT(*)
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'Stays'
      AND INDEX_NAME = 'idx_stays_hotel_checkin'
);

SET @ddl = IF(
    @has_index = 0,
    'CREATE INDEX idx_stays_hotel_checkin ON Stays (Hotel_ID, CheckIn)',
    'SELECT 1'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Review the execution plan after creating the index.
SET @hotel_id = 1;
SET @from = '2026-02-14';
SET @to = '2026-02-17';

EXPLAIN
SELECT StayID
FROM Stays
WHERE Hotel_ID = @hotel_id
  AND CheckIn < DATE_ADD(@to, INTERVAL 1 DAY)
  AND (Checkout IS NULL OR Checkout >= DATE_ADD(@from, INTERVAL 1 DAY));
