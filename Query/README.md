# Query package: Hotel Management

Requires MySQL 8.0 or later and the database `Hotel_Management_Group3`.

| File | Content |
|---|---|
| `queries.sql` | View and queries Q1 to Q14 |
| `index.sql` | Creates the `Stays` index and displays an execution plan with `EXPLAIN` |
| `updates.sql` | Demonstrates INSERT, UPDATE, DELETE, COMMIT and ROLLBACK |
| `08_queries_report.md` | Query descriptions, relational algebra, index and transaction notes |

## Run order

Run the existing database setup scripts first, if the database has not already been created and populated:

1. `Database/schema1.sql`
2. `Database/sample_data1.sql`

Then run the files in this folder:

3. `index.sql`
4. `queries.sql`
5. `updates.sql`

Do not rerun the schema or sample-data scripts on an already populated database unless you intend to recreate the database. The schema script may drop and rebuild the database, and the sample-data script may produce duplicate-key errors when run twice.

Change the test parameters at the top of `queries.sql` to test other dates, hotels or stays. `index.sql` checks whether its index already exists before creating it. `updates.sql` uses reserved test IDs (9000 and above) and a temporary room number (`999`); run it only when those IDs and that room number are reserved for this test.
