<?php
require_once __DIR__ . '/vendor/autoload.php';

// Try loading .env file with multiple potential paths
$envPaths = [
    __DIR__ . '/.env',
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
    '/Applications/XAMPP/xamppfiles/htdocs/LoginFarmer/Laravel-capstone/.env'
];

foreach ($envPaths as $path) {
    echo "Trying path: $path\n";
    if (file_exists($path)) {
        try {
            $dotenv = Dotenv\Dotenv::createImmutable(dirname($path), basename($path));
            $dotenv->load();
            
            echo "Successfully loaded .env file from: $path\n";
            
            // Print out loaded environment variables
            print_r($_ENV);
            exit;
        } catch (Exception $e) {
            echo "Error loading .env from $path: " . $e->getMessage() . "\n";
        }
    }
}

echo "No .env file found in any of the attempted paths.\n";