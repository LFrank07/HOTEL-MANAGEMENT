package hotel.model;

import java.util.ArrayList;
import java.util.List;

public class Hotel {
    private Long hotelId;
    private String name;
    private String address;
<<<<<<< HEAD
    private List<Floor> floors = new ArrayList<>();
=======

    // Quan hệ từ sơ đồ UML:
    // Hotel HAS (1 -> 0..*) Floor
    private List<Floor> floors = new ArrayList<>();

    // Hotel OWNS (1 -> 0..*) Room
>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
    private List<Room> rooms = new ArrayList<>();

    public Hotel() {}

    public Hotel(Long hotelId, String name, String address) {
        this.hotelId = hotelId;
        this.name = name;
        this.address = address;
    }

    public Long getHotelId() { return hotelId; }
    public void setHotelId(Long hotelId) { this.hotelId = hotelId; }
<<<<<<< HEAD
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public List<Floor> getFloors() { return floors; }
    public void setFloors(List<Floor> floors) { this.floors = floors; }
=======

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public List<Floor> getFloors() { return floors; }
    public void setFloors(List<Floor> floors) { this.floors = floors; }

>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
    public List<Room> getRooms() { return rooms; }
    public void setRooms(List<Room> rooms) { this.rooms = rooms; }
}