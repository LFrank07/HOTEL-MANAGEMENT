-- =====================================================================
-- IT079IU - Hotel Management (Topic 23)
-- 04_updates_and_transactions.sql
--   A. one INSERT, one UPDATE and one DELETE for each main table
--   B. transactions that change several tables together (COMMIT / ROLLBACK)
--   C. EXPLAIN of Q1 showing the index idx_stay_room_dates
-- The script leaves the data exactly as it found it, so it can be run repeatedly.
-- In the Java application every literal below becomes a "?" parameter.
-- =====================================================================
USE hotel_group;

-- ======================= A. CRUD per main table =======================
-- Order respects the foreign keys: parents are inserted first, deleted last.

-- hotel
INSERT INTO hotel (hotel_id, name, city, address) VALUES (9001, 'Test Hotel', 'Ho Chi Minh City', '1 Test Street');
UPDATE hotel SET address = '2 Test Street' WHERE hotel_id = 9001;

-- room_type and rate_plan
INSERT INTO room_type (type_id, name, capacity, base_price) VALUES (9001, 'Test Room', 2, 500000);
UPDATE room_type SET base_price = 550000 WHERE type_id = 9001;
INSERT INTO rate_plan (rateplan_id, type_id, season_name, start_date, end_date, price)
VALUES (9001, 9001, 'Test season', '2027-01-01', '2027-01-31', 600000);
UPDATE rate_plan SET price = 650000 WHERE rateplan_id = 9001;

-- room (weak entity: key = hotel + room number)
INSERT INTO room (hotel_id, room_number, floor_number, type_id, status) VALUES (9001, '101', 1, 9001, 'AVAILABLE');
UPDATE room SET status = 'CLEANING' WHERE hotel_id = 9001 AND room_number = '101';

-- job_position and staff
INSERT INTO job_position (role_id, title, base_role, level, department_focus) VALUES (9001, 'Test Role', 'OTHER', 1, 'Testing');
UPDATE job_position SET level = 2 WHERE role_id = 9001;
INSERT INTO staff (staff_id, hotel_id, supervisor_id, role_id, name, shift) VALUES (9001, 9001, NULL, 9001, 'Test Staff', 'DAY');
UPDATE staff SET shift = 'NIGHT' WHERE staff_id = 9001;

-- guest, guest_phone, identity_document
INSERT INTO guest (guest_id, name, email) VALUES (9001, 'Test Guest', 'test.guest@example.com');
UPDATE guest SET name = 'Test Guest Updated' WHERE guest_id = 9001;
INSERT INTO guest_phone (guest_id, phone) VALUES (9001, '0900000001');
UPDATE guest_phone SET phone = '0900000002' WHERE guest_id = 9001 AND phone = '0900000001';
INSERT INTO identity_document (doc_id, guest_id, doc_type, doc_number) VALUES (9001, 9001, 'PASSPORT', 'TEST0001');
UPDATE identity_document SET doc_number = 'TEST0002' WHERE doc_id = 9001;

-- reservation (for a room TYPE; no room yet)
INSERT INTO reservation (reservation_id, guest_id, hotel_id, type_id, start_date, end_date, no_of_guests, status)
VALUES (9001, 9001, 9001, 9001, '2027-01-10', '2027-01-12', 2, 'PENDING');
UPDATE reservation SET status = 'CONFIRMED' WHERE reservation_id = 9001;

-- stay (the room is assigned here, at check-in)
INSERT INTO stay (stay_id, reservation_id, hotel_id, room_number, check_in, check_out)
VALUES (9001, 9001, 9001, '101', '2027-01-10 14:00:00', NULL);
UPDATE stay SET check_out = '2027-01-12 11:00:00' WHERE stay_id = 9001;

-- service and service_consumption
INSERT INTO service (service_id, name, service_type, unit_price) VALUES (9001, 'Test Service', 'MINIBAR', 20000);
UPDATE service SET unit_price = 25000 WHERE service_id = 9001;
INSERT INTO service_consumption (consumption_id, stay_id, service_id, quantity, unit_price, consumed_at)
VALUES (9001, 9001, 9001, 2, 25000, '2027-01-11 20:00:00');
UPDATE service_consumption SET quantity = 3 WHERE consumption_id = 9001;

-- invoice, invoice_line, payment
INSERT INTO invoice (invoice_id, stay_id, issue_date, status) VALUES (9001, 9001, '2027-01-12', 'UNPAID');
UPDATE invoice SET status = 'PARTIAL' WHERE invoice_id = 9001;
INSERT INTO invoice_line (invoice_id, line_no, line_type, description, amount) VALUES (9001, 1, 'ROOM', 'Test night', 650000);
UPDATE invoice_line SET amount = 700000 WHERE invoice_id = 9001 AND line_no = 1;
INSERT INTO payment (payment_id, invoice_id, paid_date, method, amount) VALUES (9001, 9001, '2027-01-12', 'CASH', 300000);
UPDATE payment SET amount = 350000 WHERE payment_id = 9001;

-- Show the inserted + updated rows before they are deleted
SELECT 'payment' AS tbl, payment_id AS id, amount FROM payment WHERE payment_id = 9001
UNION ALL SELECT 'guest', guest_id, name FROM guest WHERE guest_id = 9001;

-- DELETEs in reverse order (children first). Deleting a parent that is still referenced
-- is rejected by ON DELETE RESTRICT - see the last statement of this section.
DELETE FROM payment             WHERE payment_id     = 9001;
DELETE FROM invoice_line        WHERE invoice_id     = 9001 AND line_no = 1;
DELETE FROM invoice             WHERE invoice_id     = 9001;
DELETE FROM service_consumption WHERE consumption_id = 9001;
DELETE FROM service             WHERE service_id     = 9001;
DELETE FROM stay                WHERE stay_id        = 9001;
DELETE FROM reservation         WHERE reservation_id = 9001;
DELETE FROM identity_document   WHERE doc_id         = 9001;
DELETE FROM guest_phone         WHERE guest_id       = 9001;
DELETE FROM guest               WHERE guest_id       = 9001;
DELETE FROM staff               WHERE staff_id       = 9001;
DELETE FROM job_position        WHERE role_id        = 9001;
DELETE FROM room                WHERE hotel_id = 9001 AND room_number = '101';
DELETE FROM rate_plan           WHERE rateplan_id    = 9001;
DELETE FROM room_type           WHERE type_id        = 9001;
DELETE FROM hotel               WHERE hotel_id       = 9001;

-- ================== B. Transactions (several tables at once) ==================
-- Preparation: a confirmed reservation for hotel 1, type of room 301 (Studio Apartment).
INSERT INTO reservation (reservation_id, guest_id, hotel_id, type_id, start_date, end_date, no_of_guests, status)
SELECT 9100, 1, r.hotel_id, r.type_id, '2026-12-01', '2026-12-04', 2, 'CONFIRMED'
FROM   room r WHERE r.hotel_id = 1 AND r.room_number = '301';

-- B1. CHECK-IN : three tables change together or not at all.
--     (1) create the stay with the room assigned, (2) reservation -> CHECKED_IN,
--     (3) room -> OCCUPIED. If any step fails the application issues ROLLBACK.
START TRANSACTION;
INSERT INTO stay (stay_id, reservation_id, hotel_id, room_number, check_in, check_out)
VALUES (9100, 9100, 1, '301', '2026-12-01 14:00:00', NULL);
UPDATE reservation SET status = 'CHECKED_IN' WHERE reservation_id = 9100;
UPDATE room SET status = 'OCCUPIED' WHERE hotel_id = 1 AND room_number = '301';
COMMIT;

-- B2. CHECK-OUT + INVOICING : close the stay, free the room, build the invoice
--     from the bill view (room nights at the seasonal rate + services).
INSERT INTO service_consumption (consumption_id, stay_id, service_id, quantity, unit_price, consumed_at)
VALUES (9100, 9100, 1, 2, 180000, '2026-12-02 07:30:00');      -- 2 breakfasts during the stay

START TRANSACTION;
UPDATE stay        SET check_out = '2026-12-04 11:00:00' WHERE stay_id = 9100;
UPDATE reservation SET status = 'COMPLETED'             WHERE reservation_id = 9100;
UPDATE room        SET status = 'CLEANING'              WHERE hotel_id = 1 AND room_number = '301';
INSERT INTO invoice (invoice_id, stay_id, issue_date, status) VALUES (9100, 9100, '2026-12-04', 'UNPAID');
INSERT INTO invoice_line (invoice_id, line_no, line_type, description, amount)
SELECT 9100,
       ROW_NUMBER() OVER (ORDER BY line_date, line_type DESC, description),
       line_type, description, amount
FROM   v_stay_bill_lines
WHERE  stay_id = 9100;
COMMIT;

SELECT i.invoice_id, i.status, SUM(l.amount) AS invoice_total
FROM   invoice i JOIN invoice_line l ON l.invoice_id = i.invoice_id
WHERE  i.invoice_id = 9100 GROUP BY i.invoice_id, i.status;

-- B3. PAYMENT with ROLLBACK : record a payment and mark the invoice PAID; the cashier
--     then cancels the operation, so everything is undone.
START TRANSACTION;
INSERT INTO payment (payment_id, invoice_id, paid_date, method, amount)
SELECT 9100, 9100, '2026-12-04', 'CARD', SUM(amount) FROM invoice_line WHERE invoice_id = 9100;
UPDATE invoice SET status = 'PAID' WHERE invoice_id = 9100;
SELECT 'inside transaction' AS moment, i.status, COUNT(p.payment_id) AS payments
FROM invoice i LEFT JOIN payment p ON p.invoice_id = i.invoice_id WHERE i.invoice_id = 9100 GROUP BY i.status;
ROLLBACK;
SELECT 'after ROLLBACK' AS moment, i.status, COUNT(p.payment_id) AS payments
FROM invoice i LEFT JOIN payment p ON p.invoice_id = i.invoice_id WHERE i.invoice_id = 9100 GROUP BY i.status;

-- Clean-up of the demo data (children first); restore room 301 of hotel 1.
DELETE FROM invoice_line        WHERE invoice_id = 9100;
DELETE FROM invoice             WHERE invoice_id = 9100;
DELETE FROM service_consumption WHERE consumption_id = 9100;
DELETE FROM stay                WHERE stay_id = 9100;
DELETE FROM reservation         WHERE reservation_id = 9100;
UPDATE room SET status = 'AVAILABLE' WHERE hotel_id = 1 AND room_number = '301';

-- ======================= C. Index check =======================
-- idx_stay_room_dates (created in 01_schema.sql) is what the NOT EXISTS of Q1 probes.
EXPLAIN SELECT 1 FROM stay s
WHERE s.hotel_id = 1 AND s.room_number = '301'
  AND DATE(s.check_in) < '2026-03-13'
  AND COALESCE(DATE(s.check_out), '9999-12-31') > '2026-03-10';
