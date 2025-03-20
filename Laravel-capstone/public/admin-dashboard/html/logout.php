<?php
session_start();

// Check if the logout confirmation button was pressed
if (isset($_POST['confirm_logout'])) {
    // If confirmed, destroy the session and redirect
    session_unset();
    session_destroy();
    header("Location: login.php");
    exit();
}

// If not confirmed, show the confirmation message
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirm Logout</title>
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/logout.css">
</head>
<body>
    <div class="dashboard-container">
        <div class="logout-confirmation">
            <h2>Are you sure you want to log out?</h2>
            <form method="post">
                <button type="submit" name="confirm_logout">Yes, Log Out</button>
                <a href="index.php" class="cancel-button">Cancel</a>
            </form>
        </div>
    </div>
</body>
</html>