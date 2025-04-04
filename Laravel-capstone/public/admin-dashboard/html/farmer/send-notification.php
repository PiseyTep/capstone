<?php
/**
 * send-notification.php
 * 
 * Endpoint for sending FCM push notifications to users
 * This file should be placed in the same directory as your other PHP backend files
 */

require_once 'connect.php';
require_once 'config.php';
require_once 'jwt_helper.php';

// Set headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Ensure correct request method
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405); // Method Not Allowed
    echo json_encode([
        'success' => false,
        'message' => 'Only POST method is allowed'
    ]);
    exit;
}

// Get database connection
$db = Database::getInstance();
$conn = $db->getConnection();

// Parse JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Check authentication
$authHeader = isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '';
$isAuthenticated = false;
$currentUserId = null;

if (!empty($authHeader)) {
    // Extract token from Authorization header
    if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        $token = $matches[1];
        
        // Verify JWT token
        $jwtHelper = new JWTHelper();
        $decoded = $jwtHelper->verifyToken($token);
        
        if ($decoded && isset($decoded->user_id)) {
            $isAuthenticated = true;
            $currentUserId = $decoded->user_id;
        }
    }
}

// Check if user is admin or super_admin
$isAdmin = false;

if ($isAuthenticated && $currentUserId) {
    $stmt = $conn->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->bind_param("i", $currentUserId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        if ($user['role'] === 'admin' || $user['role'] === 'super_admin') {
            $isAdmin = true;
        }
    }
}

// Only admins can send notifications
if (!$isAdmin) {
    http_response_code(403); // Forbidden
    echo json_encode([
        'success' => false,
        'message' => 'Only administrators can send notifications'
    ]);
    exit;
}

// Get FCM server key from config
define('FCM_SERVER_KEY', $_ENV['FCM_SERVER_KEY'] ?? 'YOUR_FCM_SERVER_KEY');

// Validate required fields
if (!isset($input['title']) || empty($input['title']) || !isset($input['body']) || empty($input['body'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Title and body are required'
    ]);
    exit;
}

// Get notification parameters
$title = $input['title'];
$body = $input['body'];
$data = isset($input['data']) ? $input['data'] : [];

// Check notification target
$target = isset($input['target']) ? $input['target'] : 'all';
$targetId = isset($input['target_id']) ? $input['target_id'] : null;

// Add notification sender info
$data['sender_id'] = $currentUserId;
$data['sent_at'] = date('Y-m-d H:i:s');
$userId = $targetUserId;

// Store notification in database
$stmt = $conn->prepare("INSERT INTO notifications (user_id, title, body, data, is_read) 
                        VALUES (?, ?, ?, ?, FALSE)");
$stmt->bind_param("isss", $userId, $title, $body, $data);
$stmt->execute();
// Initialize result
$result = [
    'success' => false,
    'message' => '',
    'sent_count' => 0,
    'failed_count' => 0
];

// Store notification in database
$notificationId = storeNotification($conn, $currentUserId, $title, $body, json_encode($data), $target, $targetId);

if (!$notificationId) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to store notification in database'
    ]);
    exit;
}

// Include notification ID in data payload
$data['notification_id'] = $notificationId;

// Send notification based on target
switch ($target) {
    case 'user':
        // Send to specific user
        $result = sendNotificationToUser($conn, $targetId, $title, $body, $data);
        break;
        
    case 'role':
        // Send to all users with a specific role
        $result = sendNotificationToRole($conn, $targetId, $title, $body, $data);
        break;
        
    case 'topic':
        // Send to a topic
        $result = sendNotificationToTopic($targetId, $title, $body, $data);
        break;
        
    case 'all':
    default:
        // Send to all users
        $result = sendNotificationToAll($conn, $title, $body, $data);
        break;
}

// Update notification status in database
updateNotificationStatus($conn, $notificationId, $result['success'], $result['sent_count'], $result['failed_count']);

// Return result
echo json_encode($result);

/**
 * Store notification in database
 */
function storeNotification($conn, $senderId, $title, $body, $data, $target, $targetId) {
    // Check if notifications table exists, create if not
    $tableCheckResult = $conn->query("SHOW TABLES LIKE 'notifications'");
    
    if ($tableCheckResult->num_rows == 0) {
        // Table doesn't exist, create it to match your new structure
        $createTableSQL = "CREATE TABLE notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id BIGINT UNSIGNED,
            sender_id INT,
            title VARCHAR(255) NOT NULL,
            body TEXT NOT NULL,
            data TEXT,
            is_read BOOLEAN DEFAULT FALSE,
            target VARCHAR(50),
            target_id VARCHAR(50),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )";
        
        if (!$conn->query($createTableSQL)) {
            error_log("Error creating notifications table: " . $conn->error);
            return false;
        }
    }
    
    // For user-specific notifications, each user gets their own notification record
    if ($target == 'user') {
        try {
            $stmt = $conn->prepare("INSERT INTO notifications 
                            (user_id, sender_id, title, body, data, target, target_id, is_read) 
                            VALUES (?, ?, ?, ?, ?, ?, ?, FALSE)");
            
            $stmt->bind_param("iisssss", 
                $targetId,     // user_id is the target user
                $senderId,     // sender_id is the admin user
                $title, 
                $body, 
                $data, 
                $target, 
                $targetId
            );
            
            if ($stmt->execute()) {
                return $conn->insert_id;
            } else {
                error_log("Error inserting notification: " . $stmt->error);
                return false;
            }
        } catch (Exception $e) {
            error_log("Exception storing notification: " . $e->getMessage());
            return false;
        }
    } else {
        // For role-based or all users, we'll store it once and create user-specific records when sending
        try {
            $stmt = $conn->prepare("INSERT INTO notifications 
                            (sender_id, title, body, data, target, target_id, is_read) 
                            VALUES (?, ?, ?, ?, ?, ?, FALSE)");
            
            $stmt->bind_param("isssss", 
                $senderId, 
                $title, 
                $body, 
                $data, 
                $target, 
                $targetId
            );
            
            if ($stmt->execute()) {
                return $conn->insert_id;
            } else {
                error_log("Error inserting notification: " . $stmt->error);
                return false;
            }
        } catch (Exception $e) {
            error_log("Exception storing notification: " . $e->getMessage());
            return false;
        }
    }
}
/**
 * Update notification status
 */
function updateNotificationStatus($conn, $notificationId, $success, $sentCount, $failedCount) {
    try {
        $stmt = $conn->prepare("UPDATE notifications 
                            SET success = ?, sent_count = ?, failed_count = ? 
                            WHERE id = ?");
        
        $successInt = $success ? 1 : 0;
        $stmt->bind_param("iiii", 
            $successInt, 
            $sentCount, 
            $failedCount, 
            $notificationId
        );
        
        return $stmt->execute();
    } catch (Exception $e) {
        error_log("Exception updating notification status: " . $e->getMessage());
        return false;
    }
}

/**
 * Send notification to a specific user
 */
/**
 * Send FCM notification to device tokens
 */
function sendFCMNotification($deviceTokens, $title, $body, $data) {
    if (empty($deviceTokens)) {
        return false;
    }
    
    $url = 'https://fcm.googleapis.com/fcm/send';
    
    // Prepare the message payload
    if (count($deviceTokens) == 1) {
        // Single recipient
        $fields = [
            'to' => $deviceTokens[0],
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
                'badge' => '1'
            ],
            'data' => $data
        ];
    } else {
        // Multiple recipients
        $fields = [
            'registration_ids' => $deviceTokens,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
                'badge' => '1'
            ],
            'data' => $data
        ];
    }
    
    $headers = [
        'Authorization: key=' . FCM_SERVER_KEY,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
    
    $result = curl_exec($ch);
    
    if ($result === false) {
        error_log('FCM Notification Error: ' . curl_error($ch));
        curl_close($ch);
        return false;
    }
    
    curl_close($ch);
    
    $response = json_decode($result, true);
    
    // Check if the notification was sent successfully
    if (isset($response['success']) && $response['success'] > 0) {
        return true;
    } else {
        error_log('FCM Notification Failed: ' . $result);
        return false;
    }
}

/**
 * Send notification to a specific user
 */
function sendNotificationToUser($conn, $userId, $title, $body, $data) {
    try {
        // Get user's device tokens
        $stmt = $conn->prepare("SELECT token FROM device_tokens WHERE user_id = ?");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $deviceTokens = [];
        while ($row = $result->fetch_assoc()) {
            $deviceTokens[] = $row['token'];
        }
        
        // If no device tokens found, try legacy device_token field
        if (empty($deviceTokens)) {
            $stmt = $conn->prepare("SELECT device_token FROM users WHERE id = ? AND device_token IS NOT NULL");
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $user = $result->fetch_assoc();
                if (!empty($user['device_token'])) {
                    $deviceTokens[] = $user['device_token'];
                }
            }
        }
        
        if (empty($deviceTokens)) {
            return [
                'success' => false,
                'message' => 'No device tokens found for user',
                'sent_count' => 0,
                'failed_count' => 0
            ];
        }
        
        $sentCount = 0;
        $failedCount = 0;
        
        // Send to each device token
        foreach ($deviceTokens as $token) {
            $success = sendFCMNotification([$token], $title, $body, $data);
            
            if ($success) {
                $sentCount++;
            } else {
                $failedCount++;
            }
        }
        
        return [
            'success' => $sentCount > 0,
            'message' => 'Notification sent to ' . $sentCount . ' devices, failed for ' . $failedCount . ' devices',
            'sent_count' => $sentCount,
            'failed_count' => $failedCount
        ];
    } catch (Exception $e) {
        error_log("Exception sending notification to user: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Error sending notification: ' . $e->getMessage(),
            'sent_count' => 0,
            'failed_count' => 1
        ];
    }
}

/**
 * Send notification to all users with a specific role
 */
/**
 * Send notification to all users
 */
function sendNotificationToAll($conn, $title, $body, $data) {
    try {
        // Get all device tokens
        $stmt = $conn->prepare("SELECT token FROM device_tokens");
        $stmt->execute();
        $result = $stmt->get_result();
        
        $deviceTokens = [];
        while ($row = $result->fetch_assoc()) {
            $deviceTokens[] = $row['token'];
        }
        
        // Also get legacy device tokens
        $stmt = $conn->prepare("SELECT device_token FROM users WHERE device_token IS NOT NULL");
        $stmt->execute();
        $result = $stmt->get_result();
        
        while ($row = $result->fetch_assoc()) {
            if (!empty($row['device_token'])) {
                $deviceTokens[] = $row['device_token'];
            }
        }
        
        // Remove duplicates
        $deviceTokens = array_unique($deviceTokens);
        
        if (empty($deviceTokens)) {
            return [
                'success' => false,
                'message' => 'No device tokens found',
                'sent_count' => 0,
                'failed_count' => 0
            ];
        }
        
        // Send to all device tokens (in chunks of 500 to avoid FCM limits)
        $chunks = array_chunk($deviceTokens, 500);
        $totalSent = 0;
        $totalFailed = 0;
        
        foreach ($chunks as $chunk) {
            $success = sendFCMNotification($chunk, $title, $body, $data);
            if ($success) {
                $totalSent += count($chunk);
            } else {
                $totalFailed += count($chunk);
            }
        }
        
        return [
            'success' => $totalSent > 0,
            'message' => 'Notification sent to ' . $totalSent . ' devices, failed for ' . $totalFailed . ' devices',
            'sent_count' => $totalSent,
            'failed_count' => $totalFailed
        ];
    } catch (Exception $e) {
        error_log("Exception sending notification to all users: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Error sending notification: ' . $e->getMessage(),
            'sent_count' => 0,
            'failed_count' => 1
        ];
    }
}

/**
 * Send notification to users with a specific role
 */
function sendNotificationToRole($conn, $role, $title, $body, $data) {
    try {
        // Get all users with the specified role
        $stmt = $conn->prepare("SELECT id FROM users WHERE role = ?");
        $stmt->bind_param("s", $role);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $userIds = [];
        while ($row = $result->fetch_assoc()) {
            $userIds[] = $row['id'];
        }
        
        if (empty($userIds)) {
            return [
                'success' => false,
                'message' => 'No users found with role: ' . $role,
                'sent_count' => 0,
                'failed_count' => 0
            ];
        }
        
        // Get device tokens for all users
        $placeholders = str_repeat('?,', count($userIds) - 1) . '?';
        $query = "SELECT token FROM device_tokens WHERE user_id IN ($placeholders)";
        
        $stmt = $conn->prepare($query);
        $types = str_repeat('i', count($userIds));
        $stmt->bind_param($types, ...$userIds);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $deviceTokens = [];
        while ($row = $result->fetch_assoc()) {
            $deviceTokens[] = $row['token'];
        }
        
        // Also get legacy device tokens
        $query = "SELECT device_token FROM users WHERE id IN ($placeholders) AND device_token IS NOT NULL";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param($types, ...$userIds);
        $stmt->execute();
        $result = $stmt->get_result();
        
        while ($row = $result->fetch_assoc()) {
            if (!empty($row['device_token'])) {
                $deviceTokens[] = $row['device_token'];
            }
        }
        
        // Remove duplicates
        $deviceTokens = array_unique($deviceTokens);
        
        if (empty($deviceTokens)) {
            return [
                'success' => false,
                'message' => 'No device tokens found for users with role: ' . $role,
                'sent_count' => 0,
                'failed_count' => 0
            ];
        }
        
        // Send to all device tokens
        $success = sendFCMNotification($deviceTokens, $title, $body, $data);
        
        return [
            'success' => $success,
            'message' => 'Notification sent to ' . count($deviceTokens) . ' devices',
            'sent_count' => $success ? count($deviceTokens) : 0,
            'failed_count' => $success ? 0 : count($deviceTokens)
        ];
    } catch (Exception $e) {
        error_log("Exception sending notification to role: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Error sending notification: ' . $e->getMessage(),
            'sent_count' => 0,
            'failed_count' => 1
        ];
    }
}

/**
 * Send notification to a topic
 */
function sendNotificationToTopic($topic, $title, $body, $data) {
    try {
        $url = 'https://fcm.googleapis.com/fcm/send';
        
        $fields = [
            'to' => '/topics/' . $topic,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
            ],
            'data' => $data
        ];
        
        $headers = [
            'Authorization: key=' . FCM_SERVER_KEY,
            'Content-Type: application/json'
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
        
        $result = curl_exec($ch);
        
        if ($result === false) {
            error_log('FCM Notification Error: ' . curl_error($ch));
            curl_close($ch);
            return [
                'success' => false,
                'message' => 'Error sending notification: ' . curl_error($ch),
                'sent_count' => 0,
                'failed_count' => 1
            ];
        }
        
        curl_close($ch);
        
        $response = json_decode($result, true);
        
        if (isset($response['message_id']) || (isset($response['success']) && $response['success'] > 0)) {
            return [
                'success' => true,
                'message' => 'Notification sent to topic: ' . $topic,
                'sent_count' => 1,
                'failed_count' => 0,
                'response' => $response
            ];
        } else {
            error_log('FCM Topic Notification Failed: ' . $result);
            return [
                'success' => false,
                'message' => 'Failed to send notification to topic: ' . $topic,
                'sent_count' => 0,
                'failed_count' => 1,
                'response' => $response
            ];
        }
    } 
    catch (Exception $e) {
        error_log("Exception sending notification to topic: " . $e->getMessage());
        return [
            'success' => false,
            'message' => 'Error sending notification: ' . $e->getMessage(),
            'sent_count' => 0,
            'failed_count' => 1
        ];
    }
}
