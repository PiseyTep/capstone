<!-- /Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/Laravel-capstone/public/admin-dashboard/html/config.php -->
<?php
// Use dotenv for more secure configuration
require_once __DIR__ . '/vendor/autoload.php';

// Try multiple potential .env file locations
$envPaths = [
    __DIR__ . '/.env',
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
    '/Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/Laravel-capstone/.env'
];

$envFileFound = false;
foreach ($envPaths as $path) {
    if (file_exists($path)) {
        try {
            $dotenv = Dotenv\Dotenv::createImmutable(dirname($path), basename($path));
            $dotenv->load();
            $envFileFound = true;
            break;
        } catch (Exception $e) {
            error_log('Error loading .env: ' . $e->getMessage());
        }
    }
}

if (!$envFileFound) {
    error_log('No .env file found');
}

// Database Configuration (with fallback to hardcoded values)
define('DB_HOST', $_ENV['DB_HOST'] ?? '127.0.0.1');
define('DB_USER', $_ENV['DB_USERNAME'] ?? 'root');
define('DB_PASS', $_ENV['DB_PASSWORD'] ?? 'Pisey@123');
define('DB_NAME', $_ENV['DB_DATABASE'] ?? 'agritech_pioneers');
define('DB_CHARSET', $_ENV['DB_CHARSET'] ?? 'utf8mb4');
define('DB_SOCKET', $_ENV['DB_SOCKET'] ?? '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock');

// JWT Configuration
define('JWT_SECRET', $_ENV['APP_KEY'] ?? 'base64:/dqcUQv1mrsB56LZByU4C72MesRH+75gz/f6+Dzu9xc=');
define('JWT_ALGO', 'HS256');
define('TOKEN_EXPIRE', 3600 * 24); // 24 hours expiration

// Error Reporting (based on APP_DEBUG)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Optional: Add logging for tracking
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/storage/logs/php-error.log');
?>