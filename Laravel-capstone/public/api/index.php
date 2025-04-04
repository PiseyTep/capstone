<?php
// API Router for Flutter App
require_once __DIR__ . '/../admin-dashboard/html/config.php';
require_once __DIR__ . '/../admin-dashboard/html/connect.php';

// Set API headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, PUT, DELETE");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Parse request URL to determine endpoint
$request_uri = $_SERVER['REQUEST_URI'];

// Remove '/api/' from the URI
$base_path = '/api/';
$path = str_replace($base_path, '', $request_uri);
$segments = explode('/', trim($path, '/'));  // Split the path into segments

// Extract endpoint and parameters
$endpoint = $segments[0] ?? '';   // First segment will be the endpoint
$param = $segments[1] ?? '';      // Second segment will be the parameter (optional)

// Process request based on endpoint
switch ($endpoint) {
    case 'status':
        // Simple status endpoint
        echo json_encode([
            'success' => true,
            'message' => 'API is running',
            'version' => '1.0',
            'timestamp' => time()
        ]);
        break;
        
    case 'mobile':
        // Handle mobile-specific endpoints
        include 'mobile/router.php';
        break;
        
    case 'stats':
        // Your existing stats endpoint
        include 'stats.php';
        break;
        
    default:
        // Unknown endpoint
        echo json_encode([
            'success' => false,
            'message' => 'Unknown endpoint'
        ]);
        http_response_code(404);
}
