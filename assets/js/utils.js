// Utility functions
export function formatNumber(num) {
    if (num == null || (typeof num === 'number' && Number.isNaN(num))) {
        return '-';
    }
    return num.toLocaleString();
}

export function formatDate(date) {
    if (!date || !(date instanceof Date) || Number.isNaN(date.getTime())) {
        return '-';
    }
    return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
    });
}

export function filterDataByDays(data, days) {
    if (days === 'all') return data;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - days);
    return data.filter(d => d.date >= cutoffDate);
}

export function calculateStats(viewsData, clonesData) {
    const totalViews = d3.sum(viewsData, d => d.total);
    const totalUniqueViews = d3.sum(viewsData, d => d.unique);
    const avgViews = Math.round(totalViews / viewsData.length);
    const peakViews = d3.max(viewsData, d => d.total);
    const totalClones = d3.sum(clonesData, d => d.total);

    return {
        totalViews,
        totalUniqueViews,
        avgViews,
        peakViews,
        totalClones
    };
}

