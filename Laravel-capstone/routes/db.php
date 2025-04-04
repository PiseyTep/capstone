<?php
// db.php
require_once '../config.php';

function getDbConnection() {
    try {
        $conn = new mysqli(
            getenv('DB_HOST') ?: '127.0.0.1',
            getenv('DB_USERNAME') ?: 'root',
            getenv('DB_PASSWORD') ?: 'Pisey@123',
            getenv('DB_DATABASE') ?: 'agriTech-poineers',
            getenv('DB_PORT') ?: 3306,
            getenv('DB_SOCKET') ?: '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock'
        );
        
        if ($conn->connect_error) {
            throw new Exception("Database connection failed: " . $conn->connect_error);
        }
        
        $conn->set_charset(getenv('DB_CHARSET') ?: 'utf8mb4');
        return $conn;
    } catch (Exception $e) {
        error_log($e->getMessage());
        http_response_code(500);
        die(json_encode([
            'success' => false,
            'message' => 'Database connection error',
            'error' => $e->getMessage() // Only in development
        ]));
    }
}