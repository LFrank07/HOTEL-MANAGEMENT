# 8. Queries

Database: `Hotel_Management_Group3` (MySQL 8.0 or later). Main script: `queries.sql`. Test parameters are defined at the top of that script and can be changed before execution.

## 8.1 List of queries

| Query | Question | Main concepts |
|---|---|---|
| Q1 | Which rooms are free at one hotel during an inclusive date range (counted per room type)? | CTE, JOIN, LEFT JOIN, date-overlap condition |
| Q2 | What is the bill of one stay, with room charges and services? | View, GROUP BY, SUM, CASE |
| Q3 | What is the occupancy rate per month for each hotel? | Recursive CTE, CROSS JOIN, LEFT JOIN, aggregation |
| Q4 | Which guests have stayed at every hotel in the group? | Double NOT EXISTS (relational division) |
| Q5 | Which service earns the most revenue per occupied room? | CTE, GROUP BY, aggregate calculation, subquery with MAX |
| Q6 | Which completed stays were made by which guest, at which hotel, and in which room type? | Multi-table JOIN |
| Q7 | Which rooms have never been used for a stay? | LEFT JOIN, IS NULL (anti-join) |
| Q8 | Which hotels earned more than 8,000,000 VND from services? | GROUP BY, HAVING |
| Q9 | Which guests have used the laundry service? | Nested query with IN |
| Q10 | Which guests either stayed in a Suite room or used the Spa service? | UNION |
| Q11 | Which invoices still have an unpaid balance? | CTE, LEFT JOIN, aggregation |
| Q12 | Which staff members work at each hotel, with their position and supervisor? | Self LEFT JOIN |
| Q13 | What is the nightly price of each room type on a selected date? | Multi-table JOIN, date condition |
| Q14 | How much money was received each month, by hotel and payment method? | GROUP BY, date range |

Q1 to Q5 answer the five questions listed for Topic 23, Hotel Management, in the assignment.

## 8.2 View

`v_stay_bill_lines` joins `Stays`, `Invoices` and `InvoiceLine`. It provides the invoice lines associated with each stay. Q2 uses this view to show the individual bill lines and calculate room charges, service charges and the total.

## 8.3 Index

`index.sql` creates `idx_stays_hotel_checkin` on `Stays (Hotel_ID, CheckIn)` if the index does not already exist. The composite index supports searches that first restrict stays to one hotel and then use the check-in date as a range condition. It is meant to help **Q1** (stays of one hotel that overlap a date range) and **Q3** (stays of each hotel that overlap a month).

The script also runs an `EXPLAIN` statement so the execution plan can be inspected in MySQL Workbench. The chosen access method depends on the database statistics and data volume; therefore, the report does not assume that the optimizer must always choose this index.

## 8.4 Update statements and transactions

`updates.sql` demonstrates INSERT, UPDATE and DELETE operations across the main transactional tables and reference tables. Most tables include all three operations; `Guests_Phone` is used for INSERT and DELETE operations. It also contains three transactions:

- **Check-in:** inserts an invoice and a stay, then updates the reservation and the temporary room; COMMIT.
- **Check-out and billing:** updates the stay, reservation and temporary room, inserts invoice lines and updates the invoice; COMMIT.
- **Payment:** inserts a second payment and changes the invoice status to `Paid`, then uses ROLLBACK. The invoice status returns to `Unpaid`, and the second payment is removed. The first payment remains unchanged.

The script reserves IDs from the 9000 range for test data, uses room `999` as a temporary room, and removes its test records at the end. The cleanup is designed for reruns after a successful execution. If execution stops partway because of an error, inspect and clean up the test records before running it again. The script assumes the sample database contains hotel 1, room type 1, staff member 1, role IDs 2 and 3, and service 1.

## 8.5 Relational algebra

Four SQL queries are also represented in relational algebra: Q4, Q7, Q9 and Q10.

**Q4: guests who stayed at every hotel**

\[
Stayed = \pi_{Guest\_ID,\ Hotel\_ID}(Reservation \bowtie Stays)
\]

\[
\pi_{Guest\_ID,\ Name}\Big(Guests \bowtie (Stayed \div \pi_{Hotel\_ID}(Hotels))\Big)
\]

**Q7: rooms never used for a stay**

\[
Unused = \pi_{Hotel\_ID,\ Room\_Number}(Room) - \pi_{Hotel\_ID,\ Room\_Number}(Stays)
\]

\[
\pi_{Hotels.Name,\ Room\_Number,\ RoomType.Name,\ Room.RoomStatus}
(Hotels \bowtie Unused \bowtie Room \bowtie RoomType)
\]

**Q9: guests who used the laundry service**

\[
\pi_{Guest\_ID,\ Name}\Big(Guests \bowtie Reservation \bowtie Stays \bowtie Records \bowtie \sigma_{ServiceType='Laundry'}(Services)\Big)
\]

**Q10: guests who stayed in a Suite or used the Spa service**

\[
R = \pi_{Reservation\_ID,\ Guest\_ID}(Reservation)
\]

\[
Suite = \pi_{Guest\_ID}\Big(R \bowtie Stays \bowtie Room \bowtie \sigma_{Name='Suite'}(RoomType)\Big)
\]

\[
Spa = \pi_{Guest\_ID}\Big(R \bowtie \pi_{StayID,\ Reservation\_ID}(Stays) \bowtie Records \bowtie \sigma_{ServiceType='Spa'}(Services)\Big)
\]

\[
\pi_{Guest\_ID,\ Name}(Guests \bowtie (Suite \cup Spa))
\]

## 8.6 Assumptions and schema limitations

- A reservation stores a room type and date range, but does not store a hotel or physical room. The physical room is assigned only when a stay is created at check-in. Therefore, Q1 checks actual stays for room conflicts; it cannot reliably subtract future reservations for one specific hotel using the current schema.
- Q1 treats the selected date range as inclusive and treats the checkout date as the first date on which the room is free. Its maintenance filter uses the current `RoomStatus`; the schema does not keep historical maintenance periods.
- Q3 calculates occupied room-nights from actual stays. Its denominator uses the total number of registered rooms because the schema does not record when a room entered or left maintenance. The result is therefore an inventory-based occupancy rate, not a maintenance-adjusted historical rate.
- For Q5, one `StayID` represents one occupied room for that stay. The query divides each service's total revenue by the number of distinct stays in which that service was recorded. This makes the meaning of “revenue per occupied room” explicit for this schema.
- The four relational-algebra expressions show the corresponding relational operations. Q7 projects the identifying room details; SQL returns the same identifying room records with the room type and current status.

## 8.7 Requirement coverage

The query set contains 14 SQL queries, one view, and four relational-algebra expressions. It includes multi-table joins (Q6), outer joins (Q7, Q11 and Q12), GROUP BY with HAVING (Q8), a nested IN query (Q9), NOT EXISTS for the “every hotel” condition (Q4), and a set operation (Q10).

The assignment also requires at least 15 realistic sample rows in every table and enough data for every required query to return a non-empty result. These are database-data and execution checks; they cannot be established by the query scripts or this report alone and must be verified against the loaded sample data.
