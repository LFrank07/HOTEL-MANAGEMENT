# 8. Queries

Database: `Hotel_Management_Group3` (MySQL 8.0 or later). Main script: `queries.sql`. Test parameters are defined at the top of that script and can be changed before execution.

## 8.1 List of queries

| Query | Question | Main concepts |
|---|---|---|
| Q1 | Which rooms are free at one hotel during an inclusive date range (counted per room type, after subtracting stays and reservations)? | CTE, JOIN, LEFT JOIN, date-overlap condition |
| Q2 | What is the bill of one stay, with room charges and services? | View, GROUP BY, SUM, CASE |
| Q3 | What is the occupancy rate per month for each hotel? | Recursive CTE, CROSS JOIN, LEFT JOIN, aggregation |
| Q4 | Which guests have stayed at every hotel in the group? | Double NOT EXISTS (relational division) |
| Q5 | Which service earns the most revenue per occupied room? | CTE, GROUP BY, aggregate calculation, subquery with MAX |
| Q6 | Which completed stays were made by which guest, at which hotel, and in which room type? | Multi-table JOIN, LEFT JOIN |
| Q7 | Which rooms have never been used for a stay? | LEFT JOIN, IS NULL (anti-join) |
| Q8 | Which hotels earned more than 8,000,000 VND from services? | GROUP BY, HAVING |
| Q9 | Which guests have used the laundry service? | Nested query with IN |
| Q10 | Which guests either stayed in a Suite room or used the Spa service? | UNION |
| Q11 | Which closed invoices (Unpaid or PartiallyPaid) still have an unpaid balance? | CTE, LEFT JOIN, aggregation |
| Q12 | Which staff members work at each hotel, with their position and supervisor? | Self LEFT JOIN |
| Q13 | What is the nightly price of each room type on one date? | LEFT JOIN with derived table, COALESCE |

Q1 to Q5 answer the five questions listed for Topic 23, Hotel Management, in the assignment.

## 8.2 View

`v_stay_bill_lines` joins `Stays`, `Invoices` and `InvoiceLine`. It provides the invoice lines associated with each stay. Q2 uses this view to show the individual bill lines and calculate room charges, service charges and the total.

## 8.3 Index

`hotel_management_full.sql` creates `IDX_Stays_Room_Dates` on `Stays (Hotel_ID, Room_Number, CheckIn, Checkout)`. Its first column is `Hotel_ID`, so it supports searches that first restrict stays to one hotel and then compare the check-in and checkout dates. It is meant to help **Q1** (stays of one hotel that overlap a date range) and **Q3** (stays of each hotel that overlap a month). The same script also creates `IDX_Reservation_Hotel_Dates` on `Reservation (Hotel_ID, TypeID, StartDate, EndDate)` for the reservation part of Q1, and the trigger that prevents overlapping stays uses `IDX_Stays_Room_Dates` as well.

`explain_index.sql` does not change the database. It runs `EXPLAIN` on the stay-overlap search twice, once normally and once with `IGNORE INDEX (IDX_Stays_Room_Dates)`, so the two execution plans can be compared in MySQL Workbench (columns `key` and `rows`). The chosen access method depends on the database statistics and data volume. `Stays` has only 70 rows in the sample data, so the optimizer may scan the whole table in both plans; the report does not assume that it must always choose this index.

## 8.4 Update statements and transactions

`crud_transaction_tests.sql` demonstrates INSERT, UPDATE and DELETE operations across the main transactional tables and reference tables. Most tables include all three operations; `Guests_Phone` is used for INSERT and DELETE operations. It also contains three transactions:

- **Check-in:** inserts an invoice and a stay, then updates the reservation and the temporary room; COMMIT.
- **Check-out and billing:** updates the stay, reservation and temporary room, inserts invoice lines and updates the invoice; COMMIT.
- **Payment:** inserts a second payment and changes the invoice status to `Paid`, then uses ROLLBACK. The invoice status returns to `Unpaid`, and the second payment is removed. The first payment remains unchanged.

The test reservation is made for hotel 1 and a Standard room (capacity 2), so the trigger that checks the number of guests accepts it. The script reserves IDs from the 9000 range for test data, uses room `999` as a temporary room, and removes its test records at the end. The cleanup is designed for reruns after a successful execution. If execution stops partway because of an error, rerun the script from the beginning: its first lines delete the test records. The script assumes the sample database contains hotel 1, room type 1, staff member 1, role IDs 2 and 3, and service 1.

## 8.5 Relational algebra

Four SQL queries are also represented in relational algebra: Q4, Q7, Q9 and Q10.

**Q4: guests who stayed at every hotel**

```text
Stayed = π Guest_ID, Hotel_ID (Reservation ⋈ Stays)

π Guest_ID, Name (Guests ⋈ (Stayed ÷ π Hotel_ID (Hotels)))
```

**Q7: rooms never used for a stay**

```text
Unused = π Hotel_ID, Room_Number (Room) − π Hotel_ID, Room_Number (Stays)

π Name, Room_Number (Hotels ⋈ Unused)
```

**Q9: guests who used the laundry service**

```text
π Guest_ID, Name (Guests ⋈ Reservation ⋈ Stays ⋈ Records ⋈ σ ServiceType = 'Laundry' (Services))
```

**Q10: guests who stayed in a Suite or used the Spa service**

```text
R = π Reservation_ID, Guest_ID (Reservation)

Suite = π Guest_ID (R ⋈ Stays ⋈ Room ⋈ σ Name = 'Suite' (RoomType))

Spa = π Guest_ID (R ⋈ π StayID, Reservation_ID (Stays) ⋈ Records ⋈ σ ServiceType = 'Spa' (Services))

π Guest_ID, Name (Guests ⋈ (Suite ∪ Spa))
```

The expressions use the natural join (⋈) on attributes with the same name. The images of the four expressions are in `Query/RA/`.

## 8.6 Assumptions and schema limitations

- A reservation stores a hotel, a room type and a date range, but not a physical room. The physical room is assigned only when a stay is created at check-in. Q1 therefore subtracts two things from the rooms of each type: rooms occupied by actual stays that overlap the date range, and reservations with status `Pending` or `Confirmed` that overlap the range and have no stay yet. A reservation is counted as one room of its type for the whole range.
- Q1 treats the selected date range as inclusive and treats the checkout date as the first date on which the room is free. Its maintenance filter uses the current `RoomStatus`; the schema does not keep historical maintenance periods.
- Q3 calculates occupied room-nights from actual stays. Its denominator uses the total number of registered rooms because the schema does not record when a room entered or left maintenance. The result is therefore an inventory-based occupancy rate, not a maintenance-adjusted historical rate.
- For Q5, one `StayID` represents one occupied room for that stay. The query divides each service's total revenue by the number of distinct stays in which that service was recorded. This makes the meaning of “revenue per occupied room” explicit for this schema.
- Q6 uses a LEFT JOIN to `Guests`, so a stay is still listed if its reservation no longer has a guest (`Guest_ID` is set to NULL when a guest is deleted).
- Q13 shows that the nightly price depends on the room type and the date. A rate plan that covers the date gives the seasonal price from `HasRate`; otherwise the `BasePrice` of the room type is used. Because rate plans cannot overlap, at most one plan covers a date. The date is set with `@on_date`.
- Q11 lists only invoices with status `Unpaid` or `PartiallyPaid`. Invoices with status `Open` belong to guests who are still in the hotel, so they are not counted as debt.
- The four relational-algebra expressions show the corresponding relational operations. Q7 projects the identifying room details; SQL returns the same identifying room records with the room type and current status.

## 8.7 Requirement coverage

The query set contains 13 SQL queries, one view, and four relational-algebra expressions. It includes multi-table joins (Q6), outer joins (Q1, Q6, Q7, Q11, Q12 and Q13), GROUP BY with HAVING (Q8), a nested IN query (Q9), NOT EXISTS for the “every hotel” condition (Q4), and a set operation (Q10).

The assignment also requires at least 15 realistic sample rows in every table and enough data for every required query to return a non-empty result. These are database-data and execution checks; they cannot be established by the query scripts or this report alone and must be verified against the loaded sample data.
