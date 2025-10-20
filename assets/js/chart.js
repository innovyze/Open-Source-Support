// Chart drawing module
import { CONFIG } from './config.js';
import { formatNumber, formatDate, filterDataByDays } from './utils.js';

export function drawChart(containerId, data, type, range) {
    const container = document.getElementById(containerId);
    container.innerHTML = '';

    const filteredData = filterDataByDays(data, range);
    
    if (filteredData.length === 0) {
        container.innerHTML = '<div class="loading">No data available</div>';
        return;
    }

    const containerWidth = container.clientWidth;
    const height = CONFIG.chartHeight;
    const width = containerWidth - CONFIG.margin.left - CONFIG.margin.right;

    const svg = d3.select(`#${containerId}`)
        .append('svg')
        .attr('class', 'chart-svg')
        .attr('width', containerWidth)
        .attr('height', height + CONFIG.margin.top + CONFIG.margin.bottom)
        .append('g')
        .attr('transform', `translate(${CONFIG.margin.left},${CONFIG.margin.top})`);

    // Scales
    const x = d3.scaleTime()
        .domain(d3.extent(filteredData, d => d.date))
        .range([0, width]);

    const maxY = d3.max(filteredData, d => Math.max(d.total, d.unique));
    const y = d3.scaleLinear()
        .domain([0, maxY * 1.1])
        .range([height, 0]);

    // Grid
    svg.append('g')
        .attr('class', 'grid')
        .attr('opacity', 0.1)
        .call(d3.axisLeft(y)
            .tickSize(-width)
            .tickFormat(''));

    // Axes
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

    // Line generators
    const lineTotal = d3.line()
        .x(d => x(d.date))
        .y(d => y(d.total))
        .curve(d3.curveMonotoneX);

    const lineUnique = d3.line()
        .x(d => x(d.date))
        .y(d => y(d.unique))
        .curve(d3.curveMonotoneX);

    // Draw lines with animation
    const totalPath = svg.append('path')
        .datum(filteredData)
        .attr('class', 'line line-total')
        .attr('d', lineTotal);

    const uniquePath = svg.append('path')
        .datum(filteredData)
        .attr('class', 'line line-unique')
        .attr('d', lineUnique);

    // Animate lines
    const totalLength = totalPath.node().getTotalLength();
    const uniqueLength = uniquePath.node().getTotalLength();

    totalPath
        .attr('stroke-dasharray', totalLength + ' ' + totalLength)
        .attr('stroke-dashoffset', totalLength)
        .transition()
        .duration(CONFIG.animationDuration)
        .ease(d3.easeLinear)
        .attr('stroke-dashoffset', 0);

    uniquePath
        .attr('stroke-dasharray', uniqueLength + ' ' + uniqueLength)
        .attr('stroke-dashoffset', uniqueLength)
        .transition()
        .duration(CONFIG.animationDuration)
        .ease(d3.easeLinear)
        .attr('stroke-dashoffset', 0);

    // Get current theme colors from CSS variables
    const computedStyle = getComputedStyle(document.documentElement);
    const totalColor = computedStyle.getPropertyValue('--chart-blue').trim();
    const uniqueColor = computedStyle.getPropertyValue('--chart-green').trim();

    // Interactive dots
    const dotTotal = svg.append('circle')
        .attr('class', 'dot')
        .attr('r', 5)
        .attr('stroke', totalColor)
        .attr('fill', totalColor);

    const dotUnique = svg.append('circle')
        .attr('class', 'dot')
        .attr('r', 5)
        .attr('stroke', uniqueColor)
        .attr('fill', uniqueColor);

    // Invisible overlay for mouse tracking
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
            
            // Update dots
            dotTotal
                .classed('visible', true)
                .attr('cx', x(d.date))
                .attr('cy', y(d.total));
            
            dotUnique
                .classed('visible', true)
                .attr('cx', x(d.date))
                .attr('cy', y(d.unique));
            
            // Update tooltip
            const tooltip = document.getElementById('tooltip');
            tooltip.classList.add('visible');
            tooltip.querySelector('.tooltip-date').textContent = formatDate(d.date);
            
            const label = type === 'views' ? 'Views' : 'Clones';
            tooltip.querySelector('.tooltip-content').innerHTML = `
                <div class="tooltip-line">
                    <div class="tooltip-color" style="background: ${totalColor};"></div>
                    <span>Total ${label}: ${formatNumber(d.total)}</span>
                </div>
                <div class="tooltip-line">
                    <div class="tooltip-color" style="background: ${uniqueColor};"></div>
                    <span>Unique ${label}: ${formatNumber(d.unique)}</span>
                </div>
            `;
            
            const tooltipWidth = tooltip.offsetWidth;
            const tooltipHeight = tooltip.offsetHeight;
            
            tooltip.style.left = (event.pageX + 15) + 'px';
            tooltip.style.top = (event.pageY - tooltipHeight / 2) + 'px';
        })
        .on('mouseleave', function() {
            dotTotal.classed('visible', false);
            dotUnique.classed('visible', false);
            document.getElementById('tooltip').classList.remove('visible');
        });
}

