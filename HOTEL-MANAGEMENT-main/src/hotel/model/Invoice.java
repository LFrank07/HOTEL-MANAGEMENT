package hotel.model;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class Invoice {
    private Long invoiceId;
    private LocalDate issueDate;
    private String status;

    private Stay stay;                       // Generates
    private List<InvoiceLine> lines;         // Contains
    private List<Payment> payments;          // Receives

    public Invoice() {
        this.lines = new ArrayList<>();
        this.payments = new ArrayList<>();
    }

    public Invoice(Long invoiceId, LocalDate issueDate, String status) {
        this();
        this.invoiceId = invoiceId;
        this.issueDate = issueDate;
        this.status = status;
    }

    public Long getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Long invoiceId) { this.invoiceId = invoiceId; }

    public LocalDate getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDate issueDate) { this.issueDate = issueDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Stay getStay() { return stay; }
    public void setStay(Stay stay) { this.stay = stay; }

    public List<InvoiceLine> getLines() { return lines; }
    public void setLines(List<InvoiceLine> lines) { this.lines = lines; }

    public List<Payment> getPayments() { return payments; }
    public void setPayments(List<Payment> payments) { this.payments = payments; }

    public void addLine(InvoiceLine line) {
        if (line != null && !lines.contains(line)) lines.add(line);
    }

    public void addPayment(Payment payment) {
        if (payment != null && !payments.contains(payment)) payments.add(payment);
    }
}