# Section 8 – Queries (English, SQL, relational algebra, result on the sample data)

System: MariaDB 10.11 (MySQL 8.0 compatible). Parameters used for the results: hotel 1, period 2026-03-10 → 2026-03-13, stay 290, year 2026, today 2026-11-17.

## View used by Q2
```sql
CREATE OR REPLACE VIEW v_stay_bill_lines AS
WITH RECURSIVE nights (stay_id, type_id, room_number, night, last_day) AS (
    SELECT s.stay_id, r.type_id, s.room_number,
           CAST(DATE(s.check_in) AS DATE),
           CAST(DATE(COALESCE(s.check_out, CURRENT_DATE)) AS DATE)
    FROM   stay s
    JOIN   room r ON r.hotel_id = s.hotel_id AND r.room_number = s.room_number
    WHERE  DATE(s.check_in) < DATE(COALESCE(s.check_out, CURRENT_DATE))
    UNION ALL
    SELECT stay_id, type_id, room_number,
           CAST(night + INTERVAL 1 DAY AS DATE), last_day
    FROM   nights
    WHERE  night + INTERVAL 1 DAY < last_day
)
SELECT n.stay_id,
       'ROOM'                                        AS line_type,
       CONCAT('Room ', n.room_number, ' - night ', n.night) AS description,
       rp.price                                      AS amount,
       n.night                                       AS line_date
FROM   nights n
JOIN   rate_plan rp ON rp.type_id = n.type_id
                   AND n.night BETWEEN rp.start_date AND rp.end_date
UNION ALL
SELECT sc.stay_id,
       'SERVICE',
       CONCAT(sv.name, ' x', sc.quantity),
       sc.quantity * sc.unit_price,
       DATE(sc.consumed_at)
FROM   service_consumption sc
JOIN   service sv ON sv.service_id = sc.service_id;
```

## Q1 – Which room inventory is available by room type at one hotel for a given date range?

> Important: reservations are made for a ROOM TYPE; a physical room is assigned only at check-in. Therefore the database cannot truthfully name the exact free room numbers for future dates. This query reports available room units by type, subtracting overlapping occupied rooms and unassigned PENDING/CONFIRMED bookings.

```sql
WITH inventory AS (
    SELECT r.type_id, COUNT(*) AS room_count
    FROM room r
    WHERE r.hotel_id = @hotel_id
      AND r.status IN ('AVAILABLE', 'OCCUPIED')
    GROUP BY r.type_id
), occupied AS (
    SELECT ro.type_id, COUNT(DISTINCT s.room_number) AS occupied_count
    FROM stay s
    JOIN room ro ON ro.hotel_id = s.hotel_id AND ro.room_number = s.room_number
    WHERE s.hotel_id = @hotel_id
      AND s.check_in < @to
      -- check-out at any time on day @from still allows a new arrival that day:
      AND (s.check_out IS NULL
           OR s.check_out >= DATE_ADD(@from, INTERVAL 1 DAY))
    GROUP BY ro.type_id
), reserved AS (
    SELECT res.type_id, COUNT(*) AS reserved_count
    FROM reservation res
    WHERE res.hotel_id = @hotel_id
      AND res.status IN ('PENDING', 'CONFIRMED')
      AND res.start_date < @to
      AND res.end_date > @from
      AND NOT EXISTS (SELECT 1 FROM stay st WHERE st.reservation_id = res.reservation_id)
    GROUP BY res.type_id
)
SELECT rt.name AS room_type,
       COALESCE(i.room_count, 0) AS room_inventory,
       COALESCE(o.occupied_count, 0) AS occupied_rooms,
       COALESCE(b.reserved_count, 0) AS unassigned_reservations,
       GREATEST(COALESCE(i.room_count, 0) - COALESCE(o.occupied_count, 0)
                - COALESCE(b.reserved_count, 0), 0) AS available_rooms
FROM room_type rt
JOIN inventory i ON i.type_id = rt.type_id
LEFT JOIN occupied o ON o.type_id = rt.type_id
LEFT JOIN reserved b ON b.type_id = rt.type_id
WHERE GREATEST(i.room_count - COALESCE(o.occupied_count, 0)
                - COALESCE(b.reserved_count, 0), 0) > 0
ORDER BY rt.name;
```

**Relational algebra**

```
Inventory := γ type_id; COUNT(room_number)→room_count ( σ hotel_id=h ∧ status∈{AVAILABLE,OCCUPIED} (Room) )
Occupied  := γ type_id; COUNT(DISTINCT room_number)→occupied_count ( Room ⋈ σ hotel_id=h ∧ check_in < to ∧ (check_out = NULL ∨ check_out ≥ from + 1 day) (Stay) )
Reserved  := γ type_id; COUNT(reservation_id)→reserved_count ( σ hotel_id=h ∧ status∈{PENDING,CONFIRMED} ∧ start_date < to ∧ end_date > from ( Reservation ▷ Stay ) )
Available := π type_id, room_count − occupied_count − reserved_count ( Inventory ⟕ Occupied ⟕ Reserved ),  kept when > 0
```
γ = grouping/aggregation, ▷ = anti-join (reservations that have no stay yet), ⟕ = left outer join. `Available` is an inventory count per room type; the exact room is chosen at check-in.

**Result**

```
+------------------+----------------+----------------+-------------------------+-----------------+
| room_type        | room_inventory | occupied_rooms | unassigned_reservations | available_rooms |
+------------------+----------------+----------------+-------------------------+-----------------+
| Standard Double  |              1 |              0 |                       0 |               1 |
| Studio Apartment |              1 |              0 |                       0 |               1 |
| Superior Twin    |              1 |              0 |                       0 |               1 |
+------------------+----------------+----------------+-------------------------+-----------------+
```

## Q2 – What is the bill of one stay, with room charges and services?

> (multi-table join through the view above, then the totals.)

```sql
SELECT line_date, line_type, description, amount
FROM   v_stay_bill_lines
WHERE  stay_id = @stay_id
ORDER BY line_date, line_type DESC, description;

SELECT stay_id,
       SUM(CASE WHEN line_type = 'ROOM'    THEN amount ELSE 0 END) AS room_charges,
       SUM(CASE WHEN line_type = 'SERVICE' THEN amount ELSE 0 END) AS service_charges,
       SUM(amount)                                                 AS total_bill
FROM   v_stay_bill_lines
WHERE  stay_id = @stay_id
GROUP BY stay_id;
```

**Result**

```
+------------+-----------+-----------------------------+------------+
| line_date  | line_type | description                 | amount     |
+------------+-----------+-----------------------------+------------+
| 2026-02-09 | SERVICE   | Room Service Meal x2        |  640000.00 |
| 2026-02-09 | ROOM      | Room 202 - night 2026-02-09 | 2380000.00 |
| 2026-02-10 | SERVICE   | Lunch Set Menu x1           |  250000.00 |
| 2026-02-10 | ROOM      | Room 202 - night 2026-02-10 | 4480000.00 |
| 2026-02-11 | ROOM      | Room 202 - night 2026-02-11 | 4480000.00 |
| 2026-02-12 | ROOM      | Room 202 - night 2026-02-12 | 4480000.00 |
| 2026-02-13 | SERVICE   | Minibar Snack x3            |  135000.00 |
| 2026-02-13 | ROOM      | Room 202 - night 2026-02-13 | 4480000.00 |
| 2026-02-14 | SERVICE   | Minibar Beer x1             |   50000.00 |
+------------+-----------+-----------------------------+------------+
+---------+--------------+-----------------+-------------+
| stay_id | room_charges | service_charges | total_bill  |
+---------+--------------+-----------------+-------------+
|     290 |  20300000.00 |      1075000.00 | 21375000.00 |
+---------+--------------+-----------------+-------------+
```

## Q3 – What is the occupancy rate per month per hotel?

> Occupancy = occupied room-nights / registered room-nights. For the current month, both numerator and denominator stop at @today (inclusive). The schema has no room-status history, so all registered rooms remain in the historical denominator; today's MAINTENANCE/CLEANING status cannot be applied retroactively.

```sql
WITH RECURSIVE months (m_start) AS (
    SELECT CAST(CONCAT(@year, '-01-01') AS DATE)
    UNION ALL
    SELECT CAST(m_start + INTERVAL 1 MONTH AS DATE)
    FROM months
    WHERE m_start + INTERVAL 1 MONTH <= CAST(CONCAT(@year, '-12-01') AS DATE)
), month_bounds AS (
    SELECT m_start,
           LEAST(m_start + INTERVAL 1 MONTH, DATE_ADD(@today, INTERVAL 1 DAY)) AS period_end
    FROM months
), hotel_inventory AS (
    SELECT hotel_id, COUNT(*) AS room_count
    FROM room
    GROUP BY hotel_id
)
SELECT h.name AS hotel,
       DATE_FORMAT(m.m_start, '%Y-%m') AS month,
       COALESCE(SUM(GREATEST(0, DATEDIFF(
           LEAST(COALESCE(s.check_out, DATE_ADD(@today, INTERVAL 1 DAY)), m.period_end),
           GREATEST(s.check_in, m.m_start)))), 0) AS occupied_nights,
       COALESCE(hi.room_count, 0) * DATEDIFF(m.period_end, m.m_start) AS available_nights,
       ROUND(100 * COALESCE(SUM(GREATEST(0, DATEDIFF(
           LEAST(COALESCE(s.check_out, DATE_ADD(@today, INTERVAL 1 DAY)), m.period_end),
           GREATEST(s.check_in, m.m_start)))), 0)
         / NULLIF(COALESCE(hi.room_count, 0) * DATEDIFF(m.period_end, m.m_start), 0), 1) AS occupancy_pct
FROM month_bounds m
CROSS JOIN hotel h
LEFT JOIN hotel_inventory hi ON hi.hotel_id = h.hotel_id
LEFT JOIN stay s
       ON s.hotel_id = h.hotel_id
      AND s.check_in < m.period_end
      AND (s.check_out IS NULL OR s.check_out > m.m_start)
WHERE m.m_start <= @today
GROUP BY h.hotel_id, h.name, hi.room_count, m.m_start, m.period_end
ORDER BY h.name, m.m_start;
```

**Result** (result shown for hotel 1 only; the query returns 15 hotels x 11 months)

```
+----------------+---------+-----------------+------------------+---------------+
| hotel          | month   | occupied_nights | available_nights | occupancy_pct |
+----------------+---------+-----------------+------------------+---------------+
| Saigon Central | 2026-01 |              62 |              155 |          40.0 |
| Saigon Central | 2026-02 |              49 |              140 |          35.0 |
| Saigon Central | 2026-03 |              50 |              155 |          32.3 |
| Saigon Central | 2026-04 |              51 |              150 |          34.0 |
| Saigon Central | 2026-05 |              38 |              155 |          24.5 |
| Saigon Central | 2026-06 |              62 |              150 |          41.3 |
| Saigon Central | 2026-07 |              70 |              155 |          45.2 |
| Saigon Central | 2026-08 |              61 |              155 |          39.4 |
| Saigon Central | 2026-09 |              67 |              150 |          44.7 |
| Saigon Central | 2026-10 |              60 |              155 |          38.7 |
| Saigon Central | 2026-11 |               7 |               85 |           8.2 |
+----------------+---------+-----------------+------------------+---------------+
```

## Q4 – Which guests have stayed at every hotel of the group?

> (relational DIVISION written with a double NOT EXISTS: there is no hotel at which the guest has not stayed.)

```sql
SELECT g.guest_id, g.name
FROM   guest g
WHERE  NOT EXISTS (
         SELECT 1
         FROM   hotel h
         WHERE  NOT EXISTS (
                  SELECT 1
                  FROM   stay s
                  JOIN   reservation r ON r.reservation_id = s.reservation_id
                  WHERE  r.guest_id = g.guest_id
                    AND  s.hotel_id = h.hotel_id))
ORDER BY g.guest_id;
```

**Relational algebra**

```
Stayed(guest_id, hotel_id) := π Reservation.guest_id, Stay.hotel_id ( Reservation ⋈ Reservation.reservation_id = Stay.reservation_id  Stay )
AllHotels(hotel_id)        := π hotel_id (Hotel)
Answer := π guest_id, name ( Guest ⋈ ( Stayed ÷ AllHotels ) )
```
Division expanded with the basic operators: `R ÷ S = π guest_id (R) − π guest_id ( ( π guest_id (R) × S ) − R )`
(the guests for whom some (guest, hotel) pair is missing are removed). This is the algebra of the double NOT EXISTS.

**Result**

```
+----------+---------------+
| guest_id | name          |
+----------+---------------+
|        1 | Nguyen Van An |
+----------+---------------+
```

## Q5 – Which service produces the most revenue per occupied room?

> Interpretation used here: service revenue divided by the number of distinct occupied room-nights on which that service was consumed. This avoids counting one physical room only once when it hosts many different stays/dates. Ties return.

```sql
WITH per_service AS (
    SELECT sv.service_id, sv.name, sv.service_type,
           SUM(sc.quantity * sc.unit_price) AS revenue,
           COUNT(DISTINCT CONCAT(st.stay_id, '-', DATE(sc.consumed_at))) AS occupied_room_nights
    FROM service_consumption sc
    JOIN service sv ON sv.service_id = sc.service_id
    JOIN stay st ON st.stay_id = sc.stay_id
    GROUP BY sv.service_id, sv.name, sv.service_type
)
SELECT name AS service, service_type, revenue, occupied_room_nights,
       ROUND(revenue / occupied_room_nights, 0) AS revenue_per_occupied_room
FROM per_service
WHERE revenue / occupied_room_nights =
      (SELECT MAX(revenue / occupied_room_nights) FROM per_service);
```

**Result**

```
+---------------+--------------+--------------+----------------------+---------------------------+
| service       | service_type | revenue      | occupied_room_nights | revenue_per_occupied_room |
+---------------+--------------+--------------+----------------------+---------------------------+
| City Tour Car | TRANSPORT    | 109800000.00 |                   62 |                   1770968 |
+---------------+--------------+--------------+----------------------+---------------------------+
```

## Q6 – [multi-table join, 7 tables] For every completed stay: who stayed, where,

> which room type was requested and which room was actually assigned.

```sql
SELECT st.stay_id, g.name AS guest, h.name AS hotel,
       rt_req.name AS requested_type, st.room_number, rt_got.name AS assigned_type,
       st.check_in, st.check_out
FROM   stay st
JOIN   reservation res  ON res.reservation_id = st.reservation_id
JOIN   guest g          ON g.guest_id   = res.guest_id
JOIN   hotel h          ON h.hotel_id   = st.hotel_id
JOIN   room_type rt_req ON rt_req.type_id = res.type_id
JOIN   room ro          ON ro.hotel_id = st.hotel_id AND ro.room_number = st.room_number
JOIN   room_type rt_got ON rt_got.type_id = ro.type_id
WHERE  st.check_out IS NOT NULL
ORDER BY st.check_in, st.stay_id
LIMIT 20;
```

**Relational algebra**

```
J := Stay ⋈ Stay.reservation_id = Reservation.reservation_id Reservation
       ⋈ Reservation.guest_id = Guest.guest_id Guest
       ⋈ Stay.hotel_id = Hotel.hotel_id Hotel
       ⋈ Reservation.type_id = ρ Req(type_id, req_name, …) (RoomType).type_id  ρ Req(RoomType)
       ⋈ (Stay.hotel_id, Stay.room_number) = (Room.hotel_id, Room.room_number) Room
       ⋈ Room.type_id = ρ Got(type_id, got_name, …) (RoomType).type_id  ρ Got(RoomType)
Answer := π stay_id, Guest.name, Hotel.name, req_name, room_number, got_name, check_in, check_out ( σ check_out ≠ NULL (J) )
```
ρ renames the two copies of RoomType (requested type / assigned type).

**Result**

```
+---------+----------------+-------------------+-------------------+-------------+-------------------+---------------------+---------------------+
| stay_id | guest          | hotel             | requested_type    | room_number | assigned_type     | check_in            | check_out           |
+---------+----------------+-------------------+-------------------+-------------+-------------------+---------------------+---------------------+
|      86 | Dinh Cong Son  | Saigon Central    | Standard Double   | 101         | Standard Double   | 2026-01-02 14:00:00 | 2026-01-05 11:00:00 |
|     294 | Maria Garcia   | Saigon Riverside  | Family Room       | 201         | Family Room       | 2026-01-02 14:15:00 | 2026-01-05 11:30:00 |
|     240 | Le Hoang Cuong | Saigon Riverside  | Standard Twin     | 101         | Standard Twin     | 2026-01-02 14:45:00 | 2026-01-06 11:00:00 |
|     163 | Kim Min Jun    | Saigon Central    | Superior Twin     | 102         | Superior Twin     | 2026-01-05 14:30:00 | 2026-01-08 11:30:00 |
|      95 | Duong Thi Mai  | Saigon Central    | Junior Suite      | 202         | Junior Suite      | 2026-01-06 14:15:00 | 2026-01-10 11:30:00 |
|     319 | Phan Thi Oanh  | Saigon Riverside  | Family Room       | 201         | Family Room       | 2026-01-06 14:45:00 | 2026-01-11 11:30:00 |
|      31 | Nguyen Van An  | Hanoi Old Quarter | Deluxe Twin       | 102         | Deluxe Twin       | 2026-01-07 14:00:00 | 2026-01-09 11:00:00 |
|      55 | Maria Garcia   | Saigon Central    | Standard Double   | 101         | Standard Double   | 2026-01-07 14:00:00 | 2026-01-08 11:00:00 |
|     338 | Lam Gia Viet   | Saigon Riverside  | Deluxe Double     | 102         | Deluxe Double     | 2026-01-08 14:00:00 | 2026-01-13 11:00:00 |
|     389 | John Smith     | Saigon Riverside  | Standard Twin     | 101         | Standard Twin     | 2026-01-10 14:15:00 | 2026-01-13 11:30:00 |
|     211 | Maria Garcia   | Saigon Central    | Junior Suite      | 202         | Junior Suite      | 2026-01-10 14:45:00 | 2026-01-15 11:00:00 |
|      48 | Tran Thi Binh  | Nha Trang Seaside | Villa             | 201         | Villa             | 2026-01-11 14:45:00 | 2026-01-14 11:30:00 |
|     199 | Le Hoang Cuong | Saigon Central    | Superior Twin     | 102         | Superior Twin     | 2026-01-13 14:45:00 | 2026-01-18 11:00:00 |
|     112 | Dinh Cong Son  | Saigon Central    | Deluxe Ocean View | 201         | Deluxe Ocean View | 2026-01-14 14:00:00 | 2026-01-16 11:30:00 |
|     220 | Phan Thi Oanh  | Saigon Central    | Standard Double   | 101         | Standard Double   | 2026-01-14 14:15:00 | 2026-01-17 11:30:00 |
|     352 | Dinh Cong Son  | Saigon Riverside  | Family Room       | 201         | Family Room       | 2026-01-14 14:15:00 | 2026-01-18 11:00:00 |
|     191 | Mai Thi Thao   | Saigon Central    | Junior Suite      | 202         | Junior Suite      | 2026-01-16 14:30:00 | 2026-01-19 11:30:00 |
|      90 | Ha Thi Uyen    | Saigon Central    | Studio Apartment  | 301         | Studio Apartment  | 2026-01-18 14:15:00 | 2026-01-22 11:30:00 |
|     169 | Vu Quang Huy   | Saigon Central    | Junior Suite      | 202         | Junior Suite      | 2026-01-19 14:00:00 | 2026-01-22 11:00:00 |
|     216 | Sato Haruki    | Saigon Central    | Deluxe Ocean View | 201         | Deluxe Ocean View | 2026-01-19 14:00:00 | 2026-01-22 11:00:00 |
+---------+----------------+-------------------+-------------------+-------------+-------------------+---------------------+---------------------+
```

## Q7 – [outer join] Which rooms of the group have never hosted a stay?

> (LEFT JOIN keeps every room; the rooms with no matching stay are those where the stay side is NULL.)

```sql
SELECT h.name AS hotel, r.room_number, rt.name AS room_type, r.status,
       COUNT(s.stay_id) AS number_of_stays
FROM   room r
JOIN   hotel h      ON h.hotel_id = r.hotel_id
JOIN   room_type rt ON rt.type_id = r.type_id
LEFT JOIN stay s    ON s.hotel_id = r.hotel_id AND s.room_number = r.room_number
GROUP BY h.hotel_id, h.name, r.room_number, rt.name, r.status
HAVING COUNT(s.stay_id) = 0
ORDER BY h.name, r.room_number;
```

**Result**

```
+-------------------+-------------+--------------------+-----------+-----------------+
| hotel             | room_number | room_type          | status    | number_of_stays |
+-------------------+-------------+--------------------+-----------+-----------------+
| Can Tho Mekong    | 101         | Villa              | AVAILABLE |               0 |
| Can Tho Mekong    | 201         | Deluxe Double      | AVAILABLE |               0 |
| Da Lat Pine Hill  | 102         | Studio Apartment   | AVAILABLE |               0 |
| Da Lat Pine Hill  | 201         | Standard Double    | AVAILABLE |               0 |
| Da Nang Bay View  | 101         | Deluxe Twin        | AVAILABLE |               0 |
| Da Nang Bay View  | 102         | Triple Room        | AVAILABLE |               0 |
| Da Nang Bay View  | 301         | Superior Double    | AVAILABLE |               0 |
| Da Nang Beach     | 301         | Standard Twin      | AVAILABLE |               0 |
| Hanoi Old Quarter | 101         | Superior Double    | AVAILABLE |               0 |
| Hanoi Old Quarter | 301         | Standard Single    | AVAILABLE |               0 |
| Hanoi West Lake   | 102         | Deluxe Ocean View  | AVAILABLE |               0 |
| Hoi An Heritage   | 102         | Junior Suite       | AVAILABLE |               0 |
| Hoi An Heritage   | 201         | Studio Apartment   | AVAILABLE |               0 |
| Hoi An Heritage   | 202         | Standard Double    | AVAILABLE |               0 |
| Hue Imperial      | 101         | Executive Suite    | AVAILABLE |               0 |
| Nha Trang Island  | 101         | Triple Room        | AVAILABLE |               0 |
| Nha Trang Island  | 102         | Presidential Suite | AVAILABLE |               0 |
| Nha Trang Seaside | 101         | Family Room        | AVAILABLE |               0 |
| Nha Trang Seaside | 102         | Executive Suite    | AVAILABLE |               0 |
... (9 more lines, truncated here)
```

## Q8 – [GROUP BY + HAVING] Which hotels earned more than 8,000,000 VND from

> services, with the number of consumption lines and the average line value?

```sql
SELECT h.name AS hotel,
       COUNT(*)                                   AS consumption_lines,
       SUM(sc.quantity * sc.unit_price)           AS service_revenue,
       ROUND(AVG(sc.quantity * sc.unit_price), 0) AS avg_line_value
FROM   service_consumption sc
JOIN   stay  st ON st.stay_id = sc.stay_id
JOIN   hotel h  ON h.hotel_id = st.hotel_id
GROUP BY h.hotel_id, h.name
HAVING SUM(sc.quantity * sc.unit_price) > 8000000
ORDER BY service_revenue DESC;
```

**Result**

```
+-------------------+-------------------+-----------------+----------------+
| hotel             | consumption_lines | service_revenue | avg_line_value |
+-------------------+-------------------+-----------------+----------------+
| Saigon Central    |               420 |    242420000.00 |         577190 |
| Saigon Riverside  |               443 |    241145000.00 |         544345 |
| Hanoi West Lake   |                18 |     10510000.00 |         583889 |
| Nha Trang Seaside |                20 |     10490000.00 |         524500 |
| Can Tho Mekong    |                13 |      9170000.00 |         705385 |
| Vung Tau Coast    |                11 |      8600000.00 |         781818 |
| Hoi An Heritage   |                14 |      8465000.00 |         604643 |
| Phu Quoc Resort   |                21 |      8340000.00 |         397143 |
+-------------------+-------------------+-----------------+----------------+
```

## Q9 – [nested query with IN] Which guests have used a laundry service during a stay?

```sql
SELECT g.guest_id, g.name
FROM   guest g
WHERE  g.guest_id IN (
         SELECT res.guest_id
         FROM   reservation res
         JOIN   stay st             ON st.reservation_id = res.reservation_id
         JOIN   service_consumption sc ON sc.stay_id = st.stay_id
         JOIN   service sv          ON sv.service_id = sc.service_id
         WHERE  sv.service_type = 'LAUNDRY')
ORDER BY g.name;
```

**Relational algebra**

```
Laundry := σ service_type='LAUNDRY' (Service)
Users   := π guest_id ( Reservation ⋈ Stay ⋈ ServiceConsumption ⋈ Laundry )
Answer  := π guest_id, name ( Guest ⋈ Users )
```
`IN (subquery)` is a semi-join: the guests whose id appears in `Users`.

**Result**

```
+----------+----------------+
| guest_id | name           |
+----------+----------------+
|        8 | Bui Anh Khoa   |
|        7 | Dang Thu Ha    |
|       16 | Dinh Cong Son  |
|        9 | Do Thi Lan     |
|       11 | Duong Thi Mai  |
|       22 | Emily Johnson  |
|       19 | Ha Thi Uyen    |
|        5 | Hoang Thi Em   |
|       21 | John Smith     |
|       23 | Kim Min Jun    |
|       20 | Lam Gia Viet   |
|        3 | Le Hoang Cuong |
|       12 | Ly Quoc Nam    |
|       17 | Mai Thi Thao   |
|       25 | Maria Garcia   |
|       10 | Ngo Van Long   |
|        1 | Nguyen Van An  |
|        4 | Pham Minh Duc  |
|       13 | Phan Thi Oanh  |
... (7 more lines, truncated here)
```

## Q10 – Which guests either stayed in a suite/villa or used a spa service?

> UNION returns each guest only once, even when both conditions are true.

```sql
SELECT g.guest_id, g.name
FROM guest g
JOIN reservation res ON res.guest_id = g.guest_id
JOIN stay st ON st.reservation_id = res.reservation_id
JOIN room ro ON ro.hotel_id = st.hotel_id AND ro.room_number = st.room_number
JOIN room_type rt ON rt.type_id = ro.type_id
WHERE rt.name LIKE '%Suite%' OR rt.name LIKE '%Villa%'
UNION
SELECT g.guest_id, g.name
FROM guest g
JOIN reservation res ON res.guest_id = g.guest_id
JOIN stay st ON st.reservation_id = res.reservation_id
JOIN service_consumption sc ON sc.stay_id = st.stay_id
JOIN service sv ON sv.service_id = sc.service_id
WHERE sv.service_type = 'SPA'
ORDER BY name;
```

**Relational algebra**

```
SuiteGuests := π guest_id, name ( Guest ⋈ Reservation ⋈ Stay ⋈ Room ⋈ σ name LIKE '%Suite%' ∨ name LIKE '%Villa%' (RoomType) )
SpaGuests   := π guest_id, name ( Guest ⋈ Reservation ⋈ Stay ⋈ ServiceConsumption ⋈ σ service_type='SPA' (Service) )
Answer      := SuiteGuests ∪ SpaGuests
```
Union is a native operator of the algebra and removes duplicates, so a guest satisfying both conditions appears once.

**Result**

```
+----------+----------------+
| guest_id | name           |
+----------+----------------+
|        8 | Bui Anh Khoa   |
|        7 | Dang Thu Ha    |
|       16 | Dinh Cong Son  |
|        9 | Do Thi Lan     |
|       11 | Duong Thi Mai  |
|       22 | Emily Johnson  |
|       19 | Ha Thi Uyen    |
|        5 | Hoang Thi Em   |
|       21 | John Smith     |
|       23 | Kim Min Jun    |
|       20 | Lam Gia Viet   |
|        3 | Le Hoang Cuong |
|       12 | Ly Quoc Nam    |
|       17 | Mai Thi Thao   |
|       25 | Maria Garcia   |
|       10 | Ngo Van Long   |
|        1 | Nguyen Van An  |
|        4 | Pham Minh Duc  |
|       13 | Phan Thi Oanh  |
... (7 more lines, truncated here)
```

## Q11 – [derived tables + outer join + EXISTS] Which invoices are not fully paid, and

> how much does each guest still owe? (total of invoice lines - payments received)

```sql
SELECT i.invoice_id, g.name AS guest, i.issue_date, i.status,
       t.total_billed, COALESCE(p.total_paid, 0) AS total_paid,
       t.total_billed - COALESCE(p.total_paid, 0) AS balance_due
FROM   invoice i
JOIN   (SELECT invoice_id, SUM(amount) AS total_billed
        FROM invoice_line GROUP BY invoice_id) t ON t.invoice_id = i.invoice_id
LEFT JOIN (SELECT invoice_id, SUM(amount) AS total_paid
           FROM payment GROUP BY invoice_id)   p ON p.invoice_id = i.invoice_id
JOIN   stay st         ON st.stay_id = i.stay_id
JOIN   reservation res ON res.reservation_id = st.reservation_id
JOIN   guest g         ON g.guest_id = res.guest_id
WHERE  t.total_billed - COALESCE(p.total_paid, 0) > 0
  AND  EXISTS (SELECT 1 FROM invoice_line il WHERE il.invoice_id = i.invoice_id)
ORDER BY balance_due DESC, i.invoice_id;
```

**Result**

```
+------------+----------------+------------+---------+--------------+-------------+-------------+
| invoice_id | guest          | issue_date | status  | total_billed | total_paid  | balance_due |
+------------+----------------+------------+---------+--------------+-------------+-------------+
|        307 | Duong Thi Mai  | 2026-09-18 | UNPAID  |  21610000.00 |        0.00 | 21610000.00 |
|         15 | Tran Thi Binh  | 2026-08-19 | PARTIAL |  40870000.00 | 20435000.00 | 20435000.00 |
|        274 | Duong Thi Mai  | 2026-08-24 | PARTIAL |  34000000.00 | 17000000.00 | 17000000.00 |
|         90 | Maria Garcia   | 2026-02-25 | UNPAID  |  16665000.00 |        0.00 | 16665000.00 |
|        239 | Dang Thu Ha    | 2026-06-29 | UNPAID  |  15480000.00 |        0.00 | 15480000.00 |
|        268 | Sato Haruki    | 2026-05-05 | UNPAID  |  13900000.00 |        0.00 | 13900000.00 |
|        374 | Maria Garcia   | 2026-10-04 | UNPAID  |  12985000.00 |        0.00 | 12985000.00 |
|        387 | Lam Gia Viet   | 2026-02-19 | PARTIAL |  24980000.00 | 12490000.00 | 12490000.00 |
|        340 | Do Thi Lan     | 2026-08-21 | UNPAID  |  12305000.00 |        0.00 | 12305000.00 |
|        394 | Bui Anh Khoa   | 2026-09-16 | UNPAID  |  12055000.00 |        0.00 | 12055000.00 |
|        123 | Sato Haruki    | 2026-09-08 | UNPAID  |  12050000.00 |        0.00 | 12050000.00 |
|        390 | Vo Thi Quynh   | 2026-04-26 | UNPAID  |  11650000.00 |        0.00 | 11650000.00 |
|        353 | Ly Quoc Nam    | 2026-06-07 | PARTIAL |  23190000.00 | 11595000.00 | 11595000.00 |
|        127 | Duong Thi Mai  | 2026-06-17 | UNPAID  |  11350000.00 |        0.00 | 11350000.00 |
|        388 | Ly Quoc Nam    | 2026-08-23 | UNPAID  |  11050000.00 |        0.00 | 11050000.00 |
|         33 | Tran Thi Binh  | 2026-06-24 | UNPAID  |  10760000.00 |        0.00 | 10760000.00 |
|        221 | Emily Johnson  | 2026-09-27 | UNPAID  |  10600000.00 |        0.00 | 10600000.00 |
|        269 | Vo Thi Quynh   | 2026-04-07 | PARTIAL |  21125000.00 | 10562000.00 | 10563000.00 |
|        224 | Le Hoang Cuong | 2026-10-03 | UNPAID  |  10320000.00 |        0.00 | 10320000.00 |
... (120 more lines, truncated here)
```

## Q12 – [recursive relationship ReportTo] Each staff member with the supervisor and the

> position; the general manager (no supervisor) must still appear.

```sql
SELECT h.name AS hotel, e.name AS staff, jp.title AS position, e.shift,
       sup.name AS supervisor
FROM   staff e
JOIN   hotel h         ON h.hotel_id = e.hotel_id
JOIN   job_position jp ON jp.role_id = e.role_id
LEFT JOIN staff sup    ON sup.staff_id = e.supervisor_id
ORDER BY h.name, jp.level DESC, e.name;
```

**Result**

```
+-------------------+---------------------------+-----------------+---------+---------------------------+
| hotel             | staff                     | position        | shift   | supervisor                |
+-------------------+---------------------------+-----------------+---------+---------------------------+
| Can Tho Mekong    | Manager Can Tho Mekong    | General Manager | DAY     | NULL                      |
| Can Tho Mekong    | Staff 14 Thu              | Room Attendant  | NIGHT   | Manager Can Tho Mekong    |
| Da Lat Pine Hill  | Manager Da Lat Pine Hill  | General Manager | DAY     | NULL                      |
| Da Lat Pine Hill  | Staff 10 Linh             | Room Attendant  | EVENING | Manager Da Lat Pine Hill  |
| Da Nang Bay View  | Manager Da Nang Bay View  | General Manager | DAY     | NULL                      |
| Da Nang Bay View  | Staff 06 Tuan             | Room Attendant  | DAY     | Manager Da Nang Bay View  |
| Da Nang Beach     | Manager Da Nang Beach     | General Manager | DAY     | NULL                      |
| Da Nang Beach     | Staff 05 Linh             | Receptionist    | NIGHT   | Manager Da Nang Beach     |
| Hanoi Old Quarter | Manager Hanoi Old Quarter | General Manager | DAY     | NULL                      |
| Hanoi Old Quarter | Staff 03 Nam              | Receptionist    | DAY     | Manager Hanoi Old Quarter |
| Hanoi West Lake   | Manager Hanoi West Lake   | General Manager | DAY     | NULL                      |
| Hanoi West Lake   | Staff 04 Thu              | Room Attendant  | EVENING | Manager Hanoi West Lake   |
| Hoi An Heritage   | Manager Hoi An Heritage   | General Manager | DAY     | NULL                      |
| Hoi An Heritage   | Staff 07 Hoa              | Receptionist    | EVENING | Manager Hoi An Heritage   |
| Hue Imperial      | Manager Hue Imperial      | General Manager | DAY     | NULL                      |
| Hue Imperial      | Staff 11 Tuan             | Receptionist    | NIGHT   | Manager Hue Imperial      |
| Nha Trang Island  | Manager Nha Trang Island  | General Manager | DAY     | NULL                      |
| Nha Trang Island  | Staff 09 Thu              | Receptionist    | DAY     | Manager Nha Trang Island  |
| Nha Trang Seaside | Manager Nha Trang Seaside | General Manager | DAY     | NULL                      |
... (12 more lines, truncated here)
```

## Q13 – [rate depends on room type AND date] What is the nightly price of every room type

> on one given date?  (Tet season by default.)

```sql
SELECT rt.name AS room_type, rp.season_name, rp.price AS nightly_price,
       rt.base_price, ROUND(100 * rp.price / rt.base_price - 100, 0) AS pct_vs_base
FROM   room_type rt
JOIN   rate_plan rp ON rp.type_id = rt.type_id
WHERE  @on_date BETWEEN rp.start_date AND rp.end_date
ORDER BY rp.price DESC;
```

**Result**

```
+--------------------+-------------+---------------+------------+-------------+
| room_type          | season_name | nightly_price | base_price | pct_vs_base |
+--------------------+-------------+---------------+------------+-------------+
| Presidential Suite | Tet peak    |    9600000.00 | 6000000.00 |          60 |
| Villa              | Tet peak    |    8000000.00 | 5000000.00 |          60 |
| Executive Suite    | Tet peak    |    4480000.00 | 2800000.00 |          60 |
| Junior Suite       | Tet peak    |    3200000.00 | 2000000.00 |          60 |
| Family Room        | Tet peak    |    2560000.00 | 1600000.00 |          60 |
| Deluxe Ocean View  | Tet peak    |    2240000.00 | 1400000.00 |          60 |
| Studio Apartment   | Tet peak    |    2080000.00 | 1300000.00 |          60 |
| Deluxe Twin        | Tet peak    |    1840000.00 | 1150000.00 |          60 |
| Deluxe Double      | Tet peak    |    1760000.00 | 1100000.00 |          60 |
| Triple Room        | Tet peak    |    1600000.00 | 1000000.00 |          60 |
| Superior Twin      | Tet peak    |    1472000.00 |  920000.00 |          60 |
| Superior Double    | Tet peak    |    1440000.00 |  900000.00 |          60 |
| Standard Twin      | Tet peak    |    1248000.00 |  780000.00 |          60 |
| Standard Double    | Tet peak    |    1200000.00 |  750000.00 |          60 |
| Standard Single    | Tet peak    |     960000.00 |  600000.00 |          60 |
+--------------------+-------------+---------------+------------+-------------+
```

## Q14 – [report screen: aggregate per month] Money actually received per month and per

> hotel, by payment method.

```sql
SELECT DATE_FORMAT(p.paid_date, '%Y-%m') AS month, h.name AS hotel, p.method,
       COUNT(*) AS payments, SUM(p.amount) AS amount_received
FROM   payment p
JOIN   invoice i ON i.invoice_id = p.invoice_id
JOIN   stay st   ON st.stay_id = i.stay_id
JOIN   hotel h   ON h.hotel_id = st.hotel_id
WHERE  p.paid_date >= MAKEDATE(@year, 1)
  AND  p.paid_date <  MAKEDATE(@year + 1, 1)
GROUP BY DATE_FORMAT(p.paid_date, '%Y-%m'), h.hotel_id, h.name, p.method
ORDER BY month, hotel, p.method;
```

**Result**

```
+---------+-------------------+----------+----------+-----------------+
| month   | hotel             | method   | payments | amount_received |
+---------+-------------------+----------+----------+-----------------+
| 2026-01 | Da Lat Pine Hill  | TRANSFER |        1 |      3221000.00 |
| 2026-01 | Hanoi Old Quarter | CASH     |        1 |      2456000.00 |
| 2026-01 | Hue Imperial      | CARD     |        1 |      6545000.00 |
| 2026-01 | Nha Trang Seaside | TRANSFER |        1 |     15410000.00 |
| 2026-01 | Saigon Central    | CARD     |        5 |      6890000.00 |
| 2026-01 | Saigon Central    | CASH     |        7 |     27730000.00 |
| 2026-01 | Saigon Central    | EWALLET  |        3 |     12944000.00 |
| 2026-01 | Saigon Central    | TRANSFER |        6 |     33261000.00 |
| 2026-01 | Saigon Riverside  | CARD     |        1 |      5244000.00 |
| 2026-01 | Saigon Riverside  | CASH     |        5 |     42228000.00 |
| 2026-01 | Saigon Riverside  | EWALLET  |        1 |      6330000.00 |
| 2026-01 | Saigon Riverside  | TRANSFER |        5 |     17412000.00 |
| 2026-02 | Hanoi Old Quarter | CARD     |        1 |      3055000.00 |
| 2026-02 | Nha Trang Island  | CARD     |        1 |      3135000.00 |
| 2026-02 | Phu Quoc Resort   | TRANSFER |        1 |      4075000.00 |
| 2026-02 | Saigon Central    | CARD     |        2 |      3778000.00 |
| 2026-02 | Saigon Central    | CASH     |        2 |     12342000.00 |
| 2026-02 | Saigon Central    | EWALLET  |        4 |     19576000.00 |
| 2026-02 | Saigon Central    | TRANSFER |        6 |     27650000.00 |
... (122 more lines, truncated here)
```
