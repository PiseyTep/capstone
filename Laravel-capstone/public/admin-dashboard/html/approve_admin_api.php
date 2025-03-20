<?php
header("Content-Type: application/json");
include("../connect.php");
session_start();

// Check if user is logged in and is a super admin
if (!isset($_SESSION['email']) || !isset($_SESSION['role']) || $_SESSION['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(["message" => "Forbidden: Only super admins can access this resource"]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$request_uri = $_SERVER['REQUEST_URI'];
$path = parse_url($request_uri, PHP_URL_PATH);
$paths = explode('/', $path);

// Get the admin ID
$id = null;
foreach ($paths as $index => $part) {
    if ($part === 'admins' && isset($paths[$index + 1]) && is_numeric($paths[$index + 1])) {
        $id = $paths[$index + 1];
        break;
    }
}

if (!$id) {
    http_response_code(400);
    echo json_encode(["message" => "Admin ID required"]);
    exit;
}

switch ($method) {
    case 'PUT':
        // Approve an admin
        $query = "UPDATE admin SET approved = 1 WHERE id = ?";
        $stmt = $conn->prepare($query);
        
        if ($stmt === false) {
            http_response_code(500);
            echo json_encode(["message" => "Database error: " . $conn->error]);
            exit;
        }
        
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(["message" => "Administrator approved successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Failed to approve administrator: " . $stmt->error]);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(["message" => "Method not allowed"]);
        break;
}

$conn->close();
?>