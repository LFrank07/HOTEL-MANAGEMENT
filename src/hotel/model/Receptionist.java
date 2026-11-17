<<<<<<< HEAD
package hotel.model;

public class Receptionist extends Staff {
    private String shift;

    public Receptionist() {
        super();
    }

=======
public class Receptionist extends Staff {
    private String shift;

>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
    public Receptionist(String name, long staffId, String shift) {
        super(name, staffId);
        this.shift = shift;
    }

    public String getShift() {
        return shift;
    }

    public void setShift(String shift) {
        this.shift = shift;
    }
<<<<<<< HEAD
}
=======
}
>>>>>>> aa305596d259241745c5cf2032dd3d663feed3f8
