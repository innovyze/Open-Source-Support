// Configuration and constants
export const CONFIG = {
    margin: { top: 20, right: 30, bottom: 50, left: 60 },
    chartHeight: Math.min(400, window.innerHeight * 0.45), // Dynamic height, max 400px or 45% of viewport
    colors: {
        total: '#5eb7ff',
        unique: '#ff9b5a'
    },
    animationDuration: 1500
};

export const FULLY_MISSING_PERIODS = [
    { start: new Date('2025-10-20'), end: new Date('2025-10-30'), label: 'Missing Data' }
];

export const RECONSTRUCTED_TOTALS_PERIODS = [
    { start: new Date('2025-11-15'), end: new Date('2026-01-07'), label: 'Reconstructed Totals' }
];

export const TIME_RANGES = {
    '30': 30,
    '90': 90,
    '365': 365,
    'all': 'all'
};

