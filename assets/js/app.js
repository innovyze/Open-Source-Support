// Main application module
import { loadTrafficData } from './dataLoader.js';
import { drawChart } from './chart.js';
import { formatNumber, formatDate, calculateStats } from './utils.js';

let viewsData = [];
let clonesData = [];
let currentRange = 'all';
let currentChartType = 'views';
let visibleSeries = { total: true, unique: true }; // Track which series are visible

function updateStats() {
    const stats = calculateStats(viewsData, clonesData);

    document.getElementById('totalViews').textContent = formatNumber(stats.totalViews);
    document.getElementById('uniqueViews').textContent = formatNumber(stats.totalUniqueViews);
    document.getElementById('avgViews').textContent = formatNumber(stats.avgViews);
    document.getElementById('peakViews').textContent = formatNumber(stats.peakViews);
    document.getElementById('totalClones').textContent = formatNumber(stats.totalClones);
}

function updateChart() {
    const data = currentChartType === 'views' ? viewsData : clonesData;
    drawChart('mainChart', data, currentChartType, currentRange, visibleSeries);
}

function setupEventListeners() {
    // Chart type toggle
    document.querySelectorAll('.toggle-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.toggle-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            currentChartType = this.dataset.type;
            
            // Update labels
            const label = currentChartType === 'views' ? 'Views' : 'Clones';
            document.getElementById('chartTypeLabel').textContent = label;
            document.getElementById('legendTypeLabel').textContent = label;
            document.getElementById('legendTypeLabel2').textContent = label;
            
            updateChart();
        });
    });

    // Time range selector
    document.querySelectorAll('.time-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.time-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            currentRange = this.dataset.days;
            updateChart();
        });
    });

    // Legend click to toggle series visibility
    document.querySelectorAll('.legend-item').forEach(item => {
        item.addEventListener('click', function() {
            const series = this.dataset.series;
            visibleSeries[series] = !visibleSeries[series];
            
            // Update visual state
            if (visibleSeries[series]) {
                this.classList.remove('disabled');
            } else {
                this.classList.add('disabled');
            }
            
            // Redraw chart
            updateChart();
        });
    });

    // Theme toggle
    const themeToggle = document.getElementById('themeToggle');
    if (themeToggle) {
        themeToggle.addEventListener('click', function() {
            document.body.classList.toggle('light-theme');
            const isLight = document.body.classList.contains('light-theme');
            localStorage.setItem('theme', isLight ? 'light' : 'dark');
            
            // Update icon
            this.querySelector('.theme-icon').textContent = isLight ? '🌙' : '☀️';
            
            // Redraw chart with new theme colors
            updateChart();
        });
    }

    // Responsive resize
    let resizeTimeout;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(() => {
            updateChart();
        }, 250);
    });
}

async function init() {
    try {
        // Load theme preference
        const savedTheme = localStorage.getItem('theme');
        if (savedTheme === 'light') {
            document.body.classList.add('light-theme');
        }

        const data = await loadTrafficData();
        viewsData = data.viewsData;
        clonesData = data.clonesData;

        updateStats();
        setupEventListeners();
        
        // Wait for layout to complete before drawing chart
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                updateChart();
            });
        });

        // Update last updated date
        const lastUpdatedEl = document.getElementById('lastUpdated');
        if (lastUpdatedEl) {
            if (viewsData.length > 0) {
                const lastDate = viewsData[viewsData.length - 1].date;
                lastUpdatedEl.textContent = `Last updated: ${formatDate(lastDate)}`;
            } else {
                lastUpdatedEl.textContent = 'Last updated: No data';
            }
        }

    } catch (error) {
        console.error('Error initializing dashboard:', error);
        document.getElementById('mainChart').innerHTML = 
            `<div class="error">${error.message}</div>`;
    }
}

// Start the application
init();


