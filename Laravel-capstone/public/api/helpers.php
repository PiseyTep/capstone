<?php
// Helper functions for API

// Generate JWT token
function generateToken($userId, $role = 'farmer') {
    $header = [
        'alg' => JWT_ALGO,
        'typ' => 'JWT'
    ];
    
    $payload = [
        'user_id' => $userId,
        'role' => $role,
        'iat' => time(),
        'exp' => time() + TOKEN_EXPIRE
    ];
    
    $headerEncoded = base64UrlEncode(json_encode($header));
    $payloadEncoded = base64UrlEncode(json_encode($payload));
    
    $signature = hash_hmac('sha256', 
                          $headerEncoded . '.' . $payloadEncoded, 
                          JWT_SECRET, 
                          true);
    $signatureEncoded = base64UrlEncode($signature);
    
    return $headerEncoded . '.' . $payloadEncoded . '.' . $signatureEncoded;
}

// Validate JWT token
function validateToken() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    
    if (empty($authHeader) || !preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        return false;
    }
    
    $token = $matches[1];
    $parts = explode('.', $token);
    
    if (count($parts) !== 3) {
        return false;
    }
    
    list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;
    
    $signature = base64UrlDecode($signatureEncoded);
    $expectedSignature = hash_hmac('sha256', 
                                  $headerEncoded . '.' . $payloadEncoded, 
                                  JWT_SECRET, 
                                  true);
    
    if (!hash_equals($expectedSignature, $signature)) {
        return false;
    }
    
    $payload = json_decode(base64UrlDecode($payloadEncoded), true);
    
    // Check if token is expired
    if (isset($payload['exp']) && $payload['exp'] < time()) {
        return false;
    }
    
    return $payload;
}

// Helper function for JWT encoding
function base64UrlEncode($data) {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

// Helper function for JWT decoding
function base64UrlDecode($data) {
    return base64_decode(strtr($data, '-_', '+/'));
}
?>