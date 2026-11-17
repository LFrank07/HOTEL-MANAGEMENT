-- =====================================================================
-- 05_constraint_tests.sql : every statement below MUST be rejected by the database
-- (assignment 2.3: duplicate key, missing foreign key, CHECK violation).
-- Run with:  mysql --force -u root < 05_constraint_tests.sql   (so it continues after each error)
-- Expected: 10 errors, no row changed.
-- =====================================================================
USE hotel_group;
INSERT INTO hotel (hotel_id, name, city, address) VALUES (1, 'Dup key', 'X', 'X');                       -- duplicate primary key
INSERT INTO hotel (name, city, address) VALUES ('Saigon Central', 'X', 'X');                              -- UNIQUE(name)
INSERT INTO room (hotel_id, room_number, floor_number, type_id) VALUES (999, '101', 1, 1);                -- hotel does not exist
INSERT INTO room (hotel_id, room_number, floor_number, type_id, status) VALUES (1, '999', 1, 1, 'BROKEN'); -- CHECK status
INSERT INTO reservation (guest_id, hotel_id, type_id, start_date, end_date) VALUES (1, 1, 1, '2026-12-05', '2026-12-01'); -- CHECK end > start
INSERT INTO stay (reservation_id, hotel_id, room_number, check_in, check_out)
VALUES (1, 1, '101', '2026-12-05 14:00:00', '2026-12-01 11:00:00');                                      -- CHECK check_out > check_in
INSERT INTO stay (reservation_id, hotel_id, room_number, check_in)
SELECT MIN(reservation_id), 1, '777', '2026-12-05 14:00:00' FROM reservation WHERE status = 'CONFIRMED'; -- room does not exist
INSERT INTO payment (invoice_id, paid_date, method, amount) VALUES (1, '2026-12-01', 'CASH', -5);         -- CHECK amount > 0
DELETE FROM guest WHERE guest_id = 1;                                                                     -- ON DELETE RESTRICT (has reservations)
DELETE FROM room_type WHERE type_id = 1;                                                                  -- ON DELETE RESTRICT (rooms use it)
