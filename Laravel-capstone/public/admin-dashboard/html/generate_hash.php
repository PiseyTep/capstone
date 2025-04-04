<?php
// Password Hashing and Verification Script

// Function to simulate Laravel's password hashing
function laravelPasswordHash($password) {
    // Laravel uses bcrypt with specific cost and format
    return password_hash($password, PASSWORD_BCRYPT, [
        'cost' => 12 // Laravel typically uses cost of 10-12
    ]);
}

// Function to verify password (compatible with Laravel)
function verifyLaravelPassword($plainPassword, $hashedPassword) {
    return password_verify($plainPassword, $hashedPassword);
}

// Test password
$testPassword = 'Password@123';

// Generate hash
$hashedPassword = laravelPasswordHash($testPassword);

// Verification Test
echo "Original Password: $testPassword\n";
echo "Hashed Password: $hashedPassword\n";
echo "Verification Result: " . 
    (verifyLaravelPassword($testPassword, $hashedPassword) ? 'Success' : 'Failed') . "\n";

// Database Update Query (for reference)
echo "\nMySQL Update Query:\n";
echo "UPDATE users SET password = '" . $hashedPassword . "' WHERE email = 'your_email@example.com';\n";
?>