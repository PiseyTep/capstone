// login.js - Save to /LoginFarmer/Laravel-capstone/public/admin-dashboard/js/login.js

// Handle form toggling
document.addEventListener("DOMContentLoaded", function() {
    // Get toggle buttons
    const signUpButton = document.getElementById('signUpButton');
    const signInButton = document.getElementById('signInButton');
    
    // Add event listeners
    if (signUpButton) {
        signUpButton.addEventListener('click', function() {
            document.getElementById('signIn').style.display = "none";
            document.getElementById('signup').style.display = "block";
        });
    }
    
    if (signInButton) {
        signInButton.addEventListener('click', function() {
            document.getElementById('signIn').style.display = "block";
            document.getElementById('signup').style.display = "none";
        });
    }
    
    // Handle error message fade out
    const errorMessage = document.getElementById("error-message");
    if (errorMessage) {
        setTimeout(() => {
            errorMessage.style.opacity = "0"; // Fade out
            setTimeout(() => {
                errorMessage.style.display = "none"; // Hide after fade-out
            }, 500); // Wait for the transition to complete
        }, 5000); // 5000 milliseconds = 5 seconds
    }
});