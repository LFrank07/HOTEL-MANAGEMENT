# Hotel Management (IT079IU, topic 23) – Query developer package

All files were run on an empty MariaDB 10.11 (MySQL 8.0-compatible) server; `01 → 02 → 03 → 04` run top-to-bottom **twice in a row without errors**.

| File | Content |
|---|---|
| `01_schema.sql` | DROP/CREATE DATABASE, 16 tables with PK, FK (ON DELETE/ON UPDATE), NOT NULL, UNIQUE, CHECK, DEFAULT, + 5 explicit composite indexes. **Test harness for the queries** – it drops and recreates `hotel_group`; use only on a disposable test server. Replace it with the Database Developer's final script before integration. |
| `02_sample_data.sql` | ≥ 15 rows in every table (400 stays, 397 invoices, …), generated, consistent (invoice lines = bill view). |
| `03_queries.sql` | **D5 query script**: 1 view + 14 queries (Q1–Q5 = the five queries of topic 23), each preceded by its English question. |
| `04_updates_and_transactions.sql` | INSERT/UPDATE/DELETE for every table; 3 transactions (check-in = 3 tables, check-out + invoicing = 5 tables, payment with ROLLBACK); EXPLAIN of the index. Leaves data unchanged (re-runnable). |
| `05_constraint_tests.sql` | 10 statements that must be rejected (duplicate key, missing FK, CHECK, RESTRICT) – run with `mysql --force`. |
| `08_queries_report.md` | Report section 8: question, SQL, relational algebra (Q1, Q4, Q6, Q9, Q10), result on the sample data. |

## Checklist against section 2.2 / 2.3 of the assignment
- ≥ 12 queries: **14** (Q1–Q14) ✔
- multi-table join: Q2 (via view), Q6 (7 tables) ✔ · outer join: Q7 (LEFT JOIN), Q11, Q12 ✔
- GROUP BY + HAVING: Q8 ✔ · nested IN: Q9 · EXISTS / NOT EXISTS: Q1, Q11 ✔
- NOT EXISTS for "for all": Q4 (guests at every hotel) ✔ · set operation: Q10 (UNION) ✔ · view: `v_stay_bill_lines` ✔
- ≥ 4 queries in relational algebra: Q4, Q6, Q9, Q10 are plain algebra (σ π ⋈ ÷ ∪); Q1 is given with aggregation (γ) as extra ✔ (in `08_queries_report.md`)
- each query preceded by its question in English ✔ · INSERT/UPDATE/DELETE per table + transaction with COMMIT/ROLLBACK ✔
- 5 explicit composite indexes and their target queries: `idx_stay_room_dates` → Q1; `idx_res_hotel_status_dates` → Q1; `idx_stay_hotel_checkin_checkout` → Q3; `idx_consumption_stay_service_date` → Q5/Q9/Q10; `idx_payment_date_invoice_method` → Q14 ✔
- Application: Q1–Q5 are parameterised with `@var`; in Java replace each by `?` (PreparedStatement). Q14 fits the "report screen" (total per month), Q6/Q2 the master-detail screen.

## Things the team should know (found while reading the repository)
1. **Room identity.** The topic says "a room is identified by the hotel plus room number". The `README.md` DDL uses `room_id BIGSERIAL` – the relational diagram (`Room_ID + Hotel_ID`) is closer. My schema uses `PRIMARY KEY (hotel_id, room_number)` and `stay` references `(hotel_id, room_number)`.
2. **Reservation has no hotel.** In the ER diagram a reservation points only to a room type, so one cannot tell *which hotel* it is for (a group of 15 hotels!). I added `reservation.hotel_id`; Data modeller should confirm.
3. **PostgreSQL DDL in README** (`BIGSERIAL`, no ON DELETE/ON UPDATE, no CHECK/UNIQUE except a few) does not meet 2.3 and does not run on MySQL. `position` is a reserved word in MySQL → table named `job_position`.
4. **Consumption amount** is derived (`quantity × unit_price`) – I do not store it (would violate 3NF); `unit_price` is the price charged at that time.
5. **Non-overlap of rate plans / double-booking of a room** cannot be a declarative CHECK; document in the report (trigger or application check, as allowed in 2.3).

## Interpretation to confirm with the group
- **Q5 "service that produces the most revenue per occupied room"**: service revenue ÷ number of distinct occupied room-nights (stay + date) on which the service was consumed; result = City Tour Car. If the group reads it differently (e.g. per hotel), only the CTE `per_service` changes.
- **Q1** returns available *units per room type* (a reservation is for a type; the room is chosen at check-in): inventory − overlapping occupied rooms − unassigned PENDING/CONFIRMED reservations. A stay with no check-out counts as occupying the room indefinitely; rooms in MAINTENANCE/CLEANING are not in the inventory.
- **Q3** stops at `@today` for the current month (numerator and denominator). The denominator uses all registered rooms because the schema has no historical room-status table; current MAINTENANCE/CLEANING status cannot safely be applied to past months.
- Q2 bills a stay still in house up to `CURRENT_DATE`.

## Dialect notes
Recursive CTE (`WITH RECURSIVE`), `ROW_NUMBER() OVER`, `DATE_FORMAT`, `AUTO_INCREMENT`, `CREATE OR REPLACE VIEW` are MySQL 8 / MariaDB specific – marked in comments; on SQL Server they need small changes.


## Before submission
- Do not run `01_schema.sql` against a database containing team data: it starts with `DROP DATABASE IF EXISTS hotel_group`.
- The query package uses its own test schema. Compare all table/column names with the team's final schema before merging.
- After running `03_queries.sql`, execute each Q1–Q14 separately and save fresh result screenshots; the results in `08_queries_report.md` were regenerated from the final `03_queries.sql`.
- `05_constraint_tests.sql` intentionally contains invalid statements; run it only with `mysql --force` on the disposable test database.


## Performance refinements in this package
- Added composite indexes for reservation overlap checks (Q1), stay date-overlap checks (Q3), service-consumption joins (Q5/Q9/Q10), and payment reporting (Q14).
- Rewrote Q3 to calculate each hotel's room inventory once and compare raw DATETIME columns to month boundaries; this avoids applying DATE() to indexed stay columns.
- Rewrote Q1's stay-overlap predicate to compare raw DATETIME columns to the requested date boundaries.
- Rewrote Q14's YEAR(date) filter as a half-open date range so the payment date index can be used.
- Query meanings and sample-data assumptions are unchanged. Indexes improve likely access paths, but actual speed must be confirmed with EXPLAIN on the target MySQL/MariaDB server.

- Q1 fix: the raw-DATETIME predicate is now `(check_out IS NULL OR check_out >= @from + 1 day)`, which keeps same-day turnover semantics without wrapping the indexed column in COALESCE. Q6/Q11 ORDER BY got a unique tie-breaker so results are deterministic.
