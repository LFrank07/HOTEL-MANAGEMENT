package hotel.model;

import java.util.ArrayList;
import java.util.List;

public class Hotel {
    private Long hotelId;
    private String name;
    private String address;
    private List<Floor> floors = new ArrayList<>();
    private List<Room> rooms = new ArrayList<>();

    public Hotel() {}

    public Hotel(Long hotelId, String name, String address) {
        this.hotelId = hotelId;
        this.name = name;
        this.address = address;
    }

    public Long getHotelId() { return hotelId; }
    public void setHotelId(Long hotelId) { this.hotelId = hotelId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public List<Floor> getFloors() { return floors; }
    public void setFloors(List<Floor> floors) { this.floors = floors; }
    public List<Room> getRooms() { return rooms; }
    public void setRooms(List<Room> rooms) { this.rooms = rooms; }
}