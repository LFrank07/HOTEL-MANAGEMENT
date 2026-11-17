public class Receptionist extends Staff {
    private String shift;

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
}
