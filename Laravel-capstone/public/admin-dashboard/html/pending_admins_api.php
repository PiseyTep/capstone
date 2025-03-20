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

switch ($method) {
    case 'GET':
        // Get all pending admins
        $query = "SELECT * FROM users WHERE approved = 0";
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            http_response_code(500);
            echo json_encode(["message" => "Database error: " . mysqli_error($conn)]);
            exit;
        }
        
        $admins = [];
        while ($row = mysqli_fetch_assoc($result)) {
            // Don't include password in the response
            unset($row['password']);
            $admins[] = $row;
        }
        
        echo json_encode($admins);
        break;
        
    default:
        http_response_code(405);
        echo json_encode(["message" => "Method not allowed"]);
        break;
}

$conn->close();
?>