<?php
require_once 'connect.php';
require_once 'jwt_helper.php';

// Set headers
header('Content-Type: application/json');

// Verify authentication
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

if (!$token) {
    echo json_encode(['success' => false, 'message' => 'Authentication required']);
    exit;
}

$jwtHelper = new JWTHelper();
$userData = $jwtHelper->verifyToken($token);

if (!$userData || !isset($userData->user_id)) {
    echo json_encode(['success' => false, 'message' => 'Invalid token']);
    exit;
}

$userId = $userData->user_id;

// Parse JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Check if notificationId is provided
if (!isset($input['notification_id']) && !isset($input['mark_all'])) {
    echo json_encode(['success' => false, 'message' => 'Notification ID or mark_all flag required']);
    exit;
}

// Get database connection
$conn = $GLOBALS['conn']; // Adjust based on your connection method

if (isset($input['mark_all']) && $input['mark_all'] === true) {
    // Mark all notifications as read
    $stmt = $conn->prepare("UPDATE notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    
    echo json_encode([
        'success' => true,
        'message' => 'All notifications marked as read',
        'count' => $stmt->affected_rows
    ]);
} else {
    // Mark single notification as read
    $notificationId = $input['notification_id'];
    
    // First check if notification belongs to user
    $stmt = $conn->prepare("SELECT id FROM notifications WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $notificationId, $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'Notification not found']);
        exit;
    }
    
    // Update notification
    $stmt = $conn->prepare("UPDATE notifications SET is_read = TRUE WHERE id = ?");
    $stmt->bind_param("i", $notificationId);
    $stmt->execute();
    
    echo json_encode(['success' => true, 'message' => 'Notification marked as read']);
}
?>