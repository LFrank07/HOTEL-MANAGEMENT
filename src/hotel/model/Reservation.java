import hotel.model.Guest;
import hotel.model.Room;
import hotel.model.RoomType;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class Reservation {
    // 1. Attributes từ thiết kế Class Diagram
    private Long reservationId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status; // Ví dụ: "PENDING", "CONFIRMED", "CANCELLED", "COMPLETED"

    // 2. Relationships (Mối quan hệ)
    // - MAKES: Một Reservation thuộc về 1 Guest (1-to-many từ Guest)
    private Guest guest;

    // - REQUESTED_AS: Đặt theo loại phòng RoomType (1-to-many từ RoomType)
    private RoomType roomType;

    // - ASSIGNED_TO: Danh sách các Room được gán cho đơn đặt này (0..* rooms)
    private List<Room> assignedRooms;

    // - BECOMES: Đơn đặt chỗ sẽ chuyển thành 1 Stay (0..1 Stay)
    private Stay stay;

    // Default Constructor
    public Reservation() {
        this.assignedRooms = new ArrayList<>();
    }

    // Constructor cơ bản
    public Reservation(Long reservationId, LocalDate startDate, LocalDate endDate, String status, Guest guest, RoomType roomType) {
        this.reservationId = reservationId;
        this.startDate = startDate;
        this.endDate = endDate;
        this.status = status;
        this.guest = guest;
        this.roomType = roomType;
        this.assignedRooms = new ArrayList<>();
    }

    // Getters and Setters
    public Long getReservationId() {
        return reservationId;
    }

    public void setReservationId(Long reservationId) {
        this.reservationId = reservationId;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Guest getGuest() {
        return guest;
    }

    public void setGuest(Guest guest) {
        this.guest = guest;
    }

    public RoomType getRoomType() {
        return roomType;
    }

    public void setRoomType(RoomType roomType) {
        this.roomType = roomType;
    }

    public List<Room> getAssignedRooms() {
        return assignedRooms;
    }

    public void setAssignedRooms(List<Room> assignedRooms) {
        this.assignedRooms = assignedRooms;
    }

    public Stay getStay() {
        return stay;
    }

    public void setStay(Stay stay) {
        this.stay = stay;
    }

    // Helper methods quản lý danh sách phòng gán cho Reservation
    public void addAssignedRoom(Room room) {
        if (room != null && !this.assignedRooms.contains(room)) {
            this.assignedRooms.add(room);
        }
    }

    public void removeAssignedRoom(Room room) {
        this.assignedRooms.remove(room);
    }

    @Override
    public String toString() {
        return "Reservation{" +
                "reservationId=" + reservationId +
                ", startDate=" + startDate +
                ", endDate=" + endDate +
                ", status='" + status + '\'' +
                ", guest=" + (guest != null ? guest.getName() : "N/A") +
                ", roomType=" + (roomType != null ? roomType.getName() : "N/A") +
                ", assignedRoomsCount=" + assignedRooms.size() +
                '}';
    }
}