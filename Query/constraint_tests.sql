-- =====================================================================
-- Hotel Management - Group 3
-- constraint_tests.sql: shows that the database rejects invalid data.
-- Run hotel_management_full.sql first.
--
-- Every test in Part A is EXPECTED TO FAIL with the error shown above it.
-- MySQL Workbench stops a script at the first error, so either:
--   - run one test at a time: put the cursor on it and press Ctrl+Enter, or
--   - turn off "Stop script execution on errors" (the toolbar toggle with
--     the red stop sign) and run the whole file with Ctrl+Shift+Enter.
-- Nothing in this file changes the data: failed statements insert nothing,
-- and the tests that need extra rows run inside a transaction that is
-- rolled back.
-- =====================================================================

USE `Hotel_Management_Group3`;

-- =====================================================================
-- PART A. Invalid data that must be rejected
-- =====================================================================

-- A1. Duplicate primary key: hotel 1 already exists.
-- Expected: Error 1062 Duplicate entry '1' for key 'hotels.PRIMARY'
INSERT INTO Hotels (Hotel_ID, Name, Address)
VALUES (1, 'Test Hotel', '1 Test Street, Ho Chi Minh City');

-- A2. Duplicate UNIQUE value: this identity document belongs to guest 1.
-- Expected: Error 1062 Duplicate entry '079201004512' for key 'guests.UQ_Guests_DocID'
INSERT INTO Guests (Guest_ID, Doc_ID, Name)
VALUES (21, '079201004512', 'Copy Of Nguyen Van An');

-- A3. Foreign key to a parent that does not exist: there is no hotel 99.
-- Expected: Error 1452 Cannot add or update a child row: a foreign key
--           constraint fails (... CONSTRAINT `FK_Room_Hotels` ...)
INSERT INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID)
VALUES (99, '101', 'Available', 1, 1);

-- A4. CHECK: a room type must sleep 1 to 5 people.
-- Expected: Error 3819 Check constraint 'CHK_RoomType_Capacity' is violated.
INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity)
VALUES (99, 'Dormitory', 300000.00, 9);

-- A5. CHECK: a reservation cannot end before it starts.
-- Expected: Error 3819 Check constraint 'CHK_Reservation_Dates' is violated.
INSERT INTO Reservation (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID)
VALUES (900, '2026-12-10', '2026-12-08', 'Pending', 2, 1, 1, 1);

-- A6. CHECK: a payment must be greater than zero.
-- Expected: Error 3819 Check constraint 'CHK_Payment_Amount' is violated.
INSERT INTO Payment (PaymentID, PaidDate, Method, Amount, Invoice_ID)
VALUES (900, '2026-11-17 10:00:00', 'Cash', 0.00, 1);

-- A7. NOT NULL: every guest must have a name.
-- Expected: Error 1048 Column 'Name' cannot be null
INSERT INTO Guests (Guest_ID, Doc_ID, Name)
VALUES (22, '079299000001', NULL);

-- A7b. NOT NULL: every position must have a level.
-- Expected: Error 1048 Column 'Level' cannot be null
INSERT INTO Position (Role_ID, DepartmentFocus, Level, BaseRole)
VALUES (99, 'Front Office', NULL, 'Receptionist');

-- A8. ENUM: an invoice status outside the allowed list (a typo).
-- Expected: Error 1265 Data truncated for column 'Status' at row 1
-- (MySQL rejects this in strict mode, which is the default in MySQL 8.)
INSERT INTO Invoices (Invoice_ID, IssueDate, Status)
VALUES (901, '2026-11-17', 'Payed');

-- A9. ON DELETE RESTRICT: hotel 1 still has rooms and staff.
-- Expected: Error 1451 Cannot delete or update a parent row: a foreign key
--           constraint fails
DELETE FROM Hotels WHERE Hotel_ID = 1;

-- A10. UNIQUE on Stays.Reservation_ID: reservation 1 already became stay 1,
--      so it cannot become a second stay (one reservation -> one stay).
-- Expected: Error 1062 Duplicate entry '1' for key 'stays.UQ_Stays_Reservation'
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (900, '2026-12-01', 'Open');
INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (900, '2026-12-01 14:00:00', '2026-12-03 10:00:00', 1, 900, 1, '103');
ROLLBACK;

-- A11. Composite foreign key: room 999 does not exist in hotel 1.
-- Expected: Error 1452 ... CONSTRAINT `FK_Stays_Room` ...
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (900, '2026-12-01', 'Open');
INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (900, '2026-12-01 14:00:00', NULL, 25, 900, 1, '999');
ROLLBACK;

-- =====================================================================
-- PART B. Business rules enforced by triggers (also expected to fail)
-- =====================================================================

-- B1. Capacity: 4 guests in a Standard Single room type (capacity 1).
-- Expected: Error 1644 Number of guests exceeds the capacity of the room type
INSERT INTO Reservation (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID)
VALUES (900, '2026-12-10', '2026-12-12', 'Pending', 4, 1, 5, 4);

-- B2. Room type: reservation 25 is for a Standard room, but room 201 of
--     hotel 1 is a Deluxe room.
-- Expected: Error 1644 The assigned room is not of the room type that was reserved
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (900, '2026-12-01', 'Open');
INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (900, '2026-12-01 14:00:00', NULL, 25, 900, 1, '201');
ROLLBACK;

-- B3. Double booking: room 102 of hotel 1 is occupied now by stay 20
--     (checked in on 2026-11-14, not checked out yet).
-- Expected: Error 1644 The room is already occupied during this stay
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (900, '2026-11-17', 'Open');
INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (900, '2026-11-17 14:00:00', NULL, 25, 900, 1, '102');
ROLLBACK;

-- B4. Wrong hotel: reservation 25 was made at hotel 1, but this stay is
--     in a Standard room (101) of hotel 2.
-- Expected: Error 1644 The stay is not at the hotel of the reservation
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (900, '2026-12-01', 'Open');
INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (900, '2026-12-01 14:00:00', NULL, 25, 900, 2, '101');
ROLLBACK;

-- B5. Room type not offered: hotel 4 (Hoi An) has no Suite (type 4).
-- Expected: Error 1644 This hotel has no room of the reserved room type
INSERT INTO Reservation (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID)
VALUES (901, '2026-12-10', '2026-12-12', 'Pending', 2, 1, 4, 4);

-- =====================================================================
-- PART C. Actions that are allowed (these succeed, then are undone)
-- =====================================================================

-- C1. DEFAULT: an invoice inserted without a status gets 'Open'.
-- Expected: one row with Status = 'Open'
START TRANSACTION;
INSERT INTO Invoices (Invoice_ID, IssueDate) VALUES (902, '2026-11-17');
SELECT Invoice_ID, IssueDate, Status FROM Invoices WHERE Invoice_ID = 902;
ROLLBACK;

-- C2. ON DELETE CASCADE and SET NULL: deleting guest 20 removes her phone
--     number (CASCADE) and keeps her reservations with Guest_ID = NULL
--     (SET NULL), so the hotel's booking history is not lost.
-- Expected before the delete: 1 phone, 2 reservations for guest 20.
-- Expected after the delete:  0 phones; reservations 75 and 76 remain,
--                             with Guest_ID = NULL.
START TRANSACTION;
SELECT COUNT(*) AS PhonesBefore FROM Guests_Phone WHERE Guest_ID = 20;
SELECT Reservation_ID, Guest_ID FROM Reservation WHERE Guest_ID = 20;
DELETE FROM Guests WHERE Guest_ID = 20;
SELECT COUNT(*) AS PhonesAfter FROM Guests_Phone WHERE Guest_ID = 20;
SELECT Reservation_ID, Guest_ID FROM Reservation WHERE Reservation_ID IN (75, 76);
ROLLBACK;

-- ---------------------------------------------------------------
-- D. New rules (run each statement alone; each must fail with the error shown)
-- ---------------------------------------------------------------
-- D1. A phone number cannot be shared by two guests.
-- Expected: Error 1062 Duplicate entry for key 'Guests_Phone.PRIMARY'
INSERT INTO Guests_Phone (Phone, Guest_ID) VALUES ('0903123456', 2);

-- D2. Two rate plans cannot overlap in time.
-- Expected: Error 1644 'This rate plan overlaps another rate plan'
INSERT INTO RatePlan (RatePlan_ID, SeasonName, StartDate, EndDate)
VALUES (9001, 'Overlap test', '2026-06-15 00:00:00', '2026-06-20 23:59:59');
