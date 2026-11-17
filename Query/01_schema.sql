-- =====================================================================
-- IT079IU - Hotel Management (Topic 23)
-- 01_schema.sql : database + tables + constraints
-- Target DBMS : MySQL 8.0+ (also tested on MariaDB 10.11). Standard SQL
--               is used wherever possible; dialect-specific parts are
--               marked with "-- [MySQL]".
-- Runs on an empty server top-to-bottom and can be re-run (it drops first).
-- NOTE: this is the schema the QUERY script was written and tested against.
--       It follows the group's ER / relational diagrams. If the Database
--       Developer changes a name, only the column names in 02_queries.sql
--       need to be updated.
-- =====================================================================
DROP DATABASE IF EXISTS hotel_group;
CREATE DATABASE hotel_group CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;  -- [MySQL]
USE hotel_group;                                                                -- [MySQL]

CREATE TABLE hotel (
    hotel_id   INT          NOT NULL AUTO_INCREMENT,                            -- [MySQL] AUTO_INCREMENT
    name       VARCHAR(100) NOT NULL,
    city       VARCHAR(60)  NOT NULL,
    address    VARCHAR(255) NOT NULL,
    CONSTRAINT pk_hotel PRIMARY KEY (hotel_id),
    CONSTRAINT uq_hotel_name UNIQUE (name)
);

CREATE TABLE job_position (
    role_id          INT         NOT NULL AUTO_INCREMENT,
    title            VARCHAR(60) NOT NULL,
    base_role        VARCHAR(30) NOT NULL,
    level            INT         NOT NULL DEFAULT 1,
    department_focus VARCHAR(40) NOT NULL,
    CONSTRAINT pk_job_position PRIMARY KEY (role_id),
    CONSTRAINT uq_job_position_title UNIQUE (title),
    CONSTRAINT ck_job_position_base CHECK (base_role IN ('MANAGER','RECEPTIONIST','HOUSEKEEPER','FNB','OTHER')),
    CONSTRAINT ck_job_position_level CHECK (level BETWEEN 1 AND 5)
);

CREATE TABLE staff (
    staff_id      INT          NOT NULL AUTO_INCREMENT,
    hotel_id      INT          NOT NULL,
    supervisor_id INT          NULL,                    -- recursive relationship ReportTo
    role_id       INT          NOT NULL,
    name          VARCHAR(100) NOT NULL,
    shift         VARCHAR(10)  NOT NULL DEFAULT 'DAY',
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT fk_staff_hotel FOREIGN KEY (hotel_id) REFERENCES hotel(hotel_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_staff_supervisor FOREIGN KEY (supervisor_id) REFERENCES staff(staff_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_staff_job_position FOREIGN KEY (role_id) REFERENCES job_position(role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_staff_shift CHECK (shift IN ('DAY','EVENING','NIGHT'))
);

CREATE TABLE room_type (
    type_id    INT           NOT NULL AUTO_INCREMENT,
    name       VARCHAR(60)   NOT NULL,
    capacity   INT           NOT NULL,
    base_price DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_room_type PRIMARY KEY (type_id),
    CONSTRAINT uq_room_type_name UNIQUE (name),
    CONSTRAINT ck_room_type_cap CHECK (capacity BETWEEN 1 AND 10),
    CONSTRAINT ck_room_type_price CHECK (base_price >= 0)
);

-- A room type has many seasonal rates; price of a night = rate whose season covers that date.
-- Non-overlap of seasons for one room type cannot be a declarative CHECK -> see report (trigger / app check).
CREATE TABLE rate_plan (
    rateplan_id INT           NOT NULL AUTO_INCREMENT,
    type_id     INT           NOT NULL,
    season_name VARCHAR(40)   NOT NULL,
    start_date  DATE          NOT NULL,
    end_date    DATE          NOT NULL,
    price       DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_rate_plan PRIMARY KEY (rateplan_id),
    CONSTRAINT uq_rate_plan UNIQUE (type_id, start_date),
    CONSTRAINT fk_rate_type FOREIGN KEY (type_id) REFERENCES room_type(type_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_rate_dates CHECK (end_date >= start_date),
    CONSTRAINT ck_rate_price CHECK (price > 0)
);

-- Weak entity: a room is identified by the hotel PLUS its room number.
CREATE TABLE room (
    hotel_id     INT         NOT NULL,
    room_number  VARCHAR(10) NOT NULL,
    floor_number INT         NOT NULL,
    type_id      INT         NOT NULL,
    status       VARCHAR(12) NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT pk_room PRIMARY KEY (hotel_id, room_number),
    CONSTRAINT fk_room_hotel FOREIGN KEY (hotel_id) REFERENCES hotel(hotel_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_room_type FOREIGN KEY (type_id) REFERENCES room_type(type_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_room_status CHECK (status IN ('AVAILABLE','OCCUPIED','CLEANING','MAINTENANCE')),
    CONSTRAINT ck_room_floor CHECK (floor_number BETWEEN 0 AND 60)
);

CREATE TABLE guest (
    guest_id INT          NOT NULL AUTO_INCREMENT,
    name     VARCHAR(100) NOT NULL,
    email    VARCHAR(120) NULL,
    CONSTRAINT pk_guest PRIMARY KEY (guest_id),
    CONSTRAINT uq_guest_email UNIQUE (email)
);

-- multivalued attribute Phone of Guest
CREATE TABLE guest_phone (
    guest_id INT         NOT NULL,
    phone    VARCHAR(20) NOT NULL,
    CONSTRAINT pk_guest_phone PRIMARY KEY (guest_id, phone),
    CONSTRAINT fk_gphone_guest FOREIGN KEY (guest_id) REFERENCES guest(guest_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE identity_document (
    doc_id     INT          NOT NULL AUTO_INCREMENT,
    guest_id   INT          NOT NULL,
    doc_type   VARCHAR(20)  NOT NULL,
    doc_number VARCHAR(40)  NOT NULL,
    CONSTRAINT pk_identity_document PRIMARY KEY (doc_id),
    CONSTRAINT uq_identity_doc UNIQUE (doc_type, doc_number),
    CONSTRAINT fk_doc_guest FOREIGN KEY (guest_id) REFERENCES guest(guest_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_doc_type CHECK (doc_type IN ('CCCD','PASSPORT','DRIVER_LICENSE'))
);

-- A reservation is made for a ROOM TYPE at a HOTEL; the physical room is assigned only at check-in (see stay).
CREATE TABLE reservation (
    reservation_id INT         NOT NULL AUTO_INCREMENT,
    guest_id       INT         NOT NULL,
    hotel_id       INT         NOT NULL,
    type_id        INT         NOT NULL,
    start_date     DATE        NOT NULL,
    end_date       DATE        NOT NULL,
    no_of_guests   INT         NOT NULL DEFAULT 1,
    status         VARCHAR(12) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_reservation PRIMARY KEY (reservation_id),
    CONSTRAINT fk_res_guest FOREIGN KEY (guest_id) REFERENCES guest(guest_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_res_hotel FOREIGN KEY (hotel_id) REFERENCES hotel(hotel_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_res_type FOREIGN KEY (type_id) REFERENCES room_type(type_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_res_dates CHECK (end_date > start_date),
    CONSTRAINT ck_res_guests CHECK (no_of_guests BETWEEN 1 AND 10),
    CONSTRAINT ck_res_status CHECK (status IN ('PENDING','CONFIRMED','CHECKED_IN','COMPLETED','CANCELLED','NO_SHOW'))
);

-- A stay is the actual occupation: reservation -> room (assigned at check-in).
CREATE TABLE stay (
    stay_id        INT         NOT NULL AUTO_INCREMENT,
    reservation_id INT         NOT NULL,
    hotel_id       INT         NOT NULL,
    room_number    VARCHAR(10) NOT NULL,
    check_in       DATETIME    NOT NULL,
    check_out      DATETIME    NULL,                  -- NULL = guest still in house
    CONSTRAINT pk_stay PRIMARY KEY (stay_id),
    CONSTRAINT uq_stay_reservation UNIQUE (reservation_id),   -- Becomes is 1:0..1
    CONSTRAINT fk_stay_reservation FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_stay_room FOREIGN KEY (hotel_id, room_number) REFERENCES room(hotel_id, room_number)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_stay_times CHECK (check_out IS NULL OR check_out > check_in)
);

CREATE TABLE service (
    service_id   INT           NOT NULL AUTO_INCREMENT,
    name         VARCHAR(80)   NOT NULL,
    service_type VARCHAR(12)   NOT NULL,                -- restaurant, laundry, minibar ...
    unit_price   DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_service PRIMARY KEY (service_id),
    CONSTRAINT uq_service_name UNIQUE (name),
    CONSTRAINT ck_service_type CHECK (service_type IN ('RESTAURANT','LAUNDRY','MINIBAR','SPA','TRANSPORT')),
    CONSTRAINT ck_service_price CHECK (unit_price >= 0)
);

-- M:N relationship Records between stay and service, carrying quantity / price / date.
CREATE TABLE service_consumption (
    consumption_id INT           NOT NULL AUTO_INCREMENT,
    stay_id        INT           NOT NULL,
    service_id     INT           NOT NULL,
    quantity       INT           NOT NULL DEFAULT 1,
    unit_price     DECIMAL(12,2) NOT NULL,              -- price charged at that time
    consumed_at    DATETIME      NOT NULL,
    CONSTRAINT pk_consumption PRIMARY KEY (consumption_id),
    CONSTRAINT fk_cons_stay FOREIGN KEY (stay_id) REFERENCES stay(stay_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cons_service FOREIGN KEY (service_id) REFERENCES service(service_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_cons_qty CHECK (quantity > 0),
    CONSTRAINT ck_cons_price CHECK (unit_price >= 0)
);

CREATE TABLE invoice (
    invoice_id INT         NOT NULL AUTO_INCREMENT,
    stay_id    INT         NOT NULL,
    issue_date DATE        NOT NULL,
    status     VARCHAR(10) NOT NULL DEFAULT 'UNPAID',
    CONSTRAINT pk_invoice PRIMARY KEY (invoice_id),
    CONSTRAINT uq_invoice_stay UNIQUE (stay_id),          -- Generates is 1:1
    CONSTRAINT fk_invoice_stay FOREIGN KEY (stay_id) REFERENCES stay(stay_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_invoice_status CHECK (status IN ('UNPAID','PARTIAL','PAID','VOID'))
);

-- Weak entity: a line is identified by its invoice plus a line number.
CREATE TABLE invoice_line (
    invoice_id  INT           NOT NULL,
    line_no     INT           NOT NULL,
    line_type   VARCHAR(10)   NOT NULL,
    description VARCHAR(200)  NOT NULL,
    amount      DECIMAL(14,2) NOT NULL,
    CONSTRAINT pk_invoice_line PRIMARY KEY (invoice_id, line_no),
    CONSTRAINT fk_line_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_line_type CHECK (line_type IN ('ROOM','SERVICE','TAX','DISCOUNT'))
);

CREATE TABLE payment (
    payment_id INT           NOT NULL AUTO_INCREMENT,
    invoice_id INT           NOT NULL,
    paid_date  DATE          NOT NULL,
    method     VARCHAR(12)   NOT NULL,
    amount     DECIMAL(14,2) NOT NULL,
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_payment_method CHECK (method IN ('CASH','CARD','TRANSFER','EWALLET')),
    CONSTRAINT ck_payment_amount CHECK (amount > 0)
);

-- ---------------------------------------------------------------------
-- INDEXES (besides those InnoDB creates automatically for PK/UNIQUE/FK)
-- idx_stay_room_dates : speeds up Q1 "rooms free for a date range" - the NOT EXISTS
--                       probes stay by (hotel, room) and then filters on the dates;
--                       with the dates in the index the check is answered from the index.
-- idx_payment_date_invoice_method : speeds up Q14 date-range scans and grouping.
-- ---------------------------------------------------------------------
CREATE INDEX idx_stay_room_dates ON stay (hotel_id, room_number, check_in, check_out);
-- Q1: narrow reservations by hotel/status and date overlap before counting by type.
CREATE INDEX idx_res_hotel_status_dates ON reservation (hotel_id, status, start_date, end_date, type_id);
-- Q3: find stays overlapping each hotel/month without wrapping check_in in DATE().
CREATE INDEX idx_stay_hotel_checkin_checkout ON stay (hotel_id, check_in, check_out);
-- Q5/Q9/Q10: service consumption joins and date-based grouping.
CREATE INDEX idx_consumption_stay_service_date ON service_consumption (stay_id, service_id, consumed_at, quantity, unit_price);
-- Q14: date-range scan plus invoice join and payment-method grouping.
CREATE INDEX idx_payment_date_invoice_method ON payment (paid_date, invoice_id, method, amount);
