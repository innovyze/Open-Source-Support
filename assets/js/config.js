// Configuration and constants
export const CONFIG = {
    margin: { top: 20, right: 30, bottom: 50, left: 60 },
    chartHeight: Math.min(400, window.innerHeight * 0.45), // Dynamic height, max 400px or 45% of viewport
    colors: {
        total: '#4fa9f0',
        unique: '#ef8848'
    },
    animationDuration: 1500
};

export const FULLY_MISSING_PERIODS = [];

export const RECONSTRUCTED_TOTALS_PERIODS = [
    { start: new Date('2025-10-20'), end: new Date('2025-10-30'), label: 'Reconstructed Totals' },
    { start: new Date('2025-11-14'), end: new Date('2026-01-07'), label: 'Reconstructed Totals' }
];

export const TIME_RANGES = {
    '30': 30,
    '90': 90,
    '365': 365,
    'all': 'all'
};

