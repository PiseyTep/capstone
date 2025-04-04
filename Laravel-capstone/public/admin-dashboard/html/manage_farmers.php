<?php
session_start();
include("connect.php");
error_reporting(E_ALL);
ini_set('display_errors', 1);

// API Base URL - Update with your actual API URL
$api_base_url = "http://172.20.10.3:8000/api";

function redirect($url) {
    header("Location: $url");
    exit();
}

// Check if user is logged in
if (!isset($_SESSION['email']) || !isset($_SESSION['api_token'])) {
    redirect("login.php");
}

// API request helper function
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

// Check if user is admin or super admin
if (!in_array($_SESSION['role'], ['admin', 'super_admin'])) {
    redirect("index.php?error=permission");
}

// Get all farmers from API
$query_params = 'role=farmer';
$farmers_response = api_request("/admin/users?$query_params");
$farmers = [];

if ($farmers_response['status'] === 200) {
    $farmers = $farmers_response['data']['data']['data'] ?? []; // Adjust based on your API response structure
}

// Handle adding new farmer
if (isset($_POST['add_farmer'])) {
    $firstName = $_POST['firstName'];
    $lastName = $_POST['lastName'];
    $email = $_POST['email'];
    $phone = $_POST['phone'];
    $password = $_POST['password'];
    
    $create_response = api_request("/admin/users", 'POST', [
        'name' => $firstName . ' ' . $lastName,
        'email' => $email,
        'password' => $password,
        'phone_number' => $phone,
        'role' => 'farmer',
        'approved' => 1 // Farmers are auto-approved
    ]);
    
    if ($create_response['status'] === 201) {
        redirect("manage_farmers.php?success=added");
    } else {
        $error_message = "Error adding farmer: " . ($create_response['data']['message'] ?? 'Unknown error');
    }
}

// Handle farmer deletion
if (isset($_POST['delete_farmer']) && isset($_POST['farmer_id'])) {
    $farmerId = $_POST['farmer_id'];
    $delete_response = api_request("/admin/users/$farmerId", 'DELETE');
    
    if ($delete_response['status'] === 200) {
        redirect("manage_farmers.php?success=deleted");
    } else {
        $error_message = "Error deleting farmer: " . ($delete_response['data']['message'] ?? 'Unknown error');
    }
}

// Handle farmer update
if (isset($_POST['update_farmer'])) {
    $farmerId = $_POST['farmer_id'];
    $name = $_POST['name'];
    $phone = $_POST['phone'];
    $status = isset($_POST['active']) ? 1 : 0;
    
    $update_response = api_request("/admin/users/$farmerId", 'PUT', [
        'name' => $name,
        'phone_number' => $phone,
        'is_active' => $status
    ]);
    
    if ($update_response['status'] === 200) {
        redirect("manage_farmers.php?success=updated");
    } else {
        $error_message = "Error updating farmer: " . ($update_response['data']['message'] ?? 'Unknown error');
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AgriTech Pioneer - Manage Farmers</title>
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/dashboard.css">
    <link rel="stylesheet" href="/LoginFarmer/Laravel-capstone/public/admin-dashboard/css/manage_farmers.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Custom styles for farmer management */
        .farmer-card {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 20px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .farmer-details {
            flex-grow: 1;
        }
        
        .farmer-name {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .farmer-email, .farmer-phone {
            color: #666;
            margin-bottom: 3px;
        }
        
        .farmer-actions {
            display: flex;
            gap: 10px;
        }
        
        .view-details-btn, .edit-btn, .delete-btn {
            padding: 8px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-weight: 500;
        }
        
        .view-details-btn {
            background-color: #375534;
            color: white;
        }
        
        .edit-btn {
            background-color: #3498db;
            color: white;
        }
        
        .delete-btn {
            background-color: #e74c3c;
            color: white;
        }
        
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
            z-index: 999;
        }
        
        .modal-content {
            background-color: white;
            width: 80%;
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        
        .close-modal {
            font-size: 24px;
            cursor: pointer;
        }
        
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        
        .form-full-width {
            grid-column: 1 / 3;
        }
        
        .success-message, .error-message {
            padding: 10px 15px;
            margin-bottom: 15px;
            border-radius: 4px;
            display: flex;
            align-items: center;
        }
        
        .success-message {
            background-color: rgba(40, 167, 69, 0.1);
            color: #28a745;
        }
        
        .error-message {
            background-color: rgba(220, 53, 69, 0.1);
            color: #dc3545;
        }
        
        .success-message i, .error-message i {
            margin-right: 10px;
        }
        
        .grid-view {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .view-toggle {
            margin-bottom: 20px;
        }
        
        .view-toggle button {
            padding: 8px 12px;
            background: none;
            border: 1px solid #ddd;
            cursor: pointer;
        }
        
        .view-toggle button.active {
            background-color: #375534;
            color: white;
            border-color: #375534;
        }
        
        .search-filter-container {
            display: flex;
            margin-bottom: 20px;
            justify-content: space-between;
        }
        
        .search-bar {
            flex: 1;
            max-width: 400px;
        }
        
        .search-bar input {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="dashboard-container">
        <!-- Sidebar menu -->
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
                <?php if ($_SESSION['role'] === 'super_admin'): ?>
                <li><a href="manage_admins.php"><i class="fas fa-user-shield"></i> Manage Admins</a></li>
                <?php endif; ?>
                <li><a href="manage_farmers.php" class="active"><i class="fas fa-users"></i> Manage Farmers</a></li>
                <li><a href="logout.php" id="logout"><i class="fas fa-sign-out-alt"></i> Logout</a></li>
            </ul>
            <div class="sidebar-footer">
                <p>&copy; 2025 AgriTech Pioneer</p>
            </div>
        </aside>

        <main class="dashboard-content">
            <header>
                <div class="header-title">
                    <h2><i class="fas fa-users"></i> Manage Farmers</h2>
                </div>
                <div class="profile">
                    <div class="admin-profile">
                        <div class="admin-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <span id="adminName"><?php echo $_SESSION['email']; ?></span>
                    </div>
                </div>
            </header>

            <!-- Success/Error Messages -->
            <?php if (isset($_GET['success'])): ?>
                <div class="success-message">
                    <i class="fas fa-check-circle"></i>
                    <?php if ($_GET['success'] === 'added'): ?>
                        <p>Farmer account has been added successfully!</p>
                    <?php elseif ($_GET['success'] === 'deleted'): ?>
                        <p>Farmer account has been deleted successfully!</p>
                    <?php elseif ($_GET['success'] === 'updated'): ?>
                        <p>Farmer account has been updated successfully!</p>
                    <?php endif; ?>
                </div>
            <?php endif; ?>

            <?php if (isset($error_message)): ?>
                <div class="error-message">
                    <i class="fas fa-exclamation-circle"></i>
                    <p><?php echo $error_message; ?></p>
                </div>
            <?php endif; ?>

            <!-- Add Farmer Button -->
            <button id="addFarmerBtn" class="add-farmer-btn">
                <i class="fas fa-plus"></i> Add New Farmer
            </button>

            <!-- Search and Filter Controls -->
            <div class="search-filter-container">
                <div class="search-bar">
                    <input type="text" id="searchInput" placeholder="Search farmers...">
                </div>
                <div class="view-toggle">
                    <button id="listViewBtn" class="active"><i class="fas fa-list"></i> List</button>
                    <button id="gridViewBtn"><i class="fas fa-th-large"></i> Grid</button>
                </div>
            </div>

            <!-- Farmers List -->
            <section class="farmers-container">
                <div id="farmersListView">
                    <?php if (empty($farmers)): ?>
                        <div class="empty-state">
                            <i class="fas fa-users"></i>
                            <p>No farmers found. Add your first farmer account!</p>
                        </div>
                    <?php else: ?>
                        <?php foreach ($farmers as $farmer): ?>
                            <div class="farmer-card">
                                <div class="farmer-details">
                                    <div class="farmer-name"><?php echo htmlspecialchars($farmer['name']); ?></div>
                                    <div class="farmer-email"><i class="fas fa-envelope"></i> <?php echo htmlspecialchars($farmer['email']); ?></div>
                                    <div class="farmer-phone"><i class="fas fa-phone"></i> <?php echo htmlspecialchars($farmer['phone_number'] ?? 'No phone number'); ?></div>
                                </div>
                                <div class="farmer-actions">
                                    <button class="view-details-btn" data-id="<?php echo $farmer['id']; ?>">
                                        <i class="fas fa-eye"></i> Details
                                    </button>
                                    <button class="edit-btn" data-id="<?php echo $farmer['id']; ?>">
                                        <i class="fas fa-edit"></i> Edit
                                    </button>
                                    <form method="post" style="display:inline;">
                                        <input type="hidden" name="farmer_id" value="<?php echo $farmer['id']; ?>">
                                        <button type="submit" name="delete_farmer" class="delete-btn" onclick="return confirm('Are you sure you want to delete this farmer account?')">
                                            <i class="fas fa-trash"></i> Delete
                                        </button>
                                    </form>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
                
                <div id="farmersGridView" class="grid-view" style="display: none;">
                    <?php if (!empty($farmers)): ?>
                        <?php foreach ($farmers as $farmer): ?>
                            <div class="farmer-grid-card">
                                <div class="farmer-avatar">
                                    <i class="fas fa-user-circle"></i>
                                </div>
                                <div class="farmer-name"><?php echo htmlspecialchars($farmer['name']); ?></div>
                                <div class="farmer-email"><?php echo htmlspecialchars($farmer['email']); ?></div>
                                <div class="farmer-actions">
                                    <button class="view-details-btn" data-id="<?php echo $farmer['id']; ?>">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    <button class="edit-btn" data-id="<?php echo $farmer['id']; ?>">
                                        <i class="fas fa-edit"></i>
                                    </button>
                                    <form method="post" style="display:inline;">
                                        <input type="hidden" name="farmer_id" value="<?php echo $farmer['id']; ?>">
                                        <button type="submit" name="delete_farmer" class="delete-btn" onclick="return confirm('Are you sure you want to delete this farmer account?')">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </form>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </div>
            </section>
        </main>
    </div>

    <!-- Add Farmer Modal -->
    <div id="addFarmerModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Add New Farmer</h2>
                <span class="close-modal">&times;</span>
            </div>
            <form method="post" action="manage_farmers.php">
                <div class="form-grid">
                    <div>
                        <label for="firstName">First Name</label>
                        <input type="text" id="firstName" name="firstName" required>
                    </div>
                    <div>
                        <label for="lastName">Last Name</label>
                        <input type="text" id="lastName" name="lastName" required>
                    </div>
                    <div class="form-full-width">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required>
                    </div>
                    <div class="form-full-width">
                        <label for="phone">Phone Number</label>
                        <input type="tel" id="phone" name="phone">
                    </div>
                    <div class="form-full-width">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" required>
                    </div>
                </div>
                <div class="form-actions">
                    <button type="button" class="cancel-btn">Cancel</button>
                    <button type="submit" name="add_farmer" class="submit-btn">Add Farmer</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Edit Farmer Modal -->
    <div id="editFarmerModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Edit Farmer</h2>
                <span class="close-modal">&times;</span>
            </div>
            <form method="post" action="manage_farmers.php">
                <input type="hidden" id="edit_farmer_id" name="farmer_id">
                <div class="form-grid">
                    <div class="form-full-width">
                        <label for="edit_name">Full Name</label>
                        <input type="text" id="edit_name" name="name" required>
                    </div>
                    <div class="form-full-width">
                        <label for="edit_phone">Phone Number</label>
                        <input type="tel" id="edit_phone" name="phone">
                    </div>
                    <div class="form-full-width">
                        <label for="edit_active">Account Status</label>
                        <div class="checkbox-container">
                            <input type="checkbox" id="edit_active" name="active" checked>
                            <label for="edit_active">Active Account</label>
                        </div>
                    </div>
                </div>
                <div class="form-actions">
                    <button type="button" class="cancel-btn">Cancel</button>
                    <button type="submit" name="update_farmer" class="submit-btn">Update Farmer</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Farmer Details Modal -->
    <div id="farmerDetailsModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2>Farmer Details</h2>
                <span class="close-modal">&times;</span>
            </div>
            <div id="farmerDetailContent">
                <!-- Farmer details will be loaded here -->
            </div>
            <div class="modal-actions">
                <button type="button" class="close-btn">Close</button>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Add Farmer Modal
            const addFarmerBtn = document.getElementById('addFarmerBtn');
            const addFarmerModal = document.getElementById('addFarmerModal');
            
            // Edit Farmer Modal
            const editFarmerModal = document.getElementById('editFarmerModal');
            
            // Farmer Details Modal
            const farmerDetailsModal = document.getElementById('farmerDetailsModal');
            
            // Close Modal Buttons
            const closeButtons = document.querySelectorAll('.close-modal, .cancel-btn, .close-btn');
            
            // View Toggle Buttons
            const listViewBtn = document.getElementById('listViewBtn');
            const gridViewBtn = document.getElementById('gridViewBtn');
            const listView = document.getElementById('farmersListView');
            const gridView = document.getElementById('farmersGridView');
            
            // Search Input
            const searchInput = document.getElementById('searchInput');
            
            // Edit Buttons
            const editButtons = document.querySelectorAll('.edit-btn');
            
            // View Details Buttons
            const viewDetailsButtons = document.querySelectorAll('.view-details-btn');
            
            // Open Add Farmer Modal
            addFarmerBtn.addEventListener('click', function() {
                addFarmerModal.style.display = 'block';
            });
            
            // Close Modals
            closeButtons.forEach(function(button) {
                button.addEventListener('click', function() {
                    addFarmerModal.style.display = 'none';
                    editFarmerModal.style.display = 'none';
                    farmerDetailsModal.style.display = 'none';
                });
            });
            
            // View Toggle
            listViewBtn.addEventListener('click', function() {
                listView.style.display = 'block';
                gridView.style.display = 'none';
                listViewBtn.classList.add('active');
                gridViewBtn.classList.remove('active');
            });
            
            gridViewBtn.addEventListener('click', function() {
                listView.style.display = 'none';
                gridView.style.display = 'grid';
                gridViewBtn.classList.add('active');
                listViewBtn.classList.remove('active');
            });
            
            // Search Functionality
            searchInput.addEventListener('input', function() {
                const searchTerm = this.value.toLowerCase();
                const farmerCards = document.querySelectorAll('.farmer-card, .farmer-grid-card');
                
                farmerCards.forEach(function(card) {
                    const farmerName = card.querySelector('.farmer-name').textContent.toLowerCase();
                    const farmerEmail = card.querySelector('.farmer-email').textContent.toLowerCase();
                    
                    if (farmerName.includes(searchTerm) || farmerEmail.includes(searchTerm)) {
                        card.style.display = '';
                    } else {
                        card.style.display = 'none';
                    }
                });
            });
            
            // Edit Farmer
            editButtons.forEach(function(button) {
                button.addEventListener('click', function() {
                    const farmerId = this.getAttribute('data-id');
                    
                    // Find farmer data
                    <?php echo "const farmers = " . json_encode($farmers) . ";"; ?>
                    const farmer = farmers.find(f => f.id.toString() === farmerId);
                    
                    if (farmer) {
                        document.getElementById('edit_farmer_id').value = farmer.id;
                        document.getElementById('edit_name').value = farmer.name;
                        document.getElementById('edit_phone').value = farmer.phone_number || '';
                        document.getElementById('edit_active').checked = farmer.is_active !== 0;
                        
                        editFarmerModal.style.display = 'block';
                    }
                });
            });
            
            // View Farmer Details
            viewDetailsButtons.forEach(function(button) {
                button.addEventListener('click', function() {
                    const farmerId = this.getAttribute('data-id');
                    
                    // Find farmer data
                    <?php echo "const farmers = " . json_encode($farmers) . ";"; ?>
                    const farmer = farmers.find(f => f.id.toString() === farmerId);
                    
                    if (farmer) {
                        const detailsHtml = `
                            <div class="farmer-detail-item">
                                <span class="detail-label">Name:</span>
                                <span class="detail-value">${farmer.name}</span>
                            </div>
                            <div class="farmer-detail-item">
                                <span class="detail-label">Email:</span>
                                <span class="detail-value">${farmer.email}</span>
                            </div>
                            <div class="farmer-detail-item">
                                <span class="detail-label">Phone:</span>
                                <span class="detail-value">${farmer.phone_number || 'Not provided'}</span>
                            </div>
                            <div class="farmer-detail-item">
                                <span class="detail-label">Account Status:</span>
                                <span class="detail-value ${farmer.is_active !== 0 ? 'status-active' : 'status-inactive'}">
                                    ${farmer.is_active !== 0 ? 'Active' : 'Inactive'}
                                </span>
                            </div>
                            <div class="farmer-detail-item">
                                <span class="detail-label">Joined:</span>
                                <span class="detail-value">${farmer.created_at ? new Date(farmer.created_at).toLocaleDateString() : 'Unknown'}</span>
                            </div>
                        `;
                        
                        document.getElementById('farmerDetailContent').innerHTML = detailsHtml;
                        farmerDetailsModal.style.display = 'block';
                    }
                });
            });
            
            // Close modal when clicking outside
            window.addEventListener('click', function(event) {
                if (event.target === addFarmerModal) {
                    addFarmerModal.style.display = 'none';
                } else if (event.target === editFarmerModal) {
                    editFarmerModal.style.display = 'none';
                } else if (event.target === farmerDetailsModal) {
                    farmerDetailsModal.style.display = 'none';
                }
            });
            
            // Auto-hide success and error messages after 5 seconds
            const messages = document.querySelectorAll('.success-message, .error-message');
            messages.forEach(function(message) {
                setTimeout(function() {
                    message.style.opacity = '0';
                    setTimeout(function() {
                        message.style.display = 'none';
                    }, 500);
                }, 5000);
            });
        });
    </script>
</body>
</html>