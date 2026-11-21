package hotel.model;

import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;

public class LoginFrame extends JFrame {

    private final JTextField accountField = new JTextField(18);
    private final JPasswordField passwordField = new JPasswordField(18);
    private final JLabel messageLabel = new JLabel(" ");

    public LoginFrame() {
        setTitle("Login - Hotel Management");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setMinimumSize(new Dimension(400, 290));
        setResizable(false);
        setLocationRelativeTo(null);

        JPanel root = new JPanel(new BorderLayout(0, 14));
        root.setBorder(BorderFactory.createEmptyBorder(22, 26, 20, 26));
        root.setBackground(new Color(245, 247, 250));

        JLabel title = new JLabel("LOGIN");
        title.setFont(new Font("Sans Serif", Font.BOLD, 20));
        title.setForeground(new Color(29, 48, 71));

        JLabel subtitle = new JLabel("Enter Account and Password");
        subtitle.setForeground(new Color(101, 114, 130));

        JPanel header = new JPanel(new GridLayout(2, 1, 0, 4));
        header.setOpaque(false);
        header.add(title);
        header.add(subtitle);
        root.add(header, BorderLayout.NORTH);

        JPanel form = new JPanel(new GridLayout(0, 1, 6, 6));
        form.setBackground(Color.WHITE);
        form.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(222, 227, 233)),
                BorderFactory.createEmptyBorder(16, 16, 12, 16)
        ));

        form.add(new JLabel("Account:"));
        form.add(accountField);
        form.add(new JLabel("Password:"));
        form.add(passwordField);

        messageLabel.setForeground(new Color(180, 35, 35));
        messageLabel.setFont(new Font("Sans Serif", Font.PLAIN, 11));
        form.add(messageLabel);

        root.add(form, BorderLayout.CENTER);

        JButton cancelButton = new JButton("Cancel");
        JButton loginButton = new JButton("Sign In");
        loginButton.setBackground(new Color(34, 112, 90));
        loginButton.setForeground(Color.WHITE);
        loginButton.setFocusPainted(false);

        JPanel actions = new JPanel(new FlowLayout(FlowLayout.RIGHT, 8, 0));
        actions.setOpaque(false);
        actions.add(cancelButton);
        actions.add(loginButton);
        root.add(actions, BorderLayout.SOUTH);

        KeyAdapter enterAction = new KeyAdapter() {
            @Override
            public void keyPressed(KeyEvent e) {
                if (e.getKeyCode() == KeyEvent.VK_ENTER) {
                    handleLogin();
                }
            }
        };
        accountField.addKeyListener(enterAction);
        passwordField.addKeyListener(enterAction);

        loginButton.addActionListener(e -> handleLogin());
        cancelButton.addActionListener(e -> System.exit(0));

        setContentPane(root);
        pack();
        setLocationRelativeTo(null);
    }

    private void handleLogin() {
        String account = accountField.getText().trim();
        String password = new String(passwordField.getPassword());

        if (account.isEmpty()) {
            messageLabel.setText("Please enter Account.");
            accountField.requestFocusInWindow();
            return;
        }
        if (password.isEmpty()) {
            messageLabel.setText("Please enter Password.");
            passwordField.requestFocusInWindow();
            return;
        }

        if ("admin".equalsIgnoreCase(account) && "123456".equals(password)) {
            dispose();
            SwingUtilities.invokeLater(HotelManagementUI::new);
        } else {
            messageLabel.setText("Invalid Account or Password.");
        }
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new LoginFrame().setVisible(true));
    }
}