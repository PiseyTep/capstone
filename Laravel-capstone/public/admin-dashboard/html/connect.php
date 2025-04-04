<!-- /Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/Laravel-capstone/public/admin-dashboard/html/connect.php -->
<?php
require_once 'config.php';


// Direct connection (for legacy code like login.php)
try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, null, DB_SOCKET);
    
    // Check connection
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Set charset
    $conn->set_charset(DB_CHARSET);  // CHANGE THIS LINE - use $conn instead of $this->connection
} catch (Exception $e) {
    echo "<div style='color:red; background:white; padding:15px; border:1px solid #ccc;'>";
    echo "<h3>Database Connection Error</h3>";
    echo "<p>" . $e->getMessage() . "</p>";
    echo "<p>Check your database credentials in config.php:</p>";
    echo "<ul>";
    echo "<li>Host: " . DB_HOST . "</li>";
    echo "<li>User: " . DB_USER . "</li>";
    echo "<li>Database: " . DB_NAME . "</li>";
    echo "</ul>";
    echo "</div>";
    die();
}

// Class-based connection (for new API code)
class Database {
    private static $instance = null;
    private $connection;
    
    // Secure connection with error handling
    private function __construct() {
        try {
            $this->connection = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
            
            if ($this->connection->connect_error) {
                throw new Exception("Database connection failed: " . $this->connection->connect_error);
            }
            
            $this->connection->set_charset(DB_CHARSET);
            
        } catch (Exception $e) {
            error_log($e->getMessage());
            die(json_encode([
                'success' => false,
                'message' => 'Database connection error: ' . $e->getMessage()
            ]));
        }
    }
    
    // Singleton instance method
    public static function getInstance() {
        if (!self::$instance) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
    
    public function getConnection() {
        return $this->connection;
    }
    
    public function secureInput($data) {
        return $this->connection->real_escape_string(htmlspecialchars($data));
    }
}
?>