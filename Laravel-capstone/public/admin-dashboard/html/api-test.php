<!-- 
 


create for test only on need in project 

 -->






<?php
// API Test
$api_url = 'http://localhost/LoginFarmer/Laravel-capstone/public/api/status';

// Make request to API
$ch = curl_init($api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

// Show the response
echo "<h2>API Connection Test</h2>";
echo "<p>Testing connection to: <strong>{$api_url}</strong></p>";

if ($response === false) {
    echo "<p style='color: red;'>Connection failed</p>";
} else {
    echo "<p style='color: green;'>Connection successful</p>";
    echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";
}
?>