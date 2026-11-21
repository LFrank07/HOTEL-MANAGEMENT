package hotel.model;

import javax.swing.*;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.FocusAdapter;
import java.awt.event.FocusEvent;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class HotelManagementUI {

    private final HotelAppDAO dao = new HotelAppDAO();

    // ================= DU LIEU CHUNG CHO TAB 1 =================
    private final DefaultTableModel roomTableModel = new DefaultTableModel(
            new Object[]{"Hotel ID", "Hotel", "Room", "Floor", "Type ID", "Room Type", "Capacity", "Price", "Status"}, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };
    private final JTable roomTable = new JTable(roomTableModel);

    private final DefaultTableModel reservationTableModel = new DefaultTableModel(
            new Object[]{"Res ID", "Guest", "Phone", "Room Type", "Room", "Check-in", "Check-out", "Status"}, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };
    private final JTable reservationTable = new JTable(reservationTableModel);

    // ================= DU LIEU CHUNG CHO TAB 2 =================
    private JComboBox<ComboItem> tab2HotelCombo;
    private JComboBox<ComboItem> tab2RoomTypeCombo;

    // ================= DU LIEU CHUNG CHO TAB 3 =================
    private final DefaultTableModel guestTableModel = new DefaultTableModel(
            new Object[]{"Guest ID", "Doc ID", "Name", "Phone"}, 0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };
    private final JTable guestTable = new JTable(guestTableModel);

    private static class ComboItem {
        final int id;
        final String label;

        ComboItem(int id, String label) {
            this.id = id;
            this.label = label;
        }

        @Override
        public String toString() {
            return label;
        }
    }

    public HotelManagementUI() {
        createWindow();
    }

    private void createWindow() {
        JFrame frame = new JFrame("Hotel Management");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setMinimumSize(new Dimension(1200, 690));
        frame.setLocationRelativeTo(null);

        JPanel root = new JPanel(new BorderLayout(0, 14));
        root.setBorder(BorderFactory.createEmptyBorder(18, 22, 18, 22));
        root.setBackground(new Color(245, 247, 250));

        JLabel title = new JLabel("HOTEL MANAGEMENT SYSTEM");
        title.setFont(new Font("Sans Serif", Font.BOLD, 22));
        title.setForeground(new Color(29, 48, 71));

        JLabel subtitle = new JLabel("Tab 1: Search & Booking  |  Tab 2: Add / Edit Hotel & Room  |  Tab 3: Guest Lookup & Edit");
        subtitle.setForeground(new Color(101, 114, 130));

        JPanel heading = new JPanel(new GridLayout(2, 1, 0, 3));
        heading.setOpaque(false);
        heading.add(title);
        heading.add(subtitle);
        root.add(heading, BorderLayout.NORTH);

        JTabbedPane tabs = new JTabbedPane();
        tabs.setFont(new Font("Sans Serif", Font.BOLD, 13));
        tabs.addTab("1. Search & Booking", buildTab1SearchAndBooking());
        tabs.addTab("2. Add / Edit Hotel & Room", buildTab2AddEditHotelAndRoom());
        tabs.addTab("3. Guest Lookup & Edit", buildTab3GuestLookupAndEdit());

        tabs.addChangeListener(e -> {
            if (tabs.getSelectedIndex() == 1) {
                reloadTab2Combos();
            }
        });

        root.add(tabs, BorderLayout.CENTER);
        frame.setContentPane(root);
        frame.setVisible(true);
    }

    // =========================================================================
    // ================================ TAB 1 ==================================
    // ============== TIM KHACH SAN, XEM PHONG, DAT PHONG, CHECK-OUT ===========
    // =========================================================================
    private JPanel buildTab1SearchAndBooking() {
        JPanel panel = new JPanel(new BorderLayout(0, 10));
        panel.setBorder(BorderFactory.createEmptyBorder(12, 8, 8, 8));
        panel.setOpaque(false);

        JTextField hotelSearchField = new JTextField(16);
        JTextField checkInField = new JTextField(LocalDate.now().toString(), 10);
        JTextField checkOutField = new JTextField(LocalDate.now().plusDays(1).toString(), 10);
        JCheckBox onlyAvailableBox = new JCheckBox("Only Available", true);
        JButton searchBtn = createButton("Search Rooms", new Color(29, 78, 137));
        JButton dueCheckoutBtn = createButton("Check Due Check-Out", new Color(181, 108, 22));

        JPanel topBar = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 4));
        topBar.setOpaque(false);
        topBar.add(new JLabel("Hotel Name:"));
        topBar.add(hotelSearchField);
        topBar.add(new JLabel("Check-in:"));
        topBar.add(checkInField);
        topBar.add(new JLabel("Check-out:"));
        topBar.add(checkOutField);
        topBar.add(onlyAvailableBox);
        topBar.add(searchBtn);
        topBar.add(dueCheckoutBtn);

        roomTable.setRowHeight(28);
        roomTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        roomTable.getTableHeader().setReorderingAllowed(false);
        roomTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected,
                                                           boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                int modelRow = table.convertRowIndexToModel(row);
                String st = String.valueOf(table.getModel().getValueAt(modelRow, 8));
                boolean isAvailable = "Available".equalsIgnoreCase(st);

                if (!isAvailable) {
                    c.setForeground(new Color(185, 38, 38));
                    c.setBackground(isSelected ? new Color(255, 210, 210) : new Color(253, 236, 236));
                } else {
                    c.setForeground(isSelected ? table.getSelectionForeground() : Color.BLACK);
                    c.setBackground(isSelected ? table.getSelectionBackground() : Color.WHITE);
                }
                return c;
            }
        });

        JTextField guestNameField = new JTextField(14);
        JTextField docIdField = new JTextField(11);
        JTextField phoneField = new JTextField(11);
        JTextField guestsCountField = new JTextField("1", 4);
        JButton bookBtn = createButton("Book Selected Room Type", new Color(34, 112, 90));

        JPanel bookingBar = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 6));
        bookingBar.setBorder(BorderFactory.createTitledBorder("Book From Selected Room"));
        bookingBar.setOpaque(false);
        bookingBar.add(new JLabel("Guest Name:"));
        bookingBar.add(guestNameField);
        bookingBar.add(new JLabel("Doc ID:"));
        bookingBar.add(docIdField);
        bookingBar.add(new JLabel("Phone:"));
        bookingBar.add(phoneField);
        bookingBar.add(new JLabel("Guests:"));
        bookingBar.add(guestsCountField);
        bookingBar.add(bookBtn);

        reservationTable.setRowHeight(28);
        reservationTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        reservationTable.getTableHeader().setReorderingAllowed(false);

        JButton loadReservationsBtn = createButton("Load Reservations", new Color(75, 85, 99));
        JButton checkInBtn = createButton("Check-In", new Color(26, 127, 150));
        JButton checkOutBtn = createButton("Check-Out", new Color(181, 108, 22));
        JButton paymentBtn = createButton("Payment", new Color(92, 68, 156));
        JButton deleteResBtn = createButton("Delete", new Color(174, 66, 66));

        JPanel resActions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 4));
        resActions.setOpaque(false);
        resActions.add(loadReservationsBtn);
        resActions.add(checkInBtn);
        resActions.add(checkOutBtn);
        resActions.add(paymentBtn);
        resActions.add(deleteResBtn);

        JPanel resSection = new JPanel(new BorderLayout(0, 6));
        resSection.setOpaque(false);
        resSection.add(bookingBar, BorderLayout.NORTH);
        resSection.add(new JScrollPane(reservationTable), BorderLayout.CENTER);
        resSection.add(resActions, BorderLayout.SOUTH);

        JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT, new JScrollPane(roomTable), resSection);
        split.setResizeWeight(0.45);

        panel.add(topBar, BorderLayout.NORTH);
        panel.add(split, BorderLayout.CENTER);

        searchBtn.addActionListener(e -> {
            try {
                LocalDate start = checkInField.getText().trim().isEmpty() ? null : LocalDate.parse(checkInField.getText().trim());
                LocalDate end = checkOutField.getText().trim().isEmpty() ? null : LocalDate.parse(checkOutField.getText().trim());
                if (start != null && end != null && end.isBefore(start)) {
                    throw new IllegalArgumentException("Check-out date cannot be before check-in date.");
                }
                List<HotelAppDAO.RoomOption> rooms = dao.searchRoomsByHotel(
                        hotelSearchField.getText(), start, end, onlyAvailableBox.isSelected());
                roomTableModel.setRowCount(0);
                for (HotelAppDAO.RoomOption r : rooms) {
                    String priceDisplay = HotelAppDAO.formatDotMoney(r.effectivePrice);
                    if (r.customRoomPrice != null) {
                        priceDisplay = priceDisplay + " *";
                    }
                    roomTableModel.addRow(new Object[]{
                            r.hotelId, r.hotelName, r.roomNumber, r.floorNumber,
                            r.typeId, r.roomTypeName, r.capacity, priceDisplay, r.roomStatus
                    });
                }
                if (rooms.isEmpty()) {
                    JOptionPane.showMessageDialog(panel, "No rooms matched your search.");
                }
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(panel, ex.getMessage(), "Search Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        dueCheckoutBtn.addActionListener(e -> showDueOrOverdueCheckouts(hotelSearchField.getText()));

        bookBtn.addActionListener(e -> {
            int row = roomTable.getSelectedRow();
            if (row < 0) {
                JOptionPane.showMessageDialog(panel, "Please select a room row first.");
                return;
            }
            try {
                int modelRow = roomTable.convertRowIndexToModel(row);
                String status = String.valueOf(roomTableModel.getValueAt(modelRow, 8));
                if (!"Available".equalsIgnoreCase(status)) {
                    throw new IllegalArgumentException("Selected room is not Available (" + status + ").");
                }
                int hotelId = ((Number) roomTableModel.getValueAt(modelRow, 0)).intValue();
                int typeId = ((Number) roomTableModel.getValueAt(modelRow, 4)).intValue();
                int capacity = ((Number) roomTableModel.getValueAt(modelRow, 6)).intValue();

                String gName = guestNameField.getText().trim();
                String docId = docIdField.getText().trim();
                String phone = phoneField.getText().trim();
                int noOfGuests = Integer.parseInt(guestsCountField.getText().trim());
                LocalDate start = LocalDate.parse(checkInField.getText().trim());
                LocalDate end = LocalDate.parse(checkOutField.getText().trim());

                if (gName.isEmpty()) throw new IllegalArgumentException("Guest Name is required.");
                if (noOfGuests <= 0 || noOfGuests > capacity) {
                    throw new IllegalArgumentException("Guests must be between 1 and " + capacity + ".");
                }
                if (end.isBefore(start)) {
                    throw new IllegalArgumentException("Check-out date cannot be before check-in date.");
                }

                int resId = dao.createReservation(hotelId, typeId, start, end, noOfGuests, docId, gName, phone);
                JOptionPane.showMessageDialog(panel, "Created Reservation #" + resId + " successfully.");
                loadReservationsTable();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(panel, ex.getMessage(), "Booking Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        loadReservationsBtn.addActionListener(e -> loadReservationsTable());
        checkInBtn.addActionListener(e -> checkInSelectedReservation());
        checkOutBtn.addActionListener(e -> checkOutSelectedReservation());
        paymentBtn.addActionListener(e -> recordPaymentForSelectedReservation());
        deleteResBtn.addActionListener(e -> deleteSelectedReservation());

        return panel;
    }

    private void showDueOrOverdueCheckouts(String hotelKeyword) {
        try {
            List<HotelAppDAO.CheckoutAlertRoom> alerts = dao.getRoomsDueOrOverdueCheckout(hotelKeyword);
            if (alerts.isEmpty()) {
                JOptionPane.showMessageDialog(null,
                        "No active rooms are due today or overdue for check-out.",
                        "Check-Out Status", JOptionPane.INFORMATION_MESSAGE);
                return;
            }
            DefaultTableModel alertModel = new DefaultTableModel(
                    new Object[]{"Alert", "Hotel", "Room", "Stay ID", "Res ID", "Guest", "Check-In", "End Date"}, 0) {
                @Override
                public boolean isCellEditable(int row, int column) {
                    return false;
                }
            };
            for (HotelAppDAO.CheckoutAlertRoom a : alerts) {
                alertModel.addRow(new Object[]{
                        a.alertStatus, a.hotelName, a.roomNumber, a.stayId,
                        a.reservationId, a.guestName, a.checkInDate, a.expectedEndDate
                });
            }
            JTable alertTable = new JTable(alertModel);
            alertTable.setRowHeight(26);
            JScrollPane sp = new JScrollPane(alertTable);
            sp.setPreferredSize(new Dimension(780, 260));
            JOptionPane.showMessageDialog(null, sp, "Rooms Due / Overdue Check-Out", JOptionPane.WARNING_MESSAGE);
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Check-Out Alert Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    // =========================================================================
    // ================================ TAB 2 ==================================
    // =========== THEM KHACH SAN, LOAI PHONG, TAO PHONG & EDIT PHONG =========
    // =========================================================================
   private JPanel buildTab2AddEditHotelAndRoom() {
        JPanel container = new JPanel(new GridLayout(1, 2, 18, 0));
        container.setBorder(BorderFactory.createEmptyBorder(14, 10, 14, 10));
        container.setOpaque(false);

        tab2HotelCombo = new JComboBox<>();
        tab2RoomTypeCombo = new JComboBox<>();
        tab2HotelCombo.addActionListener(e -> reloadRoomTypesForSelectedHotel());

        // --- Cot trai Tab 2: Them Hotel + Them RoomType (co pham vi rieng cho 1 Hotel) ---
        JPanel hotelCard = new JPanel(new GridLayout(0, 2, 8, 8));
        hotelCard.setBorder(BorderFactory.createTitledBorder("Add New Hotel"));
        JTextField hotelNameField = new JTextField(18);
        JTextField hotelAddressField = new JTextField(18);
        JButton saveHotelBtn = createButton("Save Hotel", new Color(34, 112, 90));

        hotelCard.add(new JLabel("Hotel Name:"));
        hotelCard.add(hotelNameField);
        hotelCard.add(new JLabel("Address:"));
        hotelCard.add(hotelAddressField);
        hotelCard.add(new JLabel(""));
        hotelCard.add(saveHotelBtn);

        saveHotelBtn.addActionListener(e -> {
            try {
                String name = hotelNameField.getText().trim();
                String addr = hotelAddressField.getText().trim();
                if (name.isEmpty() || addr.isEmpty()) {
                    throw new IllegalArgumentException("Please enter both Hotel Name and Address.");
                }
                int id = dao.addHotel(name, addr);
                hotelNameField.setText("");
                hotelAddressField.setText("");
                reloadTab2Combos();
                JOptionPane.showMessageDialog(container, "Hotel added with ID #" + id + ".");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(container, ex.getMessage(), "Add Hotel Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel roomTypeCard = new JPanel(new GridLayout(0, 2, 8, 6));
        roomTypeCard.setBorder(BorderFactory.createTitledBorder("Add Room Type / Special Extra Type"));
        JTextField typeNameField = new JTextField(16);
        JTextField basePriceField = new JTextField("1.000.000", 16);
        attachDotMoneyFormatter(basePriceField);
        JTextField capacityField = new JTextField("2", 16);
        JCheckBox onlyThisHotelBox = new JCheckBox("Extra only for selected Hotel", true);
        JButton saveTypeBtn = createButton("Save Room Type", new Color(92, 68, 156));

        roomTypeCard.add(new JLabel("Type Name:"));
        roomTypeCard.add(typeNameField);
        roomTypeCard.add(new JLabel("Default Price:"));
        roomTypeCard.add(basePriceField);
        roomTypeCard.add(new JLabel("Capacity (1-5):"));
        roomTypeCard.add(capacityField);
        roomTypeCard.add(new JLabel("Scope:"));
        roomTypeCard.add(onlyThisHotelBox);
        roomTypeCard.add(new JLabel(""));
        roomTypeCard.add(saveTypeBtn);

        saveTypeBtn.addActionListener(e -> {
            try {
                String tName = typeNameField.getText().trim();
                BigDecimal price = HotelAppDAO.parseDotMoney(basePriceField.getText());
                if (price == null) {
                    throw new IllegalArgumentException("Please enter a valid price.");
                }
                basePriceField.setText(HotelAppDAO.formatDotMoney(price));
                int cap = Integer.parseInt(capacityField.getText().trim());
                ComboItem selectedHotel = (ComboItem) tab2HotelCombo.getSelectedItem();
                if (onlyThisHotelBox.isSelected() && selectedHotel == null) {
                    throw new IllegalArgumentException("Please select a Hotel on the right first.");
                }
                Integer targetHotelId = onlyThisHotelBox.isSelected() ? selectedHotel.id : null;
                int typeId = dao.addRoomType(tName, price, cap, targetHotelId);
                typeNameField.setText("");
                reloadRoomTypesForSelectedHotel();
                JOptionPane.showMessageDialog(container, "Room Type #" + typeId + " (" + tName + ") added.");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(container, ex.getMessage(), "Add Room Type Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel leftStack = new JPanel(new GridLayout(2, 1, 0, 12));
        leftStack.setOpaque(false);
        leftStack.add(hotelCard);
        leftStack.add(roomTypeCard);

        // --- Cot phai Tab 2: Them phong (gia rieng tung hotel) + Edit phong + Tao nhanh nhieu tang ---
        JPanel addRoomCard = new JPanel(new GridLayout(0, 2, 8, 6));
        addRoomCard.setBorder(BorderFactory.createTitledBorder("Add Room(s) — Single / List (101, 102, 104) / Range (101-105)"));
        JTextField roomsPatternField = new JTextField("101-105", 14);
        JTextField floorNumberField = new JTextField("1", 14);
        JTextField addRoomPriceField = new JTextField("", 14);
        attachDotMoneyFormatter(addRoomPriceField);
        JComboBox<String> roomStatusCombo = new JComboBox<>(new String[]{"Available", "Occupied", "Maintenance"});
        JButton saveRoomsBtn = createButton("Save Room(s)", new Color(29, 78, 137));
        JButton deleteHotelBtn = createButton("Delete Hotel", new Color(174, 66, 66));

        JPanel hotelSelectorRow = new JPanel(new BorderLayout(6, 0));
        hotelSelectorRow.setOpaque(false);
        hotelSelectorRow.add(tab2HotelCombo, BorderLayout.CENTER);
        hotelSelectorRow.add(deleteHotelBtn, BorderLayout.EAST);

        addRoomCard.add(new JLabel("Hotel:"));
        addRoomCard.add(hotelSelectorRow);
        addRoomCard.add(new JLabel("Room No / List / Range:"));
        addRoomCard.add(roomsPatternField);
        addRoomCard.add(new JLabel("Floor Number:"));
        addRoomCard.add(floorNumberField);
        addRoomCard.add(new JLabel("Room Type:"));
        addRoomCard.add(tab2RoomTypeCombo);
        addRoomCard.add(new JLabel("Custom Price (blank = default):"));
        addRoomCard.add(addRoomPriceField);
        addRoomCard.add(new JLabel("Status:"));
        addRoomCard.add(roomStatusCombo);
        addRoomCard.add(new JLabel(""));
        addRoomCard.add(saveRoomsBtn);

        deleteHotelBtn.addActionListener(e -> {
            ComboItem selectedHotel = (ComboItem) tab2HotelCombo.getSelectedItem();
            if (selectedHotel == null) {
                JOptionPane.showMessageDialog(container, "Please select a Hotel first.");
                return;
            }
            int confirm = JOptionPane.showConfirmDialog(
                    container,
                    "Delete hotel '" + selectedHotel.label + "'?\nRooms and Extra room types belonging to this hotel will also be removed.",
                    "Confirm Delete Hotel",
                    JOptionPane.YES_NO_OPTION
            );
            if (confirm == JOptionPane.YES_OPTION) {
                try {
                    dao.deleteHotel(selectedHotel.id);
                    reloadTab2Combos();
                    JOptionPane.showMessageDialog(container, "Hotel deleted successfully.");
                } catch (Exception ex) {
                    JOptionPane.showMessageDialog(container, ex.getMessage(), "Delete Hotel Error", JOptionPane.WARNING_MESSAGE);
                }
            }
        });

        saveRoomsBtn.addActionListener(e -> {
            try {
                ComboItem selectedHotel = (ComboItem) tab2HotelCombo.getSelectedItem();
                ComboItem selectedType = (ComboItem) tab2RoomTypeCombo.getSelectedItem();
                if (selectedHotel == null || selectedType == null) {
                    throw new IllegalArgumentException("Please select a Hotel and a Room Type.");
                }
                int floor = Integer.parseInt(floorNumberField.getText().trim());
                String st = String.valueOf(roomStatusCombo.getSelectedItem());
                BigDecimal customPrice = HotelAppDAO.parseDotMoney(addRoomPriceField.getText());
                if (customPrice != null) {
                    addRoomPriceField.setText(HotelAppDAO.formatDotMoney(customPrice));
                }
                int added = dao.addRoomsByPattern(selectedHotel.id, floor, roomsPatternField.getText(),
                        selectedType.id, st, customPrice);
                JOptionPane.showMessageDialog(container, "Saved " + added + " room(s) on Floor " + floor + ".");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(container, ex.getMessage(), "Add Room Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel editRoomCard = new JPanel(new GridLayout(0, 2, 8, 6));
        editRoomCard.setBorder(BorderFactory.createTitledBorder("Edit Existing Room (Number / Type / Price / Status)"));
        JTextField oldRoomField = new JTextField(12);
        JTextField newRoomField = new JTextField(12);
        JTextField editFloorField = new JTextField("1", 12);
        JTextField editRoomPriceField = new JTextField("", 12);
        attachDotMoneyFormatter(editRoomPriceField);
        JComboBox<String> editStatusCombo = new JComboBox<>(new String[]{"Available", "Occupied", "Maintenance"});
        JButton updateRoomBtn = createButton("Update Room", new Color(54, 91, 135));

        editRoomCard.add(new JLabel("Current Room No:"));
        editRoomCard.add(oldRoomField);
        editRoomCard.add(new JLabel("New Room No:"));
        editRoomCard.add(newRoomField);
        editRoomCard.add(new JLabel("New Floor:"));
        editRoomCard.add(editFloorField);
        editRoomCard.add(new JLabel("New Price (blank = default):"));
        editRoomCard.add(editRoomPriceField);
        editRoomCard.add(new JLabel("New Status:"));
        editRoomCard.add(editStatusCombo);
        editRoomCard.add(new JLabel(""));
        editRoomCard.add(updateRoomBtn);

        updateRoomBtn.addActionListener(e -> {
            try {
                ComboItem selectedHotel = (ComboItem) tab2HotelCombo.getSelectedItem();
                ComboItem selectedType = (ComboItem) tab2RoomTypeCombo.getSelectedItem();
                if (selectedHotel == null || selectedType == null) {
                    throw new IllegalArgumentException("Please select a Hotel and a Room Type.");
                }
                String oldNo = oldRoomField.getText().trim();
                String newNo = newRoomField.getText().trim().isEmpty() ? oldNo : newRoomField.getText().trim();
                int fl = Integer.parseInt(editFloorField.getText().trim());
                String st = String.valueOf(editStatusCombo.getSelectedItem());
                BigDecimal customPrice = HotelAppDAO.parseDotMoney(editRoomPriceField.getText());
                if (customPrice != null) {
                    editRoomPriceField.setText(HotelAppDAO.formatDotMoney(customPrice));
                }
                dao.updateRoom(selectedHotel.id, oldNo, newNo, fl, selectedType.id, st, customPrice);
                JOptionPane.showMessageDialog(container, "Updated room " + oldNo + " -> " + newNo + ".");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(container, ex.getMessage(), "Update Room Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel quickBatchCard = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 6));
        quickBatchCard.setBorder(BorderFactory.createTitledBorder("Quick Generate Floors x Rooms"));
        JTextField floorsField = new JTextField("6", 4);
        JTextField perFloorField = new JTextField("10", 4);
        JButton generateBtn = createButton("Generate", new Color(75, 85, 99));
        quickBatchCard.add(new JLabel("Floors:"));
        quickBatchCard.add(floorsField);
        quickBatchCard.add(new JLabel("Rooms/Floor:"));
        quickBatchCard.add(perFloorField);
        quickBatchCard.add(generateBtn);

        generateBtn.addActionListener(e -> {
            try {
                ComboItem selectedHotel = (ComboItem) tab2HotelCombo.getSelectedItem();
                if (selectedHotel == null) {
                    throw new IllegalArgumentException("Please select a Hotel first.");
                }
                int floors = Integer.parseInt(floorsField.getText().trim());
                int perFloor = Integer.parseInt(perFloorField.getText().trim());
                int created = dao.generateRoomsForHotel(selectedHotel.id, floors, perFloor);
                JOptionPane.showMessageDialog(container, "Generated " + created + " room(s).");
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(container, ex.getMessage(), "Generate Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        JPanel rightStack = new JPanel(new BorderLayout(0, 8));
        rightStack.setOpaque(false);
        rightStack.add(addRoomCard, BorderLayout.NORTH);
        rightStack.add(editRoomCard, BorderLayout.CENTER);
        rightStack.add(quickBatchCard, BorderLayout.SOUTH);

        container.add(leftStack);
        container.add(rightStack);
        return container;
    }

    private void reloadRoomTypesForSelectedHotel() {
        if (tab2RoomTypeCombo == null) return;
        try {
            ComboItem h = (ComboItem) tab2HotelCombo.getSelectedItem();
            Integer hId = (h != null) ? h.id : null;
            tab2RoomTypeCombo.removeAllItems();
            for (Map.Entry<Integer, String> entry : dao.getRoomTypesForHotel(hId).entrySet()) {
                tab2RoomTypeCombo.addItem(new ComboItem(entry.getKey(), entry.getValue()));
            }
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Load Room Type Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void reloadTab2Combos() {
        if (tab2HotelCombo == null || tab2RoomTypeCombo == null) return;
        try {
            tab2HotelCombo.removeAllItems();
            for (Map.Entry<Integer, String> entry : dao.getHotels().entrySet()) {
                tab2HotelCombo.addItem(new ComboItem(entry.getKey(), entry.getValue()));
            }
            reloadRoomTypesForSelectedHotel();
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Load Combo Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    // =========================================================================
    // ================================ TAB 3 ==================================
    // =================== TRA CUU & SUA THONG TIN KHACH HANG ==================
    // =========================================================================
    private JPanel buildTab3GuestLookupAndEdit() {
        JPanel panel = new JPanel(new BorderLayout(0, 12));
        panel.setBorder(BorderFactory.createEmptyBorder(12, 8, 8, 8));
        panel.setOpaque(false);

        JTextField keywordField = new JTextField(22);
        JButton searchGuestBtn = createButton("Search Guest", new Color(29, 78, 137));

        JPanel topBar = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 4));
        topBar.setOpaque(false);
        topBar.add(new JLabel("Name / Doc ID / Phone:"));
        topBar.add(keywordField);
        topBar.add(searchGuestBtn);

        guestTable.setRowHeight(28);
        guestTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        guestTable.getTableHeader().setReorderingAllowed(false);

        JTextField editNameField = new JTextField(16);
        JTextField editDocField = new JTextField(14);
        JTextField editPhoneField = new JTextField(14);
        JButton saveGuestBtn = createButton("Save Guest Info", new Color(34, 112, 90));

        final int[] selectedGuestId = {-1};
        final String[] originalPhone = {""};

        guestTable.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                int row = guestTable.getSelectedRow();
                if (row >= 0) {
                    int mRow = guestTable.convertRowIndexToModel(row);
                    selectedGuestId[0] = ((Number) guestTableModel.getValueAt(mRow, 0)).intValue();
                    editDocField.setText(String.valueOf(guestTableModel.getValueAt(mRow, 1)));
                    editNameField.setText(String.valueOf(guestTableModel.getValueAt(mRow, 2)));
                    String p = String.valueOf(guestTableModel.getValueAt(mRow, 3));
                    editPhoneField.setText(p);
                    originalPhone[0] = p;
                }
            }
        });

        JPanel editBar = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 6));
        editBar.setBorder(BorderFactory.createTitledBorder("Edit Selected Guest"));
        editBar.setOpaque(false);
        editBar.add(new JLabel("Name:"));
        editBar.add(editNameField);
        editBar.add(new JLabel("Doc ID:"));
        editBar.add(editDocField);
        editBar.add(new JLabel("Phone:"));
        editBar.add(editPhoneField);
        editBar.add(saveGuestBtn);

        searchGuestBtn.addActionListener(e -> {
            try {
                List<HotelAppDAO.GuestSummary> guests = dao.searchGuests(keywordField.getText());
                guestTableModel.setRowCount(0);
                for (HotelAppDAO.GuestSummary g : guests) {
                    guestTableModel.addRow(new Object[]{g.guestId, g.docId, g.name, g.phone});
                }
                if (guests.isEmpty()) {
                    JOptionPane.showMessageDialog(panel, "No guests found.");
                }
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(panel, ex.getMessage(), "Search Guest Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        saveGuestBtn.addActionListener(e -> {
            if (selectedGuestId[0] < 0) {
                JOptionPane.showMessageDialog(panel, "Please select a guest in the table first.");
                return;
            }
            try {
                String nName = editNameField.getText().trim();
                String nDoc = editDocField.getText().trim();
                String nPhone = editPhoneField.getText().trim();
                if (nName.isEmpty() || nDoc.isEmpty()) {
                    throw new IllegalArgumentException("Guest Name and Doc ID cannot be empty.");
                }
                dao.updateGuest(selectedGuestId[0], nDoc, nName, originalPhone[0], nPhone);
                originalPhone[0] = nPhone;
                JOptionPane.showMessageDialog(panel, "Guest information updated.");
                List<HotelAppDAO.GuestSummary> guests = dao.searchGuests(keywordField.getText());
                guestTableModel.setRowCount(0);
                for (HotelAppDAO.GuestSummary g : guests) {
                    guestTableModel.addRow(new Object[]{g.guestId, g.docId, g.name, g.phone});
                }
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(panel, ex.getMessage(), "Update Guest Error", JOptionPane.WARNING_MESSAGE);
            }
        });

        panel.add(topBar, BorderLayout.NORTH);
        panel.add(new JScrollPane(guestTable), BorderLayout.CENTER);
        panel.add(editBar, BorderLayout.SOUTH);
        return panel;
    }

    // ================= CAC HAM HO TRO DAT PHONG / CHECK-IN / CHECK-OUT =================
    private void attachDotMoneyFormatter(JTextField field) {
        field.addFocusListener(new FocusAdapter() {
            @Override
            public void focusLost(FocusEvent e) {
                try {
                    BigDecimal val = HotelAppDAO.parseDotMoney(field.getText());
                    if (val != null) {
                        field.setText(HotelAppDAO.formatDotMoney(val));
                    }
                } catch (Exception ignored) {
                }
            }
        });
    }

    private void loadReservationsTable() {
        reservationTableModel.setRowCount(0);
        String sql = "SELECT r.Reservation_ID, g.Name AS guest_name, MIN(gp.Phone) AS phone, " +
                "rt.Name AS room_type_name, s.Room_Number AS room_number, r.StartDate, r.EndDate, r.BookingStatus " +
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
                reservationTableModel.addRow(new Object[]{
                        rs.getLong("Reservation_ID"),
                        rs.getString("guest_name"),
                        rs.getString("phone") != null ? rs.getString("phone") : "",
                        rs.getString("room_type_name") != null ? rs.getString("room_type_name").trim() : "",
                        rs.getString("room_number") != null ? rs.getString("room_number") : "Unassigned",
                        rs.getDate("StartDate") != null ? rs.getDate("StartDate").toLocalDate() : null,
                        rs.getDate("EndDate") != null ? rs.getDate("EndDate").toLocalDate() : null,
                        rs.getString("BookingStatus")
                });
            }
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void checkInSelectedReservation() {
        int row = reservationTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(null, "Please select a reservation first.");
            return;
        }
        int mRow = reservationTable.convertRowIndexToModel(row);
        long resId = ((Number) reservationTableModel.getValueAt(mRow, 0)).longValue();
        try (Connection conn = DatabaseConnection.getConnection()) {
            int hotelId;
            int typeId;
            try (PreparedStatement ps = conn.prepareStatement("SELECT Hotel_ID, TypeID FROM Reservation WHERE Reservation_ID = ?")) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return;
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
                    while (rs.next()) rooms.add(rs.getString("Room_Number"));
                }
            }
            if (rooms.isEmpty()) {
                JOptionPane.showMessageDialog(null, "No Available room for this reservation.");
                return;
            }
            String roomNum = (String) JOptionPane.showInputDialog(null, "Pick a room:", "Check-In",
                    JOptionPane.PLAIN_MESSAGE, null, rooms.toArray(), rooms.get(0));
            if (roomNum == null) return;

            conn.setAutoCommit(false);
            try {
                long nextInv = 1, nextStay = 1;
                try (Statement st = conn.createStatement()) {
                    try (ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(Invoice_ID), 0) + 1 FROM Invoices")) {
                        if (rs.next()) nextInv = rs.getLong(1);
                    }
                    try (ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(StayID), 0) + 1 FROM Stays")) {
                        if (rs.next()) nextStay = rs.getLong(1);
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Invoices (Invoice_ID, IssueDate, Status) VALUES (?, CURRENT_DATE(), 'Open')")) {
                    ps.setLong(1, nextInv);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Stays (StayID, CheckIn, Checkout, Reservation_ID, Invoice_ID, Hotel_ID, Room_Number) VALUES (?, NOW(), NULL, ?, ?, ?, ?)")) {
                    ps.setLong(1, nextStay);
                    ps.setLong(2, resId);
                    ps.setLong(3, nextInv);
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
                loadReservationsTable();
                JOptionPane.showMessageDialog(null, "Checked-In to Room " + roomNum + ".");
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Check-In Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void checkOutSelectedReservation() {
        int row = reservationTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(null, "Please select a reservation first.");
            return;
        }
        int mRow = reservationTable.convertRowIndexToModel(row);
        long resId = ((Number) reservationTableModel.getValueAt(mRow, 0)).longValue();
        try (Connection conn = DatabaseConnection.getConnection()) {
            dao.ensureExtendedColumns(conn);
            long stayId, invoiceId;
            int hotelId, typeId;
            String roomNum;
            LocalDate checkInDate;
            BigDecimal basePrice, customRoomPrice;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT s.StayID, s.Invoice_ID, s.Hotel_ID, s.Room_Number, s.CheckIn, " +
                            "r.TypeID, rt.BasePrice, rm.RoomPrice " +
                            "FROM Stays s " +
                            "JOIN Reservation r ON s.Reservation_ID = r.Reservation_ID " +
                            "JOIN RoomType rt ON r.TypeID = rt.TypeID " +
                            "LEFT JOIN Room rm ON s.Hotel_ID = rm.Hotel_ID AND s.Room_Number = rm.Room_Number " +
                            "WHERE s.Reservation_ID = ? AND s.Checkout IS NULL")) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        JOptionPane.showMessageDialog(null, "No active stay for Reservation #" + resId);
                        return;
                    }
                    stayId = rs.getLong("StayID");
                    invoiceId = rs.getLong("Invoice_ID");
                    hotelId = rs.getInt("Hotel_ID");
                    typeId = rs.getInt("TypeID");
                    roomNum = rs.getString("Room_Number");
                    checkInDate = rs.getDate("CheckIn").toLocalDate();
                    basePrice = rs.getBigDecimal("BasePrice");
                    customRoomPrice = rs.getBigDecimal("RoomPrice");
                }
            }

            // Tinh tien theo tung dem (RatePlan/HasRate > RoomPrice > BasePrice) va gom cac dem cung don gia
            long nights = Math.max(1L, ChronoUnit.DAYS.between(checkInDate, LocalDate.now()));
            Map<BigDecimal, Integer> rateToNights = new LinkedHashMap<>();
            for (long i = 0; i < nights; i++) {
                LocalDate night = checkInDate.plusDays(i);
                BigDecimal nightlyRate = dao.resolveNightlyRate(conn, typeId, night, customRoomPrice, basePrice);
                rateToNights.put(nightlyRate, rateToNights.getOrDefault(nightlyRate, 0) + 1);
            }

            BigDecimal grandRoomTotal = BigDecimal.ZERO;

            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Stays SET Checkout = NOW() WHERE StayID = ?")) {
                    ps.setLong(1, stayId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Reservation SET BookingStatus = 'CheckedOut' WHERE Reservation_ID = ?")) {
                    ps.setLong(1, resId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Room SET RoomStatus = 'Available' WHERE Hotel_ID = ? AND Room_Number = ?")) {
                    ps.setInt(1, hotelId);
                    ps.setString(2, roomNum);
                    ps.executeUpdate();
                }

                int nextLineId = 1;
                try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(MAX(LineID), 0) + 1 FROM InvoiceLine WHERE Invoice_ID = ?")) {
                    ps.setLong(1, invoiceId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) nextLineId = rs.getInt(1);
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO InvoiceLine (LineID, Invoice_ID, Type, Amount, Description) VALUES (?, ?, 'Room', ?, ?)")) {
                    for (Map.Entry<BigDecimal, Integer> entry : rateToNights.entrySet()) {
                        BigDecimal unitRate = entry.getKey();
                        int countNights = entry.getValue();
                        BigDecimal lineAmount = unitRate.multiply(BigDecimal.valueOf(countNights));
                        grandRoomTotal = grandRoomTotal.add(lineAmount);

                        ps.setInt(1, nextLineId++);
                        ps.setLong(2, invoiceId);
                        ps.setBigDecimal(3, lineAmount);
                        ps.setString(4, countNights + " night(s) @ " + HotelAppDAO.formatDotMoney(unitRate));
                        ps.executeUpdate();
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement("UPDATE Invoices SET Status = 'Unpaid' WHERE Invoice_ID = ?")) {
                    ps.setLong(1, invoiceId);
                    ps.executeUpdate();
                }
                conn.commit();
                loadReservationsTable();
                JOptionPane.showMessageDialog(null, "Checked-Out (" + nights + " night(s)). Total: " + HotelAppDAO.formatDotMoney(grandRoomTotal));
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Check-Out Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void recordPaymentForSelectedReservation() {
        int row = reservationTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(null, "Please select a reservation first.");
            return;
        }
        int mRow = reservationTable.convertRowIndexToModel(row);
        long resId = ((Number) reservationTableModel.getValueAt(mRow, 0)).longValue();
        try (Connection conn = DatabaseConnection.getConnection()) {
            long invoiceId;
            try (PreparedStatement ps = conn.prepareStatement("SELECT Invoice_ID FROM Stays WHERE Reservation_ID = ?")) {
                ps.setLong(1, resId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        JOptionPane.showMessageDialog(null, "No invoice found for Reservation #" + resId);
                        return;
                    }
                    invoiceId = rs.getLong("Invoice_ID");
                }
            }
            BigDecimal total = BigDecimal.ZERO, paid = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(SUM(Amount), 0) FROM InvoiceLine WHERE Invoice_ID = ?")) {
                ps.setLong(1, invoiceId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) total = rs.getBigDecimal(1);
                }
            }
            try (PreparedStatement ps = conn.prepareStatement("SELECT COALESCE(SUM(Amount), 0) FROM Payment WHERE Invoice_ID = ?")) {
                ps.setLong(1, invoiceId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) paid = rs.getBigDecimal(1);
                }
            }
            BigDecimal remaining = total.subtract(paid);
            if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
                JOptionPane.showMessageDialog(null, "Invoice already paid.");
                return;
            }
            String formattedRemaining = HotelAppDAO.formatDotMoney(remaining);
            String input = JOptionPane.showInputDialog(null,
                    "Remaining: " + formattedRemaining + "\nEnter payment amount:", formattedRemaining);
            if (input == null) return;
            BigDecimal amount = HotelAppDAO.parseDotMoney(input);
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0 || amount.compareTo(remaining) > 0) {
                throw new IllegalArgumentException("Invalid payment amount.");
            }
            conn.setAutoCommit(false);
            try {
                long nextPayId = 1;
                try (Statement st = conn.createStatement();
                     ResultSet rs = st.executeQuery("SELECT COALESCE(MAX(PaymentID), 0) + 1 FROM Payment")) {
                    if (rs.next()) nextPayId = rs.getLong(1);
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Payment (PaymentID, PaidDate, Method, Amount, Invoice_ID) VALUES (?, NOW(), 'Cash', ?, ?)")) {
                    ps.setLong(1, nextPayId);
                    ps.setBigDecimal(2, amount);
                    ps.setLong(3, invoiceId);
                    ps.executeUpdate();
                }
                String newStatus = paid.add(amount).compareTo(total) >= 0 ? "Paid" : "PartiallyPaid";
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Invoices SET Status = ? WHERE Invoice_ID = ?")) {
                    ps.setString(1, newStatus);
                    ps.setLong(2, invoiceId);
                    ps.executeUpdate();
                }
                conn.commit();
                JOptionPane.showMessageDialog(null, "Payment recorded. Invoice status: " + newStatus);
            } catch (Exception ex) {
                conn.rollback();
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception ex) {
            JOptionPane.showMessageDialog(null, ex.getMessage(), "Payment Error", JOptionPane.WARNING_MESSAGE);
        }
    }

    private void deleteSelectedReservation() {
        int row = reservationTable.getSelectedRow();
        if (row < 0) {
            JOptionPane.showMessageDialog(null, "Please select a reservation first.");
            return;
        }
        int mRow = reservationTable.convertRowIndexToModel(row);
        long resId = ((Number) reservationTableModel.getValueAt(mRow, 0)).longValue();
        int confirm = JOptionPane.showConfirmDialog(null,
                "Delete Reservation #" + resId + "?", "Confirm", JOptionPane.YES_NO_OPTION);
        if (confirm == JOptionPane.YES_OPTION) {
            try (Connection conn = DatabaseConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement("DELETE FROM Reservation WHERE Reservation_ID = ?")) {
                ps.setLong(1, resId);
                ps.executeUpdate();
                loadReservationsTable();
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(null, ex.getMessage(), "Delete Error", JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private JButton createButton(String text, Color color) {
        JButton button = new JButton(text);
        button.setForeground(Color.WHITE);
        button.setBackground(color);
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createEmptyBorder(7, 11, 7, 11));
        return button;
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(HotelManagementUI::new);
    }
}
