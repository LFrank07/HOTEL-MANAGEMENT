package hotel.model;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
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
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class HotelManagementUI {

    private static class RoomTypeOption {
        final int typeId;
        final String name;
        final int capacity;
        final BigDecimal basePrice;

        RoomTypeOption(int typeId, String name, int capacity, BigDecimal basePrice) {
            this.typeId = typeId;
            this.name = name;
            this.capacity = capacity;
            this.basePrice = basePrice;
        }

        @Override
        public String toString() {
            return name + " (Max: " + capacity + " guests)";
        }
    }

    private final DefaultTableModel tableModel = new DefaultTableModel(
            new Object[]{"Reservation ID", "Guest Name", "Phone", "Room Type",
                    "Room", "Check-in", "Check-out", "Status"}, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };

    private final JTable reservationTable = new JTable(tableModel);

    public HotelManagementUI() {
        createWindow();
        refreshTable();
    }

    private void createWindow() {
        JFrame frame = new JFrame("Hotel Management");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setMinimumSize(new Dimension(1120, 560));
        frame.setLocationRelativeTo(null);

        JPanel root = new JPanel(new BorderLayout(0, 16));
        root.setBorder(BorderFactory.createEmptyBorder(20, 24, 20, 24));
        root.setBackground(new Color(245, 247, 250));

        JLabel title = new JLabel("RESERVATION MANAGEMENT");
        title.setFont(new Font("Sans Serif", Font.BOLD, 22));
        title.setForeground(new Color(29, 48, 71));

        JLabel subtitle = new JLabel("Connected to MySQL Database");
        subtitle.setForeground(new Color(101, 114, 130));

        JPanel heading = new JPanel(new GridLayout(2, 1, 0, 4));
        heading.setOpaque(false);
        heading.add(title);
        heading.add(subtitle);
        root.add(heading, BorderLayout.NORTH);

        reservationTable.setRowHeight(32);
        reservationTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        reservationTable.getTableHeader().setFont(new Font("Sans Serif", Font.BOLD, 12));
        reservationTable.setFillsViewportHeight(true);

        reservationTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                                                           boolean isSelected, boolean hasFocus,
                                                           int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);

                if (!isSelected) {
                    c.setForeground(Color.BLACK);
                }
                c.setFont(table.getFont());

                if (column == 6 && value != null) {
                    try {
                        LocalDate checkOutDate = LocalDate.parse(value.toString());
                        LocalDate today = LocalDate.now();
                        int modelRow = table.convertRowIndexToModel(row);
                        String status = String.valueOf(table.getModel().getValueAt(modelRow, 7));

                        if (!"Cancelled".equalsIgnoreCase(status) && !"CheckedOut".equalsIgnoreCase(status)) {
                            if (!today.isBefore(checkOutDate)) {
                                if (!isSelected) {
                                    c.setForeground(new Color(210, 40, 40));
                                }
                                c.setFont(new Font("Sans Serif", Font.BOLD, 12));
                            }
                        }
                    } catch (Exception ignored) {
                    }
                }
                return c;
            }
        });

        JScrollPane scrollPane = new JScrollPane(reservationTable);
        scrollPane.setBorder(BorderFactory.createLineBorder(new Color(222, 227, 233)));
        root.add(scrollPane, BorderLayout.CENTER);

        JButton checkInButton = createButton("Check-In", new Color(26, 127, 150));
        JButton checkOutButton = createButton("Check-Out", new Color(181, 108, 22));
        JButton paymentButton = createButton("Payment", new Color(92, 68, 156));
        JButton addButton = createButton("+ Add Reservation", new Color(34, 112, 90));
        JButton editButton = createButton("Edit", new Color(54, 91, 135));
        JButton deleteButton = createButton("Delete", new Color(174, 66, 66));

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        actions.setOpaque(false);
        actions.add(checkInButton);
        actions.add(checkOutButton);
        actions.add(paymentButton);
        actions.add(addButton);
        actions.add(editButton);
        actions.add(deleteButton);
        root.add(actions, BorderLayout.SOUTH);

        checkInButton.addActionListener(event -> checkInSelectedReservation());
        checkOutButton.addActionListener(event -> checkOutSelectedReservation());
        paymentButton.addActionListener(event -> recordPaymentForSelectedReservation());
        addButton.addActionListener(event -> showReservationDialog(true));
        editButton.addActionListener(event -> editSelectedReservation());
        deleteButton.addActionListener(event -> deleteSelectedReservation());

        reservationTable.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseClicked(java.awt.event.MouseEvent event) {
                if (event.getClickCount() == 2) {
                    editSelectedReservation();
                }
            }
        });

        frame.setContentPane(root);
        frame.setVisible(true);
    }

    private JButton createButton(String text, Color color) {
        JButton button = new JButton(text);
        button.setForeground(Color.WHITE);
        button.setBackground(color);
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createEmptyBorder(10, 14, 10, 14));
        return button;
    }

    private String formatSqlError(SQLException e) {
        int code = e.getErrorCode();
        String msg = e.getMessage() != null ? e.getMessage() : "Database error";

        if (code == 1451) {
            return "Can't delete this record because it is already referenced by existing data.";
        }
        if (code == 1452) {
            return "Some referenced record (guest, room type, hotel, invoice, or stay) doesn't exist.";
        }
        if (code == 1062) {
            if (msg.toLowerCase().contains("guests_phone") || msg.toLowerCase().contains("phone")) {
                return "This phone number already belongs to another guest.";
            }
            return "This information already exists. Please double-check and try again.";
        }
        if (code == 3819) {
            return "Data violates a CHECK constraint in the database (check dates, guest count, amount, or status).";
        }
        if (code == 1644 || msg.contains("45000")) {
            return "Operation rejected by database rule: " + msg;
        }
        return "Database error (" + code + "): " + msg;
    }

    private boolean isValidStatusTransition(String oldStatus, String newStatus) {
        if (oldStatus == null || oldStatus.equals(newStatus)) {
            return true;
        }
        switch (oldStatus) {
            case "Pending":
                return "Confirmed".equals(newStatus)
                        || "CheckedIn".equals(newStatus)
                        || "Cancelled".equals(newStatus)
                        || "NoShow".equals(newStatus);
            case "Confirmed":
                return "CheckedIn".equals(newStatus)
                        || "Cancelled".equals(newStatus)
                        || "NoShow".equals(newStatus);
            case "CheckedIn":
                return "CheckedOut".equals(newStatus);
            case "CheckedOut":
            case "Cancelled":
            case "NoShow":
            default:
                return false;
        }
    }

    private boolean hasExistingStay(Connection conn, long resId) throws SQLException {
        String sql = "SELECT 1 FROM Stays WHERE Reservation_ID = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, resId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private void showReservationDialog(boolean isNew) {
        JTextField guestName = new JTextField(18);
        JTextField phone = new JTextField(18);
        JTextField guestsCount = new JTextField("1", 18);
        JTextField startDate = new JTextField(LocalDate.now().toString(), 18);
        JTextField endDate = new JTextField(LocalDate.now().plusDays(1).toString(), 18);

        JComboBox<String> hotelBox = new JComboBox<>();
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT Hotel_ID, Name FROM Hotels ORDER BY Hotel_ID")) {
            while (rs.next()) {
                hotelBox.addItem(rs.getInt("Hotel_ID") + " - " + rs.getString("Name"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

JComboBox<RoomTypeOption> roomTypeBox = new JComboBox<>();
try (Connection conn = DatabaseConnection.getConnection();
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT TypeID, Name, Capacity, BasePrice FROM RoomType ORDER BY TypeID")) {
    while (rs.next()) {
        RoomTypeOption opt = new RoomTypeOption(
                rs.getInt("TypeID"),
                rs.getString("Name"),
                rs.getInt("Capacity"),
                rs.getBigDecimal("BasePrice")
        );
        roomTypeBox.addItem(opt);
    }
} catch (Exception e) {
    e.printStackTrace();
}

JLabel capacityGuideLabel = new JLabel("Select a room type to see max guests.");
capacityGuideLabel.setFont(new Font("Sans Serif", Font.ITALIC, 11));
capacityGuideLabel.setForeground(new Color(65, 85, 110));

        JComboBox<String> status = new JComboBox<>(
                new String[]{"Pending", "Confirmed", "CheckedIn", "CheckedOut", "Cancelled", "NoShow"});

        String oldStatus = null;
        boolean stayAlreadyExists = false;
        long editingResId = -1L;

        if (!isNew) {
            int selectedRow = reservationTable.getSelectedRow();
            if (selectedRow >= 0) {
                editingResId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();
                guestName.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 1)));
                phone.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 2)));
                String currentRtName = String.valueOf(reservationTable.getValueAt(selectedRow, 3));
                for (int i = 0; i < roomTypeBox.getItemCount(); i++) {
                    if (roomTypeBox.getItemAt(i).name.equals(currentRtName)) {
                        roomTypeBox.setSelectedIndex(i);
                        break;
                    }
                }
                startDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 5)));
                endDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 6)));
                oldStatus = String.valueOf(reservationTable.getValueAt(selectedRow, 7));
                status.setSelectedItem(oldStatus);

                try (Connection conn = DatabaseConnection.getConnection()) {
                    stayAlreadyExists = hasExistingStay(conn, editingResId);
                    try (PreparedStatement pstmt = conn.prepareStatement(
                            "SELECT Hotel_ID, NoOfGuests FROM Reservation WHERE Reservation_ID = ?")) {
                        pstmt.setLong(1, editingResId);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                int hId = rs.getInt("Hotel_ID");
                                guestsCount.setText(String.valueOf(rs.getInt("NoOfGuests")));
                                for (int i = 0; i < hotelBox.getItemCount(); i++) {
                                    if (hotelBox.getItemAt(i).startsWith(hId + " - ")) {
                                        hotelBox.setSelectedIndex(i);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        if (stayAlreadyExists) {
            hotelBox.setEnabled(false);
            roomTypeBox.setEnabled(false);
        }

        JPanel page1Fields = new JPanel(new GridLayout(0, 2, 10, 10));
        page1Fields.add(new JLabel("Guest Name:"));
        page1Fields.add(guestName);
        page1Fields.add(new JLabel("Phone Number:"));
        page1Fields.add(phone);
        page1Fields.add(new JLabel("Hotel:"));
        page1Fields.add(hotelBox);

        JPanel page1 = new JPanel(new BorderLayout(0, 10));
        page1.setBorder(BorderFactory.createEmptyBorder(12, 14, 12, 14));
        page1.add(page1Fields, BorderLayout.CENTER);

        JPanel page2Fields = new JPanel(new GridLayout(0, 2, 10, 10));
        page2Fields.add(new JLabel("Room Type:"));
        page2Fields.add(roomTypeBox);
        page2Fields.add(new JLabel("Guests:"));
        page2Fields.add(guestsCount);
        page2Fields.add(new JLabel("Check-in (yyyy-MM-dd):"));
        page2Fields.add(startDate);
        page2Fields.add(new JLabel("Check-out (yyyy-MM-dd):"));
        page2Fields.add(endDate);
        page2Fields.add(new JLabel("Status:"));
        page2Fields.add(status);

        JPanel page2Top = new JPanel(new GridLayout(2, 1, 0, 4));
        page2Top.add(capacityGuideLabel);

        JPanel page2 = new JPanel(new BorderLayout(0, 10));
        page2.setBorder(BorderFactory.createEmptyBorder(12, 14, 12, 14));
        page2.add(page2Top, BorderLayout.NORTH);
        page2.add(page2Fields, BorderLayout.CENTER);

        CardLayout cardLayout = new CardLayout();
        JPanel cardPanel = new JPanel(cardLayout);
        cardPanel.add(page1, "PAGE_1");
        cardPanel.add(page2, "PAGE_2");

        JDialog dialog = new JDialog((Frame) null, isNew ? "Add Reservation" : "Edit Reservation", true);
        dialog.setLayout(new BorderLayout());
        dialog.add(cardPanel, BorderLayout.CENTER);

        JButton backBtn = new JButton("< Back");
        JButton nextBtn = new JButton("Next >");
        JButton saveBtn = new JButton("Save");
        JButton cancelBtn = new JButton("Cancel");

        backBtn.setEnabled(false);
        saveBtn.setVisible(false);

        final boolean[] isPage2 = {false};
        nextBtn.addActionListener(e -> {
            if (guestName.getText().trim().isEmpty()) {
                JOptionPane.showMessageDialog(dialog, "Please enter the guest's name.",
                        "Invalid Information", JOptionPane.WARNING_MESSAGE);
                return;
            }
            cardLayout.show(cardPanel, "PAGE_2");
            isPage2[0] = true;
            backBtn.setEnabled(true);
            nextBtn.setVisible(false);
            saveBtn.setVisible(true);
            dialog.pack();
        });

        backBtn.addActionListener(e -> {
            cardLayout.show(cardPanel, "PAGE_1");
            isPage2[0] = false;
            backBtn.setEnabled(false);
            nextBtn.setVisible(true);
            saveBtn.setVisible(false);
            dialog.pack();
        });

        cancelBtn.addActionListener(e -> dialog.dispose());

        final long finalEditingResId = editingResId;
        final String finalOldStatus = oldStatus;
        final boolean finalStayExists = stayAlreadyExists;

        saveBtn.addActionListener(e -> {
            try {
                String name = guestName.getText().trim();
                if (name.isEmpty()) {
                    throw new IllegalArgumentException("Please enter the guest's name.");
                }
                int numGuests = Integer.parseInt(guestsCount.getText().trim());
                if (numGuests <= 0) {
                    throw new IllegalArgumentException("Number of guests must be greater than 0.");
                }

                RoomTypeOption selectedRt = (RoomTypeOption) roomTypeBox.getSelectedItem();
                if (selectedRt == null) {
                    throw new IllegalArgumentException("Please select a room type.");
                }
                if (numGuests > selectedRt.capacity) {
                    throw new IllegalArgumentException(
                            "Number of guests (" + numGuests + ") exceeds capacity (" + selectedRt.capacity
                                    + ") for " + selectedRt.name + ".");
                }

                LocalDate checkIn = LocalDate.parse(startDate.getText().trim());
                LocalDate checkOut = LocalDate.parse(endDate.getText().trim());
                if (checkOut.isBefore(checkIn)) {
                    throw new IllegalArgumentException("Check-out date cannot be before check-in date.");
                }

                String selectedHotelItem = (String) hotelBox.getSelectedItem();
                if (selectedHotelItem == null) {
                    throw new IllegalArgumentException("Please select a hotel.");
                }
                int hotelId = Integer.parseInt(selectedHotelItem.split(" - ")[0].trim());
                String selectedStatus = (String) status.getSelectedItem();
                String phoneStr = phone.getText().trim();

                if (!isNew && !isValidStatusTransition(finalOldStatus, selectedStatus)) {
                    throw new IllegalArgumentException(
                            "Can't change status from " + finalOldStatus + " to " + selectedStatus + ".");
                }

                try (Connection conn = DatabaseConnection.getConnection()) {
                    conn.setAutoCommit(false);
                    try {
                        long guestId = -1;
                        String findGuestSql = "SELECT Guest_ID FROM Guests WHERE Name = ? LIMIT 1";
                        try (PreparedStatement pstmt = conn.prepareStatement(findGuestSql)) {
                            pstmt.setString(1, name);
                            try (ResultSet rs = pstmt.executeQuery()) {
                                if (rs.next()) {
                                    guestId = rs.getLong("Guest_ID");
                                }
                            }
                        }

                        if (guestId == -1) {
                            long nextGuestId = 1;
                            try (Statement st = conn.createStatement();
                                 ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(Guest_ID), 0) + 1 FROM Guests")) {
                                if (rs.next()) nextGuestId = rs.getLong(1);
                            }
                            String docId = "G" + nextGuestId + "_" + (System.currentTimeMillis() % 100000);
                            String insertGuestSql = "INSERT INTO Guests (Guest_ID, Doc_ID, Name) VALUES (?, ?, ?)";
                            try (PreparedStatement pstmt = conn.prepareStatement(insertGuestSql)) {
                                pstmt.setLong(1, nextGuestId);
                                pstmt.setString(2, docId);
                                pstmt.setString(3, name);
                                pstmt.executeUpdate();
                                guestId = nextGuestId;
                            }
                        }

                        if (!phoneStr.isEmpty()) {
                            String insertPhoneSql = "INSERT INTO Guests_Phone (Phone, Guest_ID) VALUES (?, ?)";
                            try (PreparedStatement pstmt = conn.prepareStatement(insertPhoneSql)) {
                                pstmt.setString(1, phoneStr);
                                pstmt.setLong(2, guestId);
                                pstmt.executeUpdate();
                            }
                        }

                        if (isNew) {
                            long nextResId = 1;
                            try (Statement st = conn.createStatement();
                                 ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(Reservation_ID), 0) + 1 FROM Reservation")) {
                                if (rs.next()) nextResId = rs.getLong(1);
                            }

                            String insertResSql = "INSERT INTO Reservation " +
                                    "(Reservation_ID, StartDate, EndDate, BookingStatus, NoOfGuests, Guest_ID, TypeID, Hotel_ID) " +
                                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                            try (PreparedStatement pstmt = conn.prepareStatement(insertResSql)) {
                                pstmt.setLong(1, nextResId);
                                pstmt.setDate(2, Date.valueOf(checkIn));
                                pstmt.setDate(3, Date.valueOf(checkOut));
                                pstmt.setString(4, selectedStatus);
                                pstmt.setInt(5, numGuests);
                                pstmt.setLong(6, guestId);
                                pstmt.setInt(7, selectedRt.typeId);
                                pstmt.setInt(8, hotelId);
                                pstmt.executeUpdate();
                            }
                        } else {
                            if (finalStayExists) {
                                try (PreparedStatement ps = conn.prepareStatement(
                                        "SELECT Hotel_ID, TypeID FROM Reservation WHERE Reservation_ID = ?")) {
                                    ps.setLong(1, finalEditingResId);
                                    try (ResultSet rs = ps.executeQuery()) {
                                        if (rs.next()) {
                                            hotelId = rs.getInt("Hotel_ID");
                                            int existingTypeId = rs.getInt("TypeID");
                                            if (existingTypeId != selectedRt.typeId) {
                                                throw new IllegalArgumentException(
                                                        "Cannot change room type after a stay has already started.");
                                            }
                                        }
                                    }
                                }
                            }

                            String updateResSql = "UPDATE Reservation SET " +
                                    "StartDate = ?, EndDate = ?, BookingStatus = ?, NoOfGuests = ?, Guest_ID = ?, TypeID = ?, Hotel_ID = ? " +
                                    "WHERE Reservation_ID = ?";
                            try (PreparedStatement pstmt = conn.prepareStatement(updateResSql)) {
                                pstmt.setDate(1, Date.valueOf(checkIn));
                                pstmt.setDate(2, Date.valueOf(checkOut));
                                pstmt.setString(3, selectedStatus);
                                pstmt.setInt(4, numGuests);
                                pstmt.setLong(5, guestId);
                                pstmt.setInt(6, selectedRt.typeId);
                                pstmt.setInt(7, hotelId);
                                pstmt.setLong(8, finalEditingResId);
                                pstmt.executeUpdate();
                            }
                        }

                        conn.commit();
                    } catch (Exception txEx) {
                        try {
                            conn.rollback();
                        } catch (Exception ignored) {
                        }
                        throw txEx;
                    } finally {
                        try {
                            conn.setAutoCommit(true);
                        } catch (Exception ignored) {
                        }
                    }
                }

                refreshTable();
                dialog.dispose();

            } catch (IllegalArgumentException exception) {
                JOptionPane.showMessageDialog(dialog, exception.getMessage(),
                        "Invalid Information", JOptionPane.WARNING_MESSAGE);
            } catch (SQLException sqlEx) {
                sqlEx.printStackTrace();
                JOptionPane.showMessageDialog(dialog, formatSqlError(sqlEx),
                        "Database Rule / Error", JOptionPane.WARNING_MESSAGE);
            } catch (Exception exception) {
                exception.printStackTrace();
                JOptionPane.showMessageDialog(dialog, "Error when saving data to MySQL: " + exception.getMessage(),
                        "Database Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel footer = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 8));
        footer.add(backBtn);
        footer.add(nextBtn);
        footer.add(saveBtn);
        footer.add(cancelBtn);
        dialog.add(footer, BorderLayout.SOUTH);

        dialog.pack();
        dialog.setLocationRelativeTo(null);
        dialog.setVisible(true);
    }

    private void checkInSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }

        long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();
        String currentStatus = String.valueOf(reservationTable.getValueAt(selectedRow, 7));

        if (!isValidStatusTransition(currentStatus, "CheckedIn")) {
            JOptionPane.showMessageDialog(null,
                    "Can't check in while status is " + currentStatus + ".",
                    "Invalid Status", JOptionPane.WARNING_MESSAGE);
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            int hotelId;
            int typeId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT Hotel_ID, TypeID FROM Reservation WHERE Reservation_ID = ?")) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        JOptionPane.showMessageDialog(null, "Reservation #" + resId + " wasn't found.");
                        return;
                    }
                    hotelId = rs.getInt("Hotel_ID");
                    typeId = rs.getInt("TypeID");
                }
            }

            List<String> rooms = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT Room_Number FROM Room WHERE Hotel_ID = ? AND TypeID = ? AND RoomStatus = 'Available' ORDER BY Room_Number")) {
                ps.setInt(1, hotelId);
                ps.setInt(2, typeId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        rooms.add(rs.getString("Room_Number"));
                    }
                }
            }

            if (rooms.isEmpty()) {
                JOptionPane.showMessageDialog(null,
                        "No Available room of this room type at this hotel.",
                        "No Room Available", JOptionPane.WARNING_MESSAGE);
                return;
            }

            String roomNum = (String) JOptionPane.showInputDialog(
                    null, "Pick a room for Reservation #" + resId + ":",
                    "Check-In", JOptionPane.PLAIN_MESSAGE, null,
                    rooms.toArray(), rooms.get(0));
            if (roomNum == null) {
                return;
            }

            conn.setAutoCommit(false);
            try {
                long nextInvoiceId = 1;
                long nextStayId = 1;
                try (Statement st = conn.createStatement()) {
                    try (ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(Invoice_ID), 0) + 1 FROM Invoices")) {
                        if (rs.next()) nextInvoiceId = rs.getLong(1);
                    }
                    try (ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(StayID), 0) + 1 FROM Stays")) {
                        if (rs.next()) nextStayId = rs.getLong(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (?, CURRENT_DATE(), 'Open')")) {
                    ps.setLong(1, nextInvoiceId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number) " +
                                "VALUES (?, NOW(), NULL, ?, ?, ?, ?)")) {
                    ps.setLong(1, nextStayId);
                    ps.setLong(2, resId);
                    ps.setLong(3, nextInvoiceId);
                    ps.setInt(4, hotelId);
                    ps.setString(5, roomNum);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Reservation SET BookingStatus = 'CheckedIn' WHERE Reservation_ID = ?")) {
                    ps.setLong(1, resId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Room SET RoomStatus = 'Occupied' WHERE Hotel_ID = ? AND Room_Number = ?")) {
                    ps.setInt(1, hotelId);
                    ps.setString(2, roomNum);
                    ps.executeUpdate();
                }

                conn.commit();
                refreshTable();
                JOptionPane.showMessageDialog(null,
                        "Check-In Successful room: " + roomNum + " (Stay #" + nextStayId + ", Invoice #" + nextInvoiceId + ").");
            } catch (Exception txEx) {
                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
                throw txEx;
            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                }
            }
        } catch (SQLException sqlEx) {
            sqlEx.printStackTrace();
            JOptionPane.showMessageDialog(null, formatSqlError(sqlEx),
                    "Check-In Failed", JOptionPane.WARNING_MESSAGE);
        } catch (Exception ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(null, "Error when Check-In: " + ex.getMessage(),
                    "Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private BigDecimal calculateNightlyRate(Connection conn, int typeId, LocalDate nightDate, BigDecimal basePrice) throws SQLException {
        String sql = "SELECT hr.Price " +
                "FROM HasRate hr " +
                "JOIN RatePlan rp ON hr.RatePlan_ID = rp.RatePlan_ID " +
                "WHERE hr.TypeID = ? AND ? >= rp.StartDate AND ? <= rp.EndDate " +
                "LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, typeId);
            ps.setDate(2, Date.valueOf(nightDate));
            ps.setDate(3, Date.valueOf(nightDate));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getBigDecimal("Price") != null) {
                    return rs.getBigDecimal("Price");
                }
            }
        }
        return basePrice;
    }

    private void checkOutSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }

        long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();
        String currentStatus = String.valueOf(reservationTable.getValueAt(selectedRow, 7));

        if (!"CheckedIn".equals(currentStatus)) {
            JOptionPane.showMessageDialog(null,
                    "Can't check out while status is " + currentStatus + ".",
                    "Invalid Status", JOptionPane.WARNING_MESSAGE);
            return;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            long stayId;
            long invoiceId;
            int hotelId;
            String roomNum;
            int typeId;
            LocalDate checkInDate;
            BigDecimal basePrice;

            String querySql = "SELECT s.StayID, s.Invoice_ID, s.Hotel_ID, s.Room_Number, s.CheckIn, " +
                    "r.TypeID, rt.BasePrice " +
                    "FROM Stays s " +
                    "JOIN Reservation r ON s.Reservation_ID = r.Reservation_ID " +
                    "JOIN RoomType rt ON r.TypeID = rt.TypeID " +
                    "WHERE s.Reservation_ID = ? AND s.Checkout IS NULL";
            try (PreparedStatement ps = conn.prepareStatement(querySql)) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        JOptionPane.showMessageDialog(null,
                                "No active stay found for Reservation #" + resId + ".",
                                "Check-Out Failed", JOptionPane.WARNING_MESSAGE);
                        return;
                    }
                    stayId = rs.getLong("StayID");
                    invoiceId = rs.getLong("Invoice_ID");
                    hotelId = rs.getInt("Hotel_ID");
                    roomNum = rs.getString("Room_Number");
                    checkInDate = rs.getDate("CheckIn").toLocalDate();
                    typeId = rs.getInt("TypeID");
                    basePrice = rs.getBigDecimal("BasePrice");
                }
            }

            LocalDate checkOutDate = LocalDate.now();
            long nights = Math.max(1L, ChronoUnit.DAYS.between(checkInDate, checkOutDate));

            Map<BigDecimal, Integer> groupedRates = new LinkedHashMap<>();
            BigDecimal roomTotal = BigDecimal.ZERO;
            for (long i = 0; i < nights; i++) {
                LocalDate night = checkInDate.plusDays(i);
                BigDecimal rate = calculateNightlyRate(conn, typeId, night, basePrice);
                groupedRates.put(rate, groupedRates.getOrDefault(rate, 0) + 1);
                roomTotal = roomTotal.add(rate);
            }

            BigDecimal serviceTotal = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(Price * Quantity), 0) FROM Records WHERE StayID = ?")) {
                ps.setLong(1, stayId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        serviceTotal = rs.getBigDecimal(1);
                    }
                }
            }

            BigDecimal grandTotal = roomTotal.add(serviceTotal);
            int confirm = JOptionPane.showConfirmDialog(null,
        "Check-Out Reservation #" + resId + " (Room " + roomNum + ")?\n" +
                "Nights: " + nights + " | Room subtotal: " + formatMoney(roomTotal) + "\n" +
                "Services subtotal: " + formatMoney(serviceTotal) + " | Total: " + formatMoney(grandTotal),
        "Confirm Check-Out", JOptionPane.YES_NO_OPTION);
if (confirm != JOptionPane.YES_OPTION) {
    return;
}

            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Stays SET Checkout = NOW() WHERE StayID = ?")) {
                    ps.setLong(1, stayId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Reservation SET BookingStatus = 'CheckedOut' WHERE Reservation_ID = ?")) {
                    ps.setLong(1, resId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Room SET RoomStatus = 'Available' WHERE Hotel_ID = ? AND Room_Number = ?")) {
                    ps.setInt(1, hotelId);
                    ps.setString(2, roomNum);
                    ps.executeUpdate();
                }

                int nextLineId = 1;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COALESCE(MAX(LineID), 0) + 1 FROM InvoiceLine WHERE Invoice_ID = ?")) {
                    ps.setLong(1, invoiceId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) nextLineId = rs.getInt(1);
                    }
                }

                for (Map.Entry<BigDecimal, Integer> entry : groupedRates.entrySet()) {
                    BigDecimal lineAmount = entry.getKey().multiply(BigDecimal.valueOf(entry.getValue()));
                    try (PreparedStatement ps = conn.prepareStatement(
        "INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount) VALUES (?, ?, 'Room', ?)")) {
    ps.setInt(1, nextLineId++);
    ps.setLong(2, invoiceId);
    ps.setBigDecimal(3, lineAmount);
    ps.executeUpdate();
}

if (serviceTotal.compareTo(BigDecimal.ZERO) > 0) {
    try (PreparedStatement ps = conn.prepareStatement(
            "INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount) VALUES (?, ?, 'Service', ?)")) {
        ps.setInt(1, nextLineId++);
        ps.setLong(2, invoiceId);
        ps.setBigDecimal(3, serviceTotal);
        ps.executeUpdate();
    }
}
}

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Invoices SET Status = 'Unpaid' WHERE Invoice_ID = ?")) {
                    ps.setLong(1, invoiceId);
                    ps.executeUpdate();
                }

                conn.commit();
                refreshTable();
                JOptionPane.showMessageDialog(null,
                        "Check-Out completed for Reservation #" + resId + ". Invoice #" + invoiceId + " is now Unpaid (Total: " + formatMoney(grandTotal) + ").");
            } catch (Exception txEx) {
                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
                throw txEx;
            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                }
            }
        } catch (SQLException sqlEx) {
            sqlEx.printStackTrace();
            JOptionPane.showMessageDialog(null, formatSqlError(sqlEx),
                    "Check-Out Failed", JOptionPane.WARNING_MESSAGE);
        } catch (Exception ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(null, "Error when Check-Out: " + ex.getMessage(),
                    "Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void recordPaymentForSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }

        long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();

        try (Connection conn = DatabaseConnection.getConnection()) {
            long invoiceId;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT Invoice_ID FROM Stays WHERE Reservation_ID = ?")) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        JOptionPane.showMessageDialog(null,
                                "Reservation #" + resId + " does not have an invoice yet.",
                                "No Invoice", JOptionPane.WARNING_MESSAGE);
                        return;
                    }
                    invoiceId = rs.getLong("Invoice_ID");
                }
            }

            BigDecimal invoiceTotal = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(Amount), 0) FROM InvoiceLine WHERE Invoice_ID = ?")) {
                ps.setLong(1, invoiceId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) invoiceTotal = rs.getBigDecimal(1);
                }
            }

            BigDecimal alreadyPaid = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(SUM(Amount), 0) FROM Payment WHERE Invoice_ID = ?")) {
                ps.setLong(1, invoiceId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) alreadyPaid = rs.getBigDecimal(1);
                }
            }

            BigDecimal remaining = invoiceTotal.subtract(alreadyPaid);
            if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
                JOptionPane.showMessageDialog(null,
                        "Invoice #" + invoiceId + " has no remaining balance (Total: " + invoiceTotal + ", Paid: " + alreadyPaid + ").",
                        "Payment Info", JOptionPane.INFORMATION_MESSAGE);
                return;
            }

            JTextField amountField = new JTextField(formatMoney(remaining), 14);
            JComboBox<String> methodBox = new JComboBox<>(
                    new String[]{"Cash", "CreditCard", "BankTransfer", "EWallet"});

            JPanel panel = new JPanel(new GridLayout(0, 2, 8, 8));
            panel.add(new JLabel("Invoice #" + invoiceId + " Remaining:"));
            panel.add(new JLabel(formatMoney(remaining)));
            panel.add(new JLabel("Amount:"));
            panel.add(amountField);
            panel.add(new JLabel("Method:"));
            panel.add(methodBox);

            int result = JOptionPane.showConfirmDialog(null, panel,
                    "Record Payment", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
            if (result != JOptionPane.OK_OPTION) {
                return;
            }

            String rawAmount = amountField.getText().trim().replace(".", "").replace(",", ".");
BigDecimal payAmount = new BigDecimal(rawAmount);
if (payAmount.compareTo(BigDecimal.ZERO) <= 0) {
    throw new IllegalArgumentException("Payment amount must be greater than 0.");
}
if (payAmount.compareTo(remaining) > 0) {
    throw new IllegalArgumentException(
            "Payment amount (" + formatMoney(payAmount) + ") cannot exceed remaining balance (" + formatMoney(remaining) + ").");
}

            String method = (String) methodBox.getSelectedItem();

            conn.setAutoCommit(false);
            try {
                long nextPaymentId = 1;
                try (Statement st = conn.createStatement();
                     ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(PaymentID), 0) + 1 FROM Payment")) {
                    if (rs.next()) nextPaymentId = rs.getLong(1);
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Payment (PaymentID, Invoice_ID, PaidDate, Amount, Method) VALUES (?, ?, CURRENT_DATE(), ?, ?)")) {
                    ps.setLong(1, nextPaymentId);
                    ps.setLong(2, invoiceId);
                    ps.setBigDecimal(3, payAmount);
                    ps.setString(4, method);
                    ps.executeUpdate();
                }

                BigDecimal newPaidTotal = alreadyPaid.add(payAmount);
                String newInvoiceStatus = newPaidTotal.compareTo(invoiceTotal) >= 0 ? "Paid" : "PartiallyPaid";

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Invoices SET Status = ? WHERE Invoice_ID = ?")) {
                    ps.setString(1, newInvoiceStatus);
                    ps.setLong(2, invoiceId);
                    ps.executeUpdate();
                }

                conn.commit();
                JOptionPane.showMessageDialog(null,
                        "Payment #" + nextPaymentId + " saved. Invoice #" + invoiceId + " status: " + newInvoiceStatus + ".");
            } catch (Exception txEx) {
                try {
                    conn.rollback();
                } catch (Exception ignored) {
                }
                throw txEx;
            } finally {
                try {
                    conn.setAutoCommit(true);
                } catch (Exception ignored) {
                }
            }
        } catch (IllegalArgumentException ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(),
                    "Invalid Payment", JOptionPane.WARNING_MESSAGE);
        } catch (SQLException sqlEx) {
            sqlEx.printStackTrace();
            JOptionPane.showMessageDialog(null, formatSqlError(sqlEx),
                    "Payment Failed", JOptionPane.WARNING_MESSAGE);
        } catch (Exception ex) {
            ex.printStackTrace();
            JOptionPane.showMessageDialog(null, "Error recording payment: " + ex.getMessage(),
                    "Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void editSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }
        showReservationDialog(false);
    }

    private void deleteSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }

        int result = JOptionPane.showConfirmDialog(null, "Delete the selected reservation from database?",
                "Confirmation", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);

        if (result == JOptionPane.YES_OPTION) {
            long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();
            String sql = "DELETE FROM Reservation WHERE Reservation_ID = ?";

            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement pstmt = conn.prepareStatement(sql)) {

                pstmt.setLong(1, resId);
                pstmt.executeUpdate();
                refreshTable();

            } catch (SQLException sqlEx) {
                sqlEx.printStackTrace();
                JOptionPane.showMessageDialog(null, formatSqlError(sqlEx),
                        "Delete Failed", JOptionPane.WARNING_MESSAGE);
            } catch (Exception e) {
                e.printStackTrace();
                JOptionPane.showMessageDialog(null, "Error when deleting data from MySQL: " + e.getMessage());
            }
        }
    }

    private void showSelectReservationMessage() {
        JOptionPane.showMessageDialog(null, "Please select a reservation in the table.",
                "No Reservation Selected", JOptionPane.INFORMATION_MESSAGE);
    }

    private void refreshTable() {
        tableModel.setRowCount(0);
        String sql = "SELECT r.Reservation_ID, " +
                "g.Name AS guest_name, " +
                "MIN(gp.Phone) AS phone, " +
                "rt.Name AS room_type_name, " +
                "s.Room_Number AS room_number, " +
                "r.StartDate, " +
                "r.EndDate, " +
                "r.BookingStatus " +
                "FROM Reservation r " +
                "LEFT JOIN Guests g ON r.Guest_ID = g.Guest_ID " +
                "LEFT JOIN Guests_Phone gp ON g.Guest_ID = gp.Guest_ID " +
                "LEFT JOIN RoomType rt ON r.TypeID = rt.TypeID " +
                "LEFT JOIN Stays s ON r.Reservation_ID = s.Reservation_ID " +
                "GROUP BY r.Reservation_ID, g.Name, rt.Name, s.Room_Number, r.StartDate, r.EndDate, r.BookingStatus " +
                "ORDER BY r.Reservation_ID";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                tableModel.addRow(new Object[]{
                        rs.getLong("Reservation_ID"),
                        rs.getString("guest_name"),
                        rs.getString("phone") != null ? rs.getString("phone") : "",
                        rs.getString("room_type_name"),
                        rs.getString("room_number") != null ? rs.getString("room_number") : "Unassigned",
                        rs.getDate("StartDate") != null ? rs.getDate("StartDate").toLocalDate() : null,
                        rs.getDate("EndDate") != null ? rs.getDate("EndDate").toLocalDate() : null,
                        rs.getString("BookingStatus")
                });
            }
        } catch (SQLException sqlEx) {
            sqlEx.printStackTrace();
            JOptionPane.showMessageDialog(null, formatSqlError(sqlEx));
        } catch (Exception e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(null, "Error when loading data from MySQL: " + e.getMessage());
        }
    }

    private String formatMoney(BigDecimal amount) {
    if (amount == null) return "0";
    BigDecimal normalized = amount.stripTrailingZeros();
    DecimalFormatSymbols symbols = new DecimalFormatSymbols(Locale.US);
    symbols.setGroupingSeparator('.');
    DecimalFormat df = new DecimalFormat("#,##0.##", symbols);
    return df.format(normalized);
}

    public static void main(String[] args) {
        SwingUtilities.invokeLater(HotelManagementUI::new);
    }
}
