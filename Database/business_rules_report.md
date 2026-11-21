# Business rules (report section 2) and their enforcement (section 7)

Every rule in this file comes from the ER diagram, the relational schema or the SQL script of the project. The ERD relationship or attribute behind the rule is given in square brackets in section 2. Section 7.1 then shows, for each rule, the element of the relational schema, the mechanism used in the SQL script (`hotel_management_full.sql`) and the reason for that mechanism.

## 2. Requirements and business rules

### 2.1 Hotels, rooms and room types

- **R1.** Every hotel has a name that no other hotel uses, and an address. [Hotels]
- **R2.** A room belongs to exactly one hotel and is identified by its room number inside that hotel, so two hotels can both have a room 101. [Contains; Room is a weak entity]
- **R3.** Every room has exactly one room type. [IsType]
- **R4.** Every room has a floor number. The status of a room is Available, Occupied or Maintenance, and a new room is Available by default. [Room.FloorNumber; Room.RoomStatus]
- **R5.** A room type has a unique name, a base price that is not negative and a capacity from 1 to 5 guests. [RoomType]
- **R6.** A rate plan is a season with a unique name, its end date is not before its start date, and its period does not overlap the period of another rate plan. [RatePlan]
- **R7.** A room type has at most one price for each rate plan, and the price is not negative. If a room type or a rate plan is deleted, its prices are deleted with it. [HasRate]

### 2.2 Staff and positions

- **R8.** Every staff member has a name, works for exactly one hotel and holds exactly one position. [Employs; Holds]
- **R9.** A position is described by a base role, a department focus and a level (Junior, Senior, Supervisor or Manager). No two positions have the same combination of the three values. [Position; Title is a composite attribute]
- **R10.** A staff member has at most one supervisor. The top manager of a hotel has none. If a supervisor is deleted, the supervised staff are kept and their supervisor becomes empty. [ReportTo; the Supervisor side is optional]

### 2.3 Guests

- **R11.** Every guest has a name and an identity document number that is unique in the group. [Guests.Doc_ID]
- **R12.** A guest can have several phone numbers, a phone number belongs to one guest only, and the numbers are deleted with the guest. [Guests.Phone is multivalued]

### 2.4 Reservations

- **R13.** A reservation has a start date, an end date that is not before the start date, a status (Pending, Confirmed, CheckedIn, CheckedOut, Cancelled or NoShow) and a number of guests of at least 1. A new reservation is Pending and for 1 guest by default. [Reservation]
- **R14.** A reservation is made for exactly one hotel and exactly one room type. [ReservedAt; Request]
- **R15.** A reservation can only be made at a hotel that has at least one room of the requested room type. [ReservedAt; Request; IsType]
- **R16.** The number of guests of a reservation does not exceed the capacity of the requested room type. [Request; RoomType.Capacity]
- **R17.** A reservation is made by a guest, but the guest is optional: if the guest is deleted, the reservation is kept and its guest becomes empty. [Makes; the Reservation side is optional]

### 2.5 Stays

- **R18.** A reservation leads to at most one stay, and every stay comes from exactly one reservation. [Becomes]
- **R19.** A stay takes place in exactly one room, and that room belongs to the hotel of the reservation. [AssignedTo; ReservedAt]
- **R20.** The room assigned to a stay has the room type that was reserved. [AssignedTo; Request; IsType]
- **R21.** A room cannot have two stays whose periods overlap. A stay without a checkout date is still in progress and keeps the room. [AssignedTo; Stays.Checkout is optional]
- **R22.** The checkout of a stay is not before its check-in. The checkout is empty (NULL) while the guest is still in the hotel. [Stays; Checkout is optional]

### 2.6 Services

- **R23.** A service has a unique name. A stay can use many services and a service can be used in many stays; every use is recorded with its date, the unit price at that time (not negative) and the quantity (at least 1, and 1 by default). The date is a date and time, so the same service can be recorded again for the same stay at another time; the same service cannot be recorded twice for the same stay at exactly the same date and time. [Records; the attributes Date, Price and Quantity are on the relationship]
- **R24.** If a stay is deleted, its service records are deleted. A service that has been recorded cannot be deleted. [Records]

### 2.7 Invoices and payments

- **R25.** Every stay has exactly one invoice, and an invoice belongs to at most one stay in the database; the ERD asks that every invoice belongs to a stay, which the check-in transaction (R28) provides. An invoice has an issue date and one status (Open, Unpaid, PartiallyPaid, Paid or Void), and a new invoice is Open by default. [Generates; Invoices.Status]
- **R26.** An invoice is made of lines. A line has a type (Room or Service) and an amount that is not negative, and it is identified by its number inside its invoice. If an invoice is deleted, its lines are deleted with it. [Contains; InvoiceLine is a weak entity]
- **R27.** A payment belongs to exactly one invoice, has a paid date, a positive amount and a method (Cash, CreditCard, BankTransfer or EWallet). An invoice that has payments cannot be deleted. [Receives]

### 2.8 Operations that must succeed or fail as a whole

- **R28.** Check-in: the invoice (Open) is created first because a stay needs an invoice, then the stay is created, the reservation becomes CheckedIn and the room becomes Occupied. All four changes happen or none happens. [Generates; Becomes; AssignedTo]
- **R29.** Check-out: the checkout date is set, the reservation becomes CheckedOut, the room becomes Available, the invoice lines are added and the invoice becomes Unpaid. All of them happen or none happens.
- **R30.** A payment and the change of the invoice status caused by it happen together or not at all.

## 7.1 How each rule is enforced

Strategy, from the strongest mechanism to the weakest:

1. **Declarative constraints** (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL, ENUM, DEFAULT). They are used for every rule about one row or about a link between two tables. The database applies them to every program.
2. **Triggers.** They are used when a rule has to read other rows or other tables. A CHECK constraint in MySQL cannot do this.
3. **Transactions.** They are used when several statements must succeed or fail together.

| Rule | ERD element | Relational schema | SQL mechanism | Why this mechanism |
|---|---|---|---|---|
| R1 | Hotels.Name | HOTELS.Name (U) | `UQ_Hotels_Name` UNIQUE, NOT NULL | One column rule. |
| R2 | Contains (weak entity Room) | ROOM: PK (Hotel_ID, Room_Number), FK Hotel_ID | `PK_Room`, `FK_Room_Hotels` | The key of a weak entity contains the key of its owner. |
| R3 | IsType | ROOM.TypeID (FK) | `FK_Room_RoomType`, NOT NULL | Direct link to another table. |
| R4 | Room.FloorNumber; Room.RoomStatus | ROOM.FloorNumber, ROOM.RoomStatus | NOT NULL; ENUM, DEFAULT 'Available' | ENUM limits the values. |
| R5 | RoomType | ROOMTYPE.Name (U) | `UQ_RoomType_Name`, `CHK_RoomType_Price`, `CHK_RoomType_Capacity` | One row rules. |
| R6 | RatePlan | RATEPLAN.SeasonName, StartDate, EndDate (U) | `UQ_RatePlan_SeasonName`, `UQ_RatePlan_StartDate`, `UQ_RatePlan_EndDate`, `CHK_RatePlan_Dates`; trigger `TRG_RatePlan_NoOverlap_BI/BU` | The name, the two dates and the date order are row rules. Because periods cannot overlap, no two plans can share a start date or an end date, so StartDate and EndDate are also unique. The overlap check must read the other rate plans, so it needs a trigger. |
| R7 | HasRate (many to many with Price) | HASRATE: PK (TypeID, RatePlan_ID) | `PK_HasRate`, `CK_HasRate_Price`, both FK with ON DELETE CASCADE | The composite key allows one price per pair. A price has no meaning without its room type or plan. |
| R8 | Employs; Holds | STAFF.Hotel_ID, STAFF.Role_ID (FK) | `FK_Staff_Hotels`, `FK_Staff_Position`, NOT NULL | Every staff member needs both links. |
| R9 | Position.Title (composite) | POSITION: alternate key (BaseRole, DepartmentFocus, Level) | `UQ_Position_Title`, ENUM, NOT NULL | The three columns form a key. |
| R10 | ReportTo | STAFF.Supervisor_ID (FK)(O) | Nullable FK, `FK_Staff_Supervisor` ON DELETE SET NULL | The top manager has no supervisor, so the column accepts NULL. |
| R11 | Guests.Doc_ID | GUESTS.Doc_ID (U) | `UQ_Guests_DocID` | One column rule. |
| R12 | Phone (multivalued) | GUESTS_PHONE: PK (Phone), FK Guest_ID | Separate table, `PK_Guests_Phone` on Phone, `FK_GuestsPhone_Guests` ON DELETE CASCADE | A multivalued attribute becomes its own table, and phones depend on the guest. Phone alone is the key, so a number belongs to one guest only. |
| R13 | Reservation | RESERVATION | `CHK_Reservation_Dates`, `CHK_Reservation_Guests`, ENUM and DEFAULT on BookingStatus, DEFAULT on NoOfGuests | One row rules. |
| R14 | ReservedAt; Request | RESERVATION.Hotel_ID, TypeID (FK) | `FK_Reservation_Hotels`, `FK_Reservation_RoomType`, NOT NULL | Direct links. |
| R15 | ReservedAt, Request, IsType | ROOM and RESERVATION | Trigger `TRG_Reservation_Capacity_BI/BU` (second check) | The rule asks whether a room of this type exists in this hotel, which needs the ROOM table. |
| R16 | Request; RoomType.Capacity | ROOMTYPE.Capacity | Trigger `TRG_Reservation_Capacity_BI/BU` (first check) | The limit is stored in another table. |
| R17 | Makes (optional side) | RESERVATION.Guest_ID (FK)(O) | Nullable FK, `FK_Reservation_Guests` ON DELETE SET NULL | Keeps the booking history when a guest is deleted. |
| R18 | Becomes | STAYS.Reservation_ID (FK)(U) | `UQ_Stays_Reservation`, `FK_Stays_Reservation`, NOT NULL | UNIQUE turns the link into one to at most one. |
| R19 | AssignedTo; ReservedAt | STAYS: FK (Hotel_ID, Room_Number) | `FK_Stays_Room`; trigger `TRG_Stays_Rules_BI/BU` (first check) | The FK gives the room. The hotel of the room must also equal the hotel of the reservation, which is in another table. |
| R20 | AssignedTo; Request; IsType | ROOM.TypeID, RESERVATION.TypeID | Trigger `TRG_Stays_Rules_BI/BU` (second check) | The two types are in two other tables. |
| R21 | AssignedTo; Checkout optional | STAYS.CheckIn, Checkout (O) | Trigger `TRG_Stays_Rules_BI/BU` (third check); index `IDX_Stays_Room_Dates` | A period must be compared with the other stays of the same room. A NULL checkout is read as 9999-12-31. |
| R22 | Stays | STAYS.Checkout (O) | `CHK_Stays_Dates` | A comparison of two columns of the same row. |
| R23 | Records (many to many with Date, Price, Quantity) | RECORDS: PK (Date, StayID, ServiceID); SERVICES.ServiceType (U) | `UQ_Services_ServiceType`, `PK_Records`, `CHK_Records_Price`, `CHK_Records_Qty`, DEFAULT 1 | The price is kept on the record, so a later price change does not change old invoices. |
| R24 | Records | RECORDS.StayID, ServiceID (FK) | `FK_Records_Stays` ON DELETE CASCADE, `FK_Records_Services` ON DELETE RESTRICT | Records have no meaning without their stay, but a used service must stay in the history. |
| R25 | Generates; Invoices.Status | STAYS.Invoice_ID (FK)(U); INVOICES.Status | `UQ_Stays_Invoice`, `FK_Stays_Invoices`, NOT NULL, ENUM, DEFAULT 'Open' | NOT NULL gives every stay an invoice and UNIQUE lets an invoice serve one stay only. The invoice side (every invoice has a stay) cannot be required by SQL; see section 7.5. |
| R26 | Contains (weak entity InvoiceLine) | INVOICELINE: PK (LineID, Invoice_ID) | `PK_InvoiceLine`, `CHK_InvoiceLine_Amount`, ENUM, `FK_InvoiceLine_Invoices` ON DELETE CASCADE | Lines depend on their invoice. |
| R27 | Receives | PAYMENT.Invoice_ID (FK) | `CHK_Payment_Amount`, ENUM, `FK_Payment_Invoices` ON DELETE RESTRICT | Payments are financial records and must not disappear with an invoice. |
| R28 | Generates; Becomes; AssignedTo | INVOICES, STAYS, RESERVATION, ROOM | Transaction (`crud_transaction_tests.sql`) | Four statements must go together, and a constraint cannot group statements. The invoice comes first because STAYS.Invoice_ID is NOT NULL. |
| R29 | Stays; Invoices | STAYS, RESERVATION, ROOM, INVOICELINE, INVOICES | Transaction (`crud_transaction_tests.sql`) | The same reason as R28. |
| R30 | Receives | PAYMENT, INVOICES | Transaction with ROLLBACK (`crud_transaction_tests.sql`) | The test shows that after ROLLBACK the invoice is still Unpaid and the second payment is not saved. |

## 7.2 Referential actions of the 18 foreign keys

| Foreign key | References | ON DELETE | ON UPDATE | Reason |
|---|---|---|---|---|
| Staff.Hotel_ID | Hotels | RESTRICT | CASCADE | A hotel with staff cannot be deleted. |
| Staff.Role_ID | Position | RESTRICT | CASCADE | A position in use cannot be deleted. |
| Staff.Supervisor_ID | Staff | SET NULL | CASCADE | The staff stay when a supervisor is deleted (R10). |
| Room.Hotel_ID | Hotels | RESTRICT | CASCADE | A hotel with rooms cannot be deleted. |
| Room.TypeID | RoomType | RESTRICT | CASCADE | A room type in use cannot be deleted. |
| HasRate.TypeID | RoomType | CASCADE | CASCADE | Prices depend on the room type (R7). |
| HasRate.RatePlan_ID | RatePlan | CASCADE | CASCADE | Prices depend on the rate plan (R7). |
| Guests_Phone.Guest_ID | Guests | CASCADE | CASCADE | Phones depend on the guest (R12). |
| Reservation.Guest_ID | Guests | SET NULL | CASCADE | History is kept (R17). |
| Reservation.TypeID | RoomType | RESTRICT | CASCADE | A room type in use cannot be deleted. |
| Reservation.Hotel_ID | Hotels | RESTRICT | CASCADE | A hotel with reservations cannot be deleted. |
| Stays.Reservation_ID | Reservation | RESTRICT | CASCADE | A reservation with a stay cannot be deleted. |
| Stays.Invoice_ID | Invoices | RESTRICT | CASCADE | An invoice of a stay cannot be deleted. |
| Stays (Hotel_ID, Room_Number) | Room | RESTRICT | CASCADE | A room with stays cannot be deleted. |
| Records.StayID | Stays | CASCADE | CASCADE | Records depend on the stay (R24). |
| Records.ServiceID | Services | RESTRICT | CASCADE | A used service cannot be deleted (R24). |
| InvoiceLine.Invoice_ID | Invoices | CASCADE | CASCADE | Lines depend on the invoice (R26). |
| Payment.Invoice_ID | Invoices | RESTRICT | CASCADE | An invoice with payments cannot be deleted (R27). |

## 7.3 Triggers

The script has two triggers for each of three tables. Each runs before the row is written and stops the statement with `SIGNAL SQLSTATE '45000'` and a message when a rule is broken. The insert trigger protects new rows and the update trigger protects changed rows, so a rule cannot be broken by editing a row after it was inserted.

| Trigger | Table and event | Rules | Error messages |
|---|---|---|---|
| `TRG_Reservation_Capacity_BI` | Reservation, BEFORE INSERT | R15, R16 | "Number of guests exceeds the capacity of the room type"; "This hotel has no room of the reserved room type" |
| `TRG_Reservation_Capacity_BU` | Reservation, BEFORE UPDATE | R15, R16 | The same two messages |
| `TRG_Stays_Rules_BI` | Stays, BEFORE INSERT | R19, R20, R21 | "The stay is not at the hotel of the reservation"; "The assigned room is not of the room type that was reserved"; "The room is already occupied during this stay" |
| `TRG_Stays_Rules_BU` | Stays, BEFORE UPDATE | R19, R20, R21 | The same three messages |
| `TRG_RatePlan_NoOverlap_BI` | RatePlan, BEFORE INSERT | R6 | "This rate plan overlaps another rate plan" |
| `TRG_RatePlan_NoOverlap_BU` | RatePlan, BEFORE UPDATE | R6 | The same message |

`constraint_tests.sql` tests each constraint and each trigger and gives the error that MySQL must return.

## 7.4 Transactions

`crud_transaction_tests.sql` runs three transactions on a temporary room (room 999 of hotel 1) with test identifiers of 9000 and above, and removes the test data at the end.

| Transaction | Statements | Result |
|---|---|---|
| Check-in (R28) | Insert the invoice (Open), insert the stay, set the reservation CheckedIn, set the room Occupied; COMMIT | The four changes are saved together. |
| Check-out (R29) | Set the checkout, set the reservation CheckedOut and the room Available, insert the invoice lines, set the invoice Unpaid; COMMIT | All the changes are saved together. |
| Payment (R30) | Insert a second payment, set the invoice Paid; ROLLBACK | The invoice stays Unpaid and the second payment is not saved. |

## 7.5 What the model does not enforce

These points are limits of the current ERD, schema and SQL. They are stated so that the report is clear about them.

- **Minimum cardinality on the parent side.** The ERD says that a hotel has at least one staff member (Employs), at least one room (Contains), that every room type has at least one room (IsType), that every invoice has at least one line (Contains), and that every invoice has a stay (Generates). SQL cannot require that a parent already has a child when the parent is inserted. The check-in transaction (R28) creates the invoice and its stay together. The sample data respects all five.
- **Price of a night.** The tables store the seasonal prices (HasRate) and the base price (RoomType). Which price applies to a night is decided by the program that builds the invoice lines: the seasonal price when a rate plan covers the date and the room type has a price in it, otherwise the base price. The invoice lines store the result.
- **Values that depend on other rows.** The database does not check that a payment total matches the invoice total, that a service record falls between check-in and checkout, or that a supervisor works in the same hotel as the staff member. The sample data is consistent for all three.
- **Supervisor and hotel.** A supervisor is a staff member (ReportTo is a relationship of Staff with itself). In practice a supervisor works in the same hotel as the staff members he or she supervises, and the sample data follows this. The schema does not require it, so the model declares no dependency Supervisor_ID → Hotel_ID, and Staff stays in 3NF. If the group decided to require it, a trigger would be needed and the dependency would have to be discussed in the normalization chapter.
- **Changes after a stay exists.** The Stays triggers check a stay when it is inserted or updated. A later change to the hotel or room type of its reservation, or to the room type of its room, is not checked again, so R19 and R20 could be broken by such a change. The application should not allow these changes once a stay exists.
