<?php
session_start();
include("connect.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);

function redirect($url) {
    header("Location: $url");
    exit();
}

// Check if user is logged in
if (!isset($_SESSION['email'])) {
    redirect("login.php");
}

// Check if user is a super admin
$email = $_SESSION['email'];
$query = $conn->prepare("SELECT * FROM `users` WHERE email=?");
$query->bind_param("s", $email);
$query->execute();
$user = $query->get_result()->fetch_assoc();

if (!$user || $user['role'] !== 'super_admin') {
    redirect("index.php?error=permission");
}

// Initialize admin arrays
$pendingAdmins = [];
$approvedAdmins = [];

// Check if super admin
$isSuperAdmin = ($user && isset($user['role']) && $user['role'] === 'super_admin');

// If not super admin, redirect to dashboard
if (!$isSuperAdmin) {
    header("Location: index.php?error=permission");
    exit();
}

// Fetch pending admins directly from database
$pendingAdmins = [];
$pendingQuery = $conn->prepare("SELECT * FROM `users` WHERE approved = 0");
$pendingQuery->execute();
$result = $pendingQuery->get_result();
while ($row = $result->fetch_assoc()) {
    $pendingAdmins[] = $row;
}

// Fetch all approved admins directly from database
$approvedAdmins = [];
$approvedQuery = $conn->prepare("SELECT * FROM `users` WHERE approved = 1");
$approvedQuery->execute();
$result = $approvedQuery->get_result();
while ($row = $result->fetch_assoc()) {
    $approvedAdmins[] = $row;
}

// Handle admin approval
if (isset($_POST['approve_admin']) && isset($_POST['admin_id'])) {
    $adminId = $_POST['admin_id'];
    $updateQuery = $conn->prepare("UPDATE `users` SET approved = 1 WHERE id = ?");
    $updateQuery->bind_param("i", $adminId);
    if ($updateQuery->execute()) {
        header("Location: manage_admins.php?success=approved");
        exit();
    } else {
        $error_message = "Error approving administrator: " . $conn->error;
    }
}

// Handle admin deletion
if (isset($_POST['delete_admin']) && isset($_POST['admin_id'])) {
    $adminId = $_POST['admin_id'];
    $deleteQuery = $conn->prepare("DELETE FROM `users` WHERE id = ? AND id != ?");
    $deleteQuery->bind_param("ii", $adminId, $user['id']);
    if ($deleteQuery->execute()) {
        header("Location: manage_admins.php?success=deleted");
        exit();
    } else {
        $error_message = "Error deleting administrator: " . $conn->error;
    }
}

// Handle adding new admin
if (isset($_POST['add_admin'])) {
    $firstName = $_POST['firstName'];
    $lastName = $_POST['lastName'];
    $email = $_POST['email'];
    $password = password_hash($_POST['password'], PASSWORD_BCRYPT);
    $role = $_POST['adminRole'];
    $approved = $_POST['adminApproved'];
    
    // Check if email already exists
    $checkEmail = $conn->prepare("SELECT * FROM `users` WHERE email = ?");
    $checkEmail->bind_param("s", $email);
    $checkEmail->execute();
    $checkResult = $checkEmail->get_result();

    if ($checkResult->num_rows > 0) {
        $error_message = "Email already exists!";
    } else {
        $insertQuery = $conn->prepare("INSERT INTO users (first_name, last_name, email, password, role, approved) VALUES (?, ?, ?, ?, ?, ?)");
        $insertQuery->bind_param("sssssi", $firstName, $lastName, $email, $password, $role, $approved);
        
        if ($insertQuery->execute()) {
            header("Location: manage_admins.php?success=added");
            exit();
        } else {
            $error_message = "Error adding administrator: " . $insertQuery->error;
        }
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AgriTech Pioneer - Manage Admins</title>
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/dashboard.css">
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/manage_admin.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <div class="dashboard-container">
        <aside class="sidebar">
            <div class="logo-container">
                <i class="fas fa-seedling"></i>
                <h2>AgriTech Pioneer</h2>
            </div>
            <ul>
                <li><a href="index.php"><i class="fas fa-home"></i> Dashboard</a></li>
                <li><a href="rentals.html"><i class="fas fa-exchange-alt"></i> Track Rentals</a></li>
                <li><a href="products.html"><i class="fas fa-tractor"></i> Manage Products</a></li>
                <li><a href="post_video.html"><i class="fas fa-video"></i> Post Video</a></li>
                <li><a href="manage_admins.php" class="active"><i class="fas fa-user-shield"></i> Manage Admins</a></li>
                <li><a href="logout.php" id="logout"><i class="fas fa-sign-out-alt"></i> Logout</a></li>
            </ul>
            <div class="sidebar-footer">
                <p>&copy; 2025 AgriTech Pioneer</p>
            </div>
        </aside>

        <main class="dashboard-content">
            <header>
                <div class="header-title">
                    <h2><i class="fas fa-user-shield"></i> Manage Administrators</h2>
                </div>
                <div class="profile">
                    <div class="notification">
                        <i class="fas fa-bell"></i>
                        <span class="notification-count"><?php echo count($pendingAdmins); ?></span>
                    </div>
                    <div class="admin-profile">
                        <div class="admin-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <span id="adminName"><?php echo $user['first_name'] . ' ' . $user['last_name']; ?></span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                </div>
            </header>

            <?php if (isset($_GET['success'])): ?>
                <div class="success-message">
                    <i class="fas fa-check-circle"></i>
                    <?php if ($_GET['success'] === 'approved'): ?>
                        <p>Administrator account has been approved successfully!</p>
                    <?php elseif ($_GET['success'] === 'deleted'): ?>
                        <p>Administrator account has been deleted successfully!</p>
                    <?php elseif ($_GET['success'] === 'added'): ?>
                        <p>New administrator has been added successfully!</p>
                    <?php endif; ?>
                </div>
            <?php endif; ?>

            <?php if (isset($error_message)): ?>
                <div class="error-message">
                    <i class="fas fa-exclamation-circle"></i>
                    <p><?php echo $error_message; ?></p>
                </div>
            <?php endif; ?>

            <section class="form-section">
                <h3>Add New Administrator</h3>
                <form id="adminForm" method="post" action="manage_admins.php">
                    <div style="display: flex; gap: 15px;">
                        <div style="flex: 1;">
                            <input type="text" id="firstName" name="firstName" placeholder="First Name" required>
                        </div>
                        <div style="flex: 1;">
                            <input type="text" id="lastName" name="lastName" placeholder="Last Name" required>
                        </div>
                    </div>
                    
                    <input type="email" id="email" name="email" placeholder="Email Address" required>
                    <input type="password" id="password" name="password" placeholder="Password" required>
                    
                    <div style="display: flex; gap: 15px;">
                        <div class="form-group" style="flex: 1;">
                            <label for="adminRole">Role:</label>
                            <select id="adminRole" name="adminRole" required>
                                <option value="admin">Admin</option>
                                <option value="super_admin">Super Admin</option>
                            </select>
                        </div>
                        <div class="form-group" style="flex: 1;">
                            <label for="adminApproved">Status:</label>
                            <select id="adminApproved" name="adminApproved" required>
                                <option value="1">Approved</option>
                                <option value="0">Pending Approval</option>
                            </select>
                        </div>
                    </div>
                    
                    <button type="submit" name="add_admin">Add Administrator</button>
                </form>
            </section>

            <?php if (!empty($pendingAdmins)): ?>
            <section class="table-section">
                <h3>Pending Approval Requests <span class="header-count"><?php echo count($pendingAdmins); ?></span></h3>
                <table id="pendingTable">
                    <thead>
                    <tr>
                        <th width="5%">ID</th>
                        <th width="25%">First Name</th>
                        <th width="25%">Last Name</th>
                        <th width="30%">Email</th>
                        <th width="10%">Role</th>
                        <th width="10%">Status</th>
                        <th width="20%">Actions</th>
                    </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($pendingAdmins as $admin): ?>
                        <tr>
                            <td><?php echo $admin['id']; ?></td>
                            <td><?php echo $admin['first_name']; ?></td>
                            <td><?php echo $admin['last_name']; ?></td>
                            <td><?php echo $admin['email']; ?></td>
                            <td><?php echo $admin['role']; ?></td>
                            <td><span class="status-pending">Pending</span></td>
                            <td>
                                <form method="post" action="manage_admins.php" style="display:inline;">
                                    <input type="hidden" name="admin_id" value="<?php echo $admin['id']; ?>">
                                    <button type="submit" name="approve_admin" class="action-btn approve-btn"><i class="fas fa-check"></i> Approve</button>
                                </form>
                                <form method="post" action="manage_admins.php" style="display:inline;">
                                    <input type="hidden" name="admin_id" value="<?php echo $admin['id']; ?>">
                                    <button type="submit" name="delete_admin" class="action-btn delete-btn" onclick="return confirm('Are you sure you want to delete this administrator?')"><i class="fas fa-trash"></i> Delete</button>
                                </form>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </section>
            <?php endif; ?>

            <section class="table-section">
                <h3>Administrator List <span class="header-count"><?php echo count($approvedAdmins); ?></span></h3>
                <?php if (!empty($approvedAdmins)): ?>
                <table>
                    <thead>
                        <tr>
                            <th width="5%">ID</th>
                            <th width="25%">First Name</th>
                            <th width="25%">Last Name</th>
                            <th width="30%">Email</th>
                            <th width="10%">Role</th>
                            <th width="10%">Status</th>
                            <th width="20%">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($approvedAdmins as $admin): ?>
                        <tr>
                            <td><?php echo $admin['id']; ?></td>
                            <td><?php echo $admin['first_name']; ?></td>
                            <td><?php echo $admin['last_name']; ?></td>
                            <td><?php echo $admin['email']; ?></td>
                            <td><?php echo $admin['role'] ?? 'Admin'; ?></td>
                            <td><span class="status-approved">Approved</span></td>
                            <td>
                                <?php if ($admin['id'] != $user['id']): ?>
                                <form method="post" action="manage_admins.php" style="display:inline;">
                                    <input type="hidden" name="admin_id" value="<?php echo $admin['id']; ?>">
                                    <button type="submit" name="delete_admin" class="action-btn delete-btn" onclick="return confirm('Are you sure you want to delete this administrator?')"><i class="fas fa-trash"></i> Delete</button>
                                </form>
                                <?php else: ?>
                                <button class="action-btn delete-btn" disabled title="Cannot delete yourself"><i class="fas fa-trash"></i> Delete</button>
                                <?php endif; ?>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                <?php else: ?>
                <div class="table-empty">
                    <p>No approved administrators found.</p>
                </div>
                <?php endif; ?>
            </section>
        </main>
    </div>
</body>
</html>