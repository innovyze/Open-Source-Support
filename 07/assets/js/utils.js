// Utility functions
export function formatNumber(num) {
    return num.toLocaleString();
}

export function formatDate(date) {
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

