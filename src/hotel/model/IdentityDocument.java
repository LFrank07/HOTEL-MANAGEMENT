package hotel.model;
public class IdentityDocument {
    private Long docId;
    private String docType;
    private String docNumber;

    public IdentityDocument() {}

    public Long getDocId() { return docId; }
    public void setDocId(Long docId) { this.docId = docId; }

    public String getDocType() { return docType; }
    public void setDocType(String docType) { this.docType = docType; }

    public String getDocNumber() { return docNumber; }
    public void setDocNumber(String docNumber) { this.docNumber = docNumber; }
}