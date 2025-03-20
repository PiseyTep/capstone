

<?php
// Replace 'your_actual_password' with whatever password you want to use
$password = 'Password@123';
$hashed_password = password_hash($password, PASSWORD_BCRYPT);
echo "Password: $password\n";
echo "Hashed: $hashed_password\n";
?>
