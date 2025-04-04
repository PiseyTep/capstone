<?php
// Strict error reporting and security settings
error_reporting(E_ALL);
ini_set('display_errors', 0);

// Secure session configuration
ini_set('session.save_path', '/tmp');
ini_set('session.use_strict_mode', 1);
ini_set('session.cookie_httponly', 1);
ini_set('session.cookie_samesite', 'Strict');

// Start output buffering
ob_start();

// Start secure session
session_start();

// Define users file path
define('USERS_FILE', __DIR__ . '/users.json');

// User Management Class
class UserManager {
    private $usersFile;

    public function __construct($usersFile) {
        $this->usersFile = $usersFile;
        
        // Ensure users file exists
        if (!file_exists($this->usersFile)) {
            file_put_contents($this->usersFile, json_encode([]));
        }
    }

    // Read users from file
    private function readUsers() {
        $users = file_get_contents($this->usersFile);
        return json_decode($users, true) ?: [];
    }

    // Write users to file
    private function writeUsers($users) {
        $jsonUsers = json_encode($users, JSON_PRETTY_PRINT);
        file_put_contents($this->usersFile, $jsonUsers);
    }

    // Verify user credentials
    public function verifyUser($email, $password) {
        $users = $this->readUsers();
        
        foreach ($users as $user) {
            if ($user['email'] === $email) {
                // Verify password
                if (password_verify($password, $user['password'])) {
                    return $user;
                }
                break;
            }
        }
        return false;
    }

    // Register new user
    public function registerUser($userData) {
        $users = $this->readUsers();
        
        // Check if email already exists
        foreach ($users as $user) {
            if ($user['email'] === $userData['email']) {
                return false;
            }
        }
        
        // Hash password
        $userData['password'] = password_hash($userData['password'], PASSWORD_DEFAULT);
        
        // Add unique ID
        $userData['id'] = uniqid();
        
        // Add timestamp
        $userData['created_at'] = date('Y-m-d H:i:s');
        
        // Assign role if not set
        $userData['role'] = $userData['role'] ?? 'user';
        
        // Add to users array
        $users[] = $userData;
        
        // Write back to file
        $this->writeUsers($users);
        
        return true;
    }
}

// Initialize User Manager
$userManager = new UserManager(USERS_FILE);

// Handle User Login
if (isset($_POST['signIn'])) {
    // Validate input
    $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
    $password = $_POST['password'] ?? '';
    
    if (!$email) {
        $error_message = "Invalid email address.";
    } elseif (empty($password)) {
        $error_message = "Password cannot be empty.";
    } else {
        // Attempt to verify user
        $user = $userManager->verifyUser($email, $password);
        
        if ($user) {
            // Clear existing session data
            session_unset();
            session_destroy();
            session_start();
            
            // Set new session data
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['email'] = $user['email'];
            $_SESSION['name'] = $user['name'];
            $_SESSION['role'] = $user['role'] ?? 'user';
            
            // Regenerate session ID for security
            session_regenerate_id(true);
            
            // Redirect based on role
            switch ($_SESSION['role']) {
                case 'admin':
                case 'super_admin':
                    header("Location: index.php");
                    break;
                default:
                    header("Location: index.php");
            }
            exit();
        } else {
            $error_message = "Invalid email or password.";
        }
    }
}

// Handle User Registration
if (isset($_POST['signUp'])) {
    // Validate input
    $firstName = filter_input(INPUT_POST, 'first_name', FILTER_SANITIZE_STRING);
    $lastName = filter_input(INPUT_POST, 'last_name', FILTER_SANITIZE_STRING);
    $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
    $password = $_POST['password'] ?? '';
    $confirmPassword = $_POST['confirm_password'] ?? '';
    
    // Validation checks
    $errors = [];
    
    if (empty($firstName)) {
        $errors[] = "First name is required.";
    }
    
    if (empty($lastName)) {
        $errors[] = "Last name is required.";
    }
    
    if (!$email) {
        $errors[] = "Invalid email address.";
    }
    
    if (strlen($password) < 8) {
        $errors[] = "Password must be at least 8 characters long.";
    }
    
    if ($password !== $confirmPassword) {
        $errors[] = "Passwords do not match.";
    }
    
    // If no validation errors, proceed with registration
    if (empty($errors)) {
        // Prepare user data
        $userData = [
            'first_name' => $firstName,
            'last_name' => $lastName,
            'name' => $firstName . ' ' . $lastName,
            'email' => $email,
            'password' => $password,
            'role' => 'user' // Default role
        ];
        
        // Attempt to register user
        if ($userManager->registerUser($userData)) {
            $success_message = "Registration successful! You can now log in.";
        } else {
            $error_message = "Email already exists. Please use a different email.";
        }
    } else {
        // Collect validation errors
        $error_message = implode("<br>", $errors);
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login & Register</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <link rel="stylesheet" href="../css/login.css">
    <style>
        .success-message {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
            text-align: center;
        }
    </style>
</head>
<body>
    <!-- Main Container -->
    <div class="main-container">

<!-- Sign Up Form -->
<div class="container" id="signup" style="display:none;">
    <h1 class="form-title">Register</h1>
    <!-- Success Message Container -->
    <?php if (isset($success_message)) { echo "<div class='success-message'>$success_message</div>"; } ?>
    <form method="post" action="login.php">
        <!-- Form fields -->
        <div class="input-group">
            <i class="fas fa-user"></i>
            <input type="text" name="fName" id="fName" placeholder="First Name" required>
            <label for="fname">First Name</label>
        </div>
        <div class="input-group">
            <i class="fas fa-user"></i>
            <input type="text" name="lName" id="lName" placeholder="Last Name" required>
            <label for="lName">Last Name</label>
        </div>
        <div class="input-group">
            <i class="fas fa-envelope"></i>
            <input type="email" name="email" id="email" placeholder="Email" required>
            <label for="email">Email</label>
        </div>
        <div class="input-group">
            <i class="fas fa-lock"></i>
            <input type="password" name="password" id="password" placeholder="Password" required>
            <label for="password">Password</label>
        </div>
        <!-- Error Message Container -->
        <?php if (isset($error_message)) { echo "<div id='error-message' class='error-message'>$error_message</div>"; } ?>
        <input type="submit" class="btn" value="Sign Up" name="signUp">
    </form>
    <p class="or">--------or--------</p>
    <div class="icons">
        <i class="fab fa-google"></i>
        <i class="fab fa-facebook"></i>
    </div>
    <div class="links">
        <p>Already Have Account ?</p>
        <button id="signInButton">Sign In</button>
    </div>
</div>

<!-- Sign In Form -->
<div class="container" id="signIn">
    <h1 class="form-title">Sign In</h1>
    <form method="post" action="login.php">
        <!-- Form fields -->
        <div class="input-group">
            <i class="fas fa-envelope"></i>
            <input type="email" name="email" id="email" placeholder="Email" required>
            <label for="email">Email</label>
        </div>
        <div class="input-group">
            <i class="fas fa-lock"></i>
            <input type="password" name="password" id="password" placeholder="Password" required>
            <label for="password">Password</label>
        </div>
        <!-- Error Message Container -->
        <?php if (isset($error_message)) { echo "<div id='error-message' class='error-message'>$error_message</div>"; } ?>
        <p class="recover"><a href="#">Recover Password</a></p>
        <input type="submit" class="btn" value="Sign In" name="signIn">
    </form>
    <p class="or">--------or--------</p>
    <div class="icons">
        <i class="fab fa-google"></i>
        <i class="fab fa-facebook"></i>
    </div>
    <div class="links">
        <p>Don't have account yet?</p>
        <button id="signUpButton">Sign Up</button>
    </div>
</div>
    
<script>
    // Form toggle functionality
    document.addEventListener("DOMContentLoaded", function() {
        // Get toggle buttons
        const signUpButton = document.getElementById('signUpButton');
        const signInButton = document.getElementById('signInButton');
        
        // Add event listeners
        if (signUpButton) {
            signUpButton.addEventListener('click', function() {
                document.getElementById('signIn').style.display = "none";
                document.getElementById('signup').style.display = "block";
            });
        }
        
        if (signInButton) {
            signInButton.addEventListener('click', function() {
                document.getElementById('signIn').style.display = "block";
                document.getElementById('signup').style.display = "none";
            });
        }
        
        // Handle error message fade out
        const errorMessage = document.getElementById("error-message");
        if (errorMessage) {
            setTimeout(() => {
                errorMessage.style.opacity = "0"; // Fade out
                setTimeout(() => {
                    errorMessage.style.display = "none"; // Hide after fade-out
                }, 500); // Wait for the transition to complete
            }, 5000); // 5000 milliseconds = 5 seconds
        }
    });
</script>
</body>
</html>