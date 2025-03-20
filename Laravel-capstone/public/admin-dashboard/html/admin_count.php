<?php
header("Content-Type: application/json");
include("connect.php");

$query = "SELECT COUNT(*) as count FROM `users`";
$result = mysqli_query($conn, $query);

if (!$result) {
    http_response_code(500);
    echo json_encode(["message" => "Database error: " . mysqli_error($conn)]);
    exit;
}

$row = mysqli_fetch_assoc($result);
echo json_encode(["count" => (int)$row['count']]);

$conn->close();
?>