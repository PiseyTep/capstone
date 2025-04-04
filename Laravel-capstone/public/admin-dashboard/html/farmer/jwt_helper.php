<?php
require_once 'config.php';
require_once __DIR__ . '/vendor/autoload.php';

use Firebase\JWT\JWT;

class JWTHelper {
    public function generateToken($userId, $email, $role) {
        $issuedAt = time();
        $expirationTime = $issuedAt + TOKEN_EXPIRE;
        
        $payload = [
            'iat' => $issuedAt,
            'exp' => $expirationTime,
            'user_id' => $userId,
            'email' => $email,
            'role' => $role
        ];
        
        return JWT::encode($payload, JWT_SECRET, JWT_ALGO);
    }
    
    public function verifyToken($token) {
        try {
            $decoded = JWT::decode($token, JWT_SECRET, [JWT_ALGO]);
            return $decoded;
        } catch (Exception $e) {
            error_log('JWT verification error: ' . $e->getMessage());
            return null;
        }
    }
}
?>