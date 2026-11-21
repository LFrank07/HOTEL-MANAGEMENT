package hotel.model;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class HotelAppDAO {

    private volatile boolean schemaColumnsChecked = false;

    public static class RoomOption {
        public final int hotelId;
        public final String hotelName;
        public final String roomNumber;
        public final int floorNumber;
        public final int typeId;
        public final String roomTypeName;
        public final int capacity;
        public final BigDecimal roomTypeBasePrice;
        public final BigDecimal customRoomPrice;
        public final BigDecimal effectivePrice;
        public final String roomStatus;

        public RoomOption(int hotelId, String hotelName, String roomNumber, int floorNumber,
                          int typeId, String roomTypeName, int capacity,
                          BigDecimal roomTypeBasePrice, BigDecimal customRoomPrice, String roomStatus) {
            this.hotelId = hotelId;
            this.hotelName = hotelName;
            this.roomNumber = roomNumber;
            this.floorNumber = floorNumber;
            this.typeId = typeId;
            this.roomTypeName = roomTypeName;
            this.capacity = capacity;
            this.roomTypeBasePrice = roomTypeBasePrice;
            this.customRoomPrice = customRoomPrice;
            this.effectivePrice = (customRoomPrice != null) ? customRoomPrice : roomTypeBasePrice;
            this.roomStatus = roomStatus;
        }
    }

    public static class GuestSummary {
        public final int guestId;
        public final String docId;
        public final String name;
        public final String phone;

        public GuestSummary(int guestId, String docId, String name, String phone) {
            this.guestId = guestId;
            this.docId = docId;
            this.name = name;
            this.phone = phone;
        }
    }

    public static class CheckoutAlertRoom {
        public final int hotelId;
        public final String hotelName;
        public final String roomNumber;
        public final int stayId;
        public final int reservationId;
        public final String guestName;
        public final Date checkInDate;
        public final Date expectedEndDate;
        public final String alertStatus;

        public CheckoutAlertRoom(int hotelId, String hotelName, String roomNumber, int stayId,
                                 int reservationId, String guestName, Date checkInDate,
                                 Date expectedEndDate, String alertStatus) {
            this.hotelId = hotelId;
            this.hotelName = hotelName;
            this.roomNumber = roomNumber;
            this.stayId = stayId;
            this.reservationId = reservationId;
            this.guestName = guestName;
            this.checkInDate = checkInDate;
            this.expectedEndDate = expectedEndDate;
            this.alertStatus = alertStatus;
        }
    }

    public static String formatDotMoney(BigDecimal amount) {
        if (amount == null) return "0";
        BigDecimal normalized = amount.stripTrailingZeros();
        if (normalized.scale() < 0) {
            normalized = normalized.setScale(0);
        }
        DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.US);
        symbols.setGroupingSeparator('.');
        symbols.setDecimalSeparator(',');
        DecimalFormat df = new DecimalFormat("#,##0.##", symbols);
        return df.format(normalized);
    }

    public static BigDecimal parseDotMoney(String raw) {
        if (raw == null) return null;
        String cleaned = raw.trim().replace(".", "").replace(" ", "").replace(",", ".");
        if (cleaned.isEmpty()) return null;
        return new BigDecimal(cleaned);
    }

    public void ensureExtendedColumns(Connection conn) throws SQLException {
        if (schemaColumnsChecked) return;
        synchronized (this) {
            if (schemaColumnsChecked) return;
            if (!columnExists(conn, "Room", "RoomPrice")) {
                try (Statement st = conn.createStatement()) {
                    st.executeUpdate("ALTER TABLE Room ADD COLUMN RoomPrice DECIMAL(12,2) NULL");
                }
            }
            if (!columnExists(conn, "RoomType", "Hotel_ID")) {
                try (Statement st = conn.createStatement()) {
                    st.executeUpdate("ALTER TABLE RoomType ADD COLUMN Hotel_ID INT NULL");
                }
            }
            schemaColumnsChecked = true;
        }
    }

    private boolean columnExists(Connection conn, String tableName, String columnName) throws SQLException {
        String sql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tableName);
            ps.setString(2, columnName);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private int nextId(Connection conn, String table, String idColumn) throws SQLException {
        String sql = "SELECT COALESCE(MAX(" + idColumn + "), 0) + 1 FROM " + table;
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            if (rs.next()) {
                return rs.getInt(1);
            }
        }
        return 1;
    }

    public Map<Integer, String> getHotels() throws SQLException {
        Map<Integer, String> map = new LinkedHashMap<>();
        String sql = "SELECT Hotel_ID, Name, Address FROM Hotels ORDER BY Hotel_ID";
        try (Connection conn = DatabaseConnection.getConnection();
             Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                int id = rs.getInt("Hotel_ID");
                String name = rs.getString("Name") != null ? rs.getString("Name").trim() : "";
                String addr = rs.getString("Address") != null ? rs.getString("Address").trim() : "";
                map.put(id, id + " - " + name + (addr.isEmpty() ? "" : " (" + addr + ")"));
            }
        }
        return map;
    }

    public void ensureDefaultRoomTypes() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            try (Statement st = conn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM RoomType")) {
                if (rs.next() && rs.getInt(1) == 0) {
                    String sql = "INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity, Hotel_ID) VALUES " +
                            "(1, 'Standard Single', 500000.00, 1, NULL), " +
                            "(2, 'Standard Double', 800000.00, 2, NULL), " +
                            "(3, 'Superior Twin',   1100000.00, 2, NULL), " +
                            "(4, 'Deluxe Family',   1600000.00, 4, NULL), " +
                            "(5, 'Executive Suite', 2500000.00, 5, NULL)";
                    st.executeUpdate(sql);
                }
            }
        }
    }

    // Chi lay cac loai phong chung (Hotel_ID IS NULL) + loai phong rieng cua hotelId
    public Map<Integer, String> getRoomTypesForHotel(Integer hotelId) throws SQLException {
        ensureDefaultRoomTypes();
        Map<Integer, String> map = new LinkedHashMap<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            if (hotelId == null) {
                String sql = "SELECT TypeID, Name, Capacity, BasePrice, Hotel_ID FROM RoomType " +
                        "WHERE Hotel_ID IS NULL ORDER BY TypeID";
                try (Statement st = conn.createStatement();
                     ResultSet rs = st.executeQuery(sql)) {
                    while (rs.next()) {
                        int id = rs.getInt("TypeID");
                        String name = rs.getString("Name") != null ? rs.getString("Name").trim() : "";
                        int cap = rs.getInt("Capacity");
                        BigDecimal price = rs.getBigDecimal("BasePrice");
                        map.put(id, name + " (Max " + cap + " | " + formatDotMoney(price) + ")");
                    }
                }
            } else {
                String sql = "SELECT TypeID, Name, Capacity, BasePrice, Hotel_ID FROM RoomType " +
                        "WHERE Hotel_ID IS NULL OR Hotel_ID = ? " +
                        "ORDER BY CASE WHEN Hotel_ID IS NULL THEN 0 ELSE 1 END, TypeID";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, hotelId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            int id = rs.getInt("TypeID");
                            String name = rs.getString("Name") != null ? rs.getString("Name").trim() : "";
                            int cap = rs.getInt("Capacity");
                            BigDecimal price = rs.getBigDecimal("BasePrice");
                            boolean isExtra = rs.getObject("Hotel_ID") != null;
                            String tag = isExtra ? " [Extra]" : "";
                            map.put(id, name + tag + " (Max " + cap + " | " + formatDotMoney(price) + ")");
                        }
                    }
                }
            }
        }
        return map;
    }

    public int addRoomType(String name, BigDecimal basePrice, int capacity, Integer hotelId) throws SQLException {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Room Type name cannot be empty.");
        }
        if (capacity < 1 || capacity > 5) {
            throw new IllegalArgumentException("Capacity must be between 1 and 5.");
        }
        if (basePrice == null || basePrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Base price cannot be negative.");
        }
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            int nextId = nextId(conn, "RoomType", "TypeID");
            String sql = "INSERT INTO RoomType (TypeID, Name, BasePrice, Capacity, Hotel_ID) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, nextId);
                ps.setString(2, name.trim());
                ps.setBigDecimal(3, basePrice);
                ps.setInt(4, capacity);
                if (hotelId != null) {
                    ps.setInt(5, hotelId);
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }
                ps.executeUpdate();
                return nextId;
            }
        }
    }

    public int addHotel(String name, String address) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            int nextId = nextId(conn, "Hotels", "Hotel_ID");
            String sql = "INSERT INTO Hotels (Hotel_ID, Name, Address) VALUES (?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, nextId);
                ps.setString(2, name.trim());
                ps.setString(3, address.trim());
                ps.executeUpdate();
                return nextId;
            }
        }
    }

    public int addRoomsByPattern(int hotelId, int floorNumber, String roomsPattern, int typeId,
                                 String status, BigDecimal customRoomPrice) throws SQLException {
        List<String> roomNumbers = parseRoomPattern(roomsPattern);
        if (roomNumbers.isEmpty()) {
            throw new IllegalArgumentException("Please enter valid room numbers (e.g. 101-105 or 101, 102, 104).");
        }
        if (customRoomPrice != null && customRoomPrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Room price cannot be negative.");
        }

        String sql = "INSERT IGNORE INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID, RoomPrice) " +
                "VALUES (?, ?, ?, ?, ?, ?)";
        int count = 0;
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (String num : roomNumbers) {
                    ps.setInt(1, hotelId);
                    ps.setString(2, num);
                    ps.setString(3, status);
                    ps.setInt(4, floorNumber);
                    ps.setInt(5, typeId);
                    if (customRoomPrice != null) {
                        ps.setBigDecimal(6, customRoomPrice);
                    } else {
                        ps.setNull(6, java.sql.Types.DECIMAL);
                    }
                    count += ps.executeUpdate();
                }
            }
        }
        return count;
    }

    public int generateRoomsForHotel(int hotelId, int totalFloors, int roomsPerFloor) throws SQLException {
        ensureDefaultRoomTypes();
        List<Integer> typeIds = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT TypeID FROM RoomType WHERE Hotel_ID IS NULL OR Hotel_ID = ? ORDER BY TypeID")) {
                ps.setInt(1, hotelId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        typeIds.add(rs.getInt("TypeID"));
                    }
                }
            }
            if (typeIds.isEmpty()) {
                throw new SQLException("RoomType is empty.");
            }

            String sql = "INSERT IGNORE INTO Room (Hotel_ID, Room_Number, RoomStatus, FloorNumber, TypeID, RoomPrice) " +
                    "VALUES (?, ?, 'Available', ?, ?, NULL)";
            int insertedCount = 0;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (int floor = 1; floor <= totalFloors; floor++) {
                    for (int idx = 1; idx <= roomsPerFloor; idx++) {
                        String roomNumber = String.format("%d%02d", floor, idx);
                        int typeIndex = ((idx - 1) * typeIds.size()) / roomsPerFloor;
                        int typeId = typeIds.get(typeIndex);

                        ps.setInt(1, hotelId);
                        ps.setString(2, roomNumber);
                        ps.setInt(3, floor);
                        ps.setInt(4, typeId);
                        insertedCount += ps.executeUpdate();
                    }
                }
            }
            return insertedCount;
        }
    }

    public void updateRoom(int hotelId, String oldRoomNumber, String newRoomNumber,
                           int floorNumber, int newTypeId, String roomStatus, BigDecimal customRoomPrice) throws SQLException {
        if (customRoomPrice != null && customRoomPrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Room price cannot be negative.");
        }
        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);

            // Lay TypeID hien tai cua phong
            Integer currentTypeId = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT TypeID FROM Room WHERE Hotel_ID = ? AND Room_Number = ?")) {
                ps.setInt(1, hotelId);
                ps.setString(2, oldRoomNumber.trim());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentTypeId = rs.getInt("TypeID");
                    }
                }
            }
            if (currentTypeId == null) {
                throw new SQLException("Room '" + oldRoomNumber.trim() + "' not found in Hotel #" + hotelId + ".");
            }

            // Chan doi loai phong neu phong da co ban ghi Stays (tranh pha rang buoc R19/R20)
            if (currentTypeId != newTypeId) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM Stays WHERE Hotel_ID = ? AND Room_Number = ?")) {
                    ps.setInt(1, hotelId);
                    ps.setString(2, oldRoomNumber.trim());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0) {
                            throw new SQLException("Cannot change Room Type because this room already has Stay history. You can still update its price, floor, or status.");
                        }
                    }
                }
            }

            String sql = "UPDATE Room SET Room_Number = ?, FloorNumber = ?, TypeID = ?, RoomStatus = ?, RoomPrice = ? " +
                    "WHERE Hotel_ID = ? AND Room_Number = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, newRoomNumber.trim());
                ps.setInt(2, floorNumber);
                ps.setInt(3, newTypeId);
                ps.setString(4, roomStatus);
                if (customRoomPrice != null) {
                    ps.setBigDecimal(5, customRoomPrice);
                } else {
                    ps.setNull(5, java.sql.Types.DECIMAL);
                }
                ps.setInt(6, hotelId);
                ps.setString(7, oldRoomNumber.trim());
                ps.executeUpdate();
            }
        }
    }

    // Tinh don gia cho 1 dem cu the: RatePlan/HasRate (neu co) > Room.RoomPrice (neu co) > RoomType.BasePrice
    public BigDecimal resolveNightlyRate(Connection conn, int typeId, LocalDate nightDate,
                                         BigDecimal customRoomPrice, BigDecimal basePrice) throws SQLException {
        String sql = "SELECT hr.Price " +
                "FROM HasRate hr " +
                "JOIN RatePlan rp ON hr.RatePlan_ID = rp.RatePlan_ID " +
                "WHERE hr.TypeID = ? " +
                "  AND ? BETWEEN DATE(rp.StartDate) AND DATE(rp.EndDate) " +
                "LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, typeId);
            ps.setDate(2, Date.valueOf(nightDate));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getBigDecimal("Price");
                }
            }
        }
        return (customRoomPrice != null) ? customRoomPrice : basePrice;
    }

    private List<String> parseRoomPattern(String pattern) {
        List<String> result = new ArrayList<>();
        if (pattern == null || pattern.trim().isEmpty()) {
            return result;
        }
        for (String part : pattern.split(",")) {
            String token = part.trim();
            if (token.isEmpty()) continue;

            if (token.contains("-")) {
                String[] bounds = token.split("-");
                if (bounds.length == 2) {
                    try {
                        int start = Integer.parseInt(bounds[0].trim());
                        int end = Integer.parseInt(bounds[1].trim());
                        for (int i = Math.min(start, end); i <= Math.max(start, end); i++) {
                            result.add(String.valueOf(i));
                        }
                        continue;
                    } catch (NumberFormatException ignored) {
                    }
                }
            }
            result.add(token);
        }
        return result;
    }

    public List<RoomOption> searchRoomsByHotel(String hotelKeyword, LocalDate checkIn, LocalDate checkOut,
                                                 boolean onlyAvailable) throws SQLException {
        List<RoomOption> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT h.Hotel_ID, h.Name AS HotelName, rm.Room_Number, rm.FloorNumber, " +
                        "rt.TypeID, rt.Name AS RoomTypeName, rt.Capacity, rt.BasePrice, rm.RoomPrice, rm.RoomStatus " +
                        "FROM Room rm " +
                        "JOIN Hotels h ON rm.Hotel_ID = h.Hotel_ID " +
                        "JOIN RoomType rt ON rm.TypeID = rt.TypeID " +
                        "WHERE LOWER(h.Name) LIKE LOWER(?) ");

        if (onlyAvailable) {
            sql.append("AND rm.RoomStatus = 'Available' ");
        }

        if (checkIn != null && checkOut != null) {
            sql.append("AND NOT EXISTS ( " +
                    "  SELECT 1 FROM Stays s " +
                    "  JOIN Reservation r ON s.Reservation_ID = r.Reservation_ID " +
                    "  WHERE s.Hotel_ID = rm.Hotel_ID " +
                    "    AND s.Room_Number = rm.Room_Number " +
                    "    AND s.Checkout IS NULL " +
                    "    AND r.BookingStatus NOT IN ('Cancelled', 'NoShow') " +
                    "    AND r.StartDate <= ? AND r.EndDate >= ? " +
                    ") ");
        }

        sql.append("ORDER BY h.Hotel_ID, rm.FloorNumber, rm.Room_Number");

        try (Connection conn = DatabaseConnection.getConnection()) {
            ensureExtendedColumns(conn);
            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                int idx = 1;
                String kw = (hotelKeyword == null ? "" : hotelKeyword.trim());
                ps.setString(idx++, "%" + kw + "%");
                if (checkIn != null && checkOut != null) {
                    ps.setDate(idx++, Date.valueOf(checkOut));
                    ps.setDate(idx++, Date.valueOf(checkIn));
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new RoomOption(
                                rs.getInt("Hotel_ID"),
                                rs.getString("HotelName") != null ? rs.getString("HotelName").trim() : "",
                                rs.getString("Room_Number"),
                                rs.getInt("FloorNumber"),
                                rs.getInt("TypeID"),
                                rs.getString("RoomTypeName") != null ? rs.getString("RoomTypeName").trim() : "",
                                rs.getInt("Capacity"),
                                rs.getBigDecimal("BasePrice"),
                                rs.getBigDecimal("RoomPrice"),
                                rs.getString("RoomStatus")
                        ));
                    }
                }
            }
        }
        return list;
    }

    public List<CheckoutAlertRoom> getRoomsDueOrOverdueCheckout(String hotelKeyword) throws SQLException {
        List<CheckoutAlertRoom> list = new ArrayList<>();
        String sql = "SELECT h.Hotel_ID, h.Name AS HotelName, s.Room_Number, s.StayID, " +
                "r.Reservation_ID, COALESCE(g.Name, 'Walk-in / Unlinked') AS GuestName, " +
                "DATE(s.CheckIn) AS CheckInDate, r.EndDate, " +
                "CASE WHEN r.EndDate < CURRENT_DATE() THEN 'OVERDUE' ELSE 'DUE_TODAY' END AS AlertStatus " +
                "FROM Stays s " +
                "JOIN Reservation r ON s.Reservation_ID = r.Reservation_ID " +
                "JOIN Hotels h ON s.Hotel_ID = h.Hotel_ID " +
                "LEFT JOIN Guests g ON r.Guest_ID = g.Guest_ID " +
                "WHERE s.Checkout IS NULL " +
                "  AND r.EndDate <= CURRENT_DATE() " +
                "  AND LOWER(h.Name) LIKE LOWER(?) " +
                "ORDER BY r.EndDate ASC, s.Room_Number ASC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + (hotelKeyword == null ? "" : hotelKeyword.trim()) + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new CheckoutAlertRoom(
                            rs.getInt("Hotel_ID"),
                            rs.getString("HotelName") != null ? rs.getString("HotelName").trim() : "",
                            rs.getString("Room_Number"),
                            rs.getInt("StayID"),
                            rs.getInt("Reservation_ID"),
                            rs.getString("GuestName"),
                            rs.getDate("CheckInDate"),
                            rs.getDate("EndDate"),
                            rs.getString("AlertStatus")
                    ));
                }
            }
        }
        return list;
    }

    public int createReservation(int hotelId, int typeId, LocalDate startDate, LocalDate endDate,
                                 int noOfGuests, String docId, String guestName, String phone) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                int guestId = -1;
                String cleanDocId = docId == null ? "" : docId.trim();
                String cleanPhone = phone == null ? "" : phone.trim();

                if (!cleanDocId.isEmpty()) {
                    try (PreparedStatement ps = conn.prepareStatement("SELECT Guest_ID FROM Guests WHERE Doc_ID = ? LIMIT 1")) {
                        ps.setString(1, cleanDocId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) guestId = rs.getInt("Guest_ID");
                        }
                    }
                }
                if (guestId == -1 && !cleanPhone.isEmpty()) {
                    try (PreparedStatement ps = conn.prepareStatement("SELECT Guest_ID FROM Guests_Phone WHERE Phone = ? LIMIT 1")) {
                        ps.setString(1, cleanPhone);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) guestId = rs.getInt("Guest_ID");
                        }
                    }
                }
                if (guestId == -1) {
                    try (PreparedStatement ps = conn.prepareStatement("SELECT Guest_ID FROM Guests WHERE Name = ? LIMIT 1")) {
                        ps.setString(1, guestName.trim());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) guestId = rs.getInt("Guest_ID");
                        }
                    }
                }

                if (guestId == -1) {
                    guestId = nextId(conn, "Guests", "Guest_ID");
                    String finalDocId = cleanDocId.isEmpty()
                            ? ("G" + guestId + "_" + (System.currentTimeMillis() % 100000))
                            : cleanDocId;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO Guests (Guest_ID, Doc_ID, Name) VALUES (?, ?, ?)")) {
                        ps.setInt(1, guestId);
                        ps.setString(2, finalDocId);
                        ps.setString(3, guestName.trim());
                        ps.executeUpdate();
                    }
                }

                if (!cleanPhone.isEmpty()) {
                    Integer ownerId = null;
                    try (PreparedStatement ps = conn.prepareStatement("SELECT Guest_ID FROM Guests_Phone WHERE Phone = ?")) {
                        ps.setString(1, cleanPhone);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) ownerId = rs.getInt("Guest_ID");
                        }
                    }
                    if (ownerId == null) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO Guests_Phone (Phone, Guest_ID) VALUES (?, ?)")) {
                            ps.setString(1, cleanPhone);
                            ps.setInt(2, guestId);
                            ps.executeUpdate();
                        }
                    } else if (ownerId != guestId) {
                        throw new SQLException("Phone number '" + cleanPhone + "' already belongs to another guest.");
                    }
                }

                int resId = nextId(conn, "Reservation", "Reservation_ID");
                String insertRes = "INSERT INTO Reservation " +
                        "(Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID) " +
                        "VALUES (?, ?, ?, 'Confirmed', ?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertRes)) {
                    ps.setInt(1, resId);
                    ps.setDate(2, Date.valueOf(startDate));
                    ps.setDate(3, Date.valueOf(endDate));
                    ps.setInt(4, noOfGuests);
                    ps.setInt(5, guestId);
                    ps.setInt(6, typeId);
                    ps.setInt(7, hotelId);
                    ps.executeUpdate();
                }

                conn.commit();
                return resId;
            } catch (Exception ex) {
                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                }
            }
        }
    }

    public List<GuestSummary> searchGuests(String keyword) throws SQLException {
        List<GuestSummary> list = new ArrayList<>();
        String kw = "%" + (keyword == null ? "" : keyword.trim()) + "%";
        String sql = "SELECT g.Guest_ID, g.Doc_ID, g.Name, COALESCE(MIN(gp.Phone), '') AS Phone " +
                "FROM Guests g " +
                "LEFT JOIN Guests_Phone gp ON g.Guest_ID = gp.Guest_ID " +
                "WHERE LOWER(g.Name) LIKE LOWER(?) " +
                "   OR LOWER(g.Doc_ID) LIKE LOWER(?) " +
                "   OR COALESCE(gp.Phone, '') LIKE ? " +
                "GROUP BY g.Guest_ID, g.Doc_ID, g.Name " +
                "ORDER BY g.Guest_ID";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, kw);
            ps.setString(2, kw);
            ps.setString(3, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new GuestSummary(
                            rs.getInt("Guest_ID"),
                            rs.getString("Doc_ID"),
                            rs.getString("Name"),
                            rs.getString("Phone")
                    ));
                }
            }
        }
        return list;
    }

    public void deleteHotel(int hotelId) throws SQLException {
    try (Connection conn = DatabaseConnection.getConnection()) {
        ensureExtendedColumns(conn);
        conn.setAutoCommit(false);
        try {
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM RoomType WHERE Hotel_ID = ?")) {
                ps.setInt(1, hotelId);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Room WHERE Hotel_ID = ?")) {
                ps.setInt(1, hotelId);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Hotels WHERE Hotel_ID = ?")) {
                ps.setInt(1, hotelId);
                int deleted = ps.executeUpdate();
                if (deleted == 0) {
                    throw new SQLException("Hotel #" + hotelId + " not found.");
                }
            }

            conn.commit();
        } catch (SQLException ex) {
            try {
                conn.rollback();
            } catch (Exception ignored) {
            }
            if (ex.getErrorCode() == 1451) {
                throw new SQLException("Cannot delete this hotel because it still has Staff, Reservations, or Rooms linked to active stays/bookings.");
            }
            throw ex;
        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (Exception ignored) {
            }
        }
    }
}

    public void updateGuest(int guestId, String newDocId, String newName,
                            String oldPhone, String newPhone) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Guests SET Doc_ID = ?, Name = ? WHERE Guest_ID = ?")) {
                    ps.setString(1, newDocId.trim());
                    ps.setString(2, newName.trim());
                    ps.setInt(3, guestId);
                    ps.executeUpdate();
                }

                String cleanOld = oldPhone == null ? "" : oldPhone.trim();
                String cleanNew = newPhone == null ? "" : newPhone.trim();

                if (!cleanNew.equals(cleanOld)) {
                    if (!cleanNew.isEmpty()) {
                        Integer ownerId = null;
                        try (PreparedStatement ps = conn.prepareStatement("SELECT Guest_ID FROM Guests_Phone WHERE Phone = ?")) {
                            ps.setString(1, cleanNew);
                            try (ResultSet rs = ps.executeQuery()) {
                                if (rs.next()) ownerId = rs.getInt("Guest_ID");
                            }
                        }
                        if (ownerId != null && ownerId != guestId) {
                            throw new SQLException("Phone number '" + cleanNew + "' is already used by another guest.");
                        }
                        if (!cleanOld.isEmpty()) {
                            try (PreparedStatement ps = conn.prepareStatement(
                                    "DELETE FROM Guests_Phone WHERE Phone = ? AND Guest_ID = ?")) {
                                ps.setString(1, cleanOld);
                                ps.setInt(2, guestId);
                                ps.executeUpdate();
                            }
                        }
                        if (ownerId == null) {
                            try (PreparedStatement ps = conn.prepareStatement(
                                    "INSERT INTO Guests_Phone (Phone, Guest_ID) VALUES (?, ?)")) {
                                ps.setString(1, cleanNew);
                                ps.setInt(2, guestId);
                                ps.executeUpdate();
                            }
                        }
                    } else if (!cleanOld.isEmpty()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "DELETE FROM Guests_Phone WHERE Phone = ? AND Guest_ID = ?")) {
                            ps.setString(1, cleanOld);
                            ps.setInt(2, guestId);
                            ps.executeUpdate();
                        }
                    }
                }

                conn.commit();
            } catch (Exception ex) {
                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
                if (ex instanceof SQLException) throw (SQLException) ex;
                throw new SQLException(ex.getMessage(), ex);
            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                }
            }
        }
    }
}
