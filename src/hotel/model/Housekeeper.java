public class Housekeeper extends Staff {
    private String roomsAssigned;

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