package hotel.model;


import java.util.ArrayList;
import java.util.List;

public class RoomType {
    private Long roomtypeId;
    private String name;
    private Integer capacity;
    private List<RatePlan> ratePlans = new ArrayList<>();

    public RoomType() {}

    public Long getRoomtypeId() { return roomtypeId; }
    public void setRoomtypeId(Long roomtypeId) { this.roomtypeId = roomtypeId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Integer getCapacity() { return capacity; }
    public void setCapacity(Integer capacity) { this.capacity = capacity; }

    public List<RatePlan> getRatePlans() { return ratePlans; }
    public void setRatePlans(List<RatePlan> ratePlans) { this.ratePlans = ratePlans; }
}