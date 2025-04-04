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
if (!isset($input['email']) || !isset($input['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required'
    ]);
    exit;
}

// Get the email and password
$email = $conn->real_escape_string(trim($input['email']));
$password = $input['password']; // Password will be verified by Firebase

// Optional: Firebase token from client
$firebaseToken = $input['firebase_token'] ?? null;

$firebase = new FirebaseHelper();
$jwtHelper = new JWTHelper();

// If Firebase token is provided, verify it
if ($firebaseToken) {
    $claims = $firebase->verifyIdToken($firebaseToken);
    
    if ($claims) {
        // Token is valid, get user from database
        $firebaseUid = $claims['sub']; // Firebase UID
        
        // Look up user by Firebase UID
        $stmt = $conn->prepare("SELECT * FROM users WHERE firebase_uid = ?");
        $stmt->bind_param("s", $firebaseUid);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            
            // Update last login time
            $updateStmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
            $updateStmt->bind_param("i", $user['id']);
            $updateStmt->execute();
            
            // Generate JWT token
            $token = $jwtHelper->generateToken($user['id'], $user['email'], $user['role']);
            
            // Return success response
            echo json_encode([
                'success' => true,
                'token' => $token,
                'user' => [
                    'id' => $user['id'],
                    'name' => $user['name'],
                    'email' => $user['email'],
                    'role' => $user['role'],
                    'phone_number' => $user['phone_number']
                ]
            ]);
            exit;
        }
    }
}

// If Firebase token is invalid or not provided, fall back to database login
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // Verify password
    if (password_verify($password, $user['password'])) {
        // Password is correct
        
        // Update last login time
        $updateStmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
        $updateStmt->bind_param("i", $user['id']);
        $updateStmt->execute();
        
        // Generate JWT token
        $token = $jwtHelper->generateToken($user['id'], $user['email'], $user['role']);
        
        // Return success response
        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'phone_number' => $user['phone_number']
            ]
        ]);
    } else {
        // Password is incorrect
        echo json_encode([
            'success' => false,
            'message' => 'Invalid credentials'
        ]);
    }
} else {
    // User not found
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
}
?><?php
require_once 'connect.php';
require_once 'firebase_helper.php';
require_once 'jwt_helper.php';

// Set headers for JSON response
header('Content-Type: application/json');

// Parse JSON input
$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

// Check for required fields
if (!isset($input['email']) || !isset($input['password'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required'
    ]);
    exit;
}

// Get the email and password
$email = $conn->real_escape_string(trim($input['email']));
$password = $input['password']; // Password will be verified by Firebase

// Optional: Firebase token from client
$firebaseToken = $input['firebase_token'] ?? null;

$firebase = new FirebaseHelper();
$jwtHelper = new JWTHelper();

// If Firebase token is provided, verify it
if ($firebaseToken) {
    $claims = $firebase->verifyIdToken($firebaseToken);
    
    if ($claims) {
        // Token is valid, get user from database
        $firebaseUid = $claims['sub']; // Firebase UID
        
        // Look up user by Firebase UID
        $stmt = $conn->prepare("SELECT * FROM users WHERE firebase_uid = ?");
        $stmt->bind_param("s", $firebaseUid);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            
            // Update last login time
            $updateStmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
            $updateStmt->bind_param("i", $user['id']);
            $updateStmt->execute();
            
            // Generate JWT token
            $token = $jwtHelper->generateToken($user['id'], $user['email'], $user['role']);
            
            // Return success response
            echo json_encode([
                'success' => true,
                'token' => $token,
                'user' => [
                    'id' => $user['id'],
                    'name' => $user['name'],
                    'email' => $user['email'],
                    'role' => $user['role'],
                    'phone_number' => $user['phone_number']
                ]
            ]);
            exit;
        }
    }
}

// If Firebase token is invalid or not provided, fall back to database login
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // Verify password
    if (password_verify($password, $user['password'])) {
        // Password is correct
        
        // Update last login time
        $updateStmt = $conn->prepare("UPDATE users SET last_login = NOW() WHERE id = ?");
        $updateStmt->bind_param("i", $user['id']);
        $updateStmt->execute();
        
        // Generate JWT token
        $token = $jwtHelper->generateToken($user['id'], $user['email'], $user['role']);
        
        // Return success response
        echo json_encode([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'phone_number' => $user['phone_number']
            ]
        ]);
    } else {
        // Password is incorrect
        echo json_encode([
            'success' => false,
            'message' => 'Invalid credentials'
        ]);
    }
} else {
    // User not found
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
}
?>