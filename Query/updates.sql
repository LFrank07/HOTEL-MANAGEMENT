USE Hotel_Management_Group3;

-- Test records use IDs >= 9000. The cleanup at the beginning makes reruns easier.
-- Keep this ID range reserved for this test script.
DELETE FROM Payment WHERE PaymentID >= 9000;
DELETE FROM InvoiceLine WHERE Invoice_ID >= 9000;
DELETE FROM Records WHERE StayID >= 9000;
DELETE FROM Stays WHERE StayID >= 9000;
DELETE FROM Invoices WHERE Invoice_ID >= 9000;
DELETE FROM Reservation WHERE Reservation_ID >= 9000;
DELETE FROM Guests_Phone WHERE Guest_ID >= 9000;
DELETE FROM Guests WHERE Guest_ID >= 9000;
DELETE FROM Staff WHERE Staff_ID >= 9000;
DELETE FROM Room WHERE Hotel_ID = 1 AND Room_Number = '999';
DELETE FROM HasRate WHERE RatePlan_ID >= 9000;
DELETE FROM RatePlan WHERE RatePlan_ID >= 9000;
DELETE FROM Services WHERE ServiceID >= 9000;
DELETE FROM RoomType WHERE TypeID >= 9000;
DELETE FROM Position WHERE Role_ID >= 9000;
DELETE FROM Hotels WHERE Hotel_ID >= 9000;


-- INSERT, UPDATE and DELETE on Guests.
INSERT INTO Guests (Guest_ID, Doc_ID, Name)
VALUES (9001, 'P9001', 'Le Quang Huy');

INSERT INTO Guests_Phone (Phone, Guest_ID)
VALUES ('0909000111', 9001);

UPDATE Guests
SET Name = 'Le Quang Huy Junior'
WHERE Guest_ID = 9001;


-- INSERT, UPDATE and DELETE on Staff.
INSERT INTO Staff (Staff_ID, Name, Supervisor_ID, Hotel_ID, Role_ID)
VALUES (9001, 'Tran Gia Bao', 1, 1, 2);

UPDATE Staff
SET Role_ID = 3
WHERE Staff_ID = 9001;

DELETE FROM Staff
WHERE Staff_ID = 9001;


-- Create a temporary room so the test does not change an existing room's status.
INSERT INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID)
VALUES (1, '999', 'Available', 9, 1);

UPDATE Room
SET RoomStatus = 'Maintenance'
WHERE Hotel_ID = 1 AND Room_Number = '999';

UPDATE Room
SET RoomStatus = 'Available'
WHERE Hotel_ID = 1 AND Room_Number = '999';


-- INSERT and UPDATE on Reservation.
INSERT INTO Reservation
    (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID)
VALUES
    (9001, '2026-12-01', '2026-12-03', 'Confirmed', 2, 9001, 1, 1);

-- Standard rooms hold at most 2 guests, so the update lowers the number.
UPDATE Reservation
SET NoOfGuests = 1
WHERE Reservation_ID = 9001;


-- Check-in transaction: create invoice and stay, then assign the temporary room.
START TRANSACTION;

INSERT INTO Invoices (Invoice_ID, IssueDate, Status)
VALUES (9001, '2026-12-01', 'Open');

INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number)
VALUES (9001, '2026-12-01 14:00:00', NULL, 9001, 9001, 1, '999');

UPDATE Reservation
SET BookingStatus = 'CheckedIn'
WHERE Reservation_ID = 9001;

UPDATE Room
SET RoomStatus = 'Occupied'
WHERE Hotel_ID = 1 AND Room_Number = '999';

COMMIT;


-- INSERT and UPDATE on Records.
INSERT INTO Records (StayID, ServiceID, Date, Price, Quantity)
VALUES (9001, 1, '2026-12-02 08:00:00', 150000, 2);

UPDATE Records
SET Quantity = 3
WHERE StayID = 9001 AND ServiceID = 1;


-- Check-out and billing transaction.
START TRANSACTION;

UPDATE Stays
SET Checkout = '2026-12-03 11:00:00'
WHERE StayID = 9001;

UPDATE Reservation
SET BookingStatus = 'CheckedOut'
WHERE Reservation_ID = 9001;

UPDATE Room
SET RoomStatus = 'Available'
WHERE Hotel_ID = 1 AND Room_Number = '999';

-- Use new LineID values to avoid assuming that IDs 1 and 2 are free.
SET @next_line_id = (SELECT COALESCE(MAX(LineID), 0) + 1 FROM InvoiceLine);

INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount, Description)
VALUES (@next_line_id, 9001, 'Room', 1600000, 'Standard room 999: 2 nights');

INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount, Description)
VALUES (@next_line_id + 1, 9001, 'Service', 450000, 'Breakfast: 3 x 150,000');

UPDATE Invoices
SET Status = 'Unpaid'
WHERE Invoice_ID = 9001;

COMMIT;


-- UPDATE and INSERT on Payment.
UPDATE InvoiceLine
SET Amount = 480000,
    Description = 'Breakfast: 3 x 150,000 + 30,000 service fee'
WHERE Invoice_ID = 9001 AND Type = 'Service';

INSERT INTO Payment (PaymentID, PaidDate, Method, Amount, Invoice_ID)
VALUES (9001, '2026-12-03 11:30:00', 'Cash', 1000000, 9001);

UPDATE Payment
SET Amount = 1200000
WHERE PaymentID = 9001;


-- Payment transaction: demonstrate ROLLBACK.
START TRANSACTION;

INSERT INTO Payment (PaymentID, PaidDate, Method, Amount, Invoice_ID)
VALUES (9002, '2026-12-03 12:00:00', 'CreditCard', 880000, 9001);

UPDATE Invoices
SET Status = 'Paid'
WHERE Invoice_ID = 9001;

ROLLBACK;

-- Expected result: invoice remains Unpaid and only payment 9001 remains.
SELECT Invoice_ID, Status
FROM Invoices
WHERE Invoice_ID = 9001;

SELECT COUNT(*) AS PaymentsOfInvoice
FROM Payment
WHERE Invoice_ID = 9001;


-- Remove the test data in foreign-key-safe order.
DELETE FROM Payment WHERE Invoice_ID = 9001;
DELETE FROM InvoiceLine WHERE Invoice_ID = 9001;
DELETE FROM Records WHERE StayID = 9001;
DELETE FROM Stays WHERE StayID = 9001;
DELETE FROM Invoices WHERE Invoice_ID = 9001;
DELETE FROM Reservation WHERE Reservation_ID = 9001;
DELETE FROM Guests_Phone WHERE Guest_ID = 9001;
DELETE FROM Guests WHERE Guest_ID = 9001;
DELETE FROM Room WHERE Hotel_ID = 1 AND Room_Number = '999';


-- INSERT, UPDATE and DELETE on the reference tables (Hotels, Position, RoomType,
-- RatePlan, HasRate, Services). Each row is removed again in this same block.
INSERT INTO Hotels (Hotel_ID, Name, Address)
VALUES (9001, 'Test Hotel', '1 Test Street, Ho Chi Minh City');
UPDATE Hotels SET Address = '2 Test Street, Ho Chi Minh City' WHERE Hotel_ID = 9001;

INSERT INTO Position (Role_ID, DepartmentFocus, Level, BaseRole)
VALUES (9001, 'Testing', 'Junior', 'Tester');
UPDATE Position SET Level = 'Senior' WHERE Role_ID = 9001;

INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity)
VALUES (9001, 'Test Room', 500000, 2);
UPDATE RoomType SET BasePrice = 550000 WHERE TypeID = 9001;

INSERT INTO RatePlan (RatePlan_ID, SeasonName, StartDate, EndDate)
VALUES (9001, 'Test Season', '2027-02-01 00:00:00', '2027-02-10 23:59:59');
UPDATE RatePlan SET EndDate = '2027-02-12 23:59:59' WHERE RatePlan_ID = 9001;

INSERT INTO HasRate (TypeID, RatePlan_ID, Price) VALUES (9001, 9001, 700000);
UPDATE HasRate SET Price = 750000 WHERE TypeID = 9001 AND RatePlan_ID = 9001;

INSERT INTO Services (ServiceID, ServiceType) VALUES (9001, 'Test Service');
UPDATE Services SET ServiceType = 'Test Service Updated' WHERE ServiceID = 9001;

DELETE FROM HasRate WHERE TypeID = 9001 AND RatePlan_ID = 9001;
DELETE FROM RatePlan WHERE RatePlan_ID = 9001;
DELETE FROM RoomType WHERE TypeID = 9001;
DELETE FROM Position WHERE Role_ID = 9001;
DELETE FROM Services WHERE ServiceID = 9001;
DELETE FROM Hotels WHERE Hotel_ID = 9001;
