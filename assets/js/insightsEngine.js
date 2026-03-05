function isValidDate(value) {
    return value instanceof Date && !Number.isNaN(value.getTime());
}

function toFiniteNumber(value) {
    return Number.isFinite(value) ? value : 0;
}

function sumTotals(data, predicate) {
    return (data ?? []).reduce((sum, point) => {
        if (!point || !isValidDate(point.date) || !predicate(point.date)) {
            return sum;
        }
        return sum + toFiniteNumber(point.total);
    }, 0);
}

function getLatestDate(data) {
    return (data ?? [])
        .filter(point => point && isValidDate(point.date))
        .reduce((latest, point) => (latest && latest > point.date ? latest : point.date), null);
}

function isOnOrBeforeMonthDay(date, monthIndex, dayOfMonth) {
    const month = date.getMonth();
    if (month < monthIndex) {
        return true;
    }
    if (month > monthIndex) {
        return false;
    }
    return date.getDate() <= dayOfMonth;
}

export function aggregateByYear(data) {
    const yearBuckets = new Map();

    (data ?? []).forEach(point => {
        if (!point || !isValidDate(point.date)) {
            return;
        }

        const year = point.date.getFullYear();
        if (!yearBuckets.has(year)) {
            yearBuckets.set(year, { year, total: 0, unique: 0, days: 0 });
        }

        const bucket = yearBuckets.get(year);
        bucket.total += toFiniteNumber(point.total);
        bucket.unique += toFiniteNumber(point.unique);
        bucket.days += 1;
    });

    return Array.from(yearBuckets.values())
        .sort((a, b) => a.year - b.year)
        .map(bucket => ({
            ...bucket,
            avgDaily: bucket.days > 0 ? bucket.total / bucket.days : 0
        }));
}

export function aggregateByMonth(data) {
    const monthBuckets = new Map();

    (data ?? []).forEach(point => {
        if (!point || !isValidDate(point.date)) {
            return;
        }

        const year = point.date.getFullYear();
        const monthValue = point.date.getMonth() + 1;
        const month = `${year}-${String(monthValue).padStart(2, '0')}`;

        if (!monthBuckets.has(month)) {
            monthBuckets.set(month, { month, total: 0, unique: 0, days: 0 });
        }

        const bucket = monthBuckets.get(month);
        bucket.total += toFiniteNumber(point.total);
        bucket.unique += toFiniteNumber(point.unique);
        bucket.days += 1;
    });

    return Array.from(monthBuckets.values())
        .sort((a, b) => a.month.localeCompare(b.month))
        .map(bucket => ({
            ...bucket,
            avgDaily: bucket.days > 0 ? bucket.total / bucket.days : 0
        }));
}

export function computeYoYGrowth(yearlyData) {
    const sorted = [...(yearlyData ?? [])].sort((a, b) => a.year - b.year);

    return sorted.map((entry, index) => {
        if (index === 0) {
            return { ...entry, growthPct: null };
        }

        const previous = sorted[index - 1];
        const growthPct = previous.total > 0
            ? ((entry.total - previous.total) / previous.total) * 100
            : null;

        return { ...entry, growthPct };
    });
}

export function computeYTDComparison(data) {
    const latestDate = getLatestDate(data);
    if (!latestDate) {
        return {
            currentYTD: 0,
            previousYTD: 0,
            growthPct: null
        };
    }

    const currentYear = latestDate.getFullYear();
    const previousYear = currentYear - 1;
    const cutoffMonth = latestDate.getMonth();
    const cutoffDay = latestDate.getDate();

    const currentYTD = sumTotals(
        data,
        date =>
            date.getFullYear() === currentYear &&
            isOnOrBeforeMonthDay(date, cutoffMonth, cutoffDay)
    );

    const previousYTD = sumTotals(
        data,
        date =>
            date.getFullYear() === previousYear &&
            isOnOrBeforeMonthDay(date, cutoffMonth, cutoffDay)
    );

    const growthPct = previousYTD > 0
        ? ((currentYTD - previousYTD) / previousYTD) * 100
        : null;

    return {
        currentYTD,
        previousYTD,
        growthPct,
        currentYear,
        previousYear,
        cutoffDate: new Date(latestDate)
    };
}

export function computeCloneRate(viewsData, clonesData) {
    const latestViewsDate = getLatestDate(viewsData);
    const latestClonesDate = getLatestDate(clonesData);
    const latestDate =
        latestViewsDate && latestClonesDate
            ? (latestViewsDate > latestClonesDate ? latestViewsDate : latestClonesDate)
            : (latestViewsDate || latestClonesDate);

    if (!latestDate) {
        return {
            currentRate: 0,
            previousRate: 0
        };
    }

    const currentYear = latestDate.getFullYear();
    const previousYear = currentYear - 1;
    const cutoffMonth = latestDate.getMonth();
    const cutoffDay = latestDate.getDate();

    const inCurrentWindow = date =>
        date.getFullYear() === currentYear &&
        isOnOrBeforeMonthDay(date, cutoffMonth, cutoffDay);
    const inPreviousWindow = date =>
        date.getFullYear() === previousYear &&
        isOnOrBeforeMonthDay(date, cutoffMonth, cutoffDay);

    const currentViews = sumTotals(viewsData, inCurrentWindow);
    const previousViews = sumTotals(viewsData, inPreviousWindow);
    const currentClones = sumTotals(clonesData, inCurrentWindow);
    const previousClones = sumTotals(clonesData, inPreviousWindow);

    const currentRate = currentViews > 0 ? (currentClones / currentViews) * 100 : 0;
    const previousRate = previousViews > 0 ? (previousClones / previousViews) * 100 : 0;

    return {
        currentRate,
        previousRate,
        currentClones,
        previousClones,
        currentViews,
        previousViews,
        currentYear,
        previousYear,
        cutoffDate: new Date(latestDate)
    };
}

export function computeMonthlyYoY(monthlyData) {
    const sorted = [...(monthlyData ?? [])].sort((a, b) => a.month.localeCompare(b.month));
    const monthLookup = new Map(sorted.map(entry => [entry.month, entry]));

    return sorted.map(entry => {
        const [yearText, monthText] = entry.month.split('-');
        const year = Number.parseInt(yearText, 10);
        const previousMonthKey = `${year - 1}-${monthText}`;
        const previous = monthLookup.get(previousMonthKey);
        const growthPct = previous && previous.total > 0
            ? ((entry.total - previous.total) / previous.total) * 100
            : null;

        return {
            ...entry,
            previousTotal: previous ? previous.total : null,
            previousAvgDaily: previous ? previous.avgDaily : null,
            growthPct
        };
    });
}
