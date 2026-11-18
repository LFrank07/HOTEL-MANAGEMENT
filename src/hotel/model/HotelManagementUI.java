package hotel.model;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class HotelManagementUI {
    private final List<Reservation> reservations = new ArrayList<>();
    private final List<Room> rooms = new ArrayList<>();
    private final List<RoomType> roomTypes = new ArrayList<>();
    private final DefaultTableModel tableModel = new DefaultTableModel(
            new Object[]{"Reservation ID", "Guest Name", "Phone", "Room Type",
                    "Room", "Check-in", "Check-out", "Status"}, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };
    private final JTable reservationTable = new JTable(tableModel);
    private long nextReservationId = 1;
    private long nextGuestId = 1;

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
        title.setFont(new Font("SansSerif", Font.BOLD, 22));
        title.setForeground(new Color(29, 48, 71));

        JLabel subtitle = new JLabel("Create and track reservation details · Demo data running in memory");
        subtitle.setForeground(new Color(101, 114, 130));

        JPanel heading = new JPanel(new GridLayout(2, 1, 0, 4));
        heading.setOpaque(false);
        heading.add(title);
        heading.add(subtitle);
        root.add(heading, BorderLayout.NORTH);

        reservationTable.setRowHeight(32);
        reservationTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        reservationTable.getTableHeader().setFont(new Font("SansSerif", Font.BOLD, 12));
        reservationTable.setFillsViewportHeight(true);

        // Custom Renderer để đổi màu cột Check-out khi đến hạn hoặc quá hạn
        reservationTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                                                           boolean isSelected, boolean hasFocus,
                                                           int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                
                // Mặc định font và màu chữ bình thường nếu không được chọn
                if (!isSelected) {
                    c.setForeground(Color.BLACK);
                    c.setFont(table.getFont());
                }

                // Cột "Check-out" là cột index số 6
                if (column == 6 && value != null) {
                    try {
                        LocalDate checkOutDate = LocalDate.parse(value.toString());
                        LocalDate today = LocalDate.now();
                        
                        // Lấy trạng thái của dòng hiện tại (cột index số 7)
                        int modelRow = table.convertRowIndexToModel(row);
                        String status = (String) table.getModel().getValueAt(modelRow, 7);

                        // Nếu chưa Cancelled/Completed và ngày hiện tại >= ngày Check-out
                        if (!"CANCELLED".equals(status) && !"COMPLETED".equals(status)) {
                            if (!today.isBefore(checkOutDate)) {
                                if (!isSelected) {
                                    c.setForeground(new Color(210, 40, 40)); // Màu đỏ nổi bật
                                }
                                c.setFont(new Font("SansSerif", Font.BOLD, 12)); // Chữ đậm
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

        JButton addButton = createButton("＋ Add Reservation", new Color(34, 112, 90));
        JButton editButton = createButton("Edit", new Color(54, 91, 135));
        JButton deleteButton = createButton("Delete", new Color(174, 66, 66));

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        actions.setOpaque(false);
        actions.add(addButton);
        actions.add(editButton);
        actions.add(deleteButton);
        root.add(actions, BorderLayout.SOUTH);

        addButton.addActionListener(event -> showReservationDialog(null));
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

    private void showReservationDialog(Reservation reservation) {
        boolean isNew = reservation == null;
        JTextField guestName = new JTextField(isNew || reservation.getGuest() == null ? "" : reservation.getGuest().getName(), 18);
        JTextField phone = new JTextField(isNew || reservation.getGuest() == null ? "" : reservation.getGuest().getPhone(), 18);
        JTextField startDate = new JTextField(isNew ? LocalDate.now().toString() : reservation.getStartDate().toString(), 18);
        JTextField endDate = new JTextField(isNew ? LocalDate.now().plusDays(1).toString() : reservation.getEndDate().toString(), 18);

        JComboBox<String> roomType = new JComboBox<>();
        for (RoomType type : roomTypes) {
            roomType.addItem(type.getName());
        }

        JComboBox<String> roomNumber = new JComboBox<>();
        roomNumber.addItem("Unassigned");
        for (Room room : rooms) {
            roomNumber.addItem(room.getRoomNumber());
        }

        JComboBox<String> status = new JComboBox<>(new String[]{"PENDING", "CONFIRMED", "CANCELLED", "COMPLETED"});

        if (!isNew) {
            roomType.setSelectedItem(reservation.getRoomType().getName());
            if (!reservation.getAssignedRooms().isEmpty()) {
                roomNumber.setSelectedItem(reservation.getAssignedRooms().get(0).getRoomNumber());
            }
            status.setSelectedItem(reservation.getStatus());
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

                RoomType selectedType = findRoomType((String) roomType.getSelectedItem());
                String selectedRoomNumber = (String) roomNumber.getSelectedItem();
                Room selectedRoom = selectedRoomNumber == null || "Unassigned".equals(selectedRoomNumber)
                        ? null : findRoom(selectedRoomNumber);
                String selectedStatus = (String) status.getSelectedItem();

                if (selectedRoom != null) {
                    if (!selectedType.getRoomtypeId().equals(selectedRoom.getRoomType().getRoomtypeId())) {
                        throw new IllegalArgumentException("The selected room does not belong to the chosen room type.");
                    }
                    if (!"CANCELLED".equals(selectedStatus) && hasRoomConflict(selectedRoom, checkIn, checkOut, reservation)) {
                        throw new IllegalArgumentException("The room is already booked during this time period.");
                    }
                }

                Guest guest = isNew || reservation.getGuest() == null ? new Guest() : reservation.getGuest();
                if (guest.getGuestId() == null) {
                    guest.setGuestId(nextGuestId++);
                }
                guest.setName(name);
                guest.setPhone(phone.getText().trim());

                if (isNew) {
                    reservation = new Reservation(nextReservationId++, checkIn, checkOut, selectedStatus, guest, selectedType);
                    reservations.add(reservation);
                } else {
                    reservation.setStartDate(checkIn);
                    reservation.setEndDate(checkOut);
                    reservation.setStatus(selectedStatus);
                    reservation.setGuest(guest);
                    reservation.setRoomType(selectedType);
                    reservation.getAssignedRooms().clear();
                }

                if (selectedRoom != null) {
                    reservation.addAssignedRoom(selectedRoom);
                }

                refreshTable();
                return;
            } catch (IllegalArgumentException exception) {
                JOptionPane.showMessageDialog(null, exception.getMessage(),
                        "Invalid Information", JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private RoomType findRoomType(String name) {
        for (RoomType type : roomTypes) {
            if (type.getName().equals(name)) {
                return type;
            }
        }
        throw new IllegalArgumentException("Please select a room type.");
    }

    private Room findRoom(String number) {
        for (Room room : rooms) {
            if (room.getRoomNumber().equals(number)) {
                return room;
            }
        }
        throw new IllegalArgumentException("Selected room not found.");
    }

    private boolean hasRoomConflict(Room room, LocalDate checkIn, LocalDate checkOut, Reservation editedReservation) {
        for (Reservation existing : reservations) {
            if (existing == editedReservation || "CANCELLED".equals(existing.getStatus())) {
                continue;
            }
            if (!existing.getStartDate().isBefore(checkOut) || !existing.getEndDate().isAfter(checkIn)) {
                continue;
            }
            for (Room assignedRoom : existing.getAssignedRooms()) {
                if (room.getRoomId().equals(assignedRoom.getRoomId())) {
                    return true;
                }
            }
        }
        return false;
    }

    private void editSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }
        showReservationDialog(reservations.get(reservationTable.convertRowIndexToModel(selectedRow)));
    }

    private void deleteSelectedReservation() {
        int selectedRow = reservationTable.getSelectedRow();
        if (selectedRow < 0) {
            showSelectReservationMessage();
            return;
        }
        int modelRow = reservationTable.convertRowIndexToModel(selectedRow);
        int result = JOptionPane.showConfirmDialog(null, "Delete the selected reservation?",
                "Confirmation", JOptionPane.YES_NO_OPTION, JOptionPane.QUESTION_MESSAGE);
        if (result == JOptionPane.YES_OPTION) {
            reservations.remove(modelRow);
            refreshTable();
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

    try (java.sql.Connection conn = hotel.model.DatabaseConnection.getConnection();
         java.sql.Statement stmt = conn.createStatement();
         java.sql.ResultSet rs = stmt.executeQuery(sql)) {

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
        javax.swing.JOptionPane.showMessageDialog(null, "Errol when loading data from MySQL: " + e.getMessage());
    }
}

    public static void main(String[] args) {
        SwingUtilities.invokeLater(HotelManagementUI::new);
    }
}
