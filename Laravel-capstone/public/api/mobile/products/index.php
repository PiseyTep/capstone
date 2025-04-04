<?php
// Mobile products endpoint
require_once __DIR__ . '/../../../config.php';
require_once __DIR__ . '/../../../connect.php';
require_once __DIR__ . '/../../helpers.php';

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Get product ID from URL if present
$segments = explode('/', trim($_SERVER['REQUEST_URI'], '/'));
$productId = null;

// Look for a product ID in the URL segments
foreach ($segments as $i => $segment) {
    if ($segment === 'products' && isset($segments[$i + 1]) && is_numeric($segments[$i + 1])) {
        $productId = $segments[$i + 1];
        break;
    }
}

// Check if this is a public endpoint
$isPublic = strpos($_SERVER['REQUEST_URI'], 'public') !== false;

// If not public and not GET method, validate token for authenticated requests
if (!$isPublic && $method !== 'GET') {
    $tokenData = validateToken();
    if (!$tokenData) {
        echo json_encode([
            'success' => false,
            'message' => 'Unauthorized access'
        ]);
        http_response_code(401);
        exit;
    }
}

// Process request based on method and ID
switch ($method) {
    case 'GET':
        if ($productId) {
            // Get specific product
            $stmt = $conn->prepare("SELECT * FROM products WHERE id = ?");
            $stmt->bind_param("i", $productId);
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
            echo json_encode([
                'success' => true,
                'data' => $product
            ]);
        } else {
            // Get all products
            $query = "SELECT * FROM products";
            if (!$isPublic) {
                $query .= " WHERE status = 'active'";
            }
            $query .= " ORDER BY name";
            
            $result = $conn->query($query);
            $products = [];
            
            while ($row = $result->fetch_assoc()) {
                $products[] = $row;
            }
            
            echo json_encode([
                'success' => true,
                'data' => $products
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