<?php
require_once 'connect.php';
require_once 'vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

$headers = getallheaders();
$token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');

try {
    $decoded = JWT::decode($token, new Key(JWT_SECRET, JWT_ALGO));
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Token is valid',
        'data' => $decoded->data
    ]);
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid token',
        'error' => $e->getMessage()
    ]);
}