public class Staff {
    private String name;
    private long staffId;

    public Staff(String name, long staffId) {
        this.name = name;
        this.staffId = staffId;
    }  

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public long getStaffId() {
        return staffId;
    }

    public void setStaffId(long staffId) {
        this.staffId = staffId;
    }
}
