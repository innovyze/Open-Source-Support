// Chart drawing module
import { CONFIG, FULLY_MISSING_PERIODS, RECONSTRUCTED_TOTALS_PERIODS } from './config.js';
import { formatNumber, formatDate, filterDataByDays } from './utils.js';

function isDateInPeriods(date, periods) {
    return periods.some(period => date >= period.start && date <= period.end);
}

function addDays(date, days) {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
}

function computePercentileMax(values, percentile = 99) {
    if (values.length === 0) {
        return 0;
    }

    const sortedValues = [...values].sort((a, b) => a - b);
    const clampedPercentile = Math.min(100, Math.max(0, percentile));
    const index = Math.floor((clampedPercentile / 100) * (sortedValues.length - 1));

    return sortedValues[index];
}

export function drawChart(containerId, data, type, range, visibleSeries = { total: true, unique: true }, fitToData = true) {
    const container = document.getElementById(containerId);
    container.innerHTML = '';

    const filteredData = filterDataByDays(data, range);

    if (filteredData.length === 0) {
        container.innerHTML = '<div class="loading">No data available</div>';
        return;
    }

    const containerWidth = container.clientWidth;
    const containerHeight = container.clientHeight;
    const svgHeight = Math.max(300, containerHeight);
    const height = svgHeight - CONFIG.margin.top - CONFIG.margin.bottom;
    const width = containerWidth - CONFIG.margin.left - CONFIG.margin.right;

    const svg = d3.select(`#${containerId}`)
        .append('svg')
        .attr('class', 'chart-svg')
        .attr('width', containerWidth)
        .attr('height', svgHeight)
        .append('g')
        .attr('transform', `translate(${CONFIG.margin.left},${CONFIG.margin.top})`);

    const isUniqueAvailable = (point) =>
        Number.isFinite(point.unique) && !isDateInPeriods(point.date, RECONSTRUCTED_TOTALS_PERIODS);

    const x = d3.scaleTime()
        .domain(d3.extent(filteredData, d => d.date))
        .range([0, width]);

    const allValues = filteredData.flatMap((point) => {
        const values = [];
        if (visibleSeries.total && Number.isFinite(point.total)) {
            values.push(point.total);
        }

        if (visibleSeries.unique && isUniqueAvailable(point)) {
            values.push(point.unique);
        }

        return values.length > 0 ? values : [];
    }).flat();

    const absoluteMax = d3.max(allValues) ?? 0;
            const percentileMax = computePercentileMax(allValues, 99);
    const scaleMax = fitToData ? percentileMax : absoluteMax;
    const yDomainTop = (scaleMax > 0 ? scaleMax : 1) * 1.1;

    const y = d3.scaleLinear()
        .domain([0, yDomainTop])
        .range([height, 0]);

    const xDomain = x.domain();
    const defs = svg.append('defs');
    const chartClipId = `line-clip-${Date.now()}`;

    defs.append('clipPath')
        .attr('id', chartClipId)
        .append('rect')
        .attr('x', 0)
        .attr('y', 0)
        .attr('width', width)
        .attr('height', height);

    const revealClipId = `line-reveal-${Date.now()}`;
    defs.append('clipPath')
        .attr('id', revealClipId)
        .append('rect')
        .attr('x', 0)
        .attr('y', 0)
        .attr('width', 0)
        .attr('height', height)
        .transition()
        .duration(CONFIG.animationDuration)
        .ease(d3.easeLinear)
        .attr('width', width);

    const addStripePattern = (patternId, strokeVariable) => {
        defs.append('pattern')
            .attr('id', patternId)
            .attr('patternUnits', 'userSpaceOnUse')
            .attr('width', 8)
            .attr('height', 8)
            .append('path')
            .attr('d', 'M-1,1 l2,-2 M0,8 l8,-8 M7,9 l2,-2')
            .attr('stroke', `var(${strokeVariable})`)
            .attr('stroke-width', 1);
    };

    const drawPeriodZones = (periods, options) => {
        const {
            zoneClass,
            patternId,
            fillVariable,
            strokeVariable,
            defaultLabel
        } = options;

        const visiblePeriods = periods
            .map(period => {
                const rangeStart = period.start > xDomain[0] ? period.start : xDomain[0];
                const periodEndExclusive = addDays(period.end, 1);
                const rangeEnd = periodEndExclusive < xDomain[1] ? periodEndExclusive : xDomain[1];
                return { ...period, rangeStart, rangeEnd };
            })
            .filter(period => period.rangeEnd > period.rangeStart);

        if (visiblePeriods.length === 0) {
            return;
        }

        const zones = svg.selectAll(`.${zoneClass}`)
            .data(visiblePeriods)
            .enter()
            .append('g')
            .attr('class', zoneClass);

        zones.append('rect')
            .attr('x', d => x(d.rangeStart))
            .attr('width', d => Math.max(0, x(d.rangeEnd) - x(d.rangeStart)))
            .attr('y', 0)
            .attr('height', height)
            .attr('fill', `var(${fillVariable})`);

        zones.append('rect')
            .attr('x', d => x(d.rangeStart))
            .attr('width', d => Math.max(0, x(d.rangeEnd) - x(d.rangeStart)))
            .attr('y', 0)
            .attr('height', height)
            .attr('fill', `url(#${patternId})`)
            .style('pointer-events', 'none');

        zones.append('text')
            .attr('x', d => x(d.rangeStart) + (x(d.rangeEnd) - x(d.rangeStart)) / 2)
            .attr('y', 20)
            .attr('text-anchor', 'middle')
            .attr('fill', `var(${strokeVariable})`)
            .style('font-size', '10px')
            .style('font-weight', '600')
            .style('opacity', d => (x(d.rangeEnd) - x(d.rangeStart) > 90 ? 1 : 0))
            .text(d => d.label || defaultLabel);
    };

    addStripePattern('missing-stripe', '--chart-error-stroke');
    addStripePattern('reconstructed-stripe', '--chart-reconstructed-stroke');

    drawPeriodZones(FULLY_MISSING_PERIODS, {
        zoneClass: 'missing-zone',
        patternId: 'missing-stripe',
        fillVariable: '--chart-error-bg',
        strokeVariable: '--chart-error-stroke',
        defaultLabel: 'Missing Data'
    });

    drawPeriodZones(RECONSTRUCTED_TOTALS_PERIODS, {
        zoneClass: 'reconstructed-zone',
        patternId: 'reconstructed-stripe',
        fillVariable: '--chart-reconstructed-bg',
        strokeVariable: '--chart-reconstructed-stroke',
        defaultLabel: 'Reconstructed Totals'
    });

    svg.append('g')
        .attr('class', 'grid')
        .attr('opacity', 0.1)
        .call(d3.axisLeft(y)
            .tickSize(-width)
            .tickFormat(''));

    const xAxis = svg.append('g')
        .attr('class', 'axis')
        .attr('transform', `translate(0,${height})`)
        .call(d3.axisBottom(x)
            .ticks(Math.min(filteredData.length, 10))
            .tickFormat(d3.timeFormat('%b %d, %Y')));

    xAxis.selectAll('text')
        .attr('transform', 'rotate(-45)')
        .style('text-anchor', 'end')
        .attr('dx', '-.8em')
        .attr('dy', '.15em');

    svg.append('g')
        .attr('class', 'axis')
        .call(d3.axisLeft(y)
            .ticks(8)
            .tickFormat(d => formatNumber(d)));

    const lineTotal = d3.line()
        .defined(d => Number.isFinite(d.total))
        .x(d => x(d.date))
        .y(d => y(d.total))
        .curve(d3.curveMonotoneX);

    const lineUnique = d3.line()
        .defined(d => isUniqueAvailable(d))
        .x(d => x(d.date))
        .y(d => y(d.unique))
        .curve(d3.curveMonotoneX);

    const lineGroup = svg.append('g')
        .attr('clip-path', `url(#${chartClipId})`);

    const drawLine = (lineGenerator, seriesData, className) => {
        const pathData = lineGenerator(seriesData);
        if (!pathData) {
            return;
        }

        lineGroup.append('path')
            .datum(seriesData)
            .attr('class', className)
            .attr('clip-path', `url(#${revealClipId})`)
            .attr('d', pathData);
    };

    if (visibleSeries.total) {
        drawLine(lineTotal, filteredData, 'line line-total');
    }

    if (visibleSeries.unique) {
        drawLine(lineUnique, filteredData, 'line line-unique');
    }

    const computedStyle = getComputedStyle(document.documentElement);
    const totalColor = computedStyle.getPropertyValue('--chart-blue').trim();
    const uniqueColor = computedStyle.getPropertyValue('--chart-green').trim();
    const overflowThreshold = yDomainTop;
    const overflowPoints = [];

    if (visibleSeries.total) {
        filteredData.forEach(point => {
            if (Number.isFinite(point.total) && point.total > overflowThreshold) {
                overflowPoints.push({ x: x(point.date), color: totalColor });
            }
        });
    }

    if (visibleSeries.unique) {
        filteredData.forEach(point => {
            if (isUniqueAvailable(point) && point.unique > overflowThreshold) {
                overflowPoints.push({ x: x(point.date), color: uniqueColor });
            }
        });
    }

    svg.append('g')
        .attr('class', 'overflow-markers')
        .selectAll('polygon')
        .data(overflowPoints)
        .join('polygon')
        .attr('class', 'overflow-marker')
        .attr('points', d => `${d.x},0 ${d.x - 5},10 ${d.x + 5},10`)
        .attr('fill', d => d.color);

    let dotTotal;
    let dotUnique;

    if (visibleSeries.total) {
        dotTotal = svg.append('circle')
            .attr('class', 'dot')
            .attr('r', 5)
            .attr('stroke', totalColor)
            .attr('fill', totalColor);
    }

    if (visibleSeries.unique) {
        dotUnique = svg.append('circle')
            .attr('class', 'dot')
            .attr('r', 5)
            .attr('stroke', uniqueColor)
            .attr('fill', uniqueColor);
    }

    const bisect = d3.bisector(d => d.date).left;

    svg.append('rect')
        .attr('width', width)
        .attr('height', height)
        .style('fill', 'none')
        .style('pointer-events', 'all')
        .on('mousemove', function(event) {
            const [mouseX] = d3.pointer(event);
            const x0 = x.invert(mouseX);
            const i = bisect(filteredData, x0, 1);
            const d0 = filteredData[i - 1];
            const d1 = filteredData[i];

            if (!d0 || !d1) return;

            const d = x0 - d0.date > d1.date - x0 ? d1 : d0;
            const hasTotal = Number.isFinite(d.total);
            const hasUnique = isUniqueAvailable(d);

            if (dotTotal && hasTotal) {
                dotTotal
                    .classed('visible', true)
                    .attr('cx', x(d.date))
                    .attr('cy', y(d.total));
            } else if (dotTotal) {
                dotTotal.classed('visible', false);
            }

            if (dotUnique && hasUnique) {
                dotUnique
                    .classed('visible', true)
                    .attr('cx', x(d.date))
                    .attr('cy', y(d.unique));
            } else if (dotUnique) {
                dotUnique.classed('visible', false);
            }

            const tooltip = document.getElementById('tooltip');
            tooltip.classList.add('visible');
            tooltip.querySelector('.tooltip-date').textContent = formatDate(d.date);

            const label = type === 'views' ? 'Views' : 'Clones';
            let tooltipContent = '';

            if (visibleSeries.total) {
                tooltipContent += `
                    <div class="tooltip-line">
                        <div class="tooltip-color" style="background: ${totalColor};"></div>
                        <span>Total ${label}: ${formatNumber(hasTotal ? d.total : null)}</span>
                    </div>
                `;
            }

            if (visibleSeries.unique) {
                tooltipContent += `
                    <div class="tooltip-line">
                        <div class="tooltip-color" style="background: ${uniqueColor};"></div>
                        <span>Unique ${label}: ${formatNumber(hasUnique ? d.unique : null)}</span>
                    </div>
                `;
            }

            tooltip.querySelector('.tooltip-content').innerHTML = tooltipContent;

            const tooltipHeight = tooltip.offsetHeight;
            tooltip.style.left = `${event.pageX + 15}px`;
            tooltip.style.top = `${event.pageY - tooltipHeight / 2}px`;
        })
        .on('mouseleave', function() {
            if (dotTotal) dotTotal.classed('visible', false);
            if (dotUnique) dotUnique.classed('visible', false);
            document.getElementById('tooltip').classList.remove('visible');
        });
}

