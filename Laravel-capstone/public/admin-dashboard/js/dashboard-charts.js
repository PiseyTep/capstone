// dashboard-charts.js

// Wait for the DOM to be fully loaded
document.addEventListener('DOMContentLoaded', function() {
    // Get the chart canvas element
    const chartCanvas = document.getElementById('rentalChart');
    
    // If the canvas doesn't exist, exit
    if (!chartCanvas) {
        console.error('Chart canvas element not found');
        return;
    }
    
    // Store the chart instance globally so we can destroy it when changing chart types
    let rentalChart = null;
    
    // Sample data - replace with your actual data
    const monthlyData = [65, 78, 82, 70, 85, 92, 88, 94, 99, 85, 72, 68];
    
    // Colors
    const primaryColor = '#2c5e1a';
    const secondaryColor = '#9be876';
    
    // Function to create the chart
    function createChart(type) {
        // If a chart already exists, destroy it
        if (rentalChart) {
            rentalChart.destroy();
        }
        
        // Get the context of the canvas element
        const ctx = chartCanvas.getContext('2d');
        
        // Configuration for the chart
        const config = {
            type: type, // 'bar' or 'line'
            data: {
                labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                datasets: [{
                    label: 'Monthly Rentals',
                    data: monthlyData,
                    backgroundColor: type === 'bar' ? primaryColor : 'rgba(44, 94, 26, 0.1)',
                    borderColor: primaryColor,
                    borderWidth: 2,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    tooltip: {
                        callbacks: {
                            title: function(tooltipItems) {
                                return tooltipItems[0].label;
                            },
                            label: function(context) {
                                return `Rentals: ${context.raw}`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Number of Rentals'
                        },
                        ticks: {
                            precision: 0
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Month'
                        }
                    }
                }
            }
        };
        
        // Create the chart
        rentalChart = new Chart(ctx, config);
        return rentalChart;
    }
    
    // Create the initial chart (bar chart by default)
    const chartTypeSelect = document.getElementById('chartType');
    const initialChartType = chartTypeSelect ? chartTypeSelect.value : 'bar';
    createChart(initialChartType);
    
    // Add event listener for chart type change
    if (chartTypeSelect) {
        chartTypeSelect.addEventListener('change', function() {
            createChart(this.value);
        });
    }
    
    // Add event listener for export button
    const downloadButton = document.getElementById('downloadReport');
    if (downloadButton) {
        downloadButton.addEventListener('click', function() {
            if (rentalChart) {
                // Create a temporary link
                const link = document.createElement('a');
                link.download = 'monthly-rentals-chart.png';
                link.href = rentalChart.toBase64Image();
                link.click();
            }
        });
    }
    
    // Function to update chart with new data
    // This could be called after fetching data from your API
    window.updateChartData = function(newData) {
        if (rentalChart) {
            rentalChart.data.datasets[0].data = newData;
            rentalChart.update();
        }
    };
});