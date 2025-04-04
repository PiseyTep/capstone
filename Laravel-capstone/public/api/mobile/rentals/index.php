<?php
// Mobile rentals endpoint
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../helpers.php';

// All rental endpoints require authentication
$tokenData = validateToken();
if (!$tokenData) {
    echo json_encode([
        'success' => false,
        'message' => 'Unauthorized access'
    ]);
    http_response_code(401);
    exit;
}

// Get user ID from token
$userId = $tokenData['user_id'];

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Get rental ID from URL if present
$segments = explode('/', trim($_SERVER['REQUEST_URI'], '/'));
$rentalId = null;

// Look for a rental ID in the URL segments
foreach ($segments as $i => $segment) {
    if ($segment === 'rentals' && isset($segments[$i + 1]) && is_numeric($segments[$i + 1])) {
        $rentalId = $segments[$i + 1];
        break;
    }
}

// Process request based on method and ID
switch ($method) {
    case 'GET':
        if ($rentalId) {
            // Get specific rental
            $stmt = $conn->prepare("
                SELECT r.*, p.name as product_name, p.image_url 
                FROM rentals r
                JOIN products p ON r.product_id = p.id
                WHERE r.id = ? AND r.user_id = ?
            ");
            $stmt->bind_param("ii", $rentalId, $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 0) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Rental not found'
                ]);
                http_response_code(404);
                exit;
            }
            
            $rental = $result->fetch_assoc();
            echo json_encode([
                'success' => true,
                'data' => $rental
            ]);
        } else {
            // Get all rentals for this user
            $stmt = $conn->prepare("
                SELECT r.*, p.name as product_name, p.image_url 
                FROM rentals r
                JOIN products p ON r.product_id = p.id
                WHERE r.user_id = ?
                ORDER BY r.rental_date DESC
            ");
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $rentals = [];
            while ($row = $result->fetch_assoc()) {
                $rentals[] = $row;
            }
            
            echo json_encode([
                'success' => true,
                'data' => $rentals
            ]);
        }
        break;
        
    case 'POST':
        // Create new rental
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid request data'
            ]);
            exit;
        }
        
        // Validate required fields
        $required_fields = ['product_id', 'rental_date', 'duration', 'location'];
        $errors = [];
        
        foreach ($required_fields as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                $errors[$field] = ucfirst(str_replace('_', ' ', $field)) . ' is required';
            }
        }
        
        if (!empty($errors)) {
            echo json_encode([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $errors
            ]);
            exit;
        }
        
        // Check if product exists and get price
        $stmt = $conn->prepare("SELECT id, price FROM products WHERE id = ?");
        $stmt->bind_param("i", $data['product_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Product not found'
            ]);
            http_response_code(404);
            exit;
        }
        
        $product = $result->fetch_assoc();
        $totalPrice = $product['price'] * $data['duration'];
        
        // Create rental
        $stmt = $conn->prepare("
            INSERT INTO rentals 
            (user_id, product_id, rental_date, duration, location, notes, total_price, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')
        ");
        $notes = $data['notes'] ?? '';
        
        $stmt->bind_param(
            "iisdssd", 
            $userId,
            $data['product_id'],
            $data['rental_date'],
            $data['duration'],
            $data['location'],
            $notes,
            $totalPrice
        );
        
        if ($stmt->execute()) {
            $rentalId = $conn->insert_id;
            
            // Get the created rental
            $stmt = $conn->prepare("
                SELECT r.*, p.name as product_name, p.image_url 
                FROM rentals r
                JOIN products p ON r.product_id = p.id
                WHERE r.id = ?
            ");
            $stmt->bind_param("i", $rentalId);
            $stmt->execute();
            $result = $stmt->get_result();
            $rental = $result->fetch_assoc();
            
            echo json_encode([
                'success' => true,
                'message' => 'Rental created successfully',
                'data' => $rental
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to create rental',
                'error' => $conn->error
            ]);
        }
        break;
        
    case 'PUT':
        // Update rental
        if (!$rentalId) {
            echo json_encode([
                'success' => false,
                'message' => 'Rental ID is required'
            ]);
            http_response_code(400);
            exit;
        }
        
        // Check if rental exists and belongs to user
        $stmt = $conn->prepare("
            SELECT * FROM rentals WHERE id = ? AND user_id = ?
        ");
        $stmt->bind_param("ii", $rentalId, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Rental not found or unauthorized'
            ]);
            http_response_code(404);
            exit;
        }
        
        $rental = $result->fetch_assoc();
        
        // Pending rentals can be updated, completed/cancelled cannot
        if ($rental['status'] !== 'pending') {
            echo json_encode([
                'success' => false,
                'message' => 'Only pending rentals can be updated'
            ]);
            http_response_code(400);
            exit;
        }
        
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid request data'
            ]);
            exit;
        }
        
        // Build update query
        $updateFields = [];
        $params = [];
        $types = '';
        
        if (isset($data['rental_date'])) {
            $updateFields[] = "rental_date = ?";
            $params[] = $data['rental_date'];
            $types .= 's';
        }
        
        if (isset($data['duration'])) {
            $updateFields[] = "duration = ?";
            $params[] = $data['duration'];
            $types .= 'd';
            
            // Recalculate total price
            $stmt = $conn->prepare("SELECT price FROM products WHERE id = ?");
            $stmt->bind_param("i", $rental['product_id']);
            $stmt->execute();
            $result = $stmt->get_result();
            $product = $result->fetch_assoc();
            
            $updateFields[] = "total_price = ?";
            $params[] = $product['price'] * $data['duration'];
            $types .= 'd';
        }
        
        if (isset($data['location'])) {
            $updateFields[] = "location = ?";
            $params[] = $data['location'];
            $types .= 's';
        }
        
        if (isset($data['notes'])) {
            $updateFields[] = "notes = ?";
            $params[] = $data['notes'];
            $types .= 's';
        }
        
        if (empty($updateFields)) {
            echo json_encode([
                'success' => false,
                'message' => 'No fields to update'
            ]);
            exit;
        }
        
        // Add rental ID to params
        $params[] = $rentalId;
        $types .= 'i';
        
        // Execute update
        $sql = "UPDATE rentals SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        
        if ($stmt->execute()) {
            // Get updated rental
            $stmt = $conn->prepare("
                SELECT r.*, p.name as product_name, p.image_url 
                FROM rentals r
                JOIN products p ON r.product_id = p.id
                WHERE r.id = ?
            ");
            $stmt->bind_param("i", $rentalId);
            $stmt->execute();
            $result = $stmt->get_result();
            $rental = $result->fetch_assoc();
            
            echo json_encode([
                'success' => true,
                'message' => 'Rental updated successfully',
                'data' => $rental
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to update rental',
                'error' => $conn->error
            ]);
        }
        break;
        
    case 'DELETE':
        // Cancel rental
        if (!$rentalId) {
            echo json_encode([
                'success' => false,
                'message' => 'Rental ID is required'
            ]);
            http_response_code(400);
            exit;
        }
        
        // Check if rental exists and belongs to user
        $stmt = $conn->prepare("
            SELECT * FROM rentals WHERE id = ? AND user_id = ?
        ");
        $stmt->bind_param("ii", $rentalId, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            echo json_encode([
                'success' => false,
                'message' => 'Rental not found or unauthorized'
            ]);
            http_response_code(404);
            exit;
        }
        
        $rental = $result->fetch_assoc();
        
        // Only pending rentals can be cancelled
        if ($rental['status'] !== 'pending') {
            echo json_encode([
                'success' => false,
                'message' => 'Only pending rentals can be cancelled'
            ]);
            http_response_code(400);
            exit;
        }
        
        // Update status to cancelled instead of deleting
        $stmt = $conn->prepare("UPDATE rentals SET status = 'cancelled' WHERE id = ?");
        $stmt->bind_param("i", $rentalId);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'Rental cancelled successfully'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to cancel rental',
                'error' => $conn->error
            ]);
        }
        break;
        
    default:
        echo json_encode([
            'success' => false,
            'message' => 'Method not allowed'
        ]);
        http_response_code(405);
}
?>