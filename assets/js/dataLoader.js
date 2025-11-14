// Data loading module
export async function loadTrafficData() {
    try {
        const [views, clones] = await Promise.all([
            d3.csv('data/views.csv'),
            d3.csv('data/clones.csv')
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

