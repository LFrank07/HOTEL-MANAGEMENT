# Query package: Hotel Management

Requires MySQL 8.0 or later (MySQL Workbench 8.0).

| File | Content |
|---|---|
| `queries.sql` | View and queries Q1 to Q14 |
| `explain_index.sql` | Shows the execution plan (`EXPLAIN`) of the stay-overlap search, with and without the index |
| `crud_transaction_tests.sql` | Demonstrates INSERT, UPDATE, DELETE, COMMIT and ROLLBACK |
| `08_queries_report.md` | Query descriptions, relational algebra, index and transaction notes |

## Run order

1. `hotel_management_full.sql` (in the `Database` folder). This single script drops and recreates the database `Hotel_Management_Group3`, creates the 16 tables, indexes and triggers, and loads the sample data. It can be run again at any time; each run restores the original sample data.

Then run the files in this folder:

2. `queries.sql`
3. `explain_index.sql`
4. `crud_transaction_tests.sql`

The index used by the queries (`IDX_Stays_Room_Dates`) is created by `hotel_management_full.sql`, so `explain_index.sql` only displays the plans and does not change the database.

Change the test parameters at the top of `queries.sql` to test other dates, hotels or stays. `crud_transaction_tests.sql` uses reserved test IDs (9000 and above) and a temporary room number (`999`) and removes its test data at the end; run it only when those IDs and that room number are reserved for this test. If it stops because of an error, run it again from the beginning, or rerun `hotel_management_full.sql` to restore the sample data.
