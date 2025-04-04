<?php
// Add this to a temporary file in your Laravel project root, e.g., route-check.php
// Run it with: php route-check.php

// Display all registered routes
echo "=== CHECKING LARAVEL ROUTES ===\n\n";

// Try to include the Laravel application
require_once __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$routes = Route::getRoutes();
echo "Total routes: " . count($routes) . "\n\n";

echo "API Routes:\n";
foreach ($routes as $route) {
    if (strpos($route->uri(), 'api/') === 0) {
        echo $route->methods()[0] . " " . $route->uri() . " => " . $route->getActionName() . "\n";
    }
}

echo "\n=== CHECKING SERVER CONFIGURATION ===\n\n";

// Check .htaccess file in public directory
$htaccessPath = __DIR__ . '/public/.htaccess';
if (file_exists($htaccessPath)) {
    echo ".htaccess file exists in public directory\n";
    echo "Content:\n" . file_get_contents($htaccessPath) . "\n";
} else {
    echo "WARNING: .htaccess file does not exist in public directory!\n";
}

// Check server document root
echo "\nServer document root should be set to: " . __DIR__ . "/public\n";
echo "Current script path: " . __FILE__ . "\n";

echo "\n=== MANUAL TESTING STEPS ===\n\n";
echo "1. Try accessing these URLs in your browser:\n";
echo "   - http://172.20.10.3:8000/api/status\n";
echo "   - http://172.20.10.3:8000/api/health\n";
echo "\n2. Check Laravel logs at: " . __DIR__ . "/storage/logs/laravel.log\n";