const API_BASE_URL = "http://127.0.0.1:8000/api";

// Check if DOM is loaded before accessing elements
document.addEventListener("DOMContentLoaded", function() {
    // Only add event listeners if elements exist
    const signUpButton = document.getElementById('signUpButton');
    const signInButton = document.getElementById('signInButton');
    const logoutButton = document.getElementById('logout');
    const errorMessage = document.getElementById('error-message');
    const productForm = document.getElementById('productForm');
    const productTable = document.getElementById('productTable');
    const rentalTable = document.getElementById('rentalTable');
    const videoForm = document.getElementById('videoForm');
    const videoTable = document.getElementById('videoTable');
    
    // Login page specific code
    if (signUpButton) {
        signUpButton.addEventListener('click', () => {
            document.getElementById('signIn').style.display = "none";
            document.getElementById('signup').style.display = "block";
        });
    }
    
    if (signInButton) {
        signInButton.addEventListener('click', () => {
            document.getElementById('signIn').style.display = "block";
            document.getElementById('signup').style.display = "none";
        });
    }
    
    // Error message fadeout
    if (errorMessage) {
        setTimeout(() => {
            errorMessage.style.opacity = "0"; // Fade out
            setTimeout(() => {
                errorMessage.style.display = "none"; // Hide after fade-out
            }, 500);
        }, 5000);
    }
    
    // Logout functionality
    if (logoutButton) {
        logoutButton.addEventListener("click", function() {
            localStorage.removeItem("adminToken");
            window.location.href = "login.php";
        });
    }
    
    // Dashboard specific code
    if (document.getElementById('adminAccount')) {
        fetchDashboardStats();
    }
    
    // Products page specific code
    if (productForm && productTable) {
        fetchAndDisplayProducts();
        
        productForm.addEventListener("submit", async function(e) {
            e.preventDefault();
            const newProduct = {
                name: document.getElementById("productName").value,
                type: document.getElementById("productType").value,
                price: document.getElementById("productPrice").value,
                description: document.getElementById("productDescription").value,
            };
            await addProduct(newProduct);
            fetchAndDisplayProducts();
        });
        
        productTable.addEventListener("click", async function(e) {
            if (e.target.classList.contains("delete-btn")) {
                const id = e.target.getAttribute("data-id");
                await deleteProduct(id);
                fetchAndDisplayProducts();
            }
        });
    }
    
    // Rentals page specific code
    if (rentalTable) {
        fetchRentals();
        
        rentalTable.addEventListener("click", async function(e) {
            const id = e.target.getAttribute("data-id");
            if (e.target.classList.contains("approve-btn")) {
                await updateRentalStatus(id, "approved");
            } else if (e.target.classList.contains("reject-btn")) {
                await updateRentalStatus(id, "rejected");
            }
        });
    }
    
    // Videos page specific code
    if (videoForm && videoTable) {
        fetchVideos();
        
        videoForm.addEventListener("submit", async function(e) {
            e.preventDefault();
            const title = document.getElementById("title").value;
            const video_url = document.getElementById("video_url").value;
            
            if (!title || !video_url) {
                alert("Please enter both title and video URL.");
                return;
            }
            
            await addVideo(title, video_url);
            fetchVideos();
        });
        
        videoTable.addEventListener("click", async function(e) {
            if (e.target.classList.contains("delete-btn")) {
                const id = e.target.getAttribute("data-id");
                await deleteVideo(id);
                fetchVideos();
            }
        });
    }
});
// Fetch admin count for dashboard
async function fetchAdminCount() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin-count`);
        if (!response.ok) throw new Error('Failed to fetch admin count');
        const data = await response.json();
        return data.count || 0;
    } catch (error) {
        console.error("Error fetching admin count:", error);
        return 0;
    }
}

// Update fetchDashboardStats to include admin count
async function fetchDashboardStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/stats`);
        const data = await response.json();
        
        // Update admin count
        if (document.getElementById('adminAccount')) {
            const adminCount = await fetchAdminCount();
            document.getElementById('adminAccount').textContent = adminCount;
        }
        
        // Update other dashboard stats
        if (document.getElementById('totalFarmers'))
            document.getElementById('totalFarmers').textContent = data.totalFarmers || 0;
        if (document.getElementById('totalMachines'))
            document.getElementById('totalMachines').textContent = data.totalMachines || 0;
        if (document.getElementById('activeRentals'))
            document.getElementById('activeRentals').textContent = data.activeRentals || 0;
            
        // If the updateChartData function exists, update chart
        if (window.updateChartData && data.monthlyRentals) {
            window.updateChartData(data.monthlyRentals);
        }
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
    }
}
// Fetch products
async function fetchProducts() {
    try {
        const response = await fetch(`${API_BASE_URL}/products`);
        if (!response.ok) throw new Error('Failed to fetch products');
        const data = await response.json();
        return data;
    } catch (error) {
        console.error("Error fetching products:", error);
        alert("Error fetching products: " + error.message);
    }
}

// Add a new product
async function addProduct(product) {
    try {
        const response = await fetch(`${API_BASE_URL}/products`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify(product),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        alert("Product added successfully!");
    } catch (error) {
        console.error("Error adding product:", error);
        alert("Failed to add product: " + error.message);
    }
}

// Delete product
async function deleteProduct(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/products/${id}`, {
            method: "DELETE"
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        alert("Product deleted successfully!");
    } catch (error) {
        console.error("Error deleting product:", error);
        alert("Failed to delete product: " + error.message);
    }
}

// Fetch and display products
async function fetchAndDisplayProducts() {
    const products = await fetchProducts();
    const productTable = document.getElementById("productTable");
    if (!products || !productTable) return;
    
    productTable.innerHTML = "";
    products.forEach((product) => {
        const imageSrc = product.image_url 
            ? product.image_url 
            : 'https://via.placeholder.com/60x60?text=No+Image';
            
        const row = document.createElement("tr");
        row.innerHTML = `
            <td><img src="${imageSrc}" alt="${product.name}" class="product-image-thumbnail"></td>
            <td>${product.name}</td>
            <td>${product.type}</td>
            <td>$${product.price}</td>
            <td>
                <button class="action-btn" onclick="deleteProduct(${product.id})">Delete</button>
            </td>
        `;
        productTable.appendChild(row);
    });
}

// Fetch dashboard stats
async function fetchDashboardStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/stats`);
        const data = await response.json();
        
        // Update dashboard stats
        if (document.getElementById('adminAccount'))
            document.getElementById('adminAccount').textContent = data.adminAccount || 0;
        if (document.getElementById('totalFarmers'))
            document.getElementById('totalFarmers').textContent = data.totalFarmers || 0;
        if (document.getElementById('totalMachines'))
            document.getElementById('totalMachines').textContent = data.totalMachines || 0;
        if (document.getElementById('activeRentals'))
            document.getElementById('activeRentals').textContent = data.activeRentals || 0;
            
        // If the updateChartData function exists, update chart
        if (window.updateChartData && data.monthlyRentals) {
            window.updateChartData(data.monthlyRentals);
        }
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
    }
}

// Fetch and display rentals
async function fetchRentals() {
    try {
        const response = await fetch(`${API_BASE_URL}/rentals`);
        const rentals = await response.json();
        const rentalTable = document.getElementById("rentalTable");
        if (!rentals || !rentalTable) return;
        
        rentalTable.innerHTML = "";
        rentals.forEach((rental) => {
            const row = document.createElement("tr");
            row.innerHTML = `
                <td>${rental.farmer_name}</td>
                <td>${rental.product_name}</td>
                <td>${rental.rental_date}</td>
                <td>${rental.status}</td>
                <td>
                    <button class="approve-btn" data-id="${rental.id}">Approve</button>
                    <button class="reject-btn" data-id="${rental.id}">Reject</button>
                </td>
            `;
            rentalTable.appendChild(row);
        });
    } catch (error) {
        console.error("Error fetching rentals:", error);
    }
}

// Update rental status
async function updateRentalStatus(id, status) {
    try {
        const response = await fetch(`${API_BASE_URL}/rentals/${id}`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ status })
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        alert(`Rental ${status} successfully!`);
        fetchRentals();
    } catch (error) {
        console.error(`Error updating rental status:`, error);
        alert(`Failed to update rental status`);
    }
}

// Fetch and display videos
async function fetchVideos() {
    try {
        const response = await fetch(`${API_BASE_URL}/videos`);
        const videos = await response.json();
        const videoTable = document.getElementById("videoTable");
        if (!videos || !videoTable) return;
        
        videoTable.innerHTML = "";
        videos.forEach((video) => {
            const row = document.createElement("tr");
            row.innerHTML = `
                <td>${video.title}</td>
                <td><a href="${video.video_url}" target="_blank">Watch Video</a></td>
                <td>
                    <button class="edit-btn" data-id="${video.id}">Edit</button>
                    <button class="delete-btn" data-id="${video.id}">Delete</button>
                </td>
            `;
            videoTable.appendChild(row);
        });
    } catch (error) {
        console.error("Error fetching videos:", error);
    }
}

// Add video
async function addVideo(title, video_url) {
    try {
        const response = await fetch(`${API_BASE_URL}/videos`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ title, video_url })
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        alert("Video added successfully!");
    } catch (error) {
        console.error("Error adding video:", error);
        alert("Failed to add video: " + error.message);
    }
}

// Delete video
async function deleteVideo(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/videos/${id}`, {
            method: "DELETE"
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        alert("Video deleted successfully!");
    } catch (error) {
        console.error("Error deleting video:", error);
        alert("Failed to delete video: " + error.message);
    }
}