package hotel.model;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDate;

public class HotelManagementUI {

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
        frame.setMinimumSize(new Dimension(980, 560));
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

        JButton addButton = createButton("+ Add Reservation", new Color(34, 112, 90));
        JButton editButton = createButton("Edit", new Color(54, 91, 135));
        JButton deleteButton = createButton("Delete", new Color(174, 66, 66));

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        actions.setOpaque(false);
        actions.add(addButton);
        actions.add(editButton);
        actions.add(deleteButton);
        root.add(actions, BorderLayout.SOUTH);

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

        JComboBox<String> roomType = new JComboBox<>();
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT Name FROM RoomType ORDER BY TypeID")) {
            while (rs.next()) {
                roomType.addItem(rs.getString("Name"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        JComboBox<String> status = new JComboBox<>(
                new String[]{"Pending", "Confirmed", "CheckedIn", "CheckedOut", "Cancelled", "NoShow"});

        if (!isNew) {
            int selectedRow = reservationTable.getSelectedRow();
            if (selectedRow >= 0) {
                guestName.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 1)));
                phone.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 2)));
                roomType.setSelectedItem(reservationTable.getValueAt(selectedRow, 3));
                startDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 5)));
                endDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 6)));
                status.setSelectedItem(reservationTable.getValueAt(selectedRow, 7));

                long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();
                try (Connection conn = DatabaseConnection.getConnection();
                     PreparedStatement pstmt = conn.prepareStatement(
                             "SELECT Hotel_ID, NoOfGuests FROM Reservation WHERE Reservation_ID = ?")) {
                    pstmt.setLong(1, resId);
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
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        JPanel form = new JPanel(new GridLayout(0, 2, 10, 10));
        form.add(new JLabel("Hotel:"));
        form.add(hotelBox);
        form.add(new JLabel("Guest Name:"));
        form.add(guestName);
        form.add(new JLabel("Phone Number:"));
        form.add(phone);
        form.add(new JLabel("Guests:"));
        form.add(guestsCount);
        form.add(new JLabel("Room Type:"));
        form.add(roomType);
        form.add(new JLabel("Check-in (yyyy-MM-dd):"));
        form.add(startDate);
        form.add(new JLabel("Check-out (yyyy-MM-dd):"));
        form.add(endDate);
        form.add(new JLabel("Status:"));
        form.add(status);

        while (true) {
            int result = JOptionPane.showConfirmDialog(null, form,
                    isNew ? "Add Reservation" : "Edit Reservation",
                    JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
            if (result != JOptionPane.OK_OPTION) {
                return;
            }

            try {
                String name = guestName.getText().trim();
                if (name.isEmpty()) {
                    throw new IllegalArgumentException("Please enter the guest's name.");
                }
                int numGuests = Integer.parseInt(guestsCount.getText().trim());
                if (numGuests <= 0) {
                    throw new IllegalArgumentException("Number of guests must be greater than 0.");
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
                String selectedRoomType = (String) roomType.getSelectedItem();
                String selectedStatus = (String) status.getSelectedItem();
                String phoneStr = phone.getText().trim();

                try (Connection conn = DatabaseConnection.getConnection()) {
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
                        String docId = "G" + nextGuestId + "_" + System.currentTimeMillis() % 100000;
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
                        String insertPhoneSql = "INSERT IGNORE INTO Guests_Phone (Phone, Guest_ID) VALUES (?, ?)";
                        try (PreparedStatement pstmt = conn.prepareStatement(insertPhoneSql)) {
                            pstmt.setString(1, phoneStr);
                            pstmt.setLong(2, guestId);
                            pstmt.executeUpdate();
                        }
                    }

                    int roomTypeId = 1;
                    String getRtSql = "SELECT TypeID FROM RoomType WHERE Name = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(getRtSql)) {
                        pstmt.setString(1, selectedRoomType);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) roomTypeId = rs.getInt("TypeID");
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
                            pstmt.setDate(2, java.sql.Date.valueOf(checkIn));
                            pstmt.setDate(3, java.sql.Date.valueOf(checkOut));
                            pstmt.setString(4, selectedStatus);
                            pstmt.setInt(5, numGuests);
                            pstmt.setLong(6, guestId);
                            pstmt.setInt(7, roomTypeId);
                            pstmt.setInt(8, hotelId);
                            pstmt.executeUpdate();
                        }
                    } else {
                        int selectedRow = reservationTable.getSelectedRow();
                        long resId = ((Number) reservationTable.getValueAt(selectedRow, 0)).longValue();

                        String updateResSql = "UPDATE Reservation SET " +
                                "StartDate = ?, EndDate = ?, BookingStatus = ?, NoOfGuests = ?, Guest_ID = ?, TypeID = ?, Hotel_ID = ? " +
                                "WHERE Reservation_ID = ?";
                        try (PreparedStatement pstmt = conn.prepareStatement(updateResSql)) {
                            pstmt.setDate(1, java.sql.Date.valueOf(checkIn));
                            pstmt.setDate(2, java.sql.Date.valueOf(checkOut));
                            pstmt.setString(3, selectedStatus);
                            pstmt.setInt(4, numGuests);
                            pstmt.setLong(5, guestId);
                            pstmt.setInt(6, roomTypeId);
                            pstmt.setInt(7, hotelId);
                            pstmt.setLong(8, resId);
                            pstmt.executeUpdate();
                        }
                    }
                }

                refreshTable();
                return;

            } catch (IllegalArgumentException exception) {
                JOptionPane.showMessageDialog(null, exception.getMessage(),
                        "Invalid Information", JOptionPane.WARNING_MESSAGE);
            } catch (Exception exception) {
                exception.printStackTrace();
                JOptionPane.showMessageDialog(null, "Error when saving data to MySQL: " + exception.getMessage(),
                        "Database Error", JOptionPane.WARNING_MESSAGE);
            }
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
        } catch (Exception e) {
            e.printStackTrace();
            JOptionPane.showMessageDialog(null, "Error when loading data from MySQL: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(HotelManagementUI::new);
    }
}
