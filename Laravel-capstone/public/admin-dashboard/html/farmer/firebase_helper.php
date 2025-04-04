<?php
// Place this file in your backend directory, e.g., admin-dashboard/html/farmer/firebase_helper.php

require_once 'connect.php';
require_once 'config.php';
require_once __DIR__ . '/vendor/autoload.php'; // Ensure you have firebase/php-jwt installed

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class FirebaseHelper {
    private $projectId;
    
    public function __construct() {
        // Your Firebase project ID from firebase_options.dart
        $this->projectId = 'YOUR_PROJECT_ID'; // Replace with your actual Firebase project ID
    }
    
    /**
     * Verify Firebase ID token
     */
    public function verifyIdToken($idToken) {
        try {
            // For proper implementation, you should use the Firebase Admin SDK
            // This is a simplified verification for demonstration
            // Load public keys from Google's public certificate endpoint
            $response = file_get_contents('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
            $keys = json_decode($response, true);
            
            // Get token header to identify which key to use
            $tokenParts = explode('.', $idToken);
            $header = json_decode(base64_decode($tokenParts[0]), true);
            
            if (isset($header['kid']) && isset($keys[$header['kid']])) {
                $key = $keys[$header['kid']];
                try {
                    $decoded = JWT::decode($idToken, new Key($key, 'RS256'));
                    
                    // Verify token is for your project
                    if ($decoded->aud !== $this->projectId) {
                        throw new Exception('Invalid audience');
                    }
                    
                    // Verify token is not expired
                    if ($decoded->exp < time()) {
                        throw new Exception('Token expired');
                    }
                    
                    return $decoded;
                } catch (Exception $e) {
                    error_log('Token validation error: ' . $e->getMessage());
                    return null;
                }
            } else {
                error_log('Unable to find appropriate key for token');
                return null;
            }
        } catch (Exception $e) {
            error_log('Firebase verification error: ' . $e->getMessage());
            return null;
        }
    }
    
    /**
     * Store/update user from Firebase in MySQL database
     */
    public function storeUserInDatabase($firebaseUid, $userData, $conn) {
        // Check if user already exists
        $stmt = $conn->prepare("SELECT id FROM users WHERE firebase_uid = ?");
        $stmt->bind_param("s", $firebaseUid);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            // User exists, update information
            $row = $result->fetch_assoc();
            $userId = $row['id'];
            
            $stmt = $conn->prepare("UPDATE users SET 
                name = ?, 
                email = ?,
                phone_number = ?,
                updated_at = NOW()
                WHERE id = ?");
                
            $stmt->bind_param("sssi", 
                $userData['name'],
                $userData['email'],
                $userData['phone_number'],
                $userId
            );
            
            $stmt->execute();
            return $userId;
        } else {
            // Create new user
            $stmt = $conn->prepare("INSERT INTO users 
                (firebase_uid, name, email, phone_number, role, created_at, updated_at) 
                VALUES (?, ?, ?, ?, 'farmer', NOW(), NOW())");
            
            $role = 'farmer'; // Default role for new users
            
            $stmt->bind_param("ssss", 
                $firebaseUid,
                $userData['name'],
                $userData['email'],
                $userData['phone_number']
            );
            
            if ($stmt->execute()) {
                return $conn->insert_id;
            } else {
                error_log("Error creating user: " . $stmt->error);
                return false;
            }
        }
    }
}
?>