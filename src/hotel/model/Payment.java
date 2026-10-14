package hotel.model;

import java.math.BigDecimal;
import java.time.LocalDate;

public class Payment {
    private Long paymentId;
    private LocalDate paidDate;
    private String method;
    private BigDecimal amount;

    private Invoice invoice; // Receives

    public Payment() {}

    public Payment(Long paymentId, LocalDate paidDate, String method, BigDecimal amount) {
        this.paymentId = paymentId;
        this.paidDate = paidDate;
        this.method = method;
        this.amount = amount;
    }

    public Long getPaymentId() { return paymentId; }
    public void setPaymentId(Long paymentId) { this.paymentId = paymentId; }

    public LocalDate getPaidDate() { return paidDate; }
    public void setPaidDate(LocalDate paidDate) { this.paidDate = paidDate; }

    public String getMethod() { return method; }
    public void setMethod(String method) { this.method = method; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public Invoice getInvoice() { return invoice; }
    public void setInvoice(Invoice invoice) { this.invoice = invoice; }
}