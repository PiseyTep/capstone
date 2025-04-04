<!-- // Insert new admin
$query = "INSERT INTO admin (firstName, lastName, email, password, role, approved) VALUES (?, ?, ?, ?, ?, ?)";
$stmt = $conn->prepare($query);
$role = isset($data['role']) ? $data['role'] : 'admin';
$approved = isset($data['approved']) && $data['approved'] === true ? 1 : 0;
$stmt->bind_param("sssssi", $data['firstName'], $data['lastName'], $data['email'], $hashedPassword, $role, $approved); -->