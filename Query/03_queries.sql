-- =====================================================================
-- IT079IU - Hotel Management (Topic 23)
-- 03_queries.sql : the SQL queries (D5), each preceded by its English question
-- Run after 01_schema.sql and 02_sample_data.sql.
-- Parameters are user variables (@name). In the Java application every
-- @name becomes a "?" of a PreparedStatement (never string concatenation).
-- Tested on MariaDB 10.11 (MySQL 8.0 compatible: recursive CTEs, views).
-- =====================================================================
USE hotel_group;

-- Test parameters (change freely) -------------------------------------
SET @today    = '2026-11-17';   -- "today"; keeps results reproducible
SET @hotel_id = 1;              -- Saigon Central
SET @from     = '2026-03-10';   -- stay period start (arrival night)
SET @to       = '2026-03-13';   -- stay period end   (departure date)
SET @stay_id  = 290;             -- stay whose bill we want
SET @year     = 2026;           -- report year
SET @on_date  = '2026-02-14';   -- date for the rate lookup (Tet season)

-- ---------------------------------------------------------------------
-- VIEW (requirement: "one view")
-- The bill of every stay, computed from the data: one ROOM line per night
-- priced with the rate plan that covers THAT night (rate depends on room
-- type AND date), plus one SERVICE line per consumption.
-- A stay still in house (check_out IS NULL) is billed up to today.
-- Recursive CTE = MySQL 8.0+ / MariaDB 10.2+ / SQL Server (with minor syntax change).
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_stay_bill_lines AS
WITH RECURSIVE nights (stay_id, type_id, room_number, night, last_day) AS (
    SELECT s.stay_id, r.type_id, s.room_number,
           CAST(DATE(s.check_in) AS DATE),
           CAST(DATE(COALESCE(s.check_out, CURRENT_DATE)) AS DATE)
    FROM   stay s
    JOIN   room r ON r.hotel_id = s.hotel_id AND r.room_number = s.room_number
    WHERE  DATE(s.check_in) < DATE(COALESCE(s.check_out, CURRENT_DATE))
    UNION ALL
    SELECT stay_id, type_id, room_number,
           CAST(night + INTERVAL 1 DAY AS DATE), last_day
    FROM   nights
    WHERE  night + INTERVAL 1 DAY < last_day
)
SELECT n.stay_id,
       'ROOM'                                        AS line_type,
       CONCAT('Room ', n.room_number, ' - night ', n.night) AS description,
       rp.price                                      AS amount,
       n.night                                       AS line_date
FROM   nights n
JOIN   rate_plan rp ON rp.type_id = n.type_id
                   AND n.night BETWEEN rp.start_date AND rp.end_date
UNION ALL
SELECT sc.stay_id,
       'SERVICE',
       CONCAT(sv.name, ' x', sc.quantity),
       sc.quantity * sc.unit_price,
       DATE(sc.consumed_at)
FROM   service_consumption sc
JOIN   service sv ON sv.service_id = sc.service_id;

-- =====================================================================
-- THE FIVE QUERIES REQUIRED BY TOPIC 23
-- =====================================================================

-- Q1. Which room inventory is available by room type at one hotel for a given date range?
--     Important: reservations are made for a ROOM TYPE; a physical room is assigned
--     only at check-in. Therefore the database cannot truthfully name the exact free
--     room numbers for future dates. This query reports available room units by type,
--     subtracting overlapping occupied rooms and unassigned PENDING/CONFIRMED bookings.
WITH inventory AS (
    SELECT r.type_id, COUNT(*) AS room_count
    FROM room r
    WHERE r.hotel_id = @hotel_id
      AND r.status IN ('AVAILABLE', 'OCCUPIED')
    GROUP BY r.type_id
), occupied AS (
    SELECT ro.type_id, COUNT(DISTINCT s.room_number) AS occupied_count
    FROM stay s
    JOIN room ro ON ro.hotel_id = s.hotel_id AND ro.room_number = s.room_number
    WHERE s.hotel_id = @hotel_id
      AND s.check_in < @to
      -- check-out at any time on day @from still allows a new arrival that day:
      AND (s.check_out IS NULL
           OR s.check_out >= DATE_ADD(@from, INTERVAL 1 DAY))
    GROUP BY ro.type_id
), reserved AS (
    SELECT res.type_id, COUNT(*) AS reserved_count
    FROM reservation res
    WHERE res.hotel_id = @hotel_id
      AND res.status IN ('PENDING', 'CONFIRMED')
      AND res.start_date < @to
      AND res.end_date > @from
      AND NOT EXISTS (SELECT 1 FROM stay st WHERE st.reservation_id = res.reservation_id)
    GROUP BY res.type_id
)
SELECT rt.name AS room_type,
       COALESCE(i.room_count, 0) AS room_inventory,
       COALESCE(o.occupied_count, 0) AS occupied_rooms,
       COALESCE(b.reserved_count, 0) AS unassigned_reservations,
       GREATEST(COALESCE(i.room_count, 0) - COALESCE(o.occupied_count, 0)
                - COALESCE(b.reserved_count, 0), 0) AS available_rooms
FROM room_type rt
JOIN inventory i ON i.type_id = rt.type_id
LEFT JOIN occupied o ON o.type_id = rt.type_id
LEFT JOIN reserved b ON b.type_id = rt.type_id
WHERE GREATEST(i.room_count - COALESCE(o.occupied_count, 0)
                - COALESCE(b.reserved_count, 0), 0) > 0
ORDER BY rt.name;

-- Q2. What is the bill of one stay, with room charges and services?
--     (multi-table join through the view above, then the totals.)
SELECT line_date, line_type, description, amount
FROM   v_stay_bill_lines
WHERE  stay_id = @stay_id
ORDER BY line_date, line_type DESC, description;

SELECT stay_id,
       SUM(CASE WHEN line_type = 'ROOM'    THEN amount ELSE 0 END) AS room_charges,
       SUM(CASE WHEN line_type = 'SERVICE' THEN amount ELSE 0 END) AS service_charges,
       SUM(amount)                                                 AS total_bill
FROM   v_stay_bill_lines
WHERE  stay_id = @stay_id
GROUP BY stay_id;

-- Q3. What is the occupancy rate per month per hotel?
--     Occupancy = occupied room-nights / registered room-nights. For the current
--     month, both numerator and denominator stop at @today (inclusive). The schema
--     has no room-status history, so historical denominator uses all registered
--     rooms; current MAINTENANCE/CLEANING status cannot be applied retroactively.
WITH RECURSIVE months (m_start) AS (
    SELECT CAST(CONCAT(@year, '-01-01') AS DATE)
    UNION ALL
    SELECT CAST(m_start + INTERVAL 1 MONTH AS DATE)
    FROM months
    WHERE m_start + INTERVAL 1 MONTH <= CAST(CONCAT(@year, '-12-01') AS DATE)
), month_bounds AS (
    SELECT m_start,
           LEAST(m_start + INTERVAL 1 MONTH, DATE_ADD(@today, INTERVAL 1 DAY)) AS period_end
    FROM months
), hotel_inventory AS (
    SELECT hotel_id, COUNT(*) AS room_count
    FROM room
    GROUP BY hotel_id
)
SELECT h.name AS hotel,
       DATE_FORMAT(m.m_start, '%Y-%m') AS month,
       COALESCE(SUM(GREATEST(0, DATEDIFF(
           LEAST(COALESCE(s.check_out, DATE_ADD(@today, INTERVAL 1 DAY)), m.period_end),
           GREATEST(s.check_in, m.m_start)))), 0) AS occupied_nights,
       COALESCE(hi.room_count, 0) * DATEDIFF(m.period_end, m.m_start) AS available_nights,
       ROUND(100 * COALESCE(SUM(GREATEST(0, DATEDIFF(
           LEAST(COALESCE(s.check_out, DATE_ADD(@today, INTERVAL 1 DAY)), m.period_end),
           GREATEST(s.check_in, m.m_start)))), 0)
         / NULLIF(COALESCE(hi.room_count, 0) * DATEDIFF(m.period_end, m.m_start), 0), 1) AS occupancy_pct
FROM month_bounds m
CROSS JOIN hotel h
LEFT JOIN hotel_inventory hi ON hi.hotel_id = h.hotel_id
LEFT JOIN stay s
       ON s.hotel_id = h.hotel_id
      AND s.check_in < m.period_end
      AND (s.check_out IS NULL OR s.check_out > m.m_start)
WHERE m.m_start <= @today
GROUP BY h.hotel_id, h.name, hi.room_count, m.m_start, m.period_end
ORDER BY h.name, m.m_start;

-- Q4. Which guests have stayed at every hotel of the group?
--     (relational DIVISION written with a double NOT EXISTS: there is no hotel
--      at which the guest has not stayed.)
SELECT g.guest_id, g.name
FROM   guest g
WHERE  NOT EXISTS (
         SELECT 1
         FROM   hotel h
         WHERE  NOT EXISTS (
                  SELECT 1
                  FROM   stay s
                  JOIN   reservation r ON r.reservation_id = s.reservation_id
                  WHERE  r.guest_id = g.guest_id
                    AND  s.hotel_id = h.hotel_id))
ORDER BY g.guest_id;

-- Q5. Which service produces the most revenue per occupied room?
--     Interpretation used here: service revenue divided by the number of distinct
--     occupied room-nights on which that service was consumed. This avoids counting
--     one physical room only once when it hosts many different stays/dates. Ties return.
WITH per_service AS (
    SELECT sv.service_id, sv.name, sv.service_type,
           SUM(sc.quantity * sc.unit_price) AS revenue,
           COUNT(DISTINCT CONCAT(st.stay_id, '-', DATE(sc.consumed_at))) AS occupied_room_nights
    FROM service_consumption sc
    JOIN service sv ON sv.service_id = sc.service_id
    JOIN stay st ON st.stay_id = sc.stay_id
    GROUP BY sv.service_id, sv.name, sv.service_type
)
SELECT name AS service, service_type, revenue, occupied_room_nights,
       ROUND(revenue / occupied_room_nights, 0) AS revenue_per_occupied_room
FROM per_service
WHERE revenue / occupied_room_nights =
      (SELECT MAX(revenue / occupied_room_nights) FROM per_service);

-- =====================================================================
-- ADDITIONAL QUERIES (cover every construct required by section 2.2)
-- =====================================================================

-- Q6. [multi-table join, 7 tables] For every completed stay: who stayed, where,
--     which room type was requested and which room was actually assigned.
SELECT st.stay_id, g.name AS guest, h.name AS hotel,
       rt_req.name AS requested_type, st.room_number, rt_got.name AS assigned_type,
       st.check_in, st.check_out
FROM   stay st
JOIN   reservation res  ON res.reservation_id = st.reservation_id
JOIN   guest g          ON g.guest_id   = res.guest_id
JOIN   hotel h          ON h.hotel_id   = st.hotel_id
JOIN   room_type rt_req ON rt_req.type_id = res.type_id
JOIN   room ro          ON ro.hotel_id = st.hotel_id AND ro.room_number = st.room_number
JOIN   room_type rt_got ON rt_got.type_id = ro.type_id
WHERE  st.check_out IS NOT NULL
ORDER BY st.check_in, st.stay_id
LIMIT 20;

-- Q7. [outer join] Which rooms of the group have never hosted a stay?
--     (LEFT JOIN keeps every room; the rooms with no matching stay are those where
--      the stay side is NULL.)
SELECT h.name AS hotel, r.room_number, rt.name AS room_type, r.status,
       COUNT(s.stay_id) AS number_of_stays
FROM   room r
JOIN   hotel h      ON h.hotel_id = r.hotel_id
JOIN   room_type rt ON rt.type_id = r.type_id
LEFT JOIN stay s    ON s.hotel_id = r.hotel_id AND s.room_number = r.room_number
GROUP BY h.hotel_id, h.name, r.room_number, rt.name, r.status
HAVING COUNT(s.stay_id) = 0
ORDER BY h.name, r.room_number;

-- Q8. [GROUP BY + HAVING] Which hotels earned more than 8,000,000 VND from
--     services, with the number of consumption lines and the average line value?
SELECT h.name AS hotel,
       COUNT(*)                                   AS consumption_lines,
       SUM(sc.quantity * sc.unit_price)           AS service_revenue,
       ROUND(AVG(sc.quantity * sc.unit_price), 0) AS avg_line_value
FROM   service_consumption sc
JOIN   stay  st ON st.stay_id = sc.stay_id
JOIN   hotel h  ON h.hotel_id = st.hotel_id
GROUP BY h.hotel_id, h.name
HAVING SUM(sc.quantity * sc.unit_price) > 8000000
ORDER BY service_revenue DESC;

-- Q9. [nested query with IN] Which guests have used a laundry service during a stay?
SELECT g.guest_id, g.name
FROM   guest g
WHERE  g.guest_id IN (
         SELECT res.guest_id
         FROM   reservation res
         JOIN   stay st             ON st.reservation_id = res.reservation_id
         JOIN   service_consumption sc ON sc.stay_id = st.stay_id
         JOIN   service sv          ON sv.service_id = sc.service_id
         WHERE  sv.service_type = 'LAUNDRY')
ORDER BY g.name;

-- Q10. Which guests either stayed in a suite/villa or used a spa service?
--      UNION returns each guest only once, even when both conditions are true.
SELECT g.guest_id, g.name
FROM guest g
JOIN reservation res ON res.guest_id = g.guest_id
JOIN stay st ON st.reservation_id = res.reservation_id
JOIN room ro ON ro.hotel_id = st.hotel_id AND ro.room_number = st.room_number
JOIN room_type rt ON rt.type_id = ro.type_id
WHERE rt.name LIKE '%Suite%' OR rt.name LIKE '%Villa%'
UNION
SELECT g.guest_id, g.name
FROM guest g
JOIN reservation res ON res.guest_id = g.guest_id
JOIN stay st ON st.reservation_id = res.reservation_id
JOIN service_consumption sc ON sc.stay_id = st.stay_id
JOIN service sv ON sv.service_id = sc.service_id
WHERE sv.service_type = 'SPA'
ORDER BY name;

-- Q11. [derived tables + outer join + EXISTS] Which invoices are not fully paid, and
--      how much does each guest still owe? (total of invoice lines - payments received)
SELECT i.invoice_id, g.name AS guest, i.issue_date, i.status,
       t.total_billed, COALESCE(p.total_paid, 0) AS total_paid,
       t.total_billed - COALESCE(p.total_paid, 0) AS balance_due
FROM   invoice i
JOIN   (SELECT invoice_id, SUM(amount) AS total_billed
        FROM invoice_line GROUP BY invoice_id) t ON t.invoice_id = i.invoice_id
LEFT JOIN (SELECT invoice_id, SUM(amount) AS total_paid
           FROM payment GROUP BY invoice_id)   p ON p.invoice_id = i.invoice_id
JOIN   stay st         ON st.stay_id = i.stay_id
JOIN   reservation res ON res.reservation_id = st.reservation_id
JOIN   guest g         ON g.guest_id = res.guest_id
WHERE  t.total_billed - COALESCE(p.total_paid, 0) > 0
  AND  EXISTS (SELECT 1 FROM invoice_line il WHERE il.invoice_id = i.invoice_id)
ORDER BY balance_due DESC, i.invoice_id;

-- Q12. [recursive relationship ReportTo] Each staff member with the supervisor and the
--      position; the general manager (no supervisor) must still appear.
SELECT h.name AS hotel, e.name AS staff, jp.title AS position, e.shift,
       sup.name AS supervisor
FROM   staff e
JOIN   hotel h         ON h.hotel_id = e.hotel_id
JOIN   job_position jp ON jp.role_id = e.role_id
LEFT JOIN staff sup    ON sup.staff_id = e.supervisor_id
ORDER BY h.name, jp.level DESC, e.name;

-- Q13. [rate depends on room type AND date] What is the nightly price of every room type
--      on one given date?  (Tet season by default.)
SELECT rt.name AS room_type, rp.season_name, rp.price AS nightly_price,
       rt.base_price, ROUND(100 * rp.price / rt.base_price - 100, 0) AS pct_vs_base
FROM   room_type rt
JOIN   rate_plan rp ON rp.type_id = rt.type_id
WHERE  @on_date BETWEEN rp.start_date AND rp.end_date
ORDER BY rp.price DESC;

-- Q14. [report screen: aggregate per month] Money actually received per month and per
--      hotel, by payment method.
SELECT DATE_FORMAT(p.paid_date, '%Y-%m') AS month, h.name AS hotel, p.method,
       COUNT(*) AS payments, SUM(p.amount) AS amount_received
FROM   payment p
JOIN   invoice i ON i.invoice_id = p.invoice_id
JOIN   stay st   ON st.stay_id = i.stay_id
JOIN   hotel h   ON h.hotel_id = st.hotel_id
WHERE  p.paid_date >= MAKEDATE(@year, 1)
  AND  p.paid_date <  MAKEDATE(@year + 1, 1)
GROUP BY DATE_FORMAT(p.paid_date, '%Y-%m'), h.hotel_id, h.name, p.method
ORDER BY month, hotel, p.method;
