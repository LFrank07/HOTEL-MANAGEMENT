package hotel.model;

import java.util.ArrayList;
import java.util.List;

public class Guest {
    private Long guestId;
    private String name;
    private String phone;
    private List<IdentityDocument> documents = new ArrayList<>();

    public Guest() {}

    public Long getGuestId() { return guestId; }
    public void setGuestId(Long guestId) { this.guestId = guestId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public List<IdentityDocument> getDocuments() { return documents; }
    public void setDocuments(List<IdentityDocument> documents) { this.documents = documents; }
}