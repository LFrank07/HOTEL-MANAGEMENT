package hotel.model;

public class Position {
    private Long roleId;
    private String title;
    private String level;
    private String baseRole;
    private String departmentFocus;

    public Position() {}

    public Position(Long roleId, String title, String level, String baseRole, String departmentFocus) {
        this.roleId = roleId;
        this.title = title;
        this.level = level;
        this.baseRole = baseRole;
        this.departmentFocus = departmentFocus;
    }

    public Long getRoleId() { return roleId; }
    public void setRoleId(Long roleId) { this.roleId = roleId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getLevel() { return level; }
    public void setLevel(String level) { this.level = level; }

    public String getBaseRole() { return baseRole; }
    public void setBaseRole(String baseRole) { this.baseRole = baseRole; }

    public String getDepartmentFocus() { return departmentFocus; }
    public void setDepartmentFocus(String departmentFocus) { this.departmentFocus = departmentFocus; }
}