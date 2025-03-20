<?php
session_start();
include("connect.php");

header('Content-Type: application/json');

// Fetch admin count
$query = "SELECT COUNT(*) as adminAccount FROM `users`";
$result = mysqli_query($conn, $query);
$row = mysqli_fetch_assoc($result);
$adminAccount = $row['adminAccount'];

// Fetch total farmers
$query = "SELECT COUNT(*) as totalFarmers FROM `farmers`"; // Adjust table name
$result = mysqli_query($conn, $query);
$row = mysqli_fetch_assoc($result);
$totalFarmers = $row['totalFarmers'];

// Fetch total machinery
$query = "SELECT COUNT(*) as totalMachines FROM `machinery`"; // Adjust table name
$result = mysqli_query($conn, $query);
$row = mysqli_fetch_assoc($result);
$totalMachines = $row['totalMachines'];

// Return JSON response
echo json_encode([
    'adminAccount' => $adminAccount,
    'totalFarmers' => $totalFarmers,
    'totalMachines' => $totalMachines
]);
?>