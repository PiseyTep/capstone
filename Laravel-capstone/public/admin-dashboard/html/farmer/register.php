<?php
require_once 'connect.php';
require_once 'firebase_helper.php';
require_once 'jwt_helper.php';

// Set headers for JSON response
header('Content-Type: application/json');

// Parse JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Check for required fields
if (!isset($input['first_name']) || !isset($input['email']) || !isset($input['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'First name, email, and password are required'
    ]);
    exit;
}

// Get the input data
$firstName = $conn->real_escape_string(trim($input['first_name']));
$lastName = $conn->real_escape_string(trim($input['last_name'] ?? ''));
$email = $conn->real_escape_string(trim($input['email']));
$password = $input['password']; // Original password for Firebase
$hashedPassword = password_hash($password, PASSWORD_DEFAULT); // Hashed for MySQL
$phoneNumber = $conn->real_escape_string(trim($input['phone_number'] ?? ''));
$firebaseUid = $input['firebase_uid'] ?? null; // Firebase UID if provided

// Check if email already exists
$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Email already registered'
    ]);
    exit;
}

// Create user record
$name = $firstName . ($lastName ? ' ' . $lastName : '');
$role = 'farmer'; // Default role

$firebase = new FirebaseHelper();
$jwtHelper = new JWTHelper();

// If Firebase UID provided, use it
if ($firebaseUid) {
    $userData = [
        'name' => $name,
        'email' => $email,
        'phone_number' => $phoneNumber
    ];
    
    $userId = $firebase->storeUserInDatabase($firebaseUid, $userData, $conn);
    
    if ($userId) {
        // Generate JWT token
        $token = $jwtHelper->generateToken($userId, $email, $role);
        
        echo json_encode([
            'success' => true,
            'message' => 'User registered successfully',
            'token' => $token,
            'user' => [
                'id' => $userId,
                'name' => $name,
                'email' => $email,
                'role' => $role,
                'phone_number' => $phoneNumber
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Error creating user record'
        ]);
    }
} else {
    // Traditional registration without Firebase
    $stmt = $conn->prepare("INSERT INTO users (name, email, password, phone_number, role, created_at, updated_at) 
                        VALUES (?, ?, ?, ?, ?, NOW(), NOW())");
    $stmt->bind_param("sssss", $name, $email, $hashedPassword, $phoneNumber, $role);
    
    if ($stmt->execute()) {
        $userId = $conn->insert_id;
        
        // Generate JWT token
        $token = $jwtHelper->generateToken($userId, $email, $role);
        
        echo json_encode([
            'success' => true,
            'message' => 'User registered successfully',
            'token' => $token,
            'user' => [
                'id' => $userId,
                'name' => $name,
                'email' => $email,
                'role' => $role,
                'phone_number' => $phoneNumber
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Error creating user account'
        ]);
    }
}
?>