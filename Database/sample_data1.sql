USE `Hotel_Management_Group3`;

INSERT INTO Hotels (Hotel_ID, Name, Address) VALUES
(1, 'Saigon Riverside Hotel',  '12 Ton Duc Thang, District 1, Ho Chi Minh City'),
(2, 'Hanoi Old Quarter Hotel', '45 Hang Bong, Hoan Kiem, Ha Noi'),
(3, 'Da Nang Beach Resort',    '210 Vo Nguyen Giap, Son Tra, Da Nang');

INSERT INTO Position (Role_ID, DepartmentFocus, Level, BaseRole) VALUES
(1, 'Management',        'Manager',    'General Manager'),
(2, 'Front Office',      'Supervisor', 'Receptionist'),
(3, 'Front Office',      'Senior',     'Receptionist'),
(4, 'Front Office',      'Junior',     'Receptionist'),
(5, 'Housekeeping',      'Supervisor', 'Housekeeper'),
(6, 'Housekeeping',      'Junior',     'Housekeeper'),
(7, 'Food and Beverage', 'Senior',     'Chef'),
(8, 'Finance',           'Senior',     'Accountant');

INSERT INTO Staff (Staff_ID, Name, Supervisor_ID, Hotel_ID, Role_ID) VALUES
(1,  'Nguyen Minh Quan', NULL, 1, 1),
(6,  'Tran Thu Ha',      NULL, 2, 1),
(11, 'Le Hoang Nam',     NULL, 3, 1);

INSERT INTO Staff (Staff_ID, Name, Supervisor_ID, Hotel_ID, Role_ID) VALUES
(2,  'Pham Thi Lan',     1,  1, 2),
(3,  'Vo Van Tai',       1,  1, 5),
(7,  'Dang Quoc Bao',    6,  2, 2),
(8,  'Bui Thi Mai',      6,  2, 5),
(12, 'Huynh Gia Huy',    11, 3, 2),
(13, 'Do Thi Ngoc',      11, 3, 5);

INSERT INTO Staff (Staff_ID, Name, Supervisor_ID, Hotel_ID, Role_ID) VALUES
(4,  'Ngo Thanh Tam',    2,  1, 4),
(5,  'Ly Kim Chi',       3,  1, 6),
(9,  'Duong Van Phuc',   7,  2, 3),
(10, 'Trinh My Linh',    8,  2, 6),
(14, 'Phan Duc Anh',     12, 3, 4),
(15, 'Cao Thi Yen',      11, 3, 7);


INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity) VALUES
(1, 'Standard',  800000.00, 2),
(2, 'Deluxe',   1200000.00, 2),
(3, 'Family',   1800000.00, 4),
(4, 'Suite',    3000000.00, 4);


INSERT INTO RatePlan (RatePlan_ID, SeasonName, StartDate, EndDate) VALUES
(1, 'Tet Holiday 2026',  '2026-02-14 00:00:00', '2026-02-22 23:59:59'),
(2, 'Summer Peak 2026',  '2026-06-01 00:00:00', '2026-08-31 23:59:59'),
(3, 'National Day 2026', '2026-09-01 00:00:00', '2026-09-03 23:59:59'),
(4, 'Year End 2026',     '2026-12-20 00:00:00', '2027-01-03 23:59:59');


INSERT INTO HasRate (TypeID, RatePlan_ID, Price) VALUES
(1, 1, 1200000.00), (2, 1, 1800000.00), (3, 1, 2600000.00), (4, 1, 4500000.00),
(1, 2, 1000000.00), (2, 2, 1500000.00), (3, 2, 2200000.00), (4, 2, 3600000.00),
(1, 3, 1100000.00), (2, 3, 1600000.00), (3, 3, 2400000.00),
(1, 4, 1300000.00), (2, 4, 1900000.00), (3, 4, 2800000.00), (4, 4, 4800000.00);


INSERT INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID) VALUES
(1, '101', 'Available',   1, 1),
(1, '102', 'Occupied',    1, 1),
(1, '103', 'Available',   1, 1),
(1, '201', 'Available',   2, 2),
(1, '202', 'Occupied',    2, 2),
(1, '301', 'Available',   3, 3),
(1, '302', 'Maintenance', 3, 3),
(1, 'P01', 'Available',   4, 4),
(2, '101', 'Available',   1, 1),
(2, '102', 'Available',   1, 1),
(2, '201', 'Occupied',    2, 2),
(2, '202', 'Available',   2, 2),
(2, '301', 'Available',   3, 3),
(2, '401', 'Available',   4, 4),
(3, '101', 'Available',   1, 1),
(3, '102', 'Available',   1, 1),
(3, '201', 'Available',   2, 2),
(3, '202', 'Maintenance', 2, 2),
(3, '301', 'Occupied',    3, 3),
(3, '401', 'Available',   4, 4);


INSERT INTO Guests (Guest_ID, Doc_ID, Name) VALUES
(1,  '079201004512', 'Nguyen Van An'),
(2,  '079199012345', 'Tran Thi Bich'),
(3,  '001200056789', 'Le Quang Huy'),
(4,  '048198034567', 'Pham Ngoc Anh'),
(5,  '079202078901', 'Hoang Minh Khoa'),
(6,  '001199523456', 'Vu Thi Thu'),
(7,  '048200167890', 'Dang Tuan Kiet'),
(8,  '079197089012', 'Bui Thanh Hang'),
(9,  'C4825613',     'John Miller'),
(10, 'M71240985',    'Sakura Tanaka'),
(11, '092201045678', 'Do Gia Bao'),
(12, '036199867891', 'Ngo Phuong Thao');


INSERT INTO Services (ServiceID, ServiceType) VALUES
(1, 'Breakfast'),
(2, 'Laundry'),
(3, 'Spa'),
(4, 'Airport Transfer'),
(5, 'Minibar'),
(6, 'Room Service'),
(7, 'Bike Rental');


INSERT INTO Guests_Phone (Phone, Guest_ID) VALUES
('0903123456', 1),
('0281234567', 1),
('0912345678', 2),
('0987654321', 3),
('0935111222', 4),
('0236555666', 4),
('0909888777', 5),
('0977123123', 6),
('0934567890', 7),
('0918222333', 8),
('+14155550123', 9),
('+819012345678', 10),
('0966444555', 11);


INSERT INTO Reservation (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID) VALUES
(1, '2026-02-13', '2026-02-16', 'CheckedOut', 2, 1, 1),
(2, '2026-02-18', '2026-02-21', 'CheckedOut', 2, 2, 2),
(3, '2026-03-05', '2026-03-08', 'CheckedOut', 1, 3, 1),
(4, '2026-03-20', '2026-03-22', 'CheckedOut', 4, 4, 3),
(5, '2026-04-10', '2026-04-13', 'CheckedOut', 2, 1, 2),
(6, '2026-04-25', '2026-04-28', 'CheckedOut', 1, 5, 1),
(7, '2026-05-29', '2026-06-03', 'CheckedOut', 2, 6, 2),
(8, '2026-06-15', '2026-06-18', 'CheckedOut', 2, 2, 1),
(9, '2026-06-20', '2026-06-24', 'CheckedOut', 3, 7, 4),
(10, '2026-07-10', '2026-07-14', 'CheckedOut', 4, 1, 3),
(11, '2026-07-18', '2026-07-21', 'CheckedOut', 2, 8, 2),
(12, '2026-07-25', '2026-07-29', 'CheckedOut', 2, 9, 4),
(13, '2026-08-05', '2026-08-08', 'CheckedOut', 2, 2, 2),
(14, '2026-08-20', '2026-08-23', 'CheckedOut', 1, 3, 1),
(15, '2026-08-30', '2026-09-04', 'CheckedOut', 2, 10, 4),
(16, '2026-09-12', '2026-09-15', 'CheckedOut', 1, 9, 1),
(17, '2026-10-02', '2026-10-05', 'CheckedOut', 3, 11, 3),
(18, '2026-10-20', '2026-10-23', 'CheckedOut', 2, 4, 2),
(19, '2026-11-03', '2026-11-06', 'CheckedOut', 1, 5, 1),
(20, '2026-11-14', '2026-11-18', 'CheckedIn', 2, 6, 1),
(21, '2026-11-15', '2026-11-19', 'CheckedIn', 2, 7, 2),
(22, '2026-11-16', '2026-11-20', 'CheckedIn', 1, 8, 2),
(23, '2026-11-13', '2026-11-18', 'CheckedIn', 4, 10, 3),
(24, '2026-09-20', '2026-09-22', 'Cancelled', 3, 3, 3),
(25, '2026-10-10', '2026-10-12', 'NoShow', 1, 11, 1),
(26, '2026-12-22', '2026-12-26', 'Confirmed', 2, 1, 4),
(27, '2026-12-05', '2026-12-07', 'Pending', 2, 4, 2),
(28, '2027-01-01', '2027-01-04', 'Confirmed', 4, 2, 3),
(29, '2026-05-10', '2026-05-12', 'Cancelled', 1, NULL, 1);


INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES
(1, '2026-02-16', 'Paid'),
(2, '2026-02-21', 'Paid'),
(3, '2026-03-08', 'Paid'),
(4, '2026-03-22', 'Paid'),
(5, '2026-04-13', 'Paid'),
(6, '2026-04-28', 'Paid'),
(7, '2026-06-03', 'Paid'),
(8, '2026-06-18', 'Paid'),
(9, '2026-06-24', 'Paid'),
(10, '2026-07-14', 'Paid'),
(11, '2026-07-21', 'Paid'),
(12, '2026-07-29', 'Paid'),
(13, '2026-08-08', 'Paid'),
(14, '2026-08-23', 'Paid'),
(15, '2026-09-04', 'PartiallyPaid'),
(16, '2026-09-15', 'Paid'),
(17, '2026-10-05', 'Paid'),
(18, '2026-10-23', 'Paid'),
(19, '2026-11-06', 'Unpaid'),
(20, '2026-11-14', 'Open'),
(21, '2026-11-15', 'Open'),
(22, '2026-11-16', 'Open'),
(23, '2026-11-13', 'Open');


INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number) VALUES
(1, '2026-02-13 15:20:00', '2026-02-16 11:00:00', 1, 1, 1, '101'),
(2, '2026-02-18 14:30:00', '2026-02-21 09:45:00', 2, 2, 2, '201'),
(3, '2026-03-05 16:10:00', '2026-03-08 11:15:00', 3, 3, 1, '103'),
(4, '2026-03-20 14:00:00', '2026-03-22 10:00:00', 4, 4, 3, '301'),
(5, '2026-04-10 18:45:00', '2026-04-13 11:50:00', 5, 5, 2, '202'),
(6, '2026-04-25 14:15:00', '2026-04-28 10:20:00', 6, 6, 3, '101'),
(7, '2026-05-29 15:00:00', '2026-06-03 09:30:00', 7, 7, 1, '201'),
(8, '2026-06-15 14:40:00', '2026-06-18 10:30:00', 8, 8, 1, '102'),
(9, '2026-06-20 13:55:00', '2026-06-24 11:00:00', 9, 9, 2, '401'),
(10, '2026-07-10 14:05:00', '2026-07-14 09:45:00', 10, 10, 3, '301'),
(11, '2026-07-18 15:20:00', '2026-07-21 11:15:00', 11, 11, 3, '201'),
(12, '2026-07-25 14:30:00', '2026-07-29 10:00:00', 12, 12, 1, 'P01'),
(13, '2026-08-05 16:10:00', '2026-08-08 11:50:00', 13, 13, 3, '201'),
(14, '2026-08-20 14:00:00', '2026-08-23 10:20:00', 14, 14, 2, '101'),
(15, '2026-08-30 18:45:00', '2026-09-04 09:30:00', 15, 15, 3, '401'),
(16, '2026-09-12 14:15:00', '2026-09-15 10:30:00', 16, 16, 3, '102'),
(17, '2026-10-02 15:00:00', '2026-10-05 11:00:00', 17, 17, 1, '301'),
(18, '2026-10-20 14:40:00', '2026-10-23 09:45:00', 18, 18, 2, '201'),
(19, '2026-11-03 13:55:00', '2026-11-06 11:15:00', 19, 19, 2, '102'),
(20, '2026-11-14 14:05:00', NULL, 20, 20, 1, '102'),
(21, '2026-11-15 15:20:00', NULL, 21, 21, 1, '202'),
(22, '2026-11-16 14:30:00', NULL, 22, 22, 2, '201'),
(23, '2026-11-13 16:10:00', NULL, 23, 23, 3, '301');


INSERT INTO Records (StayID, ServiceID, Date, Price, Quantity) VALUES
(1, 1, '2026-02-14 07:30:00', 150000.00, 2),
(1, 1, '2026-02-15 07:30:00', 150000.00, 2),
(1, 5, '2026-02-15 21:00:00', 120000.00, 1),
(2, 3, '2026-02-19 15:00:00', 600000.00, 2),
(2, 4, '2026-02-21 09:00:00', 350000.00, 1),
(3, 2, '2026-03-06 10:00:00', 80000.00, 1),
(4, 1, '2026-03-21 08:00:00', 150000.00, 4),
(4, 6, '2026-03-21 20:00:00', 200000.00, 1),
(5, 1, '2026-04-11 07:45:00', 150000.00, 2),
(5, 1, '2026-04-12 07:45:00', 150000.00, 2),
(5, 2, '2026-04-12 10:30:00', 80000.00, 2),
(7, 1, '2026-05-30 08:00:00', 150000.00, 2),
(7, 3, '2026-05-31 16:00:00', 600000.00, 1),
(7, 1, '2026-06-01 08:00:00', 150000.00, 2),
(7, 5, '2026-06-02 22:00:00', 120000.00, 2),
(8, 6, '2026-06-16 19:30:00', 200000.00, 1),
(8, 2, '2026-06-17 09:00:00', 80000.00, 1),
(9, 4, '2026-06-20 14:30:00', 350000.00, 1),
(9, 3, '2026-06-21 15:00:00', 600000.00, 3),
(9, 1, '2026-06-22 08:15:00', 150000.00, 3),
(9, 4, '2026-06-24 09:00:00', 350000.00, 1),
(10, 1, '2026-07-11 07:30:00', 180000.00, 4),
(10, 1, '2026-07-12 07:30:00', 180000.00, 4),
(10, 5, '2026-07-12 21:30:00', 120000.00, 3),
(10, 1, '2026-07-13 07:30:00', 180000.00, 4),
(11, 3, '2026-07-19 14:00:00', 600000.00, 2),
(12, 1, '2026-07-26 08:00:00', 180000.00, 2),
(12, 6, '2026-07-26 20:00:00', 200000.00, 2),
(12, 3, '2026-07-27 16:00:00', 600000.00, 2),
(12, 4, '2026-07-29 09:30:00', 350000.00, 1),
(13, 1, '2026-08-06 08:00:00', 180000.00, 2),
(13, 2, '2026-08-07 10:00:00', 80000.00, 1),
(14, 5, '2026-08-21 22:15:00', 120000.00, 1),
(15, 1, '2026-08-31 08:00:00', 180000.00, 2),
(15, 1, '2026-09-01 08:00:00', 180000.00, 2),
(15, 1, '2026-09-02 08:00:00', 180000.00, 2),
(15, 3, '2026-09-02 15:30:00', 600000.00, 2),
(15, 4, '2026-09-04 09:00:00', 350000.00, 1),
(17, 1, '2026-10-03 07:45:00', 180000.00, 3),
(17, 6, '2026-10-03 19:00:00', 200000.00, 1),
(17, 1, '2026-10-04 07:45:00', 180000.00, 3),
(18, 2, '2026-10-21 10:00:00', 80000.00, 2),
(18, 5, '2026-10-22 21:00:00', 120000.00, 2),
(19, 1, '2026-11-04 07:30:00', 180000.00, 1),
(19, 4, '2026-11-06 08:30:00', 350000.00, 1),
(20, 1, '2026-11-15 07:30:00', 180000.00, 2),
(20, 1, '2026-11-16 07:30:00', 180000.00, 2),
(21, 3, '2026-11-16 15:00:00', 600000.00, 1),
(22, 6, '2026-11-16 20:30:00', 200000.00, 1),
(23, 1, '2026-11-14 08:00:00', 180000.00, 4),
(23, 1, '2026-11-15 08:00:00', 180000.00, 4),
(23, 2, '2026-11-15 10:00:00', 80000.00, 2),
(23, 1, '2026-11-16 08:00:00', 180000.00, 4);


INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount, Description) VALUES
(1, 1, 'Room', 800000.00, 'Standard room 101: 1 night x 800,000 (Base price)'),
(2, 1, 'Room', 2400000.00, 'Standard room 101: 2 nights x 1,200,000 (Tet Holiday 2026)'),
(3, 1, 'Service', 300000.00, 'Breakfast on 2026-02-14: 2 x 150,000'),
(4, 1, 'Service', 300000.00, 'Breakfast on 2026-02-15: 2 x 150,000'),
(5, 1, 'Service', 120000.00, 'Minibar on 2026-02-15: 1 x 120,000'),
(1, 2, 'Room', 5400000.00, 'Deluxe room 201: 3 nights x 1,800,000 (Tet Holiday 2026)'),
(2, 2, 'Service', 1200000.00, 'Spa on 2026-02-19: 2 x 600,000'),
(3, 2, 'Service', 350000.00, 'Airport Transfer on 2026-02-21: 1 x 350,000'),
(1, 3, 'Room', 2400000.00, 'Standard room 103: 3 nights x 800,000 (Base price)'),
(2, 3, 'Service', 80000.00, 'Laundry on 2026-03-06: 1 x 80,000'),
(1, 4, 'Room', 3600000.00, 'Family room 301: 2 nights x 1,800,000 (Base price)'),
(2, 4, 'Service', 600000.00, 'Breakfast on 2026-03-21: 4 x 150,000'),
(3, 4, 'Service', 200000.00, 'Room Service on 2026-03-21: 1 x 200,000'),
(1, 5, 'Room', 3600000.00, 'Deluxe room 202: 3 nights x 1,200,000 (Base price)'),
(2, 5, 'Service', 300000.00, 'Breakfast on 2026-04-11: 2 x 150,000'),
(3, 5, 'Service', 300000.00, 'Breakfast on 2026-04-12: 2 x 150,000'),
(4, 5, 'Service', 160000.00, 'Laundry on 2026-04-12: 2 x 80,000'),
(1, 6, 'Room', 2400000.00, 'Standard room 101: 3 nights x 800,000 (Base price)'),
(1, 7, 'Room', 3600000.00, 'Deluxe room 201: 3 nights x 1,200,000 (Base price)'),
(2, 7, 'Room', 3000000.00, 'Deluxe room 201: 2 nights x 1,500,000 (Summer Peak 2026)'),
(3, 7, 'Service', 300000.00, 'Breakfast on 2026-05-30: 2 x 150,000'),
(4, 7, 'Service', 600000.00, 'Spa on 2026-05-31: 1 x 600,000'),
(5, 7, 'Service', 300000.00, 'Breakfast on 2026-06-01: 2 x 150,000'),
(6, 7, 'Service', 240000.00, 'Minibar on 2026-06-02: 2 x 120,000'),
(1, 8, 'Room', 3000000.00, 'Standard room 102: 3 nights x 1,000,000 (Summer Peak 2026)'),
(2, 8, 'Service', 200000.00, 'Room Service on 2026-06-16: 1 x 200,000'),
(3, 8, 'Service', 80000.00, 'Laundry on 2026-06-17: 1 x 80,000'),
(1, 9, 'Room', 14400000.00, 'Suite room 401: 4 nights x 3,600,000 (Summer Peak 2026)'),
(2, 9, 'Service', 350000.00, 'Airport Transfer on 2026-06-20: 1 x 350,000'),
(3, 9, 'Service', 1800000.00, 'Spa on 2026-06-21: 3 x 600,000'),
(4, 9, 'Service', 450000.00, 'Breakfast on 2026-06-22: 3 x 150,000'),
(5, 9, 'Service', 350000.00, 'Airport Transfer on 2026-06-24: 1 x 350,000'),
(1, 10, 'Room', 8800000.00, 'Family room 301: 4 nights x 2,200,000 (Summer Peak 2026)'),
(2, 10, 'Service', 720000.00, 'Breakfast on 2026-07-11: 4 x 180,000'),
(3, 10, 'Service', 720000.00, 'Breakfast on 2026-07-12: 4 x 180,000'),
(4, 10, 'Service', 360000.00, 'Minibar on 2026-07-12: 3 x 120,000'),
(5, 10, 'Service', 720000.00, 'Breakfast on 2026-07-13: 4 x 180,000'),
(1, 11, 'Room', 4500000.00, 'Deluxe room 201: 3 nights x 1,500,000 (Summer Peak 2026)'),
(2, 11, 'Service', 1200000.00, 'Spa on 2026-07-19: 2 x 600,000'),
(1, 12, 'Room', 14400000.00, 'Suite room P01: 4 nights x 3,600,000 (Summer Peak 2026)'),
(2, 12, 'Service', 360000.00, 'Breakfast on 2026-07-26: 2 x 180,000'),
(3, 12, 'Service', 400000.00, 'Room Service on 2026-07-26: 2 x 200,000'),
(4, 12, 'Service', 1200000.00, 'Spa on 2026-07-27: 2 x 600,000'),
(5, 12, 'Service', 350000.00, 'Airport Transfer on 2026-07-29: 1 x 350,000'),
(1, 13, 'Room', 4500000.00, 'Deluxe room 201: 3 nights x 1,500,000 (Summer Peak 2026)'),
(2, 13, 'Service', 360000.00, 'Breakfast on 2026-08-06: 2 x 180,000'),
(3, 13, 'Service', 80000.00, 'Laundry on 2026-08-07: 1 x 80,000'),
(1, 14, 'Room', 3000000.00, 'Standard room 101: 3 nights x 1,000,000 (Summer Peak 2026)'),
(2, 14, 'Service', 120000.00, 'Minibar on 2026-08-21: 1 x 120,000'),
(1, 15, 'Room', 7200000.00, 'Suite room 401: 2 nights x 3,600,000 (Summer Peak 2026)'),
(2, 15, 'Room', 9000000.00, 'Suite room 401: 3 nights x 3,000,000 (Base price)'),
(3, 15, 'Service', 360000.00, 'Breakfast on 2026-08-31: 2 x 180,000'),
(4, 15, 'Service', 360000.00, 'Breakfast on 2026-09-01: 2 x 180,000'),
(5, 15, 'Service', 360000.00, 'Breakfast on 2026-09-02: 2 x 180,000'),
(6, 15, 'Service', 1200000.00, 'Spa on 2026-09-02: 2 x 600,000'),
(7, 15, 'Service', 350000.00, 'Airport Transfer on 2026-09-04: 1 x 350,000'),
(1, 16, 'Room', 2400000.00, 'Standard room 102: 3 nights x 800,000 (Base price)'),
(1, 17, 'Room', 5400000.00, 'Family room 301: 3 nights x 1,800,000 (Base price)'),
(2, 17, 'Service', 540000.00, 'Breakfast on 2026-10-03: 3 x 180,000'),
(3, 17, 'Service', 200000.00, 'Room Service on 2026-10-03: 1 x 200,000'),
(4, 17, 'Service', 540000.00, 'Breakfast on 2026-10-04: 3 x 180,000'),
(1, 18, 'Room', 3600000.00, 'Deluxe room 201: 3 nights x 1,200,000 (Base price)'),
(2, 18, 'Service', 160000.00, 'Laundry on 2026-10-21: 2 x 80,000'),
(3, 18, 'Service', 240000.00, 'Minibar on 2026-10-22: 2 x 120,000'),
(1, 19, 'Room', 2400000.00, 'Standard room 102: 3 nights x 800,000 (Base price)'),
(2, 19, 'Service', 180000.00, 'Breakfast on 2026-11-04: 1 x 180,000'),
(3, 19, 'Service', 350000.00, 'Airport Transfer on 2026-11-06: 1 x 350,000');


INSERT INTO Payment (PaymentID, PaidDate, Method, Amount, Invoice_ID) VALUES
(1, '2026-02-16 11:00:00', 'Cash', 3920000.00, 1),
(2, '2026-02-21 09:45:00', 'BankTransfer', 6950000.00, 2),
(3, '2026-03-08 11:15:00', 'EWallet', 2480000.00, 3),
(4, '2026-03-22 10:00:00', 'CreditCard', 4400000.00, 4),
(5, '2026-04-13 11:50:00', 'Cash', 4360000.00, 5),
(6, '2026-04-28 10:20:00', 'BankTransfer', 2400000.00, 6),
(7, '2026-06-03 09:30:00', 'EWallet', 8040000.00, 7),
(8, '2026-06-18 10:30:00', 'CreditCard', 3280000.00, 8),
(9, '2026-06-20 13:55:00', 'BankTransfer', 5000000.00, 9),
(10, '2026-06-24 11:00:00', 'CreditCard', 12350000.00, 9),
(11, '2026-07-14 09:45:00', 'BankTransfer', 11320000.00, 10),
(12, '2026-07-21 11:15:00', 'EWallet', 5700000.00, 11),
(13, '2026-07-25 14:30:00', 'BankTransfer', 5000000.00, 12),
(14, '2026-07-29 10:00:00', 'CreditCard', 11710000.00, 12),
(15, '2026-08-08 11:50:00', 'Cash', 4940000.00, 13),
(16, '2026-08-23 10:20:00', 'BankTransfer', 3120000.00, 14),
(17, '2026-09-04 09:30:00', 'CreditCard', 10000000.00, 15),
(18, '2026-09-15 10:30:00', 'CreditCard', 2400000.00, 16),
(19, '2026-10-05 11:00:00', 'Cash', 6680000.00, 17),
(20, '2026-10-23 09:45:00', 'BankTransfer', 4000000.00, 18);


SELECT 'Hotels' AS TableName, COUNT(*) AS NumRows FROM Hotels
UNION ALL SELECT 'Position', COUNT(*) FROM Position
UNION ALL SELECT 'Staff', COUNT(*) FROM Staff
UNION ALL SELECT 'RoomType', COUNT(*) FROM RoomType
UNION ALL SELECT 'RatePlan', COUNT(*) FROM RatePlan
UNION ALL SELECT 'HasRate', COUNT(*) FROM HasRate
UNION ALL SELECT 'Room', COUNT(*) FROM Room
UNION ALL SELECT 'Guests', COUNT(*) FROM Guests
UNION ALL SELECT 'Services', COUNT(*) FROM Services
UNION ALL SELECT 'Guests_Phone', COUNT(*) FROM Guests_Phone
UNION ALL SELECT 'Reservation', COUNT(*) FROM Reservation
UNION ALL SELECT 'Invoices', COUNT(*) FROM Invoices
UNION ALL SELECT 'Stays', COUNT(*) FROM Stays
UNION ALL SELECT 'Records', COUNT(*) FROM Records
UNION ALL SELECT 'InvoiceLine', COUNT(*) FROM InvoiceLine
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment;




