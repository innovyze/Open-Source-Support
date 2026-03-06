// Data loading module
export async function loadTrafficData() {
    try {
        const timestamp = Date.now();
        const [views, clones] = await Promise.all([
            d3.csv(`data/views.csv?t=${timestamp}`),
            d3.csv(`data/clones.csv?t=${timestamp}`)
        ]);

        const viewsData = views.map(d => ({
            date: new Date(d._date),
            total: +d.total_views,
            unique: +d.unique_views
        })).sort((a, b) => a.date - b.date);

        const clonesData = clones.map(d => ({
            date: new Date(d._date),
            total: +d.total_clones,
            unique: +d.unique_clones
        })).sort((a, b) => a.date - b.date);

        return { viewsData, clonesData };
    } catch (error) {
        console.error('Error loading data:', error);
        throw new Error('Failed to load traffic data. Please check that CSV files exist in the data/ directory.');
    }
}

export async function loadMilestones() {
    try {
        const timestamp = Date.now();
        const milestones = await d3.json(`data/milestones.json?t=${timestamp}`);
        return milestones.sort((a, b) => a.date.localeCompare(b.date));
    } catch (error) {
        console.error('Error loading milestones:', error);
        throw new Error('Failed to load milestones data.');
    }
}

export function aggregateMonthlyViews(viewsData) {
    const map = new Map();
    for (const d of viewsData) {
        const key = d.date.toISOString().slice(0, 7);
        if (!map.has(key)) map.set(key, 0);
        map.set(key, map.get(key) + d.total);
    }
    return Array.from(map.entries())
        .map(([month, views]) => ({ month, views }))
        .sort((a, b) => a.month.localeCompare(b.month));
}
