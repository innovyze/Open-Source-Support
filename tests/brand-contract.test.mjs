import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const stylesPath = join(root, 'assets', 'css', 'styles.css');
const configPath = join(root, 'assets', 'js', 'config.js');
const insightsPath = join(root, 'assets', 'js', 'insightsApp.js');
const milestonesPath = join(root, 'assets', 'js', 'milestonesApp.js');
const indexPath = join(root, 'index.html');
const faviconPath = join(root, 'assets', 'brand', 'favicon.svg');
const ogCardPath = join(root, 'docs', 'generate-og-card.html');
const chartPath = join(root, 'assets', 'js', 'chart.js');

const css = readFileSync(stylesPath, 'utf8');
const chartJs = readFileSync(chartPath, 'utf8');
const configJs = readFileSync(configPath, 'utf8');
const insightsJs = readFileSync(insightsPath, 'utf8');
const milestonesJs = readFileSync(milestonesPath, 'utf8');
const indexHtml = readFileSync(indexPath, 'utf8');
const faviconSvg = readFileSync(faviconPath, 'utf8');
const ogCardHtml = readFileSync(ogCardPath, 'utf8');

test('styles.css uses Autodesk brand token contract', () => {
  for (const token of [
    '--adsk-black',
    '--adsk-white',
    '--adsk-twilight',
    '--adsk-morning',
    '--adsk-font-display',
    '--adsk-font-body',
    '--adsk-space-3',
  ]) {
    assert.match(css, new RegExp(token.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), `missing ${token}`);
  }
});

test('styles.css does not import Google Fonts', () => {
  assert.doesNotMatch(css, /fonts\.googleapis\.com/i, 'Google Fonts import must be removed');
  assert.doesNotMatch(css, /Space Grotesk/i, 'legacy font stack must be removed');
  assert.doesNotMatch(css, /JetBrains Mono/i, 'legacy monospace stack must be removed');
});

test('styles.css uses Artifakt local-family stacks', () => {
  assert.match(css, /Artifakt Legend/, 'display font stack must reference Artifakt Legend');
  assert.match(css, /Artifakt Element/, 'body font stack must reference Artifakt Element');
});

test('styles.css has no CSS gradients', () => {
  assert.doesNotMatch(css, /linear-gradient/i, 'styles.css must not use linear gradients');
  assert.doesNotMatch(css, /radial-gradient/i, 'styles.css must not use radial gradients');
  assert.doesNotMatch(css, /conic-gradient/i, 'styles.css must not use conic gradients');
  assert.doesNotMatch(css, /repeating-linear-gradient/i, 'styles.css must not use repeating gradients');
});

test('styles.css excludes custom off-token surface literals', () => {
  assert.doesNotMatch(css, /#111111/i, 'custom surface #111111 must not appear');
  assert.doesNotMatch(css, /#141414/i, 'custom surface #141414 must not appear');
});

test('styles.css excludes legacy palette values', () => {
  assert.doesNotMatch(css, /#0696[Dd]7/i, 'legacy Autodesk blue must not appear');
  assert.doesNotMatch(css, /#4fa9f0/i, 'legacy chart blue must not appear');
  assert.doesNotMatch(css, /#ef8848/i, 'legacy chart orange must not appear');
  assert.doesNotMatch(css, /#0b111d/i, 'legacy navy background must not appear');
});

test('styles.css uses token-backed semantic surfaces', () => {
  assert.match(css, /--bg-secondary:\s*var\(--adsk-/, '--bg-secondary must use Autodesk token');
  assert.match(css, /--bg-card:\s*var\(--adsk-/, '--bg-card must use Autodesk token');
  assert.match(css, /--tooltip-bg:\s*var\(--adsk-/, '--tooltip-bg must use Autodesk token');
});

test('styles.css provides high-contrast focus-visible for interactive controls', () => {
  assert.match(css, /:focus-visible/, 'focus-visible styles must be present');
  assert.match(css, /\.page-toggle-btn:focus-visible/, 'page navigation needs focus-visible');
  assert.match(css, /\.toggle-btn:focus-visible/, 'toggle buttons need focus-visible');
  assert.match(css, /\.time-btn:focus-visible/, 'time buttons need focus-visible');
  assert.match(css, /\.filter-pill:focus-visible/, 'filter pills need focus-visible');
  assert.match(css, /\.legend-item:focus-visible/, 'legend controls need focus-visible');
});

test('styles.css honors prefers-reduced-motion', () => {
  assert.match(css, /@media\s*\(\s*prefers-reduced-motion:\s*reduce\s*\)/, 'reduced-motion query required');
});

test('styles.css preserves dots and pip-glow keyframes', () => {
  assert.match(css, /@keyframes\s+dots\b/, 'dots keyframes must remain');
  assert.match(css, /@keyframes\s+pip-glow\b/, 'pip-glow keyframes must remain');
});

test('styles.css avoids off-scale spacing literals in control styling', () => {
  const controlBlocks = [
    css.match(/\.page-toggle-btn\s*\{[^}]*\}/s)?.[0] ?? '',
    css.match(/\.toggle-btn\s*\{[^}]*\}/s)?.[0] ?? '',
    css.match(/\.filter-pill\s*\{[^}]*\}/s)?.[0] ?? '',
    css.match(/\.legend-item\s*\{[^}]*\}/s)?.[0] ?? '',
  ].join('\n');
  assert.doesNotMatch(controlBlocks, /\b6px\b/, 'control spacing must use brand tokens, not 6px');
  assert.doesNotMatch(controlBlocks, /\b10px\b/, 'control spacing must use brand tokens, not 10px');
  assert.doesNotMatch(controlBlocks, /\b14px\b/, 'control spacing must use brand tokens, not 14px');
});

test('config.js keeps animationDuration and drops legacy colors', () => {
  assert.match(configJs, /animationDuration:\s*1500/, 'animationDuration must remain 1500');
  assert.doesNotMatch(configJs, /colors\s*:\s*\{/, 'legacy CONFIG.colors must be removed');
  assert.doesNotMatch(configJs, /#4fa9f0/i, 'legacy chart blue must not appear in config.js');
  assert.doesNotMatch(configJs, /#ef8848/i, 'legacy chart orange must not appear in config.js');
});

test('insightsApp.js uses official Twilight fallback', () => {
  assert.doesNotMatch(insightsJs, /#4fa9f0/i, 'legacy chart blue fallback must be removed');
  assert.match(insightsJs, /#1[Dd]91[Dd]0/, 'Twilight fallback must be used');
});

test('milestonesApp.js uses cssVar directly without cssColor pass-through', () => {
  assert.doesNotMatch(milestonesJs, /function cssColor\b/, 'redundant cssColor helper must be removed');
  assert.match(milestonesJs, /function cssVar\b/, 'cssVar helper must remain');
  assert.match(milestonesJs, /cssVar\('--chart-blue'\)/, 'chart colors must resolve via cssVar');
});

test('index.html uses button elements for interactive legend series', () => {
  assert.match(indexHtml, /<button[^>]*class="legend-item"[^>]*data-series="total"/, 'total legend must be a button');
  assert.match(indexHtml, /<button[^>]*class="legend-item"[^>]*data-series="unique"/, 'unique legend must be a button');
  assert.doesNotMatch(
    indexHtml,
    /<div[^>]*class="legend-item"[^>]*data-series="/,
    'interactive legend series must not use div wrappers'
  );
});

test('favicon.svg uses on-scale corner radius', () => {
  assert.doesNotMatch(faviconSvg, /rx="2"/, 'favicon inner rect must not use off-scale rx="2"');
  assert.match(faviconSvg, /rx="4"/, 'favicon inner rect must use 4px brand radius');
});

test('generate-og-card.html excludes off-token surface literals', () => {
  assert.doesNotMatch(ogCardHtml, /#141414/i, 'custom surface #141414 must not appear in OG card generator');
});

const EMPTY_STATE_MARKUP =
  '<div class="chart-empty-state">Select at least one series in the legend to display the chart.</div>';

test('chart.js renders a clear empty state when all legend series are hidden', () => {
  assert.match(
    chartJs,
    /!visibleSeries\.total\s*&&\s*!visibleSeries\.unique/,
    'drawChart must detect when every interactive series is hidden'
  );
  assert.match(
    chartJs,
    new RegExp(
      `container\\.innerHTML\\s*=\\s*['"]${EMPTY_STATE_MARKUP.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}['"]`
    ),
    'drawChart must assign the exact static empty-state markup'
  );

  const drawChartBody = chartJs.match(/export function drawChart[\s\S]*/)?.[0] ?? '';
  const emptyStateIndex = drawChartBody.search(/chart-empty-state/);
  const d3Index = drawChartBody.search(/d3\.select/);
  assert.ok(
    emptyStateIndex > -1 && d3Index > -1 && emptyStateIndex < d3Index,
    'empty-state handling must short-circuit before chart construction'
  );
});

test('chart.js dismisses tooltip before redraw and early returns', () => {
  const drawChartBody = chartJs.match(/export function drawChart[\s\S]*/)?.[0] ?? '';
  const dismissIndex = drawChartBody.search(
    /dismissTooltip\s*\(|getElementById\(['"]tooltip['"]\)[\s\S]*?classList\.remove\(['"]visible['"]\)/
  );
  const clearContainerIndex = drawChartBody.search(/container\.innerHTML\s*=\s*['"]['"]/);
  const noDataIndex = drawChartBody.search(/No data available/);
  const emptyStateIndex = drawChartBody.search(/chart-empty-state/);

  assert.ok(dismissIndex > -1, 'drawChart must dismiss the tooltip');
  assert.ok(
    dismissIndex < clearContainerIndex,
    'tooltip must be dismissed before clearing the chart container'
  );
  assert.ok(dismissIndex < noDataIndex, 'tooltip must be dismissed before no-data early return');
  assert.ok(
    dismissIndex < emptyStateIndex,
    'tooltip must be dismissed before all-series-hidden early return'
  );
});

test('styles.css guards narrow-viewport Daily Traffic chart height', () => {
  const narrowViewportBlock =
    css.match(/@media\s*\(\s*max-width:\s*768px\s*\)\s*\{([\s\S]*?)\n\}/)?.[1] ?? '';

  assert.match(
    narrowViewportBlock,
    /#mainChart[\s\S]*min-height:\s*300px/,
    '#mainChart must not shrink below the SVG chart minimum on narrow viewports'
  );
  assert.match(
    narrowViewportBlock,
    /\.chart-container[\s\S]*overflow:\s*visible/,
    'Daily Traffic chart container must allow rotated x-axis labels to render without clipping the legend'
  );
});

test('styles.css stacks page-toggle below title on landscape tablet widths', () => {
  const landscapeHeaderBlock =
    css.match(/@media\s*\(\s*max-width:\s*960px\s*\)\s*\{([\s\S]*?)\n\}/)?.[1] ?? '';

  assert.ok(
    landscapeHeaderBlock.length > 0,
    'landscape tablet media query with max-width: 960px required so 812px viewports avoid header overlap'
  );
  assert.match(
    landscapeHeaderBlock,
    /\.page-toggle[\s\S]*position:\s*static/,
    '.page-toggle must leave absolute header positioning at max-width: 960px'
  );
  assert.match(
    landscapeHeaderBlock,
    /\.page-toggle[\s\S]*margin:\s*0\s+auto/,
    '.page-toggle must keep centered spacing when stacked in the header'
  );
  assert.match(
    landscapeHeaderBlock,
    /\.page-toggle[\s\S]*width:\s*fit-content/,
    '.page-toggle must shrink-wrap when stacked in the header'
  );
});

test('styles.css guards short-viewport Daily Traffic chart height', () => {
  const shortViewportBlock =
    css.match(/@media\s*\([^)]*max-height:\s*600px[^)]*\)\s*\{([\s\S]*?)\n\}/)?.[1] ?? '';

  assert.ok(
    shortViewportBlock.length > 0,
    'short-viewport media query with max-height: 600px required'
  );
  assert.match(
    shortViewportBlock,
    /body:not\(\.insights-page\):not\(\.milestones-page\)/,
    'short-viewport rules must exclude Insights and Milestones pages'
  );
  assert.match(
    shortViewportBlock,
    /#mainChart[\s\S]*min-height:\s*300px/,
    '#mainChart must not shrink below the SVG chart minimum on short viewports'
  );
  assert.match(
    shortViewportBlock,
    /\.chart-container[\s\S]*overflow:\s*visible/,
    'Daily Traffic chart container must allow rotated x-axis labels to render without clipping the legend on short viewports'
  );
});
