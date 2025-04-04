<?php
session_start();
include '../connect.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Ensure only admin or super admin can access
if (!isset($_SESSION['role']) || 
    ($_SESSION['role'] !== 'admin' && $_SESSION['role'] !== 'super_admin')) {
    http_response_code(403);
    echo json_encode([
        'success' => false, 
        'message' => 'Unauthorized access'
    ]);
    exit();
}

// Handle different request methods
$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Fetch farmers
        fetchFarmers($conn);
        break;
    
    case 'POST':
        // Create or update farmer
        handleFarmerOperation($conn);
        break;
    
    case 'PUT':
        // Update farmer status or details
        updateFarmer($conn);
        break;
    
    case 'DELETE':
        // Delete farmer account
        deleteFarmer($conn);
        break;
    
    default:
        http_response_code(405);
        echo json_encode([
            'success' => false, 
            'message' => 'Method Not Allowed'
        ]);
}

function fetchFarmers($conn) {
    // Fetch all farmers with optional filtering
    $search = $_GET['search'] ?? '';
    $status = $_GET['status'] ?? '';
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $offset = ($page - 1) * $limit;

    // Base query
    $query = "SELECT 
                id, 
                first_name, 
                last_name, 
                email, 
                phone_number, 
                status, 
                created_at 
              FROM farmers 
              WHERE 1=1";

    // Add search conditions
    if (!empty($search)) {
        $search = "%{$search}%";
        $query .= " AND (first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR phone_number LIKE ?)";
    }

    // Add status filter
    if (!empty($status)) {
        $query .= " AND status = ?";
    }

    // Count total farmers
    $countQuery = str_replace('SELECT id, first_name, last_name, email, phone_number, status, created_at', 'SELECT COUNT(*) as total', $query);
    
    // Prepare and execute count query
    $countStmt = $conn->prepare($countQuery);
    if (!empty($search)) {
        $countStmt->bind_param("ssss", $search, $search, $search, $search);
    }
    if (!empty($status)) {
        $countStmt->bind_param("s", $status);
    }
    $countStmt->execute();
    $countResult = $countStmt->get_result();
    $totalFarmers = $countResult->fetch_assoc()['total'];

    // Add pagination to main query
    $query .= " LIMIT ? OFFSET ?";

    // Prepare and execute main query
    $stmt = $conn->prepare($query);
    
    // Bind parameters
    if (!empty($search) && !empty($status)) {
        $stmt->bind_param("sssssii", $search, $search, $search, $search, $status, $limit, $offset);
    } elseif (!empty($search)) {
        $stmt->bind_param("sssiii", $search, $search, $search, $search, $limit, $offset);
    } elseif (!empty($status)) {
        $stmt->bind_param("sii", $status, $limit, $offset);
    } else {
        $stmt->bind_param("ii", $limit, $offset);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $farmers = [];
    while ($row = $result->fetch_assoc()) {
        $farmers[] = $row;
    }

    echo json_encode([
        'success' => true,
        'data' => $farmers,
        'pagination' => [
            'total' => $totalFarmers,
            'page' => $page,
            'limit' => $limit
        ]
    ]);
}

function handleFarmerOperation($conn) {
    $data = json_decode(file_get_contents('php://input'), true);

    // Validate input
    if (!isset($data['first_name']) || !isset($data['last_name']) || 
        !isset($data['email']) || !isset($data['phone_number'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'message' => 'Missing required fields'
        ]);
        return;
    }

    // Check if farmer exists (update) or is new (insert)
    $checkQuery = "SELECT id FROM farmers WHERE email = ?";
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param("s", $data['email']);
    $checkStmt->execute();
    $checkResult = $checkStmt->get_result();

    if ($checkResult->num_rows > 0) {
        // Update existing farmer
        $updateQuery = "UPDATE farmers SET 
                        first_name = ?, 
                        last_name = ?, 
                        phone_number = ?, 
                        status = ?, 
                        updated_at = NOW() 
                        WHERE email = ?";
        $updateStmt = $conn->prepare($updateQuery);
        $status = $data['status'] ?? 'active';
        $updateStmt->bind_param(
            "sssss", 
            $data['first_name'], 
            $data['last_name'], 
            $data['phone_number'], 
            $status, 
            $data['email']
        );

        if ($updateStmt->execute()) {
            echo json_encode([
                'success' => true, 
                'message' => 'Farmer updated successfully'
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false, 
                'message' => 'Failed to update farmer'
            ]);
        }
    } else {
        // Insert new farmer
        $insertQuery = "INSERT INTO farmers (
            first_name, 
            last_name, 
            email, 
            phone_number, 
            status, 
            created_at
        ) VALUES (?, ?, ?, ?, ?, NOW())";
        
        $insertStmt = $conn->prepare($insertQuery);
        $status = $data['status'] ?? 'active';
        $insertStmt->bind_param(
            "sssss", 
            $data['first_name'], 
            $data['last_name'], 
            $data['email'], 
            $data['phone_number'], 
            $status
        );

        if ($insertStmt->execute()) {
            echo json_encode([
                'success' => true, 
                'message' => 'Farmer added successfully',
                'farmer_id' => $conn->insert_id
            ]);
        } else {
            http_response_code(500);
            echo json_encode([
                'success' => false, 
                'message' => 'Failed to add farmer'
            ]);
        }
    }
}

function updateFarmer($conn) {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['id']) || !isset($data['status'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'message' => 'Missing required fields'
        ]);
        return;
    }

    $updateQuery = "UPDATE farmers SET 
                    status = ?, 
                    updated_at = NOW() 
                    WHERE id = ?";
    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param("si", $data['status'], $data['id']);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true, 
            'message' => 'Farmer status updated successfully'
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Failed to update farmer status'
        ]);
    }
}

function deleteFarmer($conn) {
    $data = json_decode(file_get_contents('php://input'), true);

    if (!isset($data['id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'message' => 'Missing farmer ID'
        ]);
        return;
    }

    $deleteQuery = "DELETE FROM farmers WHERE id = ?";
    $stmt = $conn->prepare($deleteQuery);
    $stmt->bind_param("i", $data['id']);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true, 
            'message' => 'Farmer deleted successfully'
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Failed to delete farmer'
        ]);
    }
}