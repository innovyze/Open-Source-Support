// Configuration and constants
export const CONFIG = {
    margin: { top: 20, right: 30, bottom: 50, left: 60 },
    chartHeight: Math.min(400, window.innerHeight * 0.45), // Dynamic height, max 400px or 45% of viewport
    colors: {
        total: '#2563eb',
        unique: '#10b981'
    },
    animationDuration: 1500
};

export const MISSING_PERIODS = [
    { start: new Date('2025-11-14'), end: new Date('2026-01-08'), label: 'Workflow Outage' },
    { start: new Date('2025-10-19'), end: new Date('2025-10-31'), label: 'Workflow Outage' }
];

export const TIME_RANGES = {
    '30': 30,
    '90': 90,
    '365': 365,
    'all': 'all'
};

