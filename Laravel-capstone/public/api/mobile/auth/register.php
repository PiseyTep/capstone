<?php
// Mobile registration endpoint
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../helpers.php';

// Get request data
$data = json_decode(file_get_contents('php://input'), true);

if (!$data) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request data'
    ]);
    exit;
}

// Validate required fields
$required_fields = ['first_name', 'last_name', 'email', 'password', 'phone_number'];
$errors = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
    }
}

if (!empty($errors)) {
    echo json_encode([
        'success' => false,
        'message' => 'Validation failed',
        'errors' => $errors
    ]);
    exit;
}

$firstName = $data['first_name'];
$lastName = $data['last_name'];
$email = $data['email'];
$password = $data['password'];
$phoneNumber = $data['phone_number'];

// Check if email already exists
$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Email already in use',
        'errors' => ['email' => 'This email address is already registered']
    ]);
    exit;
}

// Hash password
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// Insert new user - set role to 'farmer' for mobile app users
$stmt = $conn->prepare("INSERT INTO users (first_name, last_name, email, password, phone_number, role, approved) VALUES (?, ?, ?, ?, ?, 'farmer', 1)");
$stmt->bind_param("sssss", $firstName, $lastName, $email, $hashedPassword, $phoneNumber);

if ($stmt->execute()) {
    $userId = $conn->insert_id;
    
    // Generate token for automatic login
    $token = generateToken($userId, 'farmer');
    
    echo json_encode([
        'success' => true,
        'message' => 'Registration successful',
        'data' => [
            'user' => [
                'id' => $userId,
                'name' => $firstName . ' ' . $lastName,
                'email' => $email,
                'role' => 'farmer'
            ],
            'token' => $token
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Registration failed',
        'error' => $conn->error
    ]);
}
?>