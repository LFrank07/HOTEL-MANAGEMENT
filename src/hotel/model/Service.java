package hotel.model;
public class Service {
    private Long serviceId;
    private String name;
    private Double unitPrice;

    public Service() {}

    public Long getServiceId() { return serviceId; }
    public void setServiceId(Long serviceId) { this.serviceId = serviceId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public Double getUnitPrice() { return unitPrice; }
    public void setUnitPrice(Double unitPrice) { this.unitPrice = unitPrice; }
}