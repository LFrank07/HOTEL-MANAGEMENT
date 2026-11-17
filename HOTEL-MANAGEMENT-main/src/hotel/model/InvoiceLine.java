package hotel.model;

import java.math.BigDecimal;

public class InvoiceLine {
    private Long lineId;
    private String type;
    private String description;
    private BigDecimal amount;

    public InvoiceLine() {}

    public InvoiceLine(Long lineId, String type, String description, BigDecimal amount) {
        this.lineId = lineId;
        this.type = type;
        this.description = description;
        this.amount = amount;
    }

    public Long getLineId() { return lineId; }
    public void setLineId(Long lineId) { this.lineId = lineId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
}