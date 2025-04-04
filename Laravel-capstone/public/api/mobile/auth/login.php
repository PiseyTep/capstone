<?php
// Mobile login endpoint
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../helpers.php';

// Get request data
$data = json_decode(file_get_contents('php://input'), true);

if (!$data || !isset($data['email']) || !isset($data['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required'
    ]);
    exit;
}

$email = $data['email'];
$password = $data['password'];

// Verify credentials
$stmt = $conn->prepare("SELECT id, first_name, last_name, email, password, role, approved FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();
    
    if (password_verify($password, $user['password'])) {
        // Check if account is approved
        if (!$user['approved']) {
            echo json_encode([
                'success' => false,
                'message' => 'Your account is pending approval'
            ]);
            exit;
        }
        
        // Check if user is a farmer
        if ($user['role'] !== 'farmer') {
            echo json_encode([
                'success' => false,
                'message' => 'This API is for farmers only. Administrators should use the web interface.'
            ]);
            exit;
        }
        
        // Generate JWT token
        $token = generateToken($user['id'], $user['role']);
        
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => [
                    'id' => $user['id'],
                    'name' => $user['first_name'] . ' ' . $user['last_name'],
                    'email' => $user['email'],
                    'role' => $user['role']
                ],
                'token' => $token
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid credentials'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
}
?>