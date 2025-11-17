#!/usr/bin/env node

/**
 * Cross-platform build script that works during npm install from GitHub
 * Does not depend on devDependencies like shx
 *
 * During GitHub install (prepare phase):
 * - Skips type checking (typescript not installed yet)
 * - Only runs pkgroll build
 *
 * During local development:
 * - Runs full type checking + build
 */

import { rmSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import { resolve } from 'path';

const distDir = 'dist';
const isGitHubInstall = !existsSync(resolve('node_modules/typescript'));

// Remove dist directory if it exists (cross-platform)
if (existsSync(distDir)) {
  console.log('Cleaning dist directory...');
  rmSync(distDir, { recursive: true, force: true });
}

// Run TypeScript type checking (skip during GitHub install)
if (isGitHubInstall) {
  console.log('Skipping type check (GitHub install - typescript not available yet)');
} else {
  console.log('Type checking...');
  try {
    execSync('npx tsc --noEmit', { stdio: 'inherit' });
  } catch (error) {
    console.error('Type checking failed');
    process.exit(1);
  }
}

// Run pkgroll to build
console.log('Building with pkgroll...');
try {
  execSync('npx pkgroll', { stdio: 'inherit' });
} catch (error) {
  console.error('Build failed');
  process.exit(1);
}

console.log('Build complete!');
