<!-- <?php
// session_start();
// include 'connect.php';

// // Handle User Registration
// if (isset($_POST['signUp'])) {
//     // Get form data
//     $firstName = $_POST['fName'];
//     $lastName = $_POST['lName'];
//     $email = $_POST['email'];
//     $password = password_hash($_POST['password'], PASSWORD_BCRYPT); // Hash the password

//     // Check if the email already exists
//     $checkEmail = "SELECT * FROM `admin` WHERE email=?";
//     $stmt = $conn->prepare($checkEmail);
//     if ($stmt === false) {
//         echo "Error preparing email check query: " . $conn->error;
//         exit();
//     }

    // $stmt->bind_param("s", $email); // 's' for string type
    // $stmt->execute();
    // $result = $stmt->get_result();

    // if ($result->num_rows > 0) {
    //     // Email already exists
    //     $error_message = "Email Address Already Exists!";
    // } else {
    //     // Insert new admin into the database
    //     $insertQuery = $conn->prepare("INSERT INTO `admin` (firstName, lastName, email, password) VALUES (?, ?, ?, ?)");
    //     if ($insertQuery === false) {
    //         echo "Error preparing insert query: " . $conn->error;
    //         exit();
    //     }

//         $insertQuery->bind_param("ssss", $firstName, $lastName, $email, $password);
//         if ($insertQuery->execute()) {
//             // Registration successful, redirect to login page
//             header("Location: login.php?status=signup_success");
//             exit();
//         } else {
//             echo "Error: " . $insertQuery->error;
//         }
//     }
// } -->

// Handle User Sign-In
// if (isset($_POST['signIn'])) {
//     $email = $_POST['email'];
//     $password = $_POST['password'];

//     // Check if the user exists
//     $checkUser = "SELECT * FROM `admin` WHERE email=?";
//     $stmt = $conn->prepare($checkUser);
//     $stmt->bind_param("s", $email);
//     $stmt->execute();
//     $result = $stmt->get_result();

//     if ($result->num_rows == 1) {
//         $user = $result->fetch_assoc();
//         if (password_verify($password, $user['password'])) {
//             $_SESSION['user_id'] = $user['Id'];
//             $_SESSION['email'] = $user['email'];
//             header("Location: index.php");  // Redirect to index.php upon successful login
//             exit();
//         } else {
//             $error_message = "Incorrect Password!";
//         }
//     } else {
//         $error_message = "No user found with that email!";
//     }
// }
// ?>