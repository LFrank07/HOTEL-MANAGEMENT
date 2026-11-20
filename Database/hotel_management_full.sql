
CREATE DATABASE `Hotel_Management_Group3`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `Hotel_Management_Group3`;

CREATE TABLE Hotels (
    Hotel_ID INT NOT NULL,
    Name CHAR(100) NOT NULL,
    Address CHAR(150) NOT NULL,
    CONSTRAINT PK_Hotels PRIMARY KEY (Hotel_ID),
    CONSTRAINT UQ_Hotels_Name UNIQUE (Name)
) ENGINE=InnoDB;

CREATE TABLE Position (
    Role_ID INT NOT NULL,
    DepartmentFocus VARCHAR(50) NOT NULL,
    Level ENUM('Junior','Senior','Supervisor','Manager') NOT NULL,
    BaseRole VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Position PRIMARY KEY (Role_ID),
    CONSTRAINT UQ_Position_Title UNIQUE (BaseRole, DepartmentFocus, Level)
) ENGINE=InnoDB;

CREATE TABLE Staff (
    Staff_ID INT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Supervisor_ID INT NULL,
    Hotel_ID INT NOT NULL,
    Role_ID INT NOT NULL,
    CONSTRAINT PK_Staff PRIMARY KEY (Staff_ID),
    CONSTRAINT FK_Staff_Hotels FOREIGN KEY (Hotel_ID)
        REFERENCES Hotels (Hotel_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Staff_Position FOREIGN KEY (Role_ID)
        REFERENCES Position (Role_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Staff_Supervisor FOREIGN KEY (Supervisor_ID)
        REFERENCES Staff (Staff_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE RoomType (
    TypeID INT NOT NULL,
    Name CHAR(100) NOT NULL,
    BasePrice DECIMAL(12,2) NOT NULL,
    Capacity INT NOT NULL,
    CONSTRAINT PK_RoomType PRIMARY KEY (TypeID),
    CONSTRAINT UQ_RoomType_Name UNIQUE (Name),
    CONSTRAINT CHK_RoomType_Price CHECK (BasePrice >= 0),
    CONSTRAINT CHK_RoomType_Capacity CHECK (Capacity BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE RatePlan (
    RatePlan_ID INT NOT NULL,
    SeasonName VARCHAR(50) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    CONSTRAINT PK_RatePlan PRIMARY KEY (RatePlan_ID),
    CONSTRAINT UQ_RatePlan_SeasonName UNIQUE (SeasonName),
    CONSTRAINT UQ_RatePlan_StartDate UNIQUE (StartDate),
    CONSTRAINT UQ_RatePlan_EndDate UNIQUE (EndDate),
    CONSTRAINT CHK_RatePlan_Dates CHECK (EndDate >= StartDate)
) ENGINE=InnoDB;

CREATE TABLE Room (
    Hotel_ID    INT NOT NULL,
    Room_Number VARCHAR(10) NOT NULL,
    RoomStatus  ENUM('Available','Occupied','Maintenance') NOT NULL DEFAULT 'Available',
    FloorNumber INT NOT NULL,
    TypeID      INT NOT NULL,
    CONSTRAINT PK_Room PRIMARY KEY (Hotel_ID, Room_Number),
    CONSTRAINT FK_Room_Hotels FOREIGN KEY (Hotel_ID)
        REFERENCES Hotels (Hotel_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Room_RoomType FOREIGN KEY (TypeID)
        REFERENCES RoomType (TypeID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Guests (
    Guest_ID INT NOT NULL,
    Doc_ID   VARCHAR(20) NOT NULL,
    Name     VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Guests PRIMARY KEY (Guest_ID),
    CONSTRAINT UQ_Guests_DocID UNIQUE (Doc_ID)
) ENGINE=InnoDB;

CREATE TABLE Services (
    ServiceID   INT NOT NULL,
    ServiceType VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Services PRIMARY KEY (ServiceID),
    CONSTRAINT UQ_Services_ServiceType UNIQUE (ServiceType)
) ENGINE=InnoDB;

CREATE TABLE HasRate (
    TypeID INT NOT NULL,
    RatePlan_ID INT NOT NULL,
    Price DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_HasRate PRIMARY KEY (TypeID, RatePlan_ID),
    CONSTRAINT FK_HasRate_RoomType FOREIGN KEY (TypeID)
        REFERENCES RoomType (TypeID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_HasRate_RatePlan FOREIGN KEY (RatePlan_ID)
        REFERENCES RatePlan (RatePlan_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT CK_HasRate_Price CHECK (Price >= 0)
) ENGINE=InnoDB;

CREATE TABLE Guests_Phone (
    Phone VARCHAR(20) NOT NULL,
    Guest_ID INT NOT NULL,
    CONSTRAINT PK_Guests_Phone PRIMARY KEY (Phone),
    CONSTRAINT FK_GuestsPhone_Guests FOREIGN KEY (Guest_ID)
        REFERENCES Guests (Guest_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Reservation (
    Reservation_ID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    BookingStatus ENUM('Pending','Confirmed','CheckedIn','CheckedOut','Cancelled','NoShow') NOT NULL DEFAULT 'Pending',
    NoOfGuests INT NOT NULL DEFAULT 1,
    Guest_ID INT NULL,
    TypeID INT NOT NULL,
    Hotel_ID INT NOT NULL,
    CONSTRAINT PK_Reservation PRIMARY KEY (Reservation_ID),
    CONSTRAINT CHK_Reservation_Guests CHECK (NoOfGuests > 0),
    CONSTRAINT CHK_Reservation_Dates CHECK (EndDate >= StartDate),
    CONSTRAINT FK_Reservation_Guests FOREIGN KEY (Guest_ID)
        REFERENCES Guests (Guest_ID)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT FK_Reservation_RoomType FOREIGN KEY (TypeID)
        REFERENCES RoomType (TypeID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Reservation_Hotels FOREIGN KEY (Hotel_ID)
        REFERENCES Hotels (Hotel_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Invoices (
    Invoice_ID INT NOT NULL,
    IssueDate DATE NOT NULL,
    Status ENUM('Open','Unpaid','PartiallyPaid','Paid','Void') NOT NULL DEFAULT 'Open',
    CONSTRAINT PK_Invoices PRIMARY KEY (Invoice_ID)
) ENGINE=InnoDB;

CREATE TABLE Stays (
    StayID INT NOT NULL,
    CheckIn DATETIME NOT NULL,
    Checkout DATETIME NULL,
    Reservation_ID INT NOT NULL,
    Invoice_ID INT NOT NULL,
    Hotel_ID INT NOT NULL,
    Room_Number VARCHAR(10) NOT NULL,
    CONSTRAINT PK_Stays PRIMARY KEY (StayID),
    CONSTRAINT UQ_Stays_Reservation UNIQUE (Reservation_ID),
    CONSTRAINT UQ_Stays_Invoice UNIQUE (Invoice_ID),
    CONSTRAINT CHK_Stays_Dates CHECK (Checkout IS NULL OR Checkout >= CheckIn),
    CONSTRAINT FK_Stays_Reservation FOREIGN KEY (Reservation_ID)
        REFERENCES Reservation (Reservation_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Stays_Invoices FOREIGN KEY (Invoice_ID)
        REFERENCES Invoices (Invoice_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT FK_Stays_Room FOREIGN KEY (Hotel_ID, Room_Number)
        REFERENCES Room (Hotel_ID, Room_Number)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Records (
    StayID INT NOT NULL,
    ServiceID INT NOT NULL,
    Date DATETIME NOT NULL,
    Price DECIMAL(12,2) NOT NULL,
    Quantity INT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Records PRIMARY KEY (Date, StayID, ServiceID),
    CONSTRAINT CHK_Records_Price CHECK (Price >= 0),
    CONSTRAINT CHK_Records_Qty CHECK (Quantity > 0),
    CONSTRAINT FK_Records_Stays FOREIGN KEY (StayID)
        REFERENCES Stays (StayID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_Records_Services FOREIGN KEY (ServiceID)
        REFERENCES Services (ServiceID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE InvoiceLine (
    LineID INT NOT NULL,
    Invoice_ID INT NOT NULL,
    Type ENUM('Room','Service') NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    Description VARCHAR(255),
    CONSTRAINT PK_InvoiceLine PRIMARY KEY (LineID, Invoice_ID),
    CONSTRAINT CHK_InvoiceLine_Amount CHECK (Amount >= 0),
    CONSTRAINT FK_InvoiceLine_Invoices FOREIGN KEY (Invoice_ID)
        REFERENCES Invoices (Invoice_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Payment (
    PaymentID INT NOT NULL,
    PaidDate DATETIME NOT NULL,
    Method ENUM('Cash','CreditCard','BankTransfer','EWallet') NOT NULL,
    Amount DECIMAL(12,2) NOT NULL,
    Invoice_ID INT NOT NULL,
    CONSTRAINT PK_Payment PRIMARY KEY (PaymentID),
    CONSTRAINT CHK_Payment_Amount CHECK (Amount > 0),
    CONSTRAINT FK_Payment_Invoices FOREIGN KEY (Invoice_ID)
        REFERENCES Invoices (Invoice_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX IDX_Stays_Room_Dates ON Stays (Hotel_ID, Room_Number, CheckIn, Checkout);

CREATE INDEX IDX_RatePlan_Dates ON RatePlan (StartDate, EndDate);

CREATE INDEX IDX_Reservation_Hotel_Dates ON Reservation (Hotel_ID, TypeID, StartDate, EndDate);

-- Business rules that compare rows or tables cannot be written as CHECK
-- constraints, so they are enforced with triggers. Each trigger raises an
-- error with SIGNAL SQLSTATE '45000' when a rule is broken.
DELIMITER $$

CREATE TRIGGER TRG_Reservation_Capacity_BI
BEFORE INSERT ON Reservation
FOR EACH ROW
BEGIN
    IF NEW.NoOfGuests > (SELECT Capacity FROM RoomType WHERE TypeID = NEW.TypeID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Number of guests exceeds the capacity of the room type';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Room
                   WHERE Hotel_ID = NEW.Hotel_ID AND TypeID = NEW.TypeID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This hotel has no room of the reserved room type';
    END IF;
END$$

CREATE TRIGGER TRG_Reservation_Capacity_BU
BEFORE UPDATE ON Reservation
FOR EACH ROW
BEGIN
    IF NEW.NoOfGuests > (SELECT Capacity FROM RoomType WHERE TypeID = NEW.TypeID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Number of guests exceeds the capacity of the room type';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Room
                   WHERE Hotel_ID = NEW.Hotel_ID AND TypeID = NEW.TypeID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This hotel has no room of the reserved room type';
    END IF;
END$$

CREATE TRIGGER TRG_Stays_Rules_BI
BEFORE INSERT ON Stays
FOR EACH ROW
BEGIN
    IF NEW.Hotel_ID <> (SELECT Hotel_ID FROM Reservation
                        WHERE Reservation_ID = NEW.Reservation_ID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The stay is not at the hotel of the reservation';
    END IF;
    IF (SELECT TypeID FROM Room
        WHERE Hotel_ID = NEW.Hotel_ID AND Room_Number = NEW.Room_Number)
       <> (SELECT TypeID FROM Reservation
           WHERE Reservation_ID = NEW.Reservation_ID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The assigned room is not of the room type that was reserved';
    END IF;
    IF EXISTS (SELECT 1 FROM Stays s
               WHERE s.Hotel_ID = NEW.Hotel_ID
                 AND s.Room_Number = NEW.Room_Number
                 AND s.StayID <> NEW.StayID
                 AND s.CheckIn < COALESCE(NEW.Checkout, '9999-12-31')
                 AND NEW.CheckIn < COALESCE(s.Checkout, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The room is already occupied during this stay';
    END IF;
END$$

CREATE TRIGGER TRG_Stays_Rules_BU
BEFORE UPDATE ON Stays
FOR EACH ROW
BEGIN
    IF NEW.Hotel_ID <> (SELECT Hotel_ID FROM Reservation
                        WHERE Reservation_ID = NEW.Reservation_ID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The stay is not at the hotel of the reservation';
    END IF;
    IF (SELECT TypeID FROM Room
        WHERE Hotel_ID = NEW.Hotel_ID AND Room_Number = NEW.Room_Number)
       <> (SELECT TypeID FROM Reservation
           WHERE Reservation_ID = NEW.Reservation_ID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The assigned room is not of the room type that was reserved';
    END IF;
    IF EXISTS (SELECT 1 FROM Stays s
               WHERE s.Hotel_ID = NEW.Hotel_ID
                 AND s.Room_Number = NEW.Room_Number
                 AND s.StayID <> NEW.StayID
                 AND s.CheckIn < COALESCE(NEW.Checkout, '9999-12-31')
                 AND NEW.CheckIn < COALESCE(s.Checkout, '9999-12-31')) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The room is already occupied during this stay';
    END IF;
END$$

CREATE TRIGGER TRG_RatePlan_NoOverlap_BI
BEFORE INSERT ON RatePlan
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM RatePlan r
               WHERE r.RatePlan_ID <> NEW.RatePlan_ID
                 AND r.StartDate <= NEW.EndDate
                 AND NEW.StartDate <= r.EndDate) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This rate plan overlaps another rate plan';
    END IF;
END$$

CREATE TRIGGER TRG_RatePlan_NoOverlap_BU
BEFORE UPDATE ON RatePlan
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM RatePlan r
               WHERE r.RatePlan_ID <> NEW.RatePlan_ID
                 AND r.StartDate <= NEW.EndDate
                 AND NEW.StartDate <= r.EndDate) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This rate plan overlaps another rate plan';
    END IF;
END$$

DELIMITER ;

INSERT INTO Hotels (Hotel_ID, Name, Address) VALUES
(1, 'Saigon Riverside Hotel', '12 Ton Duc Thang, District 1, Ho Chi Minh City'),
(2, 'Hanoi Old Quarter Hotel', '45 Hang Bong, Hoan Kiem, Ha Noi'),
(3, 'Da Nang Beach Resort', '210 Vo Nguyen Giap, Son Tra, Da Nang'),
(4, 'Hoi An Ancient Town Hotel', '88 Tran Phu, Hoi An, Quang Nam'),
(5, 'Nha Trang Bay Hotel', '34 Tran Phu, Nha Trang, Khanh Hoa'),
(6, 'Da Lat Pine Hill Hotel', '15 Tran Hung Dao, Da Lat, Lam Dong'),
(7, 'Hue Imperial Hotel', '5 Le Loi, Hue'),
(8, 'Phu Quoc Sunset Resort', '120 Tran Hung Dao, Duong Dong, Phu Quoc, Kien Giang'),
(9, 'Vung Tau Seaside Hotel', '66 Thuy Van, Vung Tau, Ba Ria - Vung Tau'),
(10, 'Can Tho Riverside Hotel', '22 Hai Ba Trung, Ninh Kieu, Can Tho'),
(11, 'Ha Long Bay Hotel', '9 Ha Long Road, Bai Chay, Ha Long, Quang Ninh'),
(12, 'Sa Pa Mountain Lodge', '18 Fansipan, Sa Pa, Lao Cai'),
(13, 'Quy Nhon Coast Hotel', '40 Xuan Dieu, Quy Nhon, Binh Dinh'),
(14, 'Hai Phong Harbour Hotel', '27 Dien Bien Phu, Ngo Quyen, Hai Phong'),
(15, 'Phan Thiet Dunes Resort', '75 Nguyen Dinh Chieu, Mui Ne, Phan Thiet, Binh Thuan');

INSERT INTO Position (Role_ID, DepartmentFocus, Level, BaseRole) VALUES
(1, 'Management', 'Manager', 'General Manager'),
(2, 'Front Office', 'Supervisor', 'Receptionist'),
(3, 'Front Office', 'Senior', 'Receptionist'),
(4, 'Front Office', 'Junior', 'Receptionist'),
(5, 'Housekeeping', 'Supervisor', 'Housekeeper'),
(6, 'Housekeeping', 'Junior', 'Housekeeper'),
(7, 'Food and Beverage', 'Senior', 'Chef'),
(8, 'Finance', 'Senior', 'Accountant'),
(9, 'Food and Beverage', 'Junior', 'Chef'),
(10, 'Food and Beverage', 'Junior', 'Waiter'),
(11, 'Front Office', 'Senior', 'Concierge'),
(12, 'Maintenance', 'Senior', 'Technician'),
(13, 'Maintenance', 'Junior', 'Technician'),
(14, 'Security', 'Junior', 'Security Officer'),
(15, 'Wellness', 'Senior', 'Spa Therapist');

INSERT INTO Staff (Staff_ID, Name, Supervisor_ID, Hotel_ID, Role_ID) VALUES
(1, 'Nguyen Minh Quan', NULL, 1, 1),
(6, 'Tran Thu Ha', NULL, 2, 1),
(11, 'Le Hoang Nam', NULL, 3, 1),
(16, 'Vo Thanh Son', NULL, 4, 1),
(17, 'Pham Bao Ngoc', NULL, 5, 1),
(18, 'Dinh Cong Minh', NULL, 6, 1),
(19, 'Ton Nu Thao', NULL, 7, 1),
(20, 'Truong Quoc Viet', NULL, 8, 1),
(21, 'Ho Thi My', NULL, 9, 1),
(22, 'Kieu Anh Dung', NULL, 10, 1),
(23, 'Lam Hoang Yen', NULL, 11, 1),
(24, 'Ta Van Khanh', NULL, 12, 1),
(25, 'Hua Ngoc Tram', NULL, 13, 1),
(26, 'Quach Minh Tri', NULL, 14, 1),
(27, 'La Thi Hong', NULL, 15, 1),
(2, 'Pham Thi Lan', 1, 1, 2),
(3, 'Vo Van Tai', 1, 1, 5),
(7, 'Dang Quoc Bao', 6, 2, 2),
(8, 'Bui Thi Mai', 6, 2, 5),
(12, 'Huynh Gia Huy', 11, 3, 2),
(13, 'Do Thi Ngoc', 11, 3, 5),
(4, 'Ngo Thanh Tam', 2, 1, 4),
(5, 'Ly Kim Chi', 3, 1, 6),
(9, 'Duong Van Phuc', 7, 2, 3),
(10, 'Trinh My Linh', 8, 2, 6),
(14, 'Phan Duc Anh', 12, 3, 4),
(15, 'Cao Thi Yen', 11, 3, 7),
(28, 'Nguyen Thi Hoa', 16, 4, 4),
(29, 'Tran Van Hung', 17, 5, 6),
(30, 'Le Thi Thanh', 18, 6, 9),
(31, 'Pham Van Dat', 19, 7, 10),
(32, 'Hoang Thi Lien', 20, 8, 11),
(33, 'Vu Van Quang', 21, 9, 12),
(34, 'Dang Thi Nhung', 22, 10, 13),
(35, 'Bui Van Thinh', 23, 11, 14),
(36, 'Do Thi Huong', 24, 12, 15),
(37, 'Ngo Van Loc', 25, 13, 8),
(38, 'Duong Thi Xuan', 26, 14, 3),
(39, 'Ly Van Hieu', 27, 15, 7);

INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity) VALUES
(1, 'Standard', 800000.00, 2),
(2, 'Deluxe', 1200000.00, 2),
(3, 'Family', 1800000.00, 4),
(4, 'Suite', 3000000.00, 4),
(5, 'Standard Single', 650000.00, 1),
(6, 'Standard Twin', 850000.00, 2),
(7, 'Superior Double', 1000000.00, 2),
(8, 'Superior Twin', 1000000.00, 2),
(9, 'Deluxe Sea View', 1500000.00, 2),
(10, 'Deluxe Triple', 1400000.00, 3),
(11, 'Family Connecting', 2200000.00, 5),
(12, 'Junior Suite', 2500000.00, 3),
(13, 'Executive Suite', 3800000.00, 4),
(14, 'Presidential Suite', 6500000.00, 4),
(15, 'Accessible Room', 900000.00, 2);

INSERT INTO RatePlan (RatePlan_ID, SeasonName, StartDate, EndDate) VALUES
(1, 'Tet Holiday 2026', '2026-02-14 00:00:00', '2026-02-22 23:59:59'),
(2, 'Summer Peak 2026', '2026-06-01 00:00:00', '2026-08-31 23:59:59'),
(3, 'National Day 2026', '2026-09-01 00:00:00', '2026-09-03 23:59:59'),
(4, 'Year End 2026', '2026-12-20 00:00:00', '2027-01-03 23:59:59'),
(5, 'New Year 2026', '2026-01-01 00:00:00', '2026-01-04 23:59:59'),
(6, 'Hung Kings Festival 2026', '2026-04-14 00:00:00', '2026-04-16 23:59:59'),
(7, 'Reunification Day 2026', '2026-04-28 00:00:00', '2026-05-03 23:59:59'),
(8, 'Mid-Autumn 2026', '2026-09-24 00:00:00', '2026-09-27 23:59:59'),
(9, 'Black Friday 2026', '2026-11-26 00:00:00', '2026-11-29 23:59:59'),
(10, 'Tet Holiday 2027', '2027-02-03 00:00:00', '2027-02-11 23:59:59'),
(11, 'Spring Low 2027', '2027-03-01 00:00:00', '2027-03-31 23:59:59'),
(12, 'Hung Kings Festival 2027', '2027-04-15 00:00:00', '2027-04-17 23:59:59'),
(13, 'Reunification Day 2027', '2027-04-28 00:00:00', '2027-05-03 23:59:59'),
(14, 'Summer Peak 2027', '2027-06-01 00:00:00', '2027-08-31 23:59:59'),
(15, 'National Day 2027', '2027-09-01 00:00:00', '2027-09-03 23:59:59');

INSERT INTO HasRate (TypeID, RatePlan_ID, Price) VALUES
(1, 1, 1200000.00),
(2, 1, 1800000.00),
(3, 1, 2600000.00),
(4, 1, 4500000.00),
(5, 1, 980000.00),
(6, 1, 1280000.00),
(7, 1, 1500000.00),
(8, 1, 1500000.00),
(9, 1, 2250000.00),
(10, 1, 2100000.00),
(11, 1, 3300000.00),
(12, 1, 3750000.00),
(13, 1, 5700000.00),
(14, 1, 9750000.00),
(1, 2, 1000000.00),
(2, 2, 1500000.00),
(3, 2, 2200000.00),
(4, 2, 3600000.00),
(5, 2, 810000.00),
(6, 2, 1060000.00),
(7, 2, 1250000.00),
(8, 2, 1250000.00),
(9, 2, 1880000.00),
(10, 2, 1750000.00),
(11, 2, 2750000.00),
(12, 2, 3120000.00),
(13, 2, 4750000.00),
(14, 2, 8120000.00),
(1, 3, 1100000.00),
(2, 3, 1600000.00),
(3, 3, 2400000.00),
(5, 3, 880000.00),
(6, 3, 1150000.00),
(7, 3, 1350000.00),
(8, 3, 1350000.00),
(9, 3, 2030000.00),
(10, 3, 1890000.00),
(11, 3, 2970000.00),
(12, 3, 3380000.00),
(13, 3, 5130000.00),
(14, 3, 8780000.00),
(1, 4, 1300000.00),
(2, 4, 1900000.00),
(3, 4, 2800000.00),
(4, 4, 4800000.00),
(5, 4, 1040000.00),
(6, 4, 1360000.00),
(7, 4, 1600000.00),
(8, 4, 1600000.00),
(9, 4, 2400000.00),
(10, 4, 2240000.00),
(11, 4, 3520000.00),
(12, 4, 4000000.00),
(13, 4, 6080000.00),
(14, 4, 10400000.00),
(1, 5, 1120000.00),
(2, 5, 1680000.00),
(3, 5, 2520000.00),
(4, 5, 4200000.00),
(5, 5, 910000.00),
(6, 5, 1190000.00),
(7, 5, 1400000.00),
(8, 5, 1400000.00),
(9, 5, 2100000.00),
(10, 5, 1960000.00),
(11, 5, 3080000.00),
(12, 5, 3500000.00),
(13, 5, 5320000.00),
(14, 5, 9100000.00),
(1, 6, 880000.00),
(2, 6, 1320000.00),
(3, 6, 1980000.00),
(4, 6, 3300000.00),
(5, 6, 720000.00),
(6, 6, 940000.00),
(7, 6, 1100000.00),
(8, 6, 1100000.00),
(9, 6, 1650000.00),
(10, 6, 1540000.00),
(11, 6, 2420000.00),
(12, 6, 2750000.00),
(13, 6, 4180000.00),
(14, 6, 7150000.00),
(1, 7, 1040000.00),
(2, 7, 1560000.00),
(3, 7, 2340000.00),
(4, 7, 3900000.00),
(5, 7, 840000.00),
(6, 7, 1100000.00),
(7, 7, 1300000.00),
(8, 7, 1300000.00),
(9, 7, 1950000.00),
(10, 7, 1820000.00),
(11, 7, 2860000.00),
(12, 7, 3250000.00),
(13, 7, 4940000.00),
(14, 7, 8450000.00),
(1, 8, 960000.00),
(2, 8, 1440000.00),
(3, 8, 2160000.00),
(4, 8, 3600000.00),
(5, 8, 780000.00),
(6, 8, 1020000.00),
(7, 8, 1200000.00),
(8, 8, 1200000.00),
(9, 8, 1800000.00),
(10, 8, 1680000.00),
(11, 8, 2640000.00),
(12, 8, 3000000.00),
(13, 8, 4560000.00),
(14, 8, 7800000.00),
(1, 9, 680000.00),
(2, 9, 1020000.00),
(3, 9, 1530000.00),
(4, 9, 2550000.00),
(5, 9, 550000.00),
(6, 9, 720000.00),
(7, 9, 850000.00),
(8, 9, 850000.00),
(9, 9, 1280000.00),
(10, 9, 1190000.00),
(11, 9, 1870000.00),
(12, 9, 2120000.00),
(13, 9, 3230000.00),
(1, 10, 1200000.00),
(2, 10, 1800000.00),
(3, 10, 2700000.00),
(4, 10, 4500000.00),
(5, 10, 980000.00),
(6, 10, 1280000.00),
(7, 10, 1500000.00),
(8, 10, 1500000.00),
(9, 10, 2250000.00),
(10, 10, 2100000.00),
(11, 10, 3300000.00),
(12, 10, 3750000.00),
(13, 10, 5700000.00),
(14, 10, 9750000.00),
(1, 11, 640000.00),
(2, 11, 960000.00),
(3, 11, 1440000.00),
(4, 11, 2400000.00),
(5, 11, 520000.00),
(6, 11, 680000.00),
(7, 11, 800000.00),
(8, 11, 800000.00),
(9, 11, 1200000.00),
(10, 11, 1120000.00),
(11, 11, 1760000.00),
(12, 11, 2000000.00),
(13, 11, 3040000.00),
(14, 11, 5200000.00),
(1, 12, 880000.00),
(2, 12, 1320000.00),
(3, 12, 1980000.00),
(4, 12, 3300000.00),
(5, 12, 720000.00),
(6, 12, 940000.00),
(7, 12, 1100000.00),
(8, 12, 1100000.00),
(9, 12, 1650000.00),
(10, 12, 1540000.00),
(11, 12, 2420000.00),
(12, 12, 2750000.00),
(13, 12, 4180000.00),
(14, 12, 7150000.00),
(1, 13, 1040000.00),
(2, 13, 1560000.00),
(3, 13, 2340000.00),
(4, 13, 3900000.00),
(5, 13, 840000.00),
(6, 13, 1100000.00),
(7, 13, 1300000.00),
(8, 13, 1300000.00),
(9, 13, 1950000.00),
(10, 13, 1820000.00),
(11, 13, 2860000.00),
(12, 13, 3250000.00),
(13, 13, 4940000.00),
(14, 13, 8450000.00),
(1, 14, 1000000.00),
(2, 14, 1500000.00),
(3, 14, 2250000.00),
(4, 14, 3750000.00),
(5, 14, 810000.00),
(6, 14, 1060000.00),
(7, 14, 1250000.00),
(8, 14, 1250000.00),
(9, 14, 1880000.00),
(10, 14, 1750000.00),
(11, 14, 2750000.00),
(12, 14, 3120000.00),
(13, 14, 4750000.00),
(14, 14, 8120000.00),
(1, 15, 1080000.00),
(2, 15, 1620000.00),
(3, 15, 2430000.00),
(4, 15, 4050000.00),
(5, 15, 880000.00),
(6, 15, 1150000.00),
(7, 15, 1350000.00),
(8, 15, 1350000.00),
(9, 15, 2030000.00),
(10, 15, 1890000.00),
(11, 15, 2970000.00),
(12, 15, 3380000.00),
(13, 15, 5130000.00),
(14, 15, 8780000.00);

INSERT INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID) VALUES
(1, '101', 'Available', 1, 1),
(1, '102', 'Occupied', 1, 1),
(1, '103', 'Available', 1, 1),
(1, '201', 'Available', 2, 2),
(1, '202', 'Occupied', 2, 2),
(1, '301', 'Available', 3, 3),
(1, '302', 'Maintenance', 3, 3),
(1, 'P01', 'Available', 4, 4),
(2, '101', 'Available', 1, 1),
(2, '102', 'Available', 1, 1),
(2, '201', 'Occupied', 2, 2),
(2, '202', 'Available', 2, 2),
(2, '301', 'Available', 3, 3),
(2, '401', 'Available', 4, 4),
(3, '101', 'Available', 1, 1),
(3, '102', 'Available', 1, 1),
(3, '201', 'Available', 2, 2),
(3, '202', 'Maintenance', 2, 2),
(3, '301', 'Occupied', 3, 3),
(3, '401', 'Available', 4, 4),
(4, '101', 'Available', 1, 5),
(4, '201', 'Available', 2, 6),
(4, '301', 'Available', 3, 7),
(5, '101', 'Available', 1, 8),
(5, '201', 'Available', 2, 9),
(5, '301', 'Available', 3, 10),
(6, '101', 'Available', 1, 11),
(6, '201', 'Available', 2, 12),
(6, '301', 'Maintenance', 3, 13),
(7, '101', 'Available', 1, 14),
(7, '201', 'Available', 2, 15),
(7, '301', 'Available', 3, 1),
(8, '101', 'Available', 1, 2),
(8, '201', 'Available', 2, 3),
(8, '301', 'Available', 3, 4),
(9, '101', 'Available', 1, 5),
(9, '201', 'Available', 2, 6),
(9, '301', 'Available', 3, 7),
(10, '101', 'Available', 1, 8),
(10, '201', 'Available', 2, 9),
(10, '301', 'Available', 3, 10),
(11, '101', 'Available', 1, 11),
(11, '201', 'Available', 2, 12),
(11, '301', 'Available', 3, 13),
(12, '101', 'Available', 1, 14),
(12, '201', 'Available', 2, 15),
(12, '301', 'Available', 3, 1),
(13, '101', 'Available', 1, 2),
(13, '201', 'Available', 2, 3),
(13, '301', 'Available', 3, 4),
(14, '101', 'Available', 1, 5),
(14, '201', 'Available', 2, 6),
(14, '301', 'Available', 3, 7),
(15, '101', 'Available', 1, 8),
(15, '201', 'Available', 2, 9),
(15, '301', 'Available', 3, 10);

INSERT INTO Guests (Guest_ID, Doc_ID, Name) VALUES
(1, '079201004512', 'Nguyen Van An'),
(2, '079199012345', 'Tran Thi Bich'),
(3, '001200056789', 'Le Quang Huy'),
(4, '048198034567', 'Pham Ngoc Anh'),
(5, '079202078901', 'Hoang Minh Khoa'),
(6, '001199523456', 'Vu Thi Thu'),
(7, '048200167890', 'Dang Tuan Kiet'),
(8, '079197089012', 'Bui Thanh Hang'),
(9, 'C4825613', 'John Miller'),
(10, 'M71240985', 'Sakura Tanaka'),
(11, '092201045678', 'Do Gia Bao'),
(12, '036199867891', 'Ngo Phuong Thao'),
(13, '079204012233', 'Truong Minh Duc'),
(14, '001198845678', 'Lam Thi Kim Ngan'),
(15, 'P2045871', 'Emma Schmidt'),
(16, '052199912345', 'Phan Van Long'),
(17, '034201067890', 'Ha Thu Trang'),
(18, 'K7834512', 'Kim Min-jun'),
(19, '064200034567', 'Mai Anh Tuan'),
(20, '087199178901', 'Luong Bao Chau');

INSERT INTO Services (ServiceID, ServiceType) VALUES
(1, 'Breakfast'),
(2, 'Laundry'),
(3, 'Spa'),
(4, 'Airport Transfer'),
(5, 'Minibar'),
(6, 'Room Service'),
(7, 'Bike Rental'),
(8, 'Restaurant Dinner'),
(9, 'Gym Pass'),
(10, 'Late Checkout'),
(11, 'Extra Bed'),
(12, 'City Tour'),
(13, 'Car Rental'),
(14, 'Babysitting'),
(15, 'Meeting Room');

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
('0966444555', 11),
('0907111222', 13),
('0913333444', 14),
('0243888999', 14),
('+4915123456789', 15),
('0945222111', 16),
('0388765432', 17),
('+821012345678', 18),
('0868123987', 19),
('0779456123', 20);

INSERT INTO Reservation (Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID) VALUES
(1, '2026-02-13', '2026-02-16', 'CheckedOut', 2, 1, 1, 1),
(2, '2026-02-18', '2026-02-21', 'CheckedOut', 2, 2, 2, 2),
(3, '2026-03-05', '2026-03-08', 'CheckedOut', 1, 3, 1, 1),
(4, '2026-03-20', '2026-03-22', 'CheckedOut', 4, 4, 3, 3),
(5, '2026-04-10', '2026-04-13', 'CheckedOut', 2, 1, 2, 2),
(6, '2026-04-25', '2026-04-28', 'CheckedOut', 1, 5, 1, 3),
(7, '2026-05-29', '2026-06-03', 'CheckedOut', 2, 6, 2, 1),
(8, '2026-06-15', '2026-06-18', 'CheckedOut', 2, 2, 1, 1),
(9, '2026-06-20', '2026-06-24', 'CheckedOut', 3, 7, 4, 2),
(10, '2026-07-10', '2026-07-14', 'CheckedOut', 4, 1, 3, 3),
(11, '2026-07-18', '2026-07-21', 'CheckedOut', 2, 8, 2, 3),
(12, '2026-07-25', '2026-07-29', 'CheckedOut', 2, 9, 4, 1),
(13, '2026-08-05', '2026-08-08', 'CheckedOut', 2, 2, 2, 3),
(14, '2026-08-20', '2026-08-23', 'CheckedOut', 1, 3, 1, 2),
(15, '2026-08-30', '2026-09-04', 'CheckedOut', 2, 10, 4, 3),
(16, '2026-09-12', '2026-09-15', 'CheckedOut', 1, 9, 1, 3),
(17, '2026-10-02', '2026-10-05', 'CheckedOut', 3, 11, 3, 1),
(18, '2026-10-20', '2026-10-23', 'CheckedOut', 2, 4, 2, 2),
(19, '2026-11-03', '2026-11-06', 'CheckedOut', 1, 5, 1, 2),
(20, '2026-11-14', '2026-11-18', 'CheckedIn', 2, 6, 1, 1),
(21, '2026-11-15', '2026-11-19', 'CheckedIn', 2, 7, 2, 1),
(22, '2026-11-16', '2026-11-20', 'CheckedIn', 1, 8, 2, 2),
(23, '2026-11-13', '2026-11-18', 'CheckedIn', 4, 10, 3, 3),
(24, '2026-09-20', '2026-09-22', 'Cancelled', 3, 3, 3, 3),
(25, '2026-10-10', '2026-10-12', 'NoShow', 1, 11, 1, 1),
(26, '2026-12-22', '2026-12-26', 'Confirmed', 2, 1, 4, 1),
(27, '2026-12-05', '2026-12-07', 'Pending', 2, 4, 2, 2),
(28, '2027-01-01', '2027-01-04', 'Confirmed', 4, 2, 3, 2),
(29, '2026-05-10', '2026-05-12', 'Cancelled', 1, NULL, 1, 2),
(30, '2026-01-05', '2026-01-07', 'CheckedOut', 1, 1, 5, 4),
(31, '2026-01-13', '2026-01-16', 'CheckedOut', 2, 1, 8, 5),
(32, '2026-01-23', '2026-01-27', 'CheckedOut', 3, 1, 11, 6),
(33, '2026-02-04', '2026-02-06', 'CheckedOut', 1, 1, 14, 7),
(34, '2026-02-18', '2026-02-21', 'CheckedOut', 2, 1, 2, 8),
(35, '2026-03-03', '2026-03-07', 'CheckedOut', 1, 1, 5, 9),
(36, '2026-03-18', '2026-03-20', 'CheckedOut', 1, 1, 8, 10),
(37, '2026-04-01', '2026-04-04', 'CheckedOut', 2, 1, 11, 11),
(38, '2026-04-17', '2026-04-21', 'CheckedOut', 3, 1, 14, 12),
(39, '2026-05-05', '2026-05-07', 'CheckedOut', 1, 1, 2, 13),
(40, '2026-05-13', '2026-05-16', 'CheckedOut', 1, 1, 5, 14),
(41, '2026-05-23', '2026-05-27', 'CheckedOut', 2, 1, 8, 15),
(42, '2026-01-08', '2026-01-10', 'CheckedOut', 1, 2, 5, 4),
(43, '2026-01-19', '2026-01-22', 'CheckedOut', 2, 2, 8, 5),
(44, '2026-02-01', '2026-02-05', 'CheckedOut', 3, 2, 11, 6),
(45, '2026-02-23', '2026-02-25', 'CheckedOut', 1, 2, 14, 7),
(46, '2026-03-09', '2026-03-12', 'CheckedOut', 2, 2, 2, 8),
(47, '2026-03-25', '2026-03-29', 'CheckedOut', 1, 2, 5, 9),
(48, '2026-04-12', '2026-04-14', 'CheckedOut', 1, 2, 8, 10),
(49, '2026-04-20', '2026-04-23', 'CheckedOut', 2, 2, 11, 11),
(50, '2026-04-30', '2026-05-04', 'CheckedOut', 3, 2, 14, 12),
(51, '2026-05-12', '2026-05-14', 'CheckedOut', 1, 2, 2, 13),
(52, '2026-05-23', '2026-05-26', 'CheckedOut', 1, 2, 5, 14),
(53, '2026-06-05', '2026-06-09', 'CheckedOut', 2, 2, 8, 15),
(54, '2026-01-12', '2026-01-14', 'CheckedOut', 1, 3, 5, 4),
(55, '2026-01-26', '2026-01-29', 'CheckedOut', 2, 3, 8, 5),
(56, '2026-02-11', '2026-02-15', 'CheckedOut', 3, 3, 11, 6),
(57, '2026-03-01', '2026-03-03', 'CheckedOut', 1, 3, 14, 7),
(58, '2026-03-10', '2026-03-13', 'CheckedOut', 2, 3, 3, 8),
(59, '2026-03-20', '2026-03-24', 'CheckedOut', 1, 3, 5, 9),
(60, '2026-04-01', '2026-04-03', 'CheckedOut', 1, 3, 8, 10),
(61, '2026-04-12', '2026-04-15', 'CheckedOut', 2, 3, 11, 11),
(62, '2026-04-25', '2026-04-29', 'CheckedOut', 3, 3, 14, 12),
(63, '2026-05-10', '2026-05-12', 'CheckedOut', 1, 3, 3, 13),
(64, '2026-05-24', '2026-05-27', 'CheckedOut', 2, 3, 6, 14),
(65, '2026-06-09', '2026-06-13', 'CheckedOut', 2, 3, 9, 15),
(66, '2026-03-03', '2026-03-05', 'CheckedOut', 1, 13, 5, 4),
(67, '2026-03-20', '2026-03-23', 'CheckedOut', 2, 13, 6, 9),
(68, '2026-04-06', '2026-04-10', 'CheckedOut', 2, 14, 8, 5),
(69, '2026-04-23', '2026-04-25', 'CheckedOut', 1, 15, 2, 8),
(70, '2026-05-10', '2026-05-13', 'CheckedOut', 2, 15, 14, 12),
(71, '2026-05-27', '2026-05-31', 'CheckedOut', 3, 16, 11, 6),
(72, '2026-06-13', '2026-06-15', 'CheckedOut', 1, 17, 14, 7),
(73, '2026-06-30', '2026-07-03', 'CheckedOut', 2, 18, 11, 11),
(74, '2026-07-17', '2026-07-21', 'CheckedOut', 2, 19, 2, 13),
(75, '2026-08-03', '2026-08-05', 'CheckedOut', 1, 20, 8, 10),
(76, '2026-08-20', '2026-08-23', 'CheckedOut', 1, 20, 5, 14);

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
(23, '2026-11-13', 'Open'),
(30, '2026-01-07', 'Paid'),
(31, '2026-01-16', 'Paid'),
(32, '2026-01-27', 'Paid'),
(33, '2026-02-06', 'Paid'),
(34, '2026-02-21', 'Paid'),
(35, '2026-03-07', 'Paid'),
(36, '2026-03-20', 'Paid'),
(37, '2026-04-04', 'Paid'),
(38, '2026-04-21', 'Paid'),
(39, '2026-05-07', 'Paid'),
(40, '2026-05-16', 'Paid'),
(41, '2026-05-27', 'Paid'),
(42, '2026-01-10', 'Paid'),
(43, '2026-01-22', 'Paid'),
(44, '2026-02-05', 'Paid'),
(45, '2026-02-25', 'Paid'),
(46, '2026-03-12', 'Paid'),
(47, '2026-03-29', 'Paid'),
(48, '2026-04-14', 'Paid'),
(49, '2026-04-23', 'Paid'),
(50, '2026-05-04', 'Paid'),
(51, '2026-05-14', 'Paid'),
(52, '2026-05-26', 'Paid'),
(53, '2026-06-09', 'Paid'),
(54, '2026-01-14', 'Paid'),
(55, '2026-01-29', 'Paid'),
(56, '2026-02-15', 'Paid'),
(57, '2026-03-03', 'Paid'),
(58, '2026-03-13', 'Paid'),
(59, '2026-03-24', 'Paid'),
(60, '2026-04-03', 'Paid'),
(61, '2026-04-15', 'Paid'),
(62, '2026-04-29', 'Paid'),
(63, '2026-05-12', 'Paid'),
(64, '2026-05-27', 'Paid'),
(65, '2026-06-13', 'Paid'),
(66, '2026-03-05', 'Paid'),
(67, '2026-03-23', 'Paid'),
(68, '2026-04-10', 'Paid'),
(69, '2026-04-25', 'Paid'),
(70, '2026-05-13', 'Paid'),
(71, '2026-05-31', 'Paid'),
(72, '2026-06-15', 'Paid'),
(73, '2026-07-03', 'Paid'),
(74, '2026-07-21', 'Paid'),
(75, '2026-08-05', 'Paid'),
(76, '2026-08-23', 'Paid');

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
(23, '2026-11-13 16:10:00', NULL, 23, 23, 3, '301'),
(30, '2026-01-05 14:05:00', '2026-01-07 10:20:00', 30, 30, 4, '101'),
(31, '2026-01-13 15:20:00', '2026-01-16 09:30:00', 31, 31, 5, '101'),
(32, '2026-01-23 14:30:00', '2026-01-27 10:30:00', 32, 32, 6, '101'),
(33, '2026-02-04 16:10:00', '2026-02-06 11:00:00', 33, 33, 7, '101'),
(34, '2026-02-18 14:00:00', '2026-02-21 09:45:00', 34, 34, 8, '101'),
(35, '2026-03-03 18:45:00', '2026-03-07 11:15:00', 35, 35, 9, '101'),
(36, '2026-03-18 14:15:00', '2026-03-20 10:00:00', 36, 36, 10, '101'),
(37, '2026-04-01 15:00:00', '2026-04-04 11:50:00', 37, 37, 11, '101'),
(38, '2026-04-17 14:40:00', '2026-04-21 10:20:00', 38, 38, 12, '101'),
(39, '2026-05-05 13:55:00', '2026-05-07 09:30:00', 39, 39, 13, '101'),
(40, '2026-05-13 14:05:00', '2026-05-16 10:30:00', 40, 40, 14, '101'),
(41, '2026-05-23 15:20:00', '2026-05-27 11:00:00', 41, 41, 15, '101'),
(42, '2026-01-08 14:30:00', '2026-01-10 09:45:00', 42, 42, 4, '101'),
(43, '2026-01-19 16:10:00', '2026-01-22 11:15:00', 43, 43, 5, '101'),
(44, '2026-02-01 14:00:00', '2026-02-05 10:00:00', 44, 44, 6, '101'),
(45, '2026-02-23 18:45:00', '2026-02-25 11:50:00', 45, 45, 7, '101'),
(46, '2026-03-09 14:15:00', '2026-03-12 10:20:00', 46, 46, 8, '101'),
(47, '2026-03-25 15:00:00', '2026-03-29 09:30:00', 47, 47, 9, '101'),
(48, '2026-04-12 14:40:00', '2026-04-14 10:30:00', 48, 48, 10, '101'),
(49, '2026-04-20 13:55:00', '2026-04-23 11:00:00', 49, 49, 11, '101'),
(50, '2026-04-30 14:05:00', '2026-05-04 09:45:00', 50, 50, 12, '101'),
(51, '2026-05-12 15:20:00', '2026-05-14 11:15:00', 51, 51, 13, '101'),
(52, '2026-05-23 14:30:00', '2026-05-26 10:00:00', 52, 52, 14, '101'),
(53, '2026-06-05 16:10:00', '2026-06-09 11:50:00', 53, 53, 15, '101'),
(54, '2026-01-12 14:00:00', '2026-01-14 10:20:00', 54, 54, 4, '101'),
(55, '2026-01-26 18:45:00', '2026-01-29 09:30:00', 55, 55, 5, '101'),
(56, '2026-02-11 14:15:00', '2026-02-15 10:30:00', 56, 56, 6, '101'),
(57, '2026-03-01 15:00:00', '2026-03-03 11:00:00', 57, 57, 7, '101'),
(58, '2026-03-10 14:40:00', '2026-03-13 09:45:00', 58, 58, 8, '201'),
(59, '2026-03-20 13:55:00', '2026-03-24 11:15:00', 59, 59, 9, '101'),
(60, '2026-04-01 14:05:00', '2026-04-03 10:00:00', 60, 60, 10, '101'),
(61, '2026-04-12 15:20:00', '2026-04-15 11:50:00', 61, 61, 11, '101'),
(62, '2026-04-25 14:30:00', '2026-04-29 10:20:00', 62, 62, 12, '101'),
(63, '2026-05-10 16:10:00', '2026-05-12 09:30:00', 63, 63, 13, '201'),
(64, '2026-05-24 14:00:00', '2026-05-27 10:30:00', 64, 64, 14, '201'),
(65, '2026-06-09 18:45:00', '2026-06-13 11:00:00', 65, 65, 15, '201'),
(66, '2026-03-03 14:15:00', '2026-03-05 09:45:00', 66, 66, 4, '101'),
(67, '2026-03-20 15:00:00', '2026-03-23 11:15:00', 67, 67, 9, '201'),
(68, '2026-04-06 14:40:00', '2026-04-10 10:00:00', 68, 68, 5, '101'),
(69, '2026-04-23 13:55:00', '2026-04-25 11:50:00', 69, 69, 8, '101'),
(70, '2026-05-10 14:05:00', '2026-05-13 10:20:00', 70, 70, 12, '101'),
(71, '2026-05-27 15:20:00', '2026-05-31 09:30:00', 71, 71, 6, '101'),
(72, '2026-06-13 14:30:00', '2026-06-15 10:30:00', 72, 72, 7, '101'),
(73, '2026-06-30 16:10:00', '2026-07-03 11:00:00', 73, 73, 11, '101'),
(74, '2026-07-17 14:00:00', '2026-07-21 09:45:00', 74, 74, 13, '101'),
(75, '2026-08-03 18:45:00', '2026-08-05 11:15:00', 75, 75, 10, '101'),
(76, '2026-08-20 14:15:00', '2026-08-23 10:00:00', 76, 76, 14, '101');

-- ---------------------------------------------------------------------
-- Records: services used during a stay (Price = unit price at that time).
-- Breakfast cost 150,000 until June and 180,000 from July; the price is
-- stored here because Services has no price column.
-- Some stays used no services. Service 7 (Bike Rental) is never sold.
-- ---------------------------------------------------------------------
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
(23, 1, '2026-11-16 08:00:00', 180000.00, 4),
(30, 8, '2026-01-06 19:30:00', 450000.00, 1),
(31, 1, '2026-01-14 07:30:00', 150000.00, 2),
(31, 10, '2026-01-16 09:00:00', 300000.00, 1),
(32, 2, '2026-01-24 19:30:00', 80000.00, 1),
(32, 13, '2026-01-24 19:30:00', 900000.00, 1),
(33, 5, '2026-02-05 19:30:00', 120000.00, 2),
(34, 3, '2026-02-19 19:30:00', 600000.00, 1),
(34, 5, '2026-02-19 19:30:00', 120000.00, 1),
(35, 9, '2026-03-04 19:30:00', 100000.00, 2),
(35, 6, '2026-03-04 19:30:00', 200000.00, 2),
(37, 4, '2026-04-02 19:30:00', 350000.00, 2),
(37, 14, '2026-04-02 19:30:00', 250000.00, 2),
(38, 10, '2026-04-21 09:00:00', 300000.00, 1),
(38, 1, '2026-04-18 07:30:00', 150000.00, 3),
(39, 11, '2026-05-05 20:00:00', 400000.00, 1),
(40, 12, '2026-05-14 19:30:00', 700000.00, 1),
(40, 4, '2026-05-14 19:30:00', 350000.00, 1),
(41, 13, '2026-05-24 19:30:00', 900000.00, 2),
(41, 12, '2026-05-24 19:30:00', 700000.00, 2),
(42, 14, '2026-01-09 19:30:00', 250000.00, 1),
(44, 8, '2026-02-02 19:30:00', 450000.00, 1),
(44, 9, '2026-02-02 19:30:00', 100000.00, 1),
(45, 1, '2026-02-24 07:30:00', 150000.00, 1),
(46, 2, '2026-03-10 19:30:00', 80000.00, 1),
(46, 13, '2026-03-10 19:30:00', 900000.00, 1),
(47, 5, '2026-03-26 19:30:00', 120000.00, 2),
(47, 8, '2026-03-26 19:30:00', 450000.00, 2),
(48, 3, '2026-04-13 19:30:00', 600000.00, 1),
(49, 9, '2026-04-21 19:30:00', 100000.00, 2),
(49, 6, '2026-04-21 19:30:00', 200000.00, 2),
(51, 4, '2026-05-13 19:30:00', 350000.00, 2),
(52, 10, '2026-05-26 09:00:00', 300000.00, 1),
(52, 1, '2026-05-24 07:30:00', 150000.00, 1),
(53, 11, '2026-06-05 20:00:00', 400000.00, 1),
(53, 3, '2026-06-06 19:30:00', 600000.00, 2),
(54, 12, '2026-01-13 19:30:00', 700000.00, 1),
(55, 13, '2026-01-27 19:30:00', 900000.00, 2),
(55, 12, '2026-01-27 19:30:00', 700000.00, 2),
(56, 14, '2026-02-12 19:30:00', 250000.00, 1),
(56, 15, '2026-02-12 19:30:00', 1500000.00, 1),
(58, 8, '2026-03-11 19:30:00', 450000.00, 1),
(58, 9, '2026-03-11 19:30:00', 100000.00, 1),
(59, 1, '2026-03-21 07:30:00', 150000.00, 1),
(59, 10, '2026-03-24 09:00:00', 300000.00, 1),
(60, 2, '2026-04-02 19:30:00', 80000.00, 1),
(61, 5, '2026-04-13 19:30:00', 120000.00, 2),
(61, 8, '2026-04-13 19:30:00', 450000.00, 2),
(62, 3, '2026-04-26 19:30:00', 600000.00, 1),
(62, 5, '2026-04-26 19:30:00', 120000.00, 1),
(63, 9, '2026-05-11 19:30:00', 100000.00, 2),
(65, 4, '2026-06-10 19:30:00', 350000.00, 2),
(65, 14, '2026-06-10 19:30:00', 250000.00, 2),
(66, 10, '2026-03-05 09:00:00', 300000.00, 1),
(67, 11, '2026-03-20 20:00:00', 400000.00, 1),
(67, 3, '2026-03-21 19:30:00', 600000.00, 2),
(68, 12, '2026-04-07 19:30:00', 700000.00, 1),
(68, 4, '2026-04-07 19:30:00', 350000.00, 1),
(69, 13, '2026-04-24 19:30:00', 900000.00, 2),
(70, 14, '2026-05-11 19:30:00', 250000.00, 1),
(70, 15, '2026-05-11 19:30:00', 1500000.00, 1),
(72, 8, '2026-06-14 19:30:00', 450000.00, 1),
(73, 1, '2026-07-01 07:30:00', 180000.00, 2),
(73, 10, '2026-07-03 09:00:00', 300000.00, 1),
(74, 2, '2026-07-18 19:30:00', 80000.00, 1),
(74, 13, '2026-07-18 19:30:00', 900000.00, 1),
(75, 5, '2026-08-04 19:30:00', 120000.00, 2),
(76, 3, '2026-08-21 19:30:00', 600000.00, 1),
(76, 5, '2026-08-21 19:30:00', 120000.00, 1);

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
(3, 19, 'Service', 350000.00, 'Airport Transfer on 2026-11-06: 1 x 350,000'),
(1, 20, 'Room', 2400000.00, 'Standard room 102: 3 nights x 800,000 (Base price, charged to 2026-11-16)'),
(2, 20, 'Service', 360000.00, 'Breakfast on 2026-11-15: 2 x 180,000'),
(3, 20, 'Service', 360000.00, 'Breakfast on 2026-11-16: 2 x 180,000'),
(1, 21, 'Room', 2400000.00, 'Deluxe room 202: 2 nights x 1,200,000 (Base price, charged to 2026-11-16)'),
(2, 21, 'Service', 600000.00, 'Spa on 2026-11-16: 1 x 600,000'),
(1, 22, 'Room', 1200000.00, 'Deluxe room 201: 1 night x 1,200,000 (Base price, charged to 2026-11-16)'),
(2, 22, 'Service', 200000.00, 'Room Service on 2026-11-16: 1 x 200,000'),
(1, 23, 'Room', 7200000.00, 'Family room 301: 4 nights x 1,800,000 (Base price, charged to 2026-11-16)'),
(2, 23, 'Service', 720000.00, 'Breakfast on 2026-11-14: 4 x 180,000'),
(3, 23, 'Service', 720000.00, 'Breakfast on 2026-11-15: 4 x 180,000'),
(4, 23, 'Service', 160000.00, 'Laundry on 2026-11-15: 2 x 80,000'),
(5, 23, 'Service', 720000.00, 'Breakfast on 2026-11-16: 4 x 180,000'),
(1, 30, 'Room', 1300000.00, 'Standard Single room 101: 2 nights x 650,000 (Base price)'),
(2, 30, 'Service', 450000.00, 'Restaurant Dinner on 2026-01-06: 1 x 450,000'),
(1, 31, 'Room', 3000000.00, 'Superior Twin room 101: 3 nights x 1,000,000 (Base price)'),
(2, 31, 'Service', 300000.00, 'Breakfast on 2026-01-14: 2 x 150,000'),
(3, 31, 'Service', 300000.00, 'Late Checkout on 2026-01-16: 1 x 300,000'),
(1, 32, 'Room', 8800000.00, 'Family Connecting room 101: 4 nights x 2,200,000 (Base price)'),
(2, 32, 'Service', 80000.00, 'Laundry on 2026-01-24: 1 x 80,000'),
(3, 32, 'Service', 900000.00, 'Car Rental on 2026-01-24: 1 x 900,000'),
(1, 33, 'Room', 13000000.00, 'Presidential Suite room 101: 2 nights x 6,500,000 (Base price)'),
(2, 33, 'Service', 240000.00, 'Minibar on 2026-02-05: 2 x 120,000'),
(1, 34, 'Room', 5400000.00, 'Deluxe room 101: 3 nights x 1,800,000 (Tet Holiday 2026)'),
(2, 34, 'Service', 600000.00, 'Spa on 2026-02-19: 1 x 600,000'),
(3, 34, 'Service', 120000.00, 'Minibar on 2026-02-19: 1 x 120,000'),
(1, 35, 'Room', 2600000.00, 'Standard Single room 101: 4 nights x 650,000 (Base price)'),
(2, 35, 'Service', 200000.00, 'Gym Pass on 2026-03-04: 2 x 100,000'),
(3, 35, 'Service', 400000.00, 'Room Service on 2026-03-04: 2 x 200,000'),
(1, 36, 'Room', 2000000.00, 'Superior Twin room 101: 2 nights x 1,000,000 (Base price)'),
(1, 37, 'Room', 6600000.00, 'Family Connecting room 101: 3 nights x 2,200,000 (Base price)'),
(2, 37, 'Service', 700000.00, 'Airport Transfer on 2026-04-02: 2 x 350,000'),
(3, 37, 'Service', 500000.00, 'Babysitting on 2026-04-02: 2 x 250,000'),
(1, 38, 'Room', 26000000.00, 'Presidential Suite room 101: 4 nights x 6,500,000 (Base price)'),
(2, 38, 'Service', 300000.00, 'Late Checkout on 2026-04-21: 1 x 300,000'),
(3, 38, 'Service', 450000.00, 'Breakfast on 2026-04-18: 3 x 150,000'),
(1, 39, 'Room', 2400000.00, 'Deluxe room 101: 2 nights x 1,200,000 (Base price)'),
(2, 39, 'Service', 400000.00, 'Extra Bed on 2026-05-05: 1 x 400,000'),
(1, 40, 'Room', 1950000.00, 'Standard Single room 101: 3 nights x 650,000 (Base price)'),
(2, 40, 'Service', 700000.00, 'City Tour on 2026-05-14: 1 x 700,000'),
(3, 40, 'Service', 350000.00, 'Airport Transfer on 2026-05-14: 1 x 350,000'),
(1, 41, 'Room', 4000000.00, 'Superior Twin room 101: 4 nights x 1,000,000 (Base price)'),
(2, 41, 'Service', 1800000.00, 'Car Rental on 2026-05-24: 2 x 900,000'),
(3, 41, 'Service', 1400000.00, 'City Tour on 2026-05-24: 2 x 700,000'),
(1, 42, 'Room', 1300000.00, 'Standard Single room 101: 2 nights x 650,000 (Base price)'),
(2, 42, 'Service', 250000.00, 'Babysitting on 2026-01-09: 1 x 250,000'),
(1, 43, 'Room', 3000000.00, 'Superior Twin room 101: 3 nights x 1,000,000 (Base price)'),
(1, 44, 'Room', 8800000.00, 'Family Connecting room 101: 4 nights x 2,200,000 (Base price)'),
(2, 44, 'Service', 450000.00, 'Restaurant Dinner on 2026-02-02: 1 x 450,000'),
(3, 44, 'Service', 100000.00, 'Gym Pass on 2026-02-02: 1 x 100,000'),
(1, 45, 'Room', 13000000.00, 'Presidential Suite room 101: 2 nights x 6,500,000 (Base price)'),
(2, 45, 'Service', 150000.00, 'Breakfast on 2026-02-24: 1 x 150,000'),
(1, 46, 'Room', 3600000.00, 'Deluxe room 101: 3 nights x 1,200,000 (Base price)'),
(2, 46, 'Service', 80000.00, 'Laundry on 2026-03-10: 1 x 80,000'),
(3, 46, 'Service', 900000.00, 'Car Rental on 2026-03-10: 1 x 900,000'),
(1, 47, 'Room', 2600000.00, 'Standard Single room 101: 4 nights x 650,000 (Base price)'),
(2, 47, 'Service', 240000.00, 'Minibar on 2026-03-26: 2 x 120,000'),
(3, 47, 'Service', 900000.00, 'Restaurant Dinner on 2026-03-26: 2 x 450,000'),
(1, 48, 'Room', 2000000.00, 'Superior Twin room 101: 2 nights x 1,000,000 (Base price)'),
(2, 48, 'Service', 600000.00, 'Spa on 2026-04-13: 1 x 600,000'),
(1, 49, 'Room', 6600000.00, 'Family Connecting room 101: 3 nights x 2,200,000 (Base price)'),
(2, 49, 'Service', 200000.00, 'Gym Pass on 2026-04-21: 2 x 100,000'),
(3, 49, 'Service', 400000.00, 'Room Service on 2026-04-21: 2 x 200,000'),
(1, 50, 'Room', 33800000.00, 'Presidential Suite room 101: 4 nights x 8,450,000 (Reunification Day 2026)'),
(1, 51, 'Room', 2400000.00, 'Deluxe room 101: 2 nights x 1,200,000 (Base price)'),
(2, 51, 'Service', 700000.00, 'Airport Transfer on 2026-05-13: 2 x 350,000'),
(1, 52, 'Room', 1950000.00, 'Standard Single room 101: 3 nights x 650,000 (Base price)'),
(2, 52, 'Service', 300000.00, 'Late Checkout on 2026-05-26: 1 x 300,000'),
(3, 52, 'Service', 150000.00, 'Breakfast on 2026-05-24: 1 x 150,000'),
(1, 53, 'Room', 5000000.00, 'Superior Twin room 101: 4 nights x 1,250,000 (Summer Peak 2026)'),
(2, 53, 'Service', 400000.00, 'Extra Bed on 2026-06-05: 1 x 400,000'),
(3, 53, 'Service', 1200000.00, 'Spa on 2026-06-06: 2 x 600,000'),
(1, 54, 'Room', 1300000.00, 'Standard Single room 101: 2 nights x 650,000 (Base price)'),
(2, 54, 'Service', 700000.00, 'City Tour on 2026-01-13: 1 x 700,000'),
(1, 55, 'Room', 3000000.00, 'Superior Twin room 101: 3 nights x 1,000,000 (Base price)'),
(2, 55, 'Service', 1800000.00, 'Car Rental on 2026-01-27: 2 x 900,000'),
(3, 55, 'Service', 1400000.00, 'City Tour on 2026-01-27: 2 x 700,000'),
(1, 56, 'Room', 6600000.00, 'Family Connecting room 101: 3 nights x 2,200,000 (Base price)'),
(2, 56, 'Room', 3300000.00, 'Family Connecting room 101: 1 night x 3,300,000 (Tet Holiday 2026)'),
(3, 56, 'Service', 250000.00, 'Babysitting on 2026-02-12: 1 x 250,000'),
(4, 56, 'Service', 1500000.00, 'Meeting Room on 2026-02-12: 1 x 1,500,000'),
(1, 57, 'Room', 13000000.00, 'Presidential Suite room 101: 2 nights x 6,500,000 (Base price)'),
(1, 58, 'Room', 5400000.00, 'Family room 201: 3 nights x 1,800,000 (Base price)'),
(2, 58, 'Service', 450000.00, 'Restaurant Dinner on 2026-03-11: 1 x 450,000'),
(3, 58, 'Service', 100000.00, 'Gym Pass on 2026-03-11: 1 x 100,000'),
(1, 59, 'Room', 2600000.00, 'Standard Single room 101: 4 nights x 650,000 (Base price)'),
(2, 59, 'Service', 150000.00, 'Breakfast on 2026-03-21: 1 x 150,000'),
(3, 59, 'Service', 300000.00, 'Late Checkout on 2026-03-24: 1 x 300,000'),
(1, 60, 'Room', 2000000.00, 'Superior Twin room 101: 2 nights x 1,000,000 (Base price)'),
(2, 60, 'Service', 80000.00, 'Laundry on 2026-04-02: 1 x 80,000'),
(1, 61, 'Room', 4400000.00, 'Family Connecting room 101: 2 nights x 2,200,000 (Base price)'),
(2, 61, 'Room', 2420000.00, 'Family Connecting room 101: 1 night x 2,420,000 (Hung Kings Festival 2026)'),
(3, 61, 'Service', 240000.00, 'Minibar on 2026-04-13: 2 x 120,000'),
(4, 61, 'Service', 900000.00, 'Restaurant Dinner on 2026-04-13: 2 x 450,000'),
(1, 62, 'Room', 19500000.00, 'Presidential Suite room 101: 3 nights x 6,500,000 (Base price)'),
(2, 62, 'Room', 8450000.00, 'Presidential Suite room 101: 1 night x 8,450,000 (Reunification Day 2026)'),
(3, 62, 'Service', 600000.00, 'Spa on 2026-04-26: 1 x 600,000'),
(4, 62, 'Service', 120000.00, 'Minibar on 2026-04-26: 1 x 120,000'),
(1, 63, 'Room', 3600000.00, 'Family room 201: 2 nights x 1,800,000 (Base price)'),
(2, 63, 'Service', 200000.00, 'Gym Pass on 2026-05-11: 2 x 100,000'),
(1, 64, 'Room', 2550000.00, 'Standard Twin room 201: 3 nights x 850,000 (Base price)'),
(1, 65, 'Room', 7520000.00, 'Deluxe Sea View room 201: 4 nights x 1,880,000 (Summer Peak 2026)'),
(2, 65, 'Service', 700000.00, 'Airport Transfer on 2026-06-10: 2 x 350,000'),
(3, 65, 'Service', 500000.00, 'Babysitting on 2026-06-10: 2 x 250,000'),
(1, 66, 'Room', 1300000.00, 'Standard Single room 101: 2 nights x 650,000 (Base price)'),
(2, 66, 'Service', 300000.00, 'Late Checkout on 2026-03-05: 1 x 300,000'),
(1, 67, 'Room', 2550000.00, 'Standard Twin room 201: 3 nights x 850,000 (Base price)'),
(2, 67, 'Service', 400000.00, 'Extra Bed on 2026-03-20: 1 x 400,000'),
(3, 67, 'Service', 1200000.00, 'Spa on 2026-03-21: 2 x 600,000'),
(1, 68, 'Room', 4000000.00, 'Superior Twin room 101: 4 nights x 1,000,000 (Base price)'),
(2, 68, 'Service', 700000.00, 'City Tour on 2026-04-07: 1 x 700,000'),
(3, 68, 'Service', 350000.00, 'Airport Transfer on 2026-04-07: 1 x 350,000'),
(1, 69, 'Room', 2400000.00, 'Deluxe room 101: 2 nights x 1,200,000 (Base price)'),
(2, 69, 'Service', 1800000.00, 'Car Rental on 2026-04-24: 2 x 900,000'),
(1, 70, 'Room', 19500000.00, 'Presidential Suite room 101: 3 nights x 6,500,000 (Base price)'),
(2, 70, 'Service', 250000.00, 'Babysitting on 2026-05-11: 1 x 250,000'),
(3, 70, 'Service', 1500000.00, 'Meeting Room on 2026-05-11: 1 x 1,500,000'),
(1, 71, 'Room', 8800000.00, 'Family Connecting room 101: 4 nights x 2,200,000 (Base price)'),
(1, 72, 'Room', 16240000.00, 'Presidential Suite room 101: 2 nights x 8,120,000 (Summer Peak 2026)'),
(2, 72, 'Service', 450000.00, 'Restaurant Dinner on 2026-06-14: 1 x 450,000'),
(1, 73, 'Room', 8250000.00, 'Family Connecting room 101: 3 nights x 2,750,000 (Summer Peak 2026)'),
(2, 73, 'Service', 360000.00, 'Breakfast on 2026-07-01: 2 x 180,000'),
(3, 73, 'Service', 300000.00, 'Late Checkout on 2026-07-03: 1 x 300,000'),
(1, 74, 'Room', 6000000.00, 'Deluxe room 101: 4 nights x 1,500,000 (Summer Peak 2026)'),
(2, 74, 'Service', 80000.00, 'Laundry on 2026-07-18: 1 x 80,000'),
(3, 74, 'Service', 900000.00, 'Car Rental on 2026-07-18: 1 x 900,000'),
(1, 75, 'Room', 2500000.00, 'Superior Twin room 101: 2 nights x 1,250,000 (Summer Peak 2026)'),
(2, 75, 'Service', 240000.00, 'Minibar on 2026-08-04: 2 x 120,000'),
(1, 76, 'Room', 2430000.00, 'Standard Single room 101: 3 nights x 810,000 (Summer Peak 2026)'),
(2, 76, 'Service', 600000.00, 'Spa on 2026-08-21: 1 x 600,000'),
(3, 76, 'Service', 120000.00, 'Minibar on 2026-08-21: 1 x 120,000');

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
(20, '2026-10-23 09:45:00', 'BankTransfer', 4000000.00, 18),
(21, '2026-01-07 10:20:00', 'BankTransfer', 1750000.00, 30),
(22, '2026-01-16 09:30:00', 'EWallet', 3600000.00, 31),
(23, '2026-01-27 10:30:00', 'CreditCard', 9780000.00, 32),
(24, '2026-02-06 11:00:00', 'Cash', 13240000.00, 33),
(25, '2026-02-21 09:45:00', 'BankTransfer', 6120000.00, 34),
(26, '2026-03-07 11:15:00', 'EWallet', 3200000.00, 35),
(27, '2026-03-20 10:00:00', 'CreditCard', 2000000.00, 36),
(28, '2026-04-04 11:50:00', 'Cash', 7800000.00, 37),
(29, '2026-04-21 10:20:00', 'BankTransfer', 26750000.00, 38),
(30, '2026-05-07 09:30:00', 'EWallet', 2800000.00, 39),
(31, '2026-05-16 10:30:00', 'CreditCard', 3000000.00, 40),
(32, '2026-05-27 11:00:00', 'Cash', 7200000.00, 41),
(33, '2026-01-10 09:45:00', 'BankTransfer', 1550000.00, 42),
(34, '2026-01-22 11:15:00', 'EWallet', 3000000.00, 43),
(35, '2026-02-05 10:00:00', 'CreditCard', 9350000.00, 44),
(36, '2026-02-25 11:50:00', 'Cash', 13150000.00, 45),
(37, '2026-03-12 10:20:00', 'BankTransfer', 4580000.00, 46),
(38, '2026-03-29 09:30:00', 'EWallet', 3740000.00, 47),
(39, '2026-04-14 10:30:00', 'CreditCard', 2600000.00, 48),
(40, '2026-04-23 11:00:00', 'Cash', 7200000.00, 49),
(41, '2026-05-04 09:45:00', 'BankTransfer', 33800000.00, 50),
(42, '2026-05-14 11:15:00', 'EWallet', 3100000.00, 51),
(43, '2026-05-26 10:00:00', 'CreditCard', 2400000.00, 52),
(44, '2026-06-09 11:50:00', 'Cash', 6600000.00, 53),
(45, '2026-01-14 10:20:00', 'BankTransfer', 2000000.00, 54),
(46, '2026-01-29 09:30:00', 'EWallet', 6200000.00, 55),
(47, '2026-02-15 10:30:00', 'CreditCard', 11650000.00, 56),
(48, '2026-03-03 11:00:00', 'Cash', 13000000.00, 57),
(49, '2026-03-13 09:45:00', 'BankTransfer', 5950000.00, 58),
(50, '2026-03-24 11:15:00', 'EWallet', 3050000.00, 59),
(51, '2026-04-03 10:00:00', 'CreditCard', 2080000.00, 60),
(52, '2026-04-15 11:50:00', 'Cash', 7960000.00, 61),
(53, '2026-04-29 10:20:00', 'BankTransfer', 28670000.00, 62),
(54, '2026-05-12 09:30:00', 'EWallet', 3800000.00, 63),
(55, '2026-05-27 10:30:00', 'CreditCard', 2550000.00, 64),
(56, '2026-06-13 11:00:00', 'Cash', 8720000.00, 65),
(57, '2026-03-05 09:45:00', 'BankTransfer', 1600000.00, 66),
(58, '2026-03-23 11:15:00', 'EWallet', 4150000.00, 67),
(59, '2026-04-10 10:00:00', 'CreditCard', 5050000.00, 68),
(60, '2026-04-25 11:50:00', 'Cash', 4200000.00, 69),
(61, '2026-05-13 10:20:00', 'BankTransfer', 21250000.00, 70),
(62, '2026-05-31 09:30:00', 'EWallet', 8800000.00, 71),
(63, '2026-06-15 10:30:00', 'CreditCard', 16690000.00, 72),
(64, '2026-07-03 11:00:00', 'Cash', 8910000.00, 73),
(65, '2026-07-21 09:45:00', 'BankTransfer', 6980000.00, 74),
(66, '2026-08-05 11:15:00', 'EWallet', 2740000.00, 75),
(67, '2026-08-23 10:00:00', 'CreditCard', 3150000.00, 76);

-- QUICK CHECK --
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
