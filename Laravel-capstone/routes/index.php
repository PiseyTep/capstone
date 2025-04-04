<?php
// API Test
$api_url = 'http://localhost/LoginFarmer/Laravel-capstone/public/api/status';

// Make request to API
$ch = curl_init($api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$info = curl_getinfo($ch);
$error = curl_error($ch);
curl_close($ch);

// Show the response
echo "<h2>API Connection Test</h2>";
echo "<p>Testing connection to: <strong>{$api_url}</strong></p>";

echo "<h3>Request Information:</h3>";
echo "<ul>";
echo "<li>HTTP Status: " . $info['http_code'] . "</li>";
echo "<li>Content Type: " . $info['content_type'] . "</li>";
echo "<li>Total Time: " . $info['total_time'] . " seconds</li>";
echo "</ul>";

if ($response === false) {
    echo "<h3 style='color: red;'>Connection failed</h3>";
    echo "<p>Error: " . $error . "</p>";
} else {
    echo "<h3 style='color: green;'>Connection successful</h3>";
    echo "<h4>Raw Response:</h4>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    
    $decoded = json_decode($response, true);
    if ($decoded === null) {
        echo "<p style='color: red;'>Failed to decode JSON response.</p>";
        echo "<p>JSON error: " . json_last_error_msg() . "</p>";
    } else {
        echo "<h4>Decoded Response:</h4>";
        echo "<pre>" . json_encode($decoded, JSON_PRETTY_PRINT) . "</pre>";
    }
}
?>