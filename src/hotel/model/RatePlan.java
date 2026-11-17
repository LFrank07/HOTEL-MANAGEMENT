package hotel.model;
import java.time.LocalDate;

public class RatePlan {
    private Long rateplanId;
    private String seasonName;
    private LocalDate startDate;
    private LocalDate endDate;
    private Double price;

    public RatePlan() {}

    public Long getRateplanId() { return rateplanId; }
    public void setRateplanId(Long rateplanId) { this.rateplanId = rateplanId; }

    public String getSeasonName() { return seasonName; }
    public void setSeasonName(String seasonName) { this.seasonName = seasonName; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }
}