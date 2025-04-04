const API_BASE_URL = "http://172.20.10.3:8000/api";

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
            } else if (e.target.classList.contains("details-btn")) {
                showRentalDetails(id);
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
            const description = document.getElementById("video_description")?.value || '';
            
            if (!title || !video_url) {
                alert("Please enter both title and video URL.");
                return;
            }
            
            await addVideo(title, video_url, description);
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

// Helper functions
function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    if (isNaN(date)) return dateString;
    return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
    });
}

function capitalizeFirstLetter(string) {
    if (!string) return '';
    return string.charAt(0).toUpperCase() + string.slice(1);
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// Dashboard functions
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

async function fetchDashboardStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/stats`);
        const data = await response.json();
        
        if (document.getElementById('adminAccount')) {
            const adminCount = await fetchAdminCount();
            document.getElementById('adminAccount').textContent = adminCount;
        }
        
        if (document.getElementById('totalFarmers'))
            document.getElementById('totalFarmers').textContent = data.totalFarmers || 0;
        if (document.getElementById('totalMachines'))
            document.getElementById('totalMachines').textContent = data.totalMachines || 0;
        if (document.getElementById('activeRentals'))
            document.getElementById('activeRentals').textContent = data.activeRentals || 0;
            
        if (window.updateChartData && data.monthlyRentals) {
            window.updateChartData(data.monthlyRentals);
        }
    } catch (error) {
        console.error("Error fetching dashboard data:", error);
    }
}

// Product functions
async function fetchProducts() {
    try {
        const response = await fetch(`${API_BASE_URL}/products`);
        if (!response.ok) throw new Error('Failed to fetch products');
        return await response.json();
    } catch (error) {
        console.error("Error fetching products:", error);
        showNotification("Error fetching products: " + error.message, 'error');
        return [];
    }
}

async function addProduct(product) {
    try {
        const response = await fetch(`${API_BASE_URL}/products`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${localStorage.getItem('adminToken')}`
            },
            body: JSON.stringify(product),
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        showNotification("Product added successfully!", 'success');
    } catch (error) {
        console.error("Error adding product:", error);
        showNotification("Failed to add product: " + error.message, 'error');
    }
}

async function deleteProduct(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/products/${id}`, {
            method: "DELETE",
            headers: {
                "Authorization": `Bearer ${localStorage.getItem('adminToken')}`
            }
        });
        if (!response.ok) {
            const data = await response.json();
            throw new Error(data.message);
        }
        showNotification("Product deleted successfully!", 'success');
    } catch (error) {
        console.error("Error deleting product:", error);
        showNotification("Failed to delete product: " + error.message, 'error');
    }
}

async function fetchAndDisplayProducts() {
    const products = await fetchProducts();
    const productTable = document.getElementById("productTable");
    if (!products || !productTable) return;
    
    productTable.innerHTML = products.length === 0 ? 
        `<tr><td colspan="5" class="text-center">No products found</td></tr>` : 
        products.map(product => {
            const imageSrc = product.image_url || 'https://via.placeholder.com/60x60?text=No+Image';
            return `
                <tr>
                    <td><img src="${imageSrc}" alt="${product.name}" class="product-image-thumbnail"></td>
                    <td>${product.name}</td>
                    <td>${product.type}</td>
                    <td>$${product.price}</td>
                    <td>
                        <button class="delete-btn" data-id="${product.id}">Delete</button>
                    </td>
                </tr>
            `;
        }).join('');
}

// Rental functions
async function fetchRentals() {
    try {
        const token = localStorage.getItem('adminToken');
        const headers = token ? { "Authorization": `Bearer ${token}` } : {};
        
        const response = await fetch(`${API_BASE_URL}/admin/rentals`, { headers });
        if (!response.ok) throw new Error('Failed to fetch rentals');
        
        const result = await response.json();
        const rentals = result.data || [];
        const rentalTable = document.getElementById("rentalTable");
        
        if (!rentalTable) return;
        
        rentalTable.innerHTML = rentals.length === 0 ? 
            `<tr><td colspan="5" class="text-center">No rental requests found</td></tr>` : 
            rentals.map(rental => {
                const statusClass = rental.status ? `status-${rental.status}` : 'status-pending';
                const statusText = capitalizeFirstLetter(rental.status || 'pending');
                
                return `
                    <tr class="${rental.status}-row">
                        <td>${rental.farmer_name || 'N/A'}</td>
                        <td>${rental.product_name || 'N/A'}</td>
                        <td>${formatDate(rental.rental_date)}</td>
                        <td>
                            <span class="status-badge ${statusClass}">${statusText}</span>
                        </td>
                        <td class="action-buttons">
                            ${getRentalActionButtons(rental)}
                        </td>
                    </tr>
                `;
            }).join('');
    } catch (error) {
        console.error("Error fetching rentals:", error);
        const rentalTable = document.getElementById("rentalTable");
        if (rentalTable) {
            rentalTable.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center">Error loading rentals: ${error.message}</td>
                </tr>
            `;
        }
    }
}

function getRentalActionButtons(rental) {
    const id = rental.id;
    let buttons = `<button class="details-btn" data-id="${id}">Details</button>`;
    
    if (rental.status === 'pending') {
        buttons += `
            <button class="approve-btn" data-id="${id}">Approve</button>
            <button class="reject-btn" data-id="${id}">Reject</button>
        `;
    } else if (rental.status === 'approved') {
        buttons += `<button class="complete-btn" data-id="${id}">Complete</button>`;
    }
    
    return buttons;
}

async function updateRentalStatus(id, status) {
    try {
        const token = localStorage.getItem('adminToken');
        const headers = {
            "Content-Type": "application/json",
            "Authorization": token ? `Bearer ${token}` : ''
        };
        
        const response = await fetch(`${API_BASE_URL}/admin/rentals/${id}`, {
            method: "PUT",
            headers: headers,
            body: JSON.stringify({ status })
        });
        
        const data = await response.json();
        if (!response.ok) throw new Error(data.message || 'Failed to update rental status');
        
        showNotification(`Rental ${status} successfully!`, 'success');
        fetchRentals();
    } catch (error) {
        console.error(`Error updating rental status:`, error);
        showNotification(`Failed to update rental status: ${error.message}`, 'error');
    }
}

async function showRentalDetails(id) {
    try {
        const rental = await fetchRentalDetails(id);
        if (!rental) return;
        
        const modalHTML = `
            <div class="modal-overlay" id="rentalDetailModal">
                <div class="modal-content">
                    <span class="close-modal">&times;</span>
                    <h2>Rental Request Details</h2>
                    
                    <div class="detail-section">
                        <h3>Customer Information</h3>
                        <p><strong>Name:</strong> ${rental.farmer_name || 'N/A'}</p>
                        <p><strong>Phone:</strong> ${rental.farmer_phone || 'N/A'}</p>
                        <p><strong>Address:</strong> ${rental.farmer_address || 'N/A'}</p>
                    </div>
                    
                    <div class="detail-section">
                        <h3>Rental Information</h3>
                        <p><strong>Product:</strong> ${rental.product_name || 'N/A'}</p>
                        <p><strong>Start Date:</strong> ${formatDate(rental.rental_date)}</p>
                        <p><strong>Return Date:</strong> ${formatDate(rental.return_date)}</p>
                        <p><strong>Land Size:</strong> ${rental.land_size || 'N/A'} ${rental.land_size_unit || 'Acres'}</p>
                        <p><strong>Total Price:</strong> $${parseFloat(rental.total_price || 0).toFixed(2)}</p>
                        <p><strong>Status:</strong> 
                            <span class="status-badge status-${rental.status}">
                                ${capitalizeFirstLetter(rental.status)}
                            </span>
                        </p>
                    </div>
                    
                    <div class="detail-section">
                        <h3>Notes</h3>
                        <p>${rental.notes || 'No notes available'}</p>
                    </div>
                    
                    <div class="modal-actions">
                        ${getModalActionButtons(rental)}
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        const modal = document.getElementById('rentalDetailModal');
        
        modal.querySelector('.close-modal').addEventListener('click', () => {
            document.body.removeChild(modal);
        });
        
        modal.querySelectorAll('.action-btn').forEach(button => {
            button.addEventListener('click', async () => {
                const action = button.getAttribute('data-action');
                await updateRentalStatus(id, action);
                document.body.removeChild(modal);
            });
        });
        
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                document.body.removeChild(modal);
            }
        });
    } catch (error) {
        console.error("Error showing rental details:", error);
        showNotification(`Error loading rental details: ${error.message}`, 'error');
    }
}

async function fetchRentalDetails(id) {
    try {
        const token = localStorage.getItem('adminToken');
        const headers = token ? { "Authorization": `Bearer ${token}` } : {};
        
        const response = await fetch(`${API_BASE_URL}/admin/rentals/${id}`, { headers });
        if (!response.ok) throw new Error('Failed to fetch rental details');
        return await response.json();
    } catch (error) {
        console.error("Error fetching rental details:", error);
        throw error;
    }
}

function getModalActionButtons(rental) {
    if (!rental) return '';
    
    if (rental.status === 'pending') {
        return `
            <button class="action-btn approve" data-action="approved" data-id="${rental.id}">Approve</button>
            <button class="action-btn reject" data-action="rejected" data-id="${rental.id}">Reject</button>
        `;
    } else if (rental.status === 'approved') {
        return `<button class="action-btn complete" data-action="completed" data-id="${rental.id}">Complete</button>`;
    }
    return '';
}

// Video functions
async function fetchVideos() {
    try {
        const response = await fetch(`${API_BASE_URL}/videos`);
        const result = await response.json();
        const videos = result.data || [];
        const videoTable = document.getElementById("videoTable");
        if (!videoTable) return;
        
        videoTable.innerHTML = videos.length === 0 ? 
            `<tr><td colspan="3" class="text-center">No videos found</td></tr>` : 
            videos.map(video => `
                <tr>
                    <td>${video.title}</td>
                    <td><a href="${video.url}" target="_blank">Watch Video</a></td>
                    <td>
                        <button class="delete-btn" data-id="${video.id}">Delete</button>
                    </td>
                </tr>
            `).join('');
    } catch (error) {
        console.error("Error fetching videos:", error);
        showNotification("Error fetching videos: " + error.message, 'error');
    }
}

async function addVideo(title, video_url, description = '') {
    try {
        const response = await fetch(`${API_BASE_URL}/videos`, {
            method: "POST",
            headers: { 
                "Content-Type": "application/json",
                "Authorization": `Bearer ${localStorage.getItem('adminToken')}`
            },
            body: JSON.stringify({ 
                title, 
                url: video_url,
                description
            })
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        showNotification("Video added successfully!", 'success');
    } catch (error) {
        console.error("Error adding video:", error);
        showNotification("Failed to add video: " + error.message, 'error');
    }
}

async function deleteVideo(id) {
    try {
        const response = await fetch(`${API_BASE_URL}/videos/${id}`, {
            method: "DELETE",
            headers: {
                "Authorization": `Bearer ${localStorage.getItem('adminToken')}`
            }
        });
        if (response.status === 204) {
            showNotification("Video deleted successfully!", 'success');
            return;
        }
        const data = await response.json();
        if (!response.ok) throw new Error(data.message);
        showNotification("Video deleted successfully!", 'success');
    } catch (error) {
        console.error("Error deleting video:", error);
        showNotification("Failed to delete video: " + error.message, 'error');
    }
}