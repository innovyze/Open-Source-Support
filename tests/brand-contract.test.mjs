import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import assert from 'node:assert/strict';

const stylesPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'css', 'styles.css');
const css = readFileSync(stylesPath, 'utf8');

test('styles.css uses Autodesk brand token contract', () => {
  for (const token of [
    '--adsk-black',
    '--adsk-white',
    '--adsk-twilight',
    '--adsk-morning',
    '--adsk-font-display',
    '--adsk-font-body',
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

test('styles.css has no page-background radial gradient', () => {
  const bodyBlock = css.match(/body\s*\{[^}]*\}/s)?.[0] ?? '';
  assert.doesNotMatch(bodyBlock, /radial-gradient/i, 'body background must not use radial gradients');
});

test('styles.css preserves dots and pip-glow keyframes', () => {
  assert.match(css, /@keyframes\s+dots\b/, 'dots keyframes must remain');
  assert.match(css, /@keyframes\s+pip-glow\b/, 'pip-glow keyframes must remain');
});

test('styles.css excludes legacy palette values', () => {
  assert.doesNotMatch(css, /#0696[Dd]7/i, 'legacy Autodesk blue must not appear');
  assert.doesNotMatch(css, /#4fa9f0/i, 'legacy chart blue must not appear');
  assert.doesNotMatch(css, /#ef8848/i, 'legacy chart orange must not appear');
  assert.doesNotMatch(css, /#0b111d/i, 'legacy navy background must not appear');
});
