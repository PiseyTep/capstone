<?php
// Mobile API Router
// This file handles all mobile-specific endpoints

// Get the specific mobile endpoint
$mobile_endpoint = $segments[1] ?? '';
$mobile_param = $segments[2] ?? '';

// Process request based on mobile endpoint
switch ($mobile_endpoint) {
    case 'login':
        // Mobile login endpoint
        include 'auth/login.php';
        break;
        
    case 'register':
        // Mobile registration endpoint
        include 'auth/register.php';
        break;
        
    case 'products':
        // Mobile products endpoint
        include 'products/index.php';
        break;
        
    case 'rentals':
        // Mobile rentals endpoint
        include 'rentals/index.php';
        break;
        
    case 'profile':
        // Mobile user profile endpoint
        include 'profile/index.php';
        break;
        
    default:
        // Unknown mobile endpoint
        echo json_encode([
            'success' => false,
            'message' => 'Unknown mobile endpoint'
        ]);
        http_response_code(404);
}
?>