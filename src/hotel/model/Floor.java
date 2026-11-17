package hotel.model;

public class Floor {
    private Long floorId;
    private Integer floorNumber;

    public Floor() {}

    public Floor(Long floorId, Integer floorNumber) {
        this.floorId = floorId;
        this.floorNumber = floorNumber;
    }

    public Long getFloorId() { return floorId; }
    public void setFloorId(Long floorId) { this.floorId = floorId; }

    public Integer getFloorNumber() { return floorNumber; }
    public void setFloorNumber(Integer floorNumber) { this.floorNumber = floorNumber; }
}