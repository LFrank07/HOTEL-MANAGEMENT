USE Hotel_Management_Group3;

-- Test parameters: change these values to test other hotels and dates.
SET @today    = '2026-11-18';
SET @hotel_id = 1;
SET @from     = '2026-02-14';
SET @to       = '2026-02-17';
SET @stay_id  = 1;
SET @year     = 2026;
SET @on_date  = '2026-02-15';

-- View used by Q2: one row for each invoice line of a stay.
CREATE OR REPLACE VIEW v_stay_bill_lines AS
SELECT
    s.StayID,
    i.Invoice_ID,
    il.LineID,
    il.Type AS LineType,
    il.Description,
    il.Amount
FROM Stays s
JOIN Invoices i
    ON s.Invoice_ID = i.Invoice_ID
JOIN InvoiceLine il
    ON i.Invoice_ID = il.Invoice_ID;


-- Q1. Which rooms are free at one hotel during an inclusive date range?
-- Checkout date is treated as the first day the room is free.
-- Rooms held by Pending or Confirmed reservations (no stay yet) are also subtracted.
WITH inventory AS (
    SELECT
        r.TypeID,
        COUNT(*) AS TotalRooms
    FROM Room r
    WHERE r.Hotel_ID = @hotel_id
      AND r.RoomStatus <> 'Maintenance'
    GROUP BY r.TypeID
),
occupied AS (
    SELECT
        r.TypeID,
        COUNT(DISTINCT s.Room_Number) AS OccupiedRooms
    FROM Stays s
    JOIN Room r
        ON s.Hotel_ID = r.Hotel_ID
       AND s.Room_Number = r.Room_Number
    WHERE s.Hotel_ID = @hotel_id
      AND r.RoomStatus <> 'Maintenance'
      AND s.CheckIn < DATE_ADD(@to, INTERVAL 1 DAY)
      AND (s.Checkout IS NULL
           OR s.Checkout >= DATE_ADD(@from, INTERVAL 1 DAY))
    GROUP BY r.TypeID
),
booked AS (
    -- Reservations that have no stay yet but already hold a room of a type.
    SELECT
        res.TypeID,
        COUNT(*) AS BookedRooms
    FROM Reservation res
    WHERE res.Hotel_ID = @hotel_id
      AND res.BookingStatus IN ('Pending', 'Confirmed')
      AND res.StartDate <= @to
      AND res.EndDate   >  @from
    GROUP BY res.TypeID
)
SELECT
    rt.Name AS RoomType,
    i.TotalRooms,
    COALESCE(o.OccupiedRooms, 0) AS OccupiedRooms,
    COALESCE(b.BookedRooms, 0) AS BookedRooms,
    GREATEST(i.TotalRooms - COALESCE(o.OccupiedRooms, 0)
                          - COALESCE(b.BookedRooms, 0), 0) AS AvailableRooms
FROM inventory i
JOIN RoomType rt
    ON i.TypeID = rt.TypeID
LEFT JOIN occupied o
    ON i.TypeID = o.TypeID
LEFT JOIN booked b
    ON i.TypeID = b.TypeID
ORDER BY rt.TypeID;


-- Q2. Show the bill of one stay, including room and service charges.
SELECT
    StayID,
    Invoice_ID,
    LineID,
    LineType,
    Description,
    Amount
FROM v_stay_bill_lines
WHERE StayID = @stay_id
ORDER BY LineID;

SELECT
    StayID,
    SUM(CASE WHEN LineType = 'Room' THEN Amount ELSE 0 END) AS RoomCharges,
    SUM(CASE WHEN LineType = 'Service' THEN Amount ELSE 0 END) AS ServiceCharges,
    SUM(Amount) AS TotalBill
FROM v_stay_bill_lines
WHERE StayID = @stay_id
GROUP BY StayID;


-- Q3. What is the occupancy rate per month for each hotel?
WITH RECURSIVE months AS (
    SELECT CAST(CONCAT(@year, '-01-01') AS DATE) AS MonthStart
    UNION ALL
    SELECT MonthStart + INTERVAL 1 MONTH
    FROM months
    WHERE MonthStart < CAST(CONCAT(@year, '-12-01') AS DATE)
),
month_periods AS (
    SELECT
        MonthStart,
        LEAST(MonthStart + INTERVAL 1 MONTH, DATE_ADD(@today, INTERVAL 1 DAY)) AS PeriodEnd
    FROM months
),
hotel_rooms AS (
    SELECT Hotel_ID, COUNT(*) AS TotalRooms
    FROM Room
    GROUP BY Hotel_ID
)
SELECT
    h.Name AS Hotel,
    DATE_FORMAT(m.MonthStart, '%Y-%m') AS Month,
    COALESCE(SUM(
        GREATEST(0, DATEDIFF(
            LEAST(COALESCE(DATE(s.Checkout), DATE_ADD(@today, INTERVAL 1 DAY)), m.PeriodEnd),
            GREATEST(DATE(s.CheckIn), m.MonthStart)
        ))
    ), 0) AS OccupiedNights,
    COALESCE(hr.TotalRooms, 0) * DATEDIFF(m.PeriodEnd, m.MonthStart) AS AvailableNights,
    ROUND(
        100 * COALESCE(SUM(
            GREATEST(0, DATEDIFF(
                LEAST(COALESCE(DATE(s.Checkout), DATE_ADD(@today, INTERVAL 1 DAY)), m.PeriodEnd),
                GREATEST(DATE(s.CheckIn), m.MonthStart)
            ))
        ), 0)
        / NULLIF(COALESCE(hr.TotalRooms, 0) * DATEDIFF(m.PeriodEnd, m.MonthStart), 0),
        1
    ) AS OccupancyRate
FROM month_periods m
CROSS JOIN Hotels h
LEFT JOIN hotel_rooms hr
    ON h.Hotel_ID = hr.Hotel_ID
LEFT JOIN Stays s
    ON h.Hotel_ID = s.Hotel_ID
   AND s.CheckIn < m.PeriodEnd
   AND (s.Checkout IS NULL OR s.Checkout >= DATE_ADD(m.MonthStart, INTERVAL 1 DAY))
WHERE m.MonthStart <= @today
GROUP BY h.Hotel_ID, h.Name, hr.TotalRooms, m.MonthStart, m.PeriodEnd
ORDER BY h.Name, m.MonthStart;


-- Q4. Which guests have stayed at every hotel in the group?
-- Double NOT EXISTS expresses the relational-division condition.
SELECT
    g.Guest_ID,
    g.Name
FROM Guests g
WHERE NOT EXISTS (
    SELECT 1
    FROM Hotels h
    WHERE NOT EXISTS (
        SELECT 1
        FROM Stays s
        JOIN Reservation res
            ON s.Reservation_ID = res.Reservation_ID
        WHERE res.Guest_ID = g.Guest_ID
          AND s.Hotel_ID = h.Hotel_ID
    )
)
ORDER BY g.Guest_ID;


-- Q5. Which service earns the most revenue per occupied room?
-- One StayID represents one room occupied during that stay.
-- Revenue per occupied room = service revenue / number of stays that used the service.
WITH service_revenue AS (
    SELECT
        sv.ServiceID,
        sv.ServiceType,
        SUM(rec.Price * rec.Quantity) AS TotalRevenue,
        COUNT(DISTINCT rec.StayID) AS OccupiedRooms
    FROM Records rec
    JOIN Services sv
        ON rec.ServiceID = sv.ServiceID
    GROUP BY sv.ServiceID, sv.ServiceType
),
service_result AS (
    SELECT
        ServiceID,
        ServiceType,
        TotalRevenue,
        OccupiedRooms,
        TotalRevenue / NULLIF(OccupiedRooms, 0) AS RevenuePerOccupiedRoom
    FROM service_revenue
)
SELECT
    ServiceType,
    TotalRevenue,
    OccupiedRooms,
    ROUND(RevenuePerOccupiedRoom, 0) AS RevenuePerOccupiedRoom
FROM service_result
WHERE RevenuePerOccupiedRoom = (
    SELECT MAX(RevenuePerOccupiedRoom)
    FROM service_result
)
ORDER BY ServiceType;


-- Q6. Show completed stays with the guest, hotel and room types.
SELECT
    s.StayID,
    g.Name AS GuestName,
    h.Name AS HotelName,
    requested.Name AS RequestedRoomType,
    s.Room_Number,
    assigned.Name AS AssignedRoomType,
    s.CheckIn,
    s.Checkout
FROM Stays s
JOIN Reservation res
    ON s.Reservation_ID = res.Reservation_ID
LEFT JOIN Guests g
    ON res.Guest_ID = g.Guest_ID
JOIN Hotels h
    ON s.Hotel_ID = h.Hotel_ID
JOIN Room r
    ON s.Hotel_ID = r.Hotel_ID
   AND s.Room_Number = r.Room_Number
JOIN RoomType assigned
    ON r.TypeID = assigned.TypeID
JOIN RoomType requested
    ON res.TypeID = requested.TypeID
WHERE s.Checkout IS NOT NULL
ORDER BY s.CheckIn;


-- Q7. Which rooms have never been used for a stay?
SELECT
    h.Name AS HotelName,
    r.Room_Number,
    rt.Name AS RoomType,
    r.RoomStatus
FROM Room r
JOIN Hotels h
    ON r.Hotel_ID = h.Hotel_ID
JOIN RoomType rt
    ON r.TypeID = rt.TypeID
LEFT JOIN Stays s
    ON r.Hotel_ID = s.Hotel_ID
   AND r.Room_Number = s.Room_Number
WHERE s.StayID IS NULL
ORDER BY h.Name, r.Room_Number;


-- Q8. Which hotels earned more than 8,000,000 VND from services?
SELECT
    h.Name AS HotelName,
    COUNT(*) AS ConsumptionLines,
    SUM(rec.Price * rec.Quantity) AS ServiceRevenue,
    ROUND(AVG(rec.Price * rec.Quantity), 0) AS AverageLineValue
FROM Records rec
JOIN Stays s
    ON rec.StayID = s.StayID
JOIN Hotels h
    ON s.Hotel_ID = h.Hotel_ID
GROUP BY h.Hotel_ID, h.Name
HAVING SUM(rec.Price * rec.Quantity) > 8000000
ORDER BY ServiceRevenue DESC;


-- Q9. Which guests have used the laundry service?
SELECT
    g.Guest_ID,
    g.Name
FROM Guests g
WHERE g.Guest_ID IN (
    SELECT res.Guest_ID
    FROM Reservation res
    JOIN Stays s
        ON res.Reservation_ID = s.Reservation_ID
    JOIN Records rec
        ON s.StayID = rec.StayID
    JOIN Services sv
        ON rec.ServiceID = sv.ServiceID
    WHERE sv.ServiceType = 'Laundry'
)
ORDER BY g.Name;


-- Q10. Which guests stayed in a Suite room or used the Spa service?
SELECT
    g.Guest_ID,
    g.Name AS GuestName
FROM Guests g
JOIN Reservation res
    ON g.Guest_ID = res.Guest_ID
JOIN Stays s
    ON res.Reservation_ID = s.Reservation_ID
JOIN Room r
    ON s.Hotel_ID = r.Hotel_ID
   AND s.Room_Number = r.Room_Number
JOIN RoomType rt
    ON r.TypeID = rt.TypeID
WHERE rt.Name = 'Suite'

UNION

SELECT
    g.Guest_ID,
    g.Name AS GuestName
FROM Guests g
JOIN Reservation res
    ON g.Guest_ID = res.Guest_ID
JOIN Stays s
    ON res.Reservation_ID = s.Reservation_ID
JOIN Records rec
    ON s.StayID = rec.StayID
JOIN Services sv
    ON rec.ServiceID = sv.ServiceID
WHERE sv.ServiceType = 'Spa'
ORDER BY GuestName;


-- Q11. Which closed invoices still have an unpaid balance?
-- Open invoices (guest still in the hotel) are not counted as debt.
WITH billed AS (
    SELECT Invoice_ID, SUM(Amount) AS TotalBilled
    FROM InvoiceLine
    GROUP BY Invoice_ID
),
paid AS (
    SELECT Invoice_ID, SUM(Amount) AS TotalPaid
    FROM Payment
    GROUP BY Invoice_ID
)
SELECT
    i.Invoice_ID,
    g.Name AS GuestName,
    i.IssueDate,
    i.Status,
    b.TotalBilled,
    COALESCE(p.TotalPaid, 0) AS TotalPaid,
    b.TotalBilled - COALESCE(p.TotalPaid, 0) AS BalanceDue
FROM Invoices i
JOIN Stays s
    ON i.Invoice_ID = s.Invoice_ID
JOIN Reservation res
    ON s.Reservation_ID = res.Reservation_ID
LEFT JOIN Guests g
    ON res.Guest_ID = g.Guest_ID
JOIN billed b
    ON i.Invoice_ID = b.Invoice_ID
LEFT JOIN paid p
    ON i.Invoice_ID = p.Invoice_ID
WHERE i.Status IN ('Unpaid', 'PartiallyPaid')
  AND b.TotalBilled > COALESCE(p.TotalPaid, 0)
ORDER BY BalanceDue DESC;


-- Q12. Show each staff member's hotel, position and supervisor.
SELECT
    h.Name AS HotelName,
    e.Staff_ID,
    e.Name AS StaffName,
    p.BaseRole,
    p.DepartmentFocus,
    p.Level,
    sup.Name AS SupervisorName
FROM Staff e
JOIN Hotels h
    ON e.Hotel_ID = h.Hotel_ID
JOIN Position p
    ON e.Role_ID = p.Role_ID
LEFT JOIN Staff sup
    ON e.Supervisor_ID = sup.Staff_ID
ORDER BY h.Name, p.DepartmentFocus, p.Level, e.Name;


-- Q13. What is the nightly price of each room type on one date?
-- A rate plan that covers the date gives the seasonal price from HasRate.
-- If no rate plan covers the date, the room type's BasePrice is used.
SELECT
    rt.TypeID,
    rt.Name AS RoomType,
    rt.BasePrice,
    seasonal.SeasonName,
    COALESCE(seasonal.Price, rt.BasePrice) AS NightlyPrice
FROM RoomType rt
LEFT JOIN (
    SELECT hr.TypeID, rp.SeasonName, hr.Price
    FROM HasRate hr
    JOIN RatePlan rp
        ON hr.RatePlan_ID = rp.RatePlan_ID
    WHERE @on_date BETWEEN rp.StartDate AND rp.EndDate
) seasonal
    ON rt.TypeID = seasonal.TypeID
ORDER BY rt.TypeID;
