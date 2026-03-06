import { loadTrafficData, loadMilestones, aggregateMonthlyViews } from './dataLoader.js';

let monthlyData = [];
let milestones = [];
let activeFilter = 'all';

function monthToIndex(monthKey) {
    for (let i = 0; i < monthlyData.length; i++) {
        if (monthlyData[i].month === monthKey) return i;
    }
    return -1;
}

function computeBeforeAfter(milestoneDate) {
    const monthKey = milestoneDate.slice(0, 7);
    const idx = monthToIndex(monthKey);
    if (idx < 0) return { before: null, after: null };

    let beforeSum = 0, beforeCnt = 0;
    for (let b = 1; b <= 3; b++) {
        const bi = idx - b;
        if (bi >= 0 && monthlyData[bi]) {
            beforeSum += monthlyData[bi].views;
            beforeCnt++;
        }
    }

    let afterSum = 0, afterCnt = 0;
    for (let a = 0; a < 3; a++) {
        const ai = idx + a;
        if (ai < monthlyData.length && monthlyData[ai]) {
            afterSum += monthlyData[ai].views;
            afterCnt++;
        }
    }

    return {
        before: beforeCnt > 0 ? Math.round(beforeSum / beforeCnt) : null,
        after: afterCnt > 0 ? Math.round(afterSum / afterCnt) : null
    };
}

function getSparklineData(milestoneDate) {
    const monthKey = milestoneDate.slice(0, 7);
    const idx = monthToIndex(monthKey);
    if (idx < 0) return { data: [], centerIdx: -1 };

    const start = Math.max(0, idx - 3);
    const end = Math.min(monthlyData.length - 1, idx + 3);
    const data = [];
    for (let i = start; i <= end; i++) {
        data.push({ month: monthlyData[i].month, views: monthlyData[i].views });
    }
    return { data, centerIdx: idx - start };
}

function drawContextChart() {
    const wrap = document.getElementById('contextChart');
    if (!wrap) return;
    wrap.innerHTML = '';

    const w = wrap.offsetWidth || 1200;
    const h = 100;
    const pad = { top: 8, right: 0, bottom: 20, left: 0 };
    const innerW = w - pad.left - pad.right;
    const innerH = h - pad.top - pad.bottom;

    const x = d3.scalePoint()
        .domain(monthlyData.map(d => d.month))
        .range([0, innerW]);

    const y = d3.scaleLinear()
        .domain([0, d3.max(monthlyData, d => d.views)])
        .range([innerH, 0]);

    const area = d3.area()
        .x(d => x(d.month))
        .y0(innerH)
        .y1(d => y(d.views));

    const svg = d3.select(wrap)
        .append('svg')
        .attr('width', w)
        .attr('height', h);

    const g = svg.append('g').attr('transform', `translate(${pad.left},${pad.top})`);

    g.append('path')
        .attr('d', area(monthlyData))
        .attr('fill', 'rgba(79, 169, 240, 0.15)')
        .attr('stroke', 'none');

    const pipContainer = document.createElement('div');
    pipContainer.className = 'context-pips';
    pipContainer.style.cssText = `position:absolute;left:${pad.left}px;top:${pad.top}px;width:${innerW}px;height:${innerH}px;pointer-events:none`;
    wrap.appendChild(pipContainer);

    milestones.forEach((ms, i) => {
        const monthKey = ms.date.slice(0, 7);
        const idx = monthToIndex(monthKey);
        if (idx < 0) return;
        const xPos = x(monthlyData[idx].month);
        const pip = document.createElement('div');
        pip.className = 'context-pip ' + ms.category;
        pip.setAttribute('data-milestone-index', String(i));
        pip.style.left = xPos + 'px';
        pip.style.pointerEvents = 'auto';
        pipContainer.appendChild(pip);
    });
}

function drawSparkline(container, milestone, color) {
    const sp = getSparklineData(milestone.date);
    if (sp.data.length === 0) return;

    const w = container.offsetWidth || 280;
    const h = 50;
    const pad = { top: 4, right: 4, bottom: 4, left: 4 };
    const innerW = w - pad.left - pad.right;
    const innerH = h - pad.top - pad.bottom;

    const x = d3.scalePoint()
        .domain(sp.data.map(d => d.month))
        .range([0, innerW]);

    const y = d3.scaleLinear()
        .domain([0, d3.max(sp.data, d => d.views)])
        .range([innerH, 0]);

    const area = d3.area()
        .x(d => x(d.month))
        .y0(innerH)
        .y1(d => y(d.views));

    const line = d3.line()
        .x(d => x(d.month))
        .y(d => y(d.views));

    const svg = d3.select(container)
        .append('svg')
        .attr('width', w)
        .attr('height', h);

    const g = svg.append('g').attr('transform', `translate(${pad.left},${pad.top})`);

    g.append('path')
        .attr('d', area(sp.data))
        .attr('fill', d3.color(color).copy({ opacity: 0.15 }).toString())
        .attr('stroke', 'none');

    g.append('path')
        .attr('d', line(sp.data))
        .attr('fill', 'none')
        .attr('stroke', d3.color(color).copy({ opacity: 0.6 }).toString())
        .attr('stroke-width', 1.5);

    if (sp.centerIdx >= 0 && sp.centerIdx < sp.data.length) {
        const cx = x(sp.data[sp.centerIdx].month);
        g.append('line')
            .attr('x1', cx).attr('x2', cx)
            .attr('y1', 0).attr('y2', innerH)
            .attr('stroke', color)
            .attr('stroke-opacity', 0.5)
            .attr('stroke-dasharray', '3,3');
    }
}

function renderCards() {
    const grid = document.getElementById('cardGrid');
    if (!grid) return;
    grid.innerHTML = '';

    milestones.forEach((ms, idx) => {
        if (activeFilter === 'ai' && ms.category !== 'ai') return;
        if (activeFilter === 'product' && ms.category !== 'product') return;

        const stats = computeBeforeAfter(ms.date);
        const color = ms.category === 'ai' ? '#4fa9f0' : '#ef8848';
        const catLabel = ms.category === 'ai' ? 'AI' : 'Product';

        const card = document.createElement('div');
        card.className = 'milestone-card';
        card.setAttribute('data-milestone-index', String(idx));

        let barTotal = 1;
        if (stats.before != null && stats.after != null) {
            barTotal = stats.before + stats.after || 1;
        }

        let afterClass = '';
        if (stats.before != null && stats.after != null) {
            afterClass = stats.after >= stats.before ? 'up' : 'down';
        }

        const beforePct = (stats.before != null && stats.after != null && barTotal > 0)
            ? Math.round((stats.before / barTotal) * 100) : 0;
        const afterPct = (stats.before != null && stats.after != null && barTotal > 0)
            ? Math.round((stats.after / barTotal) * 100) : 0;

        card.innerHTML =
            '<div class="card-header">' +
                '<span class="category-badge ' + ms.category + '"><span class="cat-dot"></span>' + catLabel + '</span>' +
                '<span class="card-date">' + ms.date + '</span>' +
            '</div>' +
            '<h3 class="card-title">' + ms.name + '</h3>' +
            '<div class="card-sparkline"></div>' +
            '<p class="card-teaser">' + ms.teaser + '</p>' +
            '<div class="card-expanded">' +
                '<p class="card-description">' + ms.description + '</p>' +
                (stats.before != null && stats.after != null ?
                    '<div class="before-after-bar">' +
                        '<div class="ba-stat-row"><span class="ba-label">Before</span><span class="ba-value before">' + stats.before.toLocaleString() + '</span></div>' +
                        '<div class="ba-stat-row"><span class="ba-label">After</span><span class="ba-value after ' + afterClass + '">' + stats.after.toLocaleString() + '</span></div>' +
                        '<div class="ms-stat-bar-wrap" style="width:100%;max-width:160px">' +
                            '<div class="ms-stat-bar before" style="width:' + beforePct + '%"></div>' +
                            '<div class="ms-stat-bar after ' + afterClass + '" style="width:' + afterPct + '%"></div>' +
                        '</div>' +
                    '</div>' : '') +
            '</div>';

        grid.appendChild(card);

        const sparkEl = card.querySelector('.card-sparkline');
        drawSparkline(sparkEl, ms, color);

        card.addEventListener('mouseenter', () => {
            document.querySelectorAll('.context-pip').forEach(p => p.classList.remove('highlight'));
            const pip = document.querySelector('.context-pip[data-milestone-index="' + idx + '"]');
            if (pip) {
                pip.classList.add('highlight');
                const chartWrap = document.querySelector('.context-chart-wrap');
                if (chartWrap) {
                    const pipRect = pip.getBoundingClientRect();
                    const wrapRect = chartWrap.getBoundingClientRect();
                    const leftPx = pipRect.left - wrapRect.left + pipRect.width / 2 - 1;
                    const vline = document.getElementById('contextVline');
                    if (vline) {
                        vline.className = 'context-vline visible';
                        vline.style.left = leftPx + 'px';
                        vline.style.background = ms.category === 'ai' ? 'rgba(79, 169, 240, 0.4)' : 'rgba(239, 136, 72, 0.4)';
                    }
                }
            }
        });

        card.addEventListener('mouseleave', () => {
            const pip = document.querySelector('.context-pip[data-milestone-index="' + idx + '"]');
            if (pip) pip.classList.remove('highlight');
            const vline = document.getElementById('contextVline');
            if (vline) vline.className = 'context-vline';
        });
    });
}

function setupFilterPills() {
    document.querySelectorAll('.filter-pill').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.filter-pill').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            activeFilter = btn.getAttribute('data-filter');
            renderCards();
        });
    });
}

let resizeTimer;
function setupResize() {
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => {
            drawContextChart();
            renderCards();
        }, 250);
    });
}

async function init() {
    try {
        const [trafficData, milestonesData] = await Promise.all([
            loadTrafficData(),
            loadMilestones()
        ]);
        monthlyData = aggregateMonthlyViews(trafficData.viewsData);
        milestones = milestonesData;

        const rangeEl = document.getElementById('contextChartRange');
        if (rangeEl && monthlyData.length > 0) {
            const fmt = key => {
                const [y, m] = key.split('-');
                const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                return months[parseInt(m, 10) - 1] + ' ' + y;
            };
            rangeEl.textContent = fmt(monthlyData[0].month) + ' \u2014 ' + fmt(monthlyData[monthlyData.length - 1].month);
        }

        drawContextChart();
        renderCards();
        setupFilterPills();
        setupResize();
    } catch (err) {
        console.error('Failed to initialize milestones page:', err);
        const grid = document.getElementById('cardGrid');
        if (grid) {
            grid.innerHTML = '<div class="error">Failed to load data. Please refresh the page.</div>';
        }
    }
}

init();
