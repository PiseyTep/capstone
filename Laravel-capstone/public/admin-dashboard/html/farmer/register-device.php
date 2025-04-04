<?php
// Place this file in your backend directory, e.g., admin-dashboard/html/farmer/register-device.php

require_once 'connect.php';
require_once 'firebase_helper.php';

// Set headers
header('Content-Type: application/json');

// Parse JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Check if required fields are present
if (!isset($input['device_token']) || empty($input['device_token'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Device token is required'
    ]);
    exit;
}

// Get database connection
$conn = $GLOBALS['conn']; // Adjust based on your connection method

// Extract data
$deviceToken = $conn->real_escape_string($input['device_token']);
$firebaseUid = isset($input['firebase_uid']) ? $conn->real_escape_string($input['firebase_uid']) : null;
$platform = isset($input['platform']) ? $conn->real_escape_string($input['platform']) : 'unknown';

// Verify the user exists in database
$userId = null;

if ($firebaseUid) {
    $stmt = $conn->prepare("SELECT id FROM users WHERE firebase_uid = ?");
    $stmt->bind_param("s", $firebaseUid);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        $userId = $user['id'];
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ]);
        exit;
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Firebase UID is required'
    ]);
    exit;
}

// Check if a device_tokens table exists, create if not
$tableCheckResult = $conn->query("SHOW TABLES LIKE 'device_tokens'");
if ($tableCheckResult->num_rows == 0) {
    // Table doesn't exist, create it
    $createTableSQL = "CREATE TABLE device_tokens (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        token VARCHAR(255) NOT NULL,
        platform VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY (token),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )";
    
    $conn->query($createTableSQL);
}

// Store or update device token
try {
    // First, check if token already exists
    $stmt = $conn->prepare("SELECT id, user_id FROM device_tokens WHERE token = ?");
    $stmt->bind_param("s", $deviceToken);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        // Token exists, update it
        $tokenRecord = $result->fetch_assoc();
        
        if ($tokenRecord['user_id'] != $userId) {
            // Token exists but for a different user, update user_id
            $stmt = $conn->prepare("UPDATE device_tokens SET user_id = ?, platform = ? WHERE token = ?");
            $stmt->bind_param("iss", $userId, $platform, $deviceToken);
            $stmt->execute();
        } else {
            // Token exists for same user, update platform if needed
            $stmt = $conn->prepare("UPDATE device_tokens SET platform = ? WHERE token = ?");
            $stmt->bind_param("ss", $platform, $deviceToken);
            $stmt->execute();
        }
    } else {
        // Token doesn't exist, insert new record
        $stmt = $conn->prepare("INSERT INTO device_tokens (user_id, token, platform) VALUES (?, ?, ?)");
        $stmt->bind_param("iss", $userId, $deviceToken, $platform);
        $stmt->execute();
    }
    
    // Also update the main user record for backward compatibility
    $stmt = $conn->prepare("UPDATE users SET device_token = ? WHERE id = ?");
    $stmt->bind_param("si", $deviceToken, $userId);
    $stmt->execute();
    
    echo json_encode([
        'success' => true,
        'message' => 'Device token registered successfully'
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>