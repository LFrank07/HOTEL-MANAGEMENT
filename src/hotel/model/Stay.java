package hotel.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class Stay {
    private Long stayId;
    private LocalDateTime checkIn;
    private LocalDateTime checkOut;

    private Reservation reservation;      // 1 Stay từ 1 Reservation
    private List<Room> rooms;             // AssignedTo
    private List<Service> services;       // Records

    public Stay() {
        this.rooms = new ArrayList<>();
        this.services = new ArrayList<>();
    }

    public Stay(Long stayId, LocalDateTime checkIn, LocalDateTime checkOut, Reservation reservation) {
        this();
        this.stayId = stayId;
        this.checkIn = checkIn;
        this.checkOut = checkOut;
        this.reservation = reservation;
    }

    public Long getStayId() { return stayId; }
    public void setStayId(Long stayId) { this.stayId = stayId; }

    public LocalDateTime getCheckIn() { return checkIn; }
    public void setCheckIn(LocalDateTime checkIn) { this.checkIn = checkIn; }

    public LocalDateTime getCheckOut() { return checkOut; }
    public void setCheckOut(LocalDateTime checkOut) { this.checkOut = checkOut; }

    public Reservation getReservation() { return reservation; }
    public void setReservation(Reservation reservation) { this.reservation = reservation; }

    public List<Room> getRooms() { return rooms; }
    public void setRooms(List<Room> rooms) { this.rooms = rooms; }

    public List<Service> getServices() { return services; }
    public void setServices(List<Service> services) { this.services = services; }

    public void addRoom(Room room) {
        if (room != null && !rooms.contains(room)) rooms.add(room);
    }

    public void addService(Service service) {
        if (service != null && !services.contains(service)) services.add(service);
    }
}