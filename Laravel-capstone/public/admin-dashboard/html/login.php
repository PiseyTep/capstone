<?php
session_start();
include 'connect.php';

// Handle User Registration
if (isset($_POST['signUp'])) {
    // Get form data
    $firstName = $_POST['fName'];
    $lastName = $_POST['lName'];
    $email = $_POST['email'];
    $password = password_hash($_POST['password'], PASSWORD_BCRYPT); // Hash the password

    // Check if the email already exists
    $checkEmail = "SELECT * FROM `users` WHERE email=?";
    $stmt = $conn->prepare($checkEmail);
    if ($stmt === false) {
        die("Error preparing email check query: " . $conn->error);
    }
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Email already exists
        $error_message = "Email Address Already Exists!";
    } else {
        // Insert new admin into the database - defaults to unapproved status
        $insertQuery = $conn->prepare("INSERT INTO `users` (firstName, lastName, email, password, approved, role) VALUES (?, ?, ?, ?, 0, 'admin')");
        if ($insertQuery === false) {
            die("Error preparing insert query: " . $conn->error);
        }

        $insertQuery->bind_param("ssss", $firstName, $lastName, $email, $password);
        if ($insertQuery->execute()) {
            // Registration successful, show pending approval message
            $success_message = "Registration successful! Your account requires approval from a super admin before you can log in.";
        } else {
            die("Error: " . $insertQuery->error);
        }
    }
}

if (isset($_POST['signIn'])) {
  $email = $_POST['email'];
  $password = $_POST['password'];

  // Check if the user exists
  $checkUser = "SELECT * FROM `users` WHERE email=?";
  $stmt = $conn->prepare($checkUser);
  if ($stmt === false) {
      die("Error preparing user check query: " . $conn->error);
  }

  $stmt->bind_param("s", $email);
  $stmt->execute();
  $result = $stmt->get_result();

  if ($result->num_rows == 1) {
      $user = $result->fetch_assoc();

      if (password_verify($password, $user['password'])) {
          // Check if account is approved
          if (!$user['approved']) {
              $error_message = "Your account is pending approval. Please contact a super admin.";
          } else {
              // Login successful
              $_SESSION['user_id'] = $user['Id']; // Use 'Id' as per your table structure
              $_SESSION['email'] = $user['email'];
              $_SESSION['role'] = $user['role'] ?? 'admin'; // Store the role in session
              
              header("Location: /LoginFarmer/Laravel-capstone/public/admin-dashboard/html/index.php"); // Redirect to index.php upon successful login
              exit();
          }
      } else {
          $error_message = "Incorrect Password!";
      }
  } else {
      $error_message = "No user found with that email!";
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
    
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/login.css">
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