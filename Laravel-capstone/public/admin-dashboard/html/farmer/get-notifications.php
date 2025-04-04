<?php
require_once 'connect.php';
require_once 'firebase_helper.php';

// Set headers
header('Content-Type: application/json');

// Verify user authentication
// Get auth token from header
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$token = null;

if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $token = $matches[1];
}

if (!$token) {
    echo json_encode([
        'success' => false,
        'message' => 'Authentication required'
    ]);
    exit;
}

// Verify token (using your existing token verification)
// Assuming jwt_helper.php has verifyToken method
require_once 'jwt_helper.php';
$jwtHelper = new JWTHelper();
$userData = $jwtHelper->verifyToken($token);

if (!$userData || !isset($userData->user_id)) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid authentication token'
    ]);
    exit;
}

$userId = $userData->user_id;

// Get database connection
$conn = $GLOBALS['conn']; // Adjust based on your connection method

// Get pagination parameters
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$offset = ($page - 1) * $limit;

// Get unread count
$stmt = $conn->prepare("SELECT COUNT(*) as unread FROM notifications WHERE user_id = ? AND is_read = FALSE");
$stmt->bind_param("i", $userId);
$stmt->execute();
$unreadResult = $stmt->get_result();
$unreadCount = $unreadResult->fetch_assoc()['unread'];

// Get notifications for user
$stmt = $conn->prepare("SELECT id, title, body, data, is_read, created_at 
                        FROM notifications 
                        WHERE user_id = ? 
                        ORDER BY created_at DESC 
                        LIMIT ? OFFSET ?");
$stmt->bind_param("iii", $userId, $limit, $offset);
$stmt->execute();
$result = $stmt->get_result();

$notifications = [];
while ($row = $result->fetch_assoc()) {
    // Parse JSON data if present
    if ($row['data']) {
        $row['data'] = json_decode($row['data'], true);
    }
    $notifications[] = $row;
}

// Get total count for pagination
$stmt = $conn->prepare("SELECT COUNT(*) as total FROM notifications WHERE user_id = ?");
$stmt->bind_param("i", $userId);
$stmt->execute();
$countResult = $stmt->get_result();
$totalCount = $countResult->fetch_assoc()['total'];

echo json_encode([
    'success' => true,
    'data' => [
        'notifications' => $notifications,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => ceil($totalCount / $limit),
            'total' => $totalCount,
            'unread' => $unreadCount
        ]
    ]
]);
?>