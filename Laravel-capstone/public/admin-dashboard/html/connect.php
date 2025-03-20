<?php
$servername = "localhost";
$username = "root";
$password = "Pisey@123";
$dbname = "agriTech-poineer";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Optional: Set charset to UTF-8
$conn->set_charset("utf8mb4");

// Remove or comment out the following line
// echo "Connected successfully!";
?>