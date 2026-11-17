package hotel.model;

<<<<<<< HEAD
=======

>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
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
<<<<<<< HEAD
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Integer getCapacity() { return capacity; }
    public void setCapacity(Integer capacity) { this.capacity = capacity; }
    public List<RatePlan> getRatePlans() { return ratePlans; }
    public void setRatePlans(List<RatePlan> ratePlans) { this.ratePlans = ratePlans; }

    public void addRatePlan(RatePlan ratePlan) {
        if (ratePlan != null && !ratePlans.contains(ratePlan)) {
            ratePlans.add(ratePlan);
        }
    }
=======

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Integer getCapacity() { return capacity; }
    public void setCapacity(Integer capacity) { this.capacity = capacity; }

    public List<RatePlan> getRatePlans() { return ratePlans; }
    public void setRatePlans(List<RatePlan> ratePlans) { this.ratePlans = ratePlans; }
>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
}