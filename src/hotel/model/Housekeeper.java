<<<<<<< HEAD
package hotel.model;

public class Housekeeper extends Staff {
    private String roomsAssigned;

    public Housekeeper() {
        super();
    }

=======
public class Housekeeper extends Staff {
    private String roomsAssigned;

>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
    public Housekeeper(String name, long staffId, String roomsAssigned) {
        super(name, staffId);
        this.roomsAssigned = roomsAssigned;
    }

    public String getRoomsAssigned() {
        return roomsAssigned;
    }

    public void setRoomsAssigned(String roomsAssigned) {
        this.roomsAssigned = roomsAssigned;
    }
}