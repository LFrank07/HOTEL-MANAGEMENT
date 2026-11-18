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

        // Custom Renderer để đổi màu cột Check-out khi đến hạn hoặc quá hạn
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

                // Cột "Check-out" là cột index số 6
                if (column == 6 && value != null) {
                    try {
                        LocalDate checkOutDate = LocalDate.parse(value.toString());
                        LocalDate today = LocalDate.now();
                        int modelRow = table.convertRowIndexToModel(row);
                        String status = (String) table.getModel().getValueAt(modelRow, 7);

                        if (!"CANCELLED".equals(status) && !"COMPLETED".equals(status)) {
                            if (!today.isBefore(checkOutDate)) {
                                if (!isSelected) {
                                    c.setForeground(new Color(210, 40, 40)); // Màu đỏ nổi bật
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
        JTextField startDate = new JTextField(LocalDate.now().toString(), 18);
        JTextField endDate = new JTextField(LocalDate.now().plusDays(1).toString(), 18);

        JComboBox<String> roomType = new JComboBox<>();
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT name FROM room_types")) {
            while (rs.next()) {
                roomType.addItem(rs.getString("name"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        JComboBox<String> roomNumber = new JComboBox<>();
        roomNumber.addItem("Unassigned");
        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT room_number FROM rooms")) {
            while (rs.next()) {
                roomNumber.addItem(rs.getString("room_number"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        JComboBox<String> status = new JComboBox<>(new String[]{"PENDING", "CONFIRMED", "CANCELLED", "COMPLETED"});

        if (!isNew) {
            int selectedRow = reservationTable.getSelectedRow();
            if (selectedRow >= 0) {
                guestName.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 1)));
                phone.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 2)));
                roomType.setSelectedItem(reservationTable.getValueAt(selectedRow, 3));
                roomNumber.setSelectedItem(reservationTable.getValueAt(selectedRow, 4));
                startDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 5)));
                endDate.setText(String.valueOf(reservationTable.getValueAt(selectedRow, 6)));
                status.setSelectedItem(reservationTable.getValueAt(selectedRow, 7));
            }
        }

        JPanel form = new JPanel(new GridLayout(0, 2, 10, 10));
        form.add(new JLabel("Guest Name:"));
        form.add(guestName);
        form.add(new JLabel("Phone Number:"));
        form.add(phone);
        form.add(new JLabel("Room Type:"));
        form.add(roomType);
        form.add(new JLabel("Room (Optional):"));
        form.add(roomNumber);
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
                LocalDate checkIn = LocalDate.parse(startDate.getText().trim());
                LocalDate checkOut = LocalDate.parse(endDate.getText().trim());
                if (!checkOut.isAfter(checkIn)) {
                    throw new IllegalArgumentException("Check-out date must be after the check-in date.");
                }

                String selectedRoomType = (String) roomType.getSelectedItem();
                String selectedRoomNumber = (String) roomNumber.getSelectedItem();
                String selectedStatus = (String) status.getSelectedItem();
                String phoneStr = phone.getText().trim();

                try (Connection conn = DatabaseConnection.getConnection()) {
                    long guestId = -1;
                    String checkGuestSql = "SELECT guest_id FROM guests WHERE name = ? AND phone = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(checkGuestSql)) {
                        pstmt.setString(1, name);
                        pstmt.setString(2, phoneStr);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) {
                                guestId = rs.getLong("guest_id");
                            }
                        }
                    }

                    if (guestId == -1) {
                        String insertGuestSql = "INSERT INTO guests (name, phone) VALUES (?, ?)";
                        try (PreparedStatement pstmt = conn.prepareStatement(insertGuestSql, Statement.RETURN_GENERATED_KEYS)) {
                            pstmt.setString(1, name);
                            pstmt.setString(2, phoneStr);
                            pstmt.executeUpdate();
                            try (ResultSet gk = pstmt.getGeneratedKeys()) {
                                if (gk.next()) guestId = gk.getLong(1);
                            }
                        }
                    }

                    long roomTypeId = 1;
                    String getRtSql = "SELECT room_type_id FROM room_types WHERE name = ?";
                    try (PreparedStatement pstmt = conn.prepareStatement(getRtSql)) {
                        pstmt.setString(1, selectedRoomType);
                        try (ResultSet rs = pstmt.executeQuery()) {
                            if (rs.next()) roomTypeId = rs.getLong("room_type_id");
                        }
                    }

                    Long roomId = null;
                    if (selectedRoomNumber != null && !"Unassigned".equals(selectedRoomNumber)) {
                        String getRoomSql = "SELECT room_id FROM rooms WHERE room_number = ?";
                        try (PreparedStatement pstmt = conn.prepareStatement(getRoomSql)) {
                            pstmt.setString(1, selectedRoomNumber);
                            try (ResultSet rs = pstmt.executeQuery()) {
                                if (rs.next()) roomId = rs.getLong("room_id");
                            }
                        }
                    }

                    if (isNew) {
                        String insertResSql = "INSERT INTO reservations (guest_id, room_type_id, room_id, start_date, end_date, status) VALUES (?, ?, ?, ?, ?, ?)";
                        try (PreparedStatement pstmt = conn.prepareStatement(insertResSql)) {
                            pstmt.setLong(1, guestId);
                            pstmt.setLong(2, roomTypeId);
                            if (roomId != null) pstmt.setLong(3, roomId);
                            else pstmt.setNull(3, java.sql.Types.INTEGER);
                            pstmt.setDate(4, java.sql.Date.valueOf(checkIn));
                            pstmt.setDate(5, java.sql.Date.valueOf(checkOut));
                            pstmt.setString(6, selectedStatus);
                            pstmt.executeUpdate();
                        }
                    } else {
                        int selectedRow = reservationTable.getSelectedRow();
                        long resId = (long) reservationTable.getValueAt(selectedRow, 0);

                        String updateResSql = "UPDATE reservations SET guest_id = ?, room_type_id = ?, room_id = ?, start_date = ?, end_date = ?, status = ? WHERE reservation_id = ?";
                        try (PreparedStatement pstmt = conn.prepareStatement(updateResSql)) {
                            pstmt.setLong(1, guestId);
                            pstmt.setLong(2, roomTypeId);
                            if (roomId != null) pstmt.setLong(3, roomId);
                            else pstmt.setNull(3, java.sql.Types.INTEGER);
                            pstmt.setDate(4, java.sql.Date.valueOf(checkIn));
                            pstmt.setDate(5, java.sql.Date.valueOf(checkOut));
                            pstmt.setString(6, selectedStatus);
                            pstmt.setLong(7, resId);
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
            long resId = (long) reservationTable.getValueAt(selectedRow, 0);
            String sql = "DELETE FROM reservations WHERE reservation_id = ?";

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
        String sql = "SELECT r.reservation_id, g.name AS guest_name, g.phone, rt.name AS room_type_name, " +
                "rm.room_number, r.start_date, r.end_date, r.status " +
                "FROM reservations r " +
                "LEFT JOIN guests g ON r.guest_id = g.guest_id " +
                "LEFT JOIN room_types rt ON r.room_type_id = rt.room_type_id " +
                "LEFT JOIN rooms rm ON r.room_id = rm.room_id";

        try (Connection conn = DatabaseConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {

            while (rs.next()) {
                tableModel.addRow(new Object[]{
                        rs.getLong("reservation_id"),
                        rs.getString("guest_name"),
                        rs.getString("phone"),
                        rs.getString("room_type_name"),
                        rs.getString("room_number") != null ? rs.getString("room_number") : "Unassigned",
                        rs.getDate("start_date") != null ? rs.getDate("start_date").toLocalDate() : null,
                        rs.getDate("end_date") != null ? rs.getDate("end_date").toLocalDate() : null,
                        rs.getString("status")
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
