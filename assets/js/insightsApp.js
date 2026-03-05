import { FULLY_MISSING_PERIODS } from './config.js';
import { loadTrafficData } from './dataLoader.js';
import {
    aggregateByMonth,
    aggregateByYear,
    computeCloneRate,
    computeMonthlyYoY,
    computeYoYGrowth,
    computeYTDComparison
} from './insightsEngine.js';
import { formatDate, formatNumber } from './utils.js';

let appState = null;

function getLatestDate(data) {
    return (data ?? [])
        .filter(point => point?.date instanceof Date && !Number.isNaN(point.date.getTime()))
        .reduce((latest, point) => (latest && latest > point.date ? latest : point.date), null);
}

function toMonthKey(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}

function formatSignedPercent(value, digits = 1) {
    if (!Number.isFinite(value)) {
        return 'n/a';
    }
    const fixed = value.toFixed(digits);
    return `${value >= 0 ? '+' : ''}${fixed}%`;
}

function formatMonthLabel(monthKey) {
    const date = new Date(`${monthKey}-01T00:00:00`);
    return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}

function getBadgeClass(value) {
    if (!Number.isFinite(value)) {
        return 'badge';
    }
    return value >= 0 ? 'badge up' : 'badge down';
}

function setBadge(el, value, text) {
    if (!el) {
        return;
    }
    el.className = getBadgeClass(value);
    el.textContent = text;
}

function shiftYear(date, amount) {
    const shifted = new Date(date);
    shifted.setFullYear(shifted.getFullYear() + amount);
    return shifted;
}

function computeRollingAverage(data, days) {
    const latestDate = getLatestDate(data);
    if (!latestDate) {
        return {
            currentAvg: 0,
            previousAvg: 0,
            growthPct: null,
            previousYear: null
        };
    }

    const startDate = new Date(latestDate);
    startDate.setDate(startDate.getDate() - (days - 1));

    const currentWindow = data.filter(point => point.date >= startDate && point.date <= latestDate);
    const previousStart = shiftYear(startDate, -1);
    const previousEnd = shiftYear(latestDate, -1);
    const previousWindow = data.filter(point => point.date >= previousStart && point.date <= previousEnd);

    const currentAvg = currentWindow.length > 0
        ? d3.sum(currentWindow, point => point.total) / currentWindow.length
        : 0;
    const previousAvg = previousWindow.length > 0
        ? d3.sum(previousWindow, point => point.total) / previousWindow.length
        : 0;
    const growthPct = previousAvg > 0
        ? ((currentAvg - previousAvg) / previousAvg) * 100
        : null;

    return {
        currentAvg,
        previousAvg,
        growthPct,
        previousYear: latestDate.getFullYear() - 1
    };
}

function collectGapMonths() {
    const months = new Set();

    FULLY_MISSING_PERIODS.forEach(period => {
        const cursor = new Date(period.start.getFullYear(), period.start.getMonth(), 1);
        const end = new Date(period.end.getFullYear(), period.end.getMonth(), 1);

        while (cursor <= end) {
            months.add(toMonthKey(cursor));
            cursor.setMonth(cursor.getMonth() + 1);
        }
    });

    return months;
}

function formatCompactNumber(value) {
    const formatter = new Intl.NumberFormat('en-US', {
        notation: 'compact',
        maximumFractionDigits: 1
    });
    return formatter.format(value);
}

function getCssVar(name, fallback) {
    const value = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
    return value || fallback;
}

function updateSummaryCards(viewsData, clonesData) {
    const viewsYTD = computeYTDComparison(viewsData);
    const clonesYTD = computeYTDComparison(clonesData);
    const cloneRate = computeCloneRate(viewsData, clonesData);
    const avg30d = computeRollingAverage(viewsData, 30);

    const viewsYtdValue = document.getElementById('viewsYtdValue');
    const viewsYtdBadge = document.getElementById('viewsYtdBadge');
    const viewsYtdContext = document.getElementById('viewsYtdContext');

    viewsYtdValue.textContent = formatNumber(Math.round(viewsYTD.currentYTD));
    setBadge(viewsYtdBadge, viewsYTD.growthPct, formatSignedPercent(viewsYTD.growthPct, 1));
    viewsYtdContext.textContent = viewsYTD.previousYear
        ? `vs ${formatNumber(Math.round(viewsYTD.previousYTD))} in same period ${viewsYTD.previousYear}`
        : 'No previous-year baseline available';

    const clonesYtdValue = document.getElementById('clonesYtdValue');
    const clonesYtdBadge = document.getElementById('clonesYtdBadge');
    const clonesYtdContext = document.getElementById('clonesYtdContext');

    clonesYtdValue.textContent = formatNumber(Math.round(clonesYTD.currentYTD));
    setBadge(clonesYtdBadge, clonesYTD.growthPct, formatSignedPercent(clonesYTD.growthPct, 1));
    clonesYtdContext.textContent = clonesYTD.previousYear
        ? `vs ${formatNumber(Math.round(clonesYTD.previousYTD))} in same period ${clonesYTD.previousYear}`
        : 'No previous-year baseline available';

    const avg30dValue = document.getElementById('avg30dValue');
    const avg30dBadge = document.getElementById('avg30dBadge');
    const avg30dContext = document.getElementById('avg30dContext');

    avg30dValue.textContent = formatNumber(Math.round(avg30d.currentAvg));
    setBadge(avg30dBadge, avg30d.growthPct, formatSignedPercent(avg30d.growthPct, 0));
    avg30dContext.textContent = avg30d.previousYear
        ? `vs ${formatNumber(Math.round(avg30d.previousAvg))} avg/day in same window ${avg30d.previousYear}`
        : 'No previous-year baseline available';

    const cloneRateValue = document.getElementById('cloneRateValue');
    const cloneRateBadge = document.getElementById('cloneRateBadge');
    const cloneRateContext = document.getElementById('cloneRateContext');
    const cloneRateDelta = cloneRate.currentRate - cloneRate.previousRate;

    cloneRateValue.textContent = `${cloneRate.currentRate.toFixed(1)}%`;
    setBadge(
        cloneRateBadge,
        cloneRateDelta,
        Number.isFinite(cloneRateDelta) ? `${cloneRateDelta >= 0 ? '+' : ''}${cloneRateDelta.toFixed(1)} pp` : 'n/a'
    );
    cloneRateContext.textContent = cloneRate.previousYear
        ? `vs ${cloneRate.previousRate.toFixed(1)}% in same period ${cloneRate.previousYear}`
        : 'No previous-year baseline available';
}

function drawYearlyChart(yearlyData, latestDate) {
    const chartEl = document.getElementById('yearlyChart');
    const noteEl = document.getElementById('yearlyChartNote');

    chartEl.innerHTML = '';
    if (!yearlyData || yearlyData.length === 0) {
        chartEl.innerHTML = '<div class="loading">No yearly data available</div>';
        noteEl.textContent = '';
        return;
    }

    const latestYear = latestDate?.getFullYear();
    const daysInYear = latestYear && new Date(latestYear, 1, 29).getDate() === 29 ? 366 : 365;
    const dayOfYear = latestDate
        ? Math.floor((latestDate - new Date(latestYear, 0, 0)) / (1000 * 60 * 60 * 24))
        : null;

    const chartRows = yearlyData.map(row => {
        const isCurrentYear = row.year === latestYear;
        const canProject = isCurrentYear && dayOfYear && dayOfYear > 0 && dayOfYear < daysInYear;
        const projectedTotal = canProject ? (row.total / dayOfYear) * daysInYear : null;
        const displayTotal = projectedTotal ?? row.total;

        return {
            ...row,
            isCurrentYear,
            projectedTotal,
            displayTotal
        };
    });

    const width = Math.max(chartEl.clientWidth, 500);
    const height = 320;
    const margin = { top: 42, right: 18, bottom: 44, left: 54 };

    const x = d3.scaleBand()
        .domain(chartRows.map(row => String(row.year)))
        .range([margin.left, width - margin.right])
        .padding(0.22);

    const maxValue = d3.max(chartRows, row => row.displayTotal) ?? 0;
    const y = d3.scaleLinear()
        .domain([0, maxValue * 1.12 || 1])
        .range([height - margin.bottom, margin.top]);

    const svg = d3.select(chartEl)
        .append('svg')
        .attr('class', 'bar-chart-svg')
        .attr('viewBox', `0 0 ${width} ${height}`)
        .attr('preserveAspectRatio', 'xMidYMid meet');

    svg.append('g')
        .attr('class', 'grid')
        .attr('transform', `translate(${margin.left},0)`)
        .call(
            d3.axisLeft(y)
                .ticks(4)
                .tickSize(-(width - margin.left - margin.right))
                .tickFormat('')
        );

    svg.append('g')
        .attr('class', 'axis')
        .attr('transform', `translate(${margin.left},0)`)
        .call(
            d3.axisLeft(y)
                .ticks(5)
                .tickFormat(value => formatCompactNumber(value))
        )
        .call(g => g.select('.domain').remove());

    const barColor = getCssVar('--bar-color', '#3b82f6');
    const barStripe = getCssVar('--bar-stripe', 'rgba(255, 255, 255, 0.5)');
    const patternId = `year-pace-${Date.now()}`;

    const defs = svg.append('defs');
    const projectedPattern = defs.append('pattern')
        .attr('id', patternId)
        .attr('width', 8)
        .attr('height', 8)
        .attr('patternUnits', 'userSpaceOnUse')
        .attr('patternTransform', 'rotate(45)');

    projectedPattern.append('rect')
        .attr('width', 8)
        .attr('height', 8)
        .attr('fill', barColor);

    projectedPattern.append('line')
        .attr('x1', 0)
        .attr('y1', 0)
        .attr('x2', 0)
        .attr('y2', 8)
        .attr('stroke', barStripe)
        .attr('stroke-width', 3);

    const groups = svg.selectAll('.year-bar')
        .data(chartRows)
        .enter()
        .append('g')
        .attr('class', 'year-bar')
        .attr('transform', row => `translate(${x(String(row.year))},0)`);

    groups.append('text')
        .attr('class', row => {
            if (row.isCurrentYear && row.projectedTotal) {
                return 'bar-growth text-muted';
            }
            if (!Number.isFinite(row.growthPct)) {
                return 'bar-growth text-muted';
            }
            return row.growthPct >= 0 ? 'bar-growth text-up' : 'bar-growth text-down';
        })
        .attr('x', x.bandwidth() / 2)
        .attr('y', row => Math.max(margin.top + 2, y(row.displayTotal) - 26))
        .attr('text-anchor', 'middle')
        .text(row => {
            if (row.isCurrentYear && row.projectedTotal) {
                return 'pace';
            }
            return Number.isFinite(row.growthPct) ? formatSignedPercent(row.growthPct, 0) : '';
        });

    groups.append('text')
        .attr('class', 'bar-value')
        .attr('x', x.bandwidth() / 2)
        .attr('y', row => Math.max(margin.top + 18, y(row.displayTotal) - 10))
        .attr('text-anchor', 'middle')
        .text(row => {
            const compact = formatCompactNumber(Math.round(row.displayTotal));
            return row.isCurrentYear && row.projectedTotal ? `~${compact}` : compact;
        });

    groups.append('rect')
        .attr('class', row => (row.isCurrentYear && row.projectedTotal ? 'bar projected' : 'bar'))
        .attr('x', 0)
        .attr('y', row => y(row.displayTotal))
        .attr('width', x.bandwidth())
        .attr('height', row => y(0) - y(row.displayTotal))
        .attr('rx', 4)
        .attr('fill', row => (row.isCurrentYear && row.projectedTotal ? `url(#${patternId})` : barColor));

    groups.append('text')
        .attr('class', 'bar-label')
        .attr('x', x.bandwidth() / 2)
        .attr('y', height - margin.bottom + 20)
        .attr('text-anchor', 'middle')
        .text(row => String(row.year));

    const currentYearRow = chartRows.find(row => row.isCurrentYear && row.projectedTotal);
    if (currentYearRow && latestDate) {
        noteEl.textContent = `Striped bar for ${currentYearRow.year} projects full-year pace from data through ${formatDate(latestDate)}.`;
    } else {
        noteEl.textContent = 'Year bars show total annual views.';
    }
}

function renderMonthlyTable(monthlyData, latestYear) {
    const tableEl = document.getElementById('monthlyTable');
    const noteEl = document.getElementById('monthlyTableNote');
    tableEl.innerHTML = '';

    if (!monthlyData || monthlyData.length === 0) {
        tableEl.innerHTML = '<div class="loading">No monthly data available</div>';
        noteEl.textContent = '';
        return;
    }

    const recentRows = monthlyData.slice(-14);
    const gapMonths = collectGapMonths();

    const rowsHtml = recentRows
        .map(row => {
            const [yearText] = row.month.split('-');
            const year = Number.parseInt(yearText, 10);
            const isGap = gapMonths.has(row.month);
            const isCurrentYear = year === latestYear;

            let yoyText = 'n/a';
            let yoyClass = 'text-muted';

            if (isGap) {
                yoyText = 'gap';
            } else if (Number.isFinite(row.growthPct)) {
                yoyText = formatSignedPercent(row.growthPct, 0);
                yoyClass = row.growthPct >= 0 ? 'text-up' : 'text-down';
            }

            const rowClasses = [
                isGap ? 'gap-row' : '',
                isCurrentYear ? 'current-year-row' : ''
            ].filter(Boolean).join(' ');

            const cellClass = isCurrentYear ? 'current-year' : '';

            return `
                <tr class="${rowClasses}">
                    <td class="${cellClass}">${formatMonthLabel(row.month)}</td>
                    <td class="${cellClass}">${formatNumber(Math.round(row.total))}</td>
                    <td class="${cellClass}">${formatNumber(Math.round(row.avgDaily))}</td>
                    <td class="yoy-cell ${yoyClass}">${yoyText}</td>
                </tr>
            `;
        })
        .join('');

    tableEl.innerHTML = `
        <table class="monthly-table">
            <thead>
                <tr>
                    <th>Month</th>
                    <th>Views</th>
                    <th>Avg/Day</th>
                    <th>vs Last Year</th>
                </tr>
            </thead>
            <tbody>
                ${rowsHtml}
            </tbody>
        </table>
    `;

    noteEl.textContent = 'Months labeled "gap" include workflow outage periods with incomplete daily coverage.';
}

function render() {
    if (!appState) {
        return;
    }

    drawYearlyChart(appState.yearlyYoY, appState.latestDate);
    renderMonthlyTable(appState.monthlyYoY, appState.latestYear);
}

function setupThemeToggle() {
    const themeToggle = document.getElementById('themeToggle');
    if (!themeToggle) {
        return;
    }

    themeToggle.addEventListener('click', function onThemeToggle() {
        document.body.classList.toggle('light-theme');
        const isLight = document.body.classList.contains('light-theme');
        localStorage.setItem('theme', isLight ? 'light' : 'dark');
        const iconEl = this.querySelector('.theme-icon');
        if (iconEl) {
            iconEl.textContent = isLight ? '🌙' : '☀️';
        }

        render();
    });
}

function applySavedTheme() {
    const savedTheme = localStorage.getItem('theme');
    const themeToggle = document.getElementById('themeToggle');
    const iconEl = themeToggle?.querySelector('.theme-icon');

    if (savedTheme === 'light') {
        document.body.classList.add('light-theme');
        if (iconEl) {
            iconEl.textContent = '🌙';
        }
    } else if (iconEl) {
        iconEl.textContent = '☀️';
    }
}

function setupResizeHandler() {
    let resizeTimeout = null;
    window.addEventListener('resize', () => {
        window.clearTimeout(resizeTimeout);
        resizeTimeout = window.setTimeout(() => {
            drawYearlyChart(appState?.yearlyYoY ?? [], appState?.latestDate ?? null);
        }, 200);
    });
}

async function init() {
    try {
        applySavedTheme();
        setupThemeToggle();
        setupResizeHandler();

        const { viewsData, clonesData } = await loadTrafficData();
        const latestDate = getLatestDate(viewsData);
        const latestYear = latestDate?.getFullYear() ?? null;

        const yearly = aggregateByYear(viewsData);
        const yearlyYoY = computeYoYGrowth(yearly);
        const monthly = aggregateByMonth(viewsData);
        const monthlyYoY = computeMonthlyYoY(monthly);

        appState = {
            yearlyYoY,
            monthlyYoY,
            latestDate,
            latestYear
        };

        updateSummaryCards(viewsData, clonesData);
        render();

        const lastUpdatedEl = document.getElementById('lastUpdated');
        if (lastUpdatedEl) {
            lastUpdatedEl.textContent = latestDate
                ? `Last updated: ${formatDate(latestDate)}`
                : 'Last updated: No data';
        }
    } catch (error) {
        console.error('Error initializing insights page:', error);
        const chartEl = document.getElementById('yearlyChart');
        const tableEl = document.getElementById('monthlyTable');
        if (chartEl) {
            chartEl.innerHTML = `<div class="error">${error.message}</div>`;
        }
        if (tableEl) {
            tableEl.innerHTML = `<div class="error">${error.message}</div>`;
        }
    }
}

init();
