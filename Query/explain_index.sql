USE Hotel_Management_Group3;

-- Index check for the stay-overlap search used by the free-room query (Q1).
-- The index IDX_Stays_Room_Dates (Hotel_ID, Room_Number, CheckIn, Checkout)
-- is created in hotel_management_full.sql, so this script does not change the
-- database. It only shows the execution plan.

SET @hotel_id = 1;
SET @from     = '2026-02-14';
SET @to       = '2026-02-17';

-- Plan 1: the optimizer may use IDX_Stays_Room_Dates (see the "key" column).
EXPLAIN
SELECT StayID
FROM Stays
WHERE Hotel_ID = @hotel_id
  AND CheckIn < DATE_ADD(@to, INTERVAL 1 DAY)
  AND (Checkout IS NULL OR Checkout >= DATE_ADD(@from, INTERVAL 1 DAY));

-- Plan 2: the same query with the index ignored, for comparison.
EXPLAIN
SELECT StayID
FROM Stays IGNORE INDEX (IDX_Stays_Room_Dates)
WHERE Hotel_ID = @hotel_id
  AND CheckIn < DATE_ADD(@to, INTERVAL 1 DAY)
  AND (Checkout IS NULL OR Checkout >= DATE_ADD(@from, INTERVAL 1 DAY));

-- Note: Stays has only 70 rows in the sample data, so MySQL may scan the whole
-- table in both plans. The index helps when the table is large.
