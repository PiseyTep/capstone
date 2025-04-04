<?php
session_start();
include("../connect.php");

// API Base URL
$api_base_url = "http://172.20.10.3:8000/api";
 
// Check if user is logged in
if (!isset($_SESSION['email']) || !isset($_SESSION['api_token'])) {
    header("Location: login.php");
    exit();
}

function api_request($endpoint, $method = 'GET', $data = null) {
    global $api_base_url;
    
    $ch = curl_init($api_base_url . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    $headers = [
        'Authorization: Bearer ' . $_SESSION['api_token'],
        'Accept: application/json'
    ];
    
    if ($data) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        $headers[] = 'Content-Type: application/json';
    }
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $response = curl_exec($ch);
    $statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'status' => $statusCode,
        'data' => json_decode($response, true)
    ];
}

// Check if user is super admin
$isSuperAdmin = ($_SESSION['role'] === 'super_admin');

// Get dashboard stats
$stats_response = api_request('/admin/stats');
$stats = [];

if ($stats_response['status'] === 200) {
    $stats = $stats_response['data']['data'] ?? [];
}

// Get pending admin count
$pendingAdmins = $stats['pendingAdmins'] ?? 0;

// Rest of your index.php code...
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AgriTech Pioneer - Admin Dashboard</title>
    <link rel="stylesheet" href="/admin-dashboard/css/dashboard.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .alert-warning {
            background-color: #fff3cd;
            color: #856404;
            border: 1px solid #ffeeba;
        }
        .alert i {
            margin-right: 5px;
        }
        .alert a {
            color: #533f03;
            font-weight: bold;
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="dashboard-container">
        <aside class="sidebar">
            <div class="logo-container">
                <i class="fas fa-seedling"></i>
                <h2>AgriTech Pioneer</h2>
            </div>
            <ul>
                <li><a href="index.php" class="active"><i class="fas fa-home"></i> Dashboard</a></li>
                <li><a href="rentals.html"><i class="fas fa-exchange-alt"></i> Track Rentals</a></li>
                <li><a href="products.html"><i class="fas fa-tractor"></i> Manage Products</a></li>
                <li><a href="post_video.html"><i class="fas fa-video"></i> Post Video</a></li>
                <?php if ($isSuperAdmin): ?>
                <li><a href="manage_admins.php"><i class="fas fa-user-shield"></i> Manage Admins</a></li>
                <?php endif; ?>
                <li><a href="manage_farmers.php" class="active"><i class="fas fa-user-shield"></i> Farmer Management</a></li>
                <li><a href="logout.php" id="logout"><i class="fas fa-sign-out-alt"></i> Logout</a></li>
            </ul>
            <div class="sidebar-footer">
                <p>&copy; 2025 AgriTech Pioneer</p>
            </div>
        </aside>

        <main class="dashboard-content">
            <header>
                <div class="header-title">
                    <h2><i class="fas fa-chart-line"></i> Dashboard</h2>
                </div>
                <div class="profile">
                    <div class="notification">
                        <i class="fas fa-bell"></i>
                        <span class="notification-count">3</span>
                    </div>
                    <div class="admin-profile">
                        <div class="admin-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <span id="adminName">
                        <?php 
                                if (isset($_SESSION['email'])) {
                                    $email = $_SESSION['email'];
                                    $query = mysqli_query($conn, "SELECT * FROM `users` WHERE email='$email'");
                                    if ($row = mysqli_fetch_array($query)) {
                                        echo htmlspecialchars($row['first_name'] . ' ' . $row['last_name']);
                                    }
                                }
                            ?>
                        </span>
                        <i class="fas fa-chevron-down"></i>
                    </div>
                </div>
            </header>

            <?php if ($isSuperAdmin): ?>
                <?php
                // Check for pending admin approvals
                $pendingQuery = mysqli_query($conn, "SELECT COUNT(*) as count FROM users WHERE approved = 0");
                $pendingCount = mysqli_fetch_assoc($pendingQuery);
                $pendingAdmins = $pendingCount['count'];
                
                if ($pendingAdmins > 0):
                ?>
                <div class="alert alert-warning">
                    <p><i class="fas fa-exclamation-triangle"></i> There are <?php echo $pendingAdmins; ?> admin account(s) pending approval. <a href="manage_admins.php">Review now</a></p>
                </div>
                <?php endif; ?>
            <?php endif; ?>

            <div class="dashboard-overview">
                <section class="stats">
                <div class="card">
    <div class="card-icon admin-icon">
        <i class="fas fa-user-shield"></i>
    </div>
    <div class="card-content">
        <h3>Admin Account</h3>
        <span id="adminAccount" class="card-value"><?php echo $totalAdmins; ?></span>
        <p class="card-trend <?php echo $trendClass; ?>">
            <i class="fas <?php echo $trendIcon; ?>"></i> 
            <?php echo $percentChange; ?>% from last month
        </p>
    </div>
</div>
                    <div class="card">
                        <div class="card-icon farmers-icon">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="card-content">
                            <h3>Total Farmers</h3>
                            <span id="totalFarmers" class="card-value">0</span>
                            <p class="card-trend positive"><i class="fas fa-arrow-up"></i> 12% from last month</p>
                        </div>
                    </div>
                    <div class="card">
                        <div class="card-icon machines-icon">
                            <i class="fas fa-tractor"></i>
                        </div>
                        <div class="card-content">
                            <h3>Total Machinery</h3>
                            <span id="totalMachines" class="card-value">0</span>
                            <p class="card-trend positive"><i class="fas fa-arrow-up"></i> 8% from last month</p>
                        </div>
                    </div>
                    <div class="card">
                        <div class="card-icon rentals-icon">
                            <i class="fas fa-handshake"></i>
                        </div>
                        <div class="card-content">
                            <h3>Active Rentals</h3>
                            <span id="activeRentals" class="card-value">0</span>
                            <p class="card-trend negative"><i class="fas fa-arrow-down"></i> 3% from last month</p>
                        </div>
                    </div>
                </section>

                <div class="dashboard-grid">
                <section class="chart-container">
    <div class="chart-header">
        <h3>Monthly Rentals</h3>
        <div class="chart-controls">
            <select id="chartType">
                <option value="bar">Bar Chart</option>
                <option value="line">Line Chart</option>
            </select>
            <button id="downloadReport" class="btn">
                <i class="fas fa-download"></i> Export
            </button>
        </div>
    </div>
    <div class="chart">
        <canvas id="rentalChart"></canvas>
    </div>
</section>

                    <section class="recent-activities">
                        <h3>Recent Activities</h3>
                        <ul id="activities-list">
                            <li class="activity-item">
                                <div class="activity-icon rental"><i class="fas fa-exchange-alt"></i></div>
                                <div class="activity-details">
                                    <p>New rental: <strong>Tractor XY-200</strong> by John Doe</p>
                                    <span class="activity-time">Today, 09:45 AM</span>
                                </div>
                            </li>
                            <li class="activity-item">
                                <div class="activity-icon user"><i class="fas fa-user-plus"></i></div>
                                <div class="activity-details">
                                    <p>New farmer registered: <strong>Maria Rodriguez</strong></p>
                                    <span class="activity-time">Yesterday, 04:30 PM</span>
                                </div>
                            </li>
                            <li class="activity-item">
                                <div class="activity-icon product"><i class="fas fa-plus-circle"></i></div>
                                <div class="activity-details">
                                    <p>New machinery added: <strong>Harvester H-100</strong></p>
                                    <span class="activity-time">Yesterday, 02:15 PM</span>
                                </div>
                            </li>
                        </ul>
                    </section>
                </div>

                <section class="upcoming-rentals">
                    <div class="section-header">
                        <h3>Upcoming Rentals</h3>
                        <a href="rentals.html" class="view-all">View All</a>
                    </div>
                    <div class="table-container">
                        <table id="rentalsTable">
                            <thead>
                                <tr>
                                    <th>Rental ID</th>
                                    <th>Farmer</th>
                                    <th>Machinery</th>
                                    <th>Start Date</th>
                                    <th>Return Date</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <!-- Data will be loaded dynamically -->
                            </tbody>
                        </table>
                    </div>
                </section>
            </div>
        </main>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="/LoginFarmer/Laravel-capstone/public/admin-dashboard/js/dashboard-charts.js"></script>
    <script src="/LoginFarmer/Laravel-capstone/public/admin-dashboard/js/script.js"></script>
</body>
</html>