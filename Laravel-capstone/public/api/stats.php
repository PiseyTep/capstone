<?php
// File: api/stats.php
error_reporting(E_ALL);
ini_set('display_errors', 1);

session_start();
include("/LoginFarmer/Laravel-capstone/public/admin-dashboard/html/connect.php");

// Check if user is logged in
if (!isset($_SESSION['email'])) {
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Unauthorized access']);
    exit();
}

header('Content-Type: application/json');

// Function to get admin accounts count
function getAdminCount($conn) {
    $query = "SELECT COUNT(*) as admin_account FROM `users`";
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        return 0;
    }
    
    $row = mysqli_fetch_assoc($result);
    return $row['admin_account'];
}

// Function to get total farmers count
function getFarmersCount($conn) {
    $query = "SELECT COUNT(*) as total_farmers FROM `farmers`";
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        return 0;
    }
    
    $row = mysqli_fetch_assoc($result);
    return $row['total_farmers'];
}

// Function to get total machinery count
function getMachineryCount($conn) {
    $query = "SELECT COUNT(*) as total_machines FROM `machinery`";
    $result = mysqli_query($conn, $query);
    
    if (!$result) {
        return 0;
    }
    
    $row = mysqli_fetch_assoc($result);
    return $row['total_machines'];
}

// Function to get monthly rental data
function getMonthlyRentalData($conn) {
    $months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    $currentYear = date('Y');
    $data = [];
    
    foreach ($months as $index => $month) {
        $monthNum = $index + 1;
        $query = "SELECT COUNT(*) as rental_count FROM `rentals` 
                 WHERE MONTH(rental_date) = $monthNum AND YEAR(rental_date) = $currentYear";
        $result = mysqli_query($conn, $query);
        
        if (!$result) {
            $data[] = 0;
            continue;
        }
        
        $row = mysqli_fetch_assoc($result);
        $data[] = (int)$row['rental_count'];
    }
    
    return [
        'labels' => $months,
        'data' => $data
    ];
}

// Process form data if it's a POST request to save data
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check for required fields and validate data
    // This is where you'd handle saving new data to your database
    
    $response = ['success' => true, 'message' => 'Data saved successfully'];
    echo json_encode($response);
    exit();
}

// Return stats data for dashboard
$response = [
    'adminAccount' => getAdminCount($conn),
    'totalFarmers' => getFarmersCount($conn),
    'totalMachines' => getMachineryCount($conn),
    'monthlyRentals' => getMonthlyRentalData($conn)
];

echo json_encode($response);
?>