package hotel.model;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    // Update host, port, or database name here if your local MySQL setup differs
    private static final String URL = "jdbc:mysql://localhost:3306/Hotel_Management_Group3?useSSL=false&serverTimezone=UTC";
    // MySQL username (change if not using "root")
    private static final String USER = "root";
    // MySQL password for the user above (update to match your local MySQL password)
    private static final String PASSWORD = "1234"; 

    // Opens a JDBC connection to the MySQL database
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
