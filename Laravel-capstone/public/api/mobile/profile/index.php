<?php
// Mobile user profile endpoint
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../helpers.php';

// All profile endpoints require authentication
$tokenData = validateToken();
if (!$tokenData) {
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized access'
    ]);
    http_response_code(401);
    exit;
}

// Get user ID from token
$userId = $tokenData['user_id'];

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Process request based on method
switch ($method) {
    case 'GET':
        // Get user profile
        $stmt = $conn->prepare("
            SELECT id, first_name, last_name, email, phone_number, role, created_at, updated_at
            FROM users WHERE id = ?
        ");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            echo json_encode([
                'success' => false,
                'message' => 'User not found'
            ]);
            http_response_code(404);
            exit;
        }
        
        $user = $result->fetch_assoc();
        
        // Format response for mobile app
        $response = [
            'id' => $user['id'],
            'first_name' => $user['first_name'],
            'last_name' => $user['last_name'],
            'name' => $user['first_name'] . ' ' . $user['last_name'],
            'email' => $user['email'],
            'phone_number' => $user['phone_number'],
            'role' => $user['role'],
            'created_at' => $user['created_at']
        ];
        
        echo json_encode([
            'success' => true,
            'data' => $response
        ]);
        break;
        
    case 'PUT':
        // Update user profile
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid request data'
            ]);
            exit;
        }
        
        // Fields that can be updated
        $updateFields = [];
        $params = [];
        $types = '';
        
        if (isset($data['first_name'])) {
            $updateFields[] = "first_name = ?";
            $params[] = $data['first_name'];
            $types .= 's';
        }
        
        if (isset($data['last_name'])) {
            $updateFields[] = "last_name = ?";
            $params[] = $data['last_name'];
            $types .= 's';
        }
        
        if (isset($data['phone_number'])) {
            $updateFields[] = "phone_number = ?";
            $params[] = $data['phone_number'];
            $types .= 's';
        }
        
        if (isset($data['password']) && !empty($data['password'])) {
            // If changing password, require current password
            if (!isset($data['current_password']) || empty($data['current_password'])) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Current password is required to change password',
                    'errors' => ['current_password' => 'Current password is required']
                ]);
                exit;
            }
            
            // Verify current password
            $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $user = $result->fetch_assoc();
            
            if (!password_verify($data['current_password'], $user['password'])) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Current password is incorrect',
                    'errors' => ['current_password' => 'Current password is incorrect']
                ]);
                exit;
            }
            
            // Add new password to update fields
            $hashedPassword = password_hash($data['password'], PASSWORD_BCRYPT);
            $updateFields[] = "password = ?";
            $params[] = $hashedPassword;
            $types .= 's';
        }
        
        if (empty($updateFields)) {
            echo json_encode([
                'success' => false,
                'message' => 'No fields to update'
            ]);
            exit;
        }
        
        // Add user ID to params
        $params[] = $userId;
        $types .= 'i';
        
        // Execute update
        $sql = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        
        if ($stmt->execute()) {
            // Get updated user data
            $stmt = $conn->prepare("
                SELECT id, first_name, last_name, email, phone_number, role
                FROM users WHERE id = ?
            ");
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            $user = $result->fetch_assoc();
            
            // Format response for mobile app
            $response = [
                'id' => $user['id'],
                'first_name' => $user['first_name'],
                'last_name' => $user['last_name'],
                'name' => $user['first_name'] . ' ' . $user['last_name'],
                'email' => $user['email'],
                'phone_number' => $user['phone_number'],
                'role' => $user['role']
            ];
            
            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully',
                'data' => $response
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to update profile',
                'error' => $conn->error
            ]);
        }
        break;
        
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Method not allowed'
        ]);
        http_response_code(405);
}
?>