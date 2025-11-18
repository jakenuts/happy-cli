# Publishing Guide

This document explains how the automated publishing system works for `happy-next`.

## Overview

The package is automatically published to npm when the version changes. This solves all the installation issues with GitHub installs and NVM.

## Automated Workflows

### 1. Version Bumping (`bump-version.yml`)

Manually trigger this workflow to bump the version:

**Via GitHub UI:**
1. Go to Actions → Bump Version
2. Click "Run workflow"
3. Select bump type: `prerelease`, `patch`, `minor`, or `major`
4. Click "Run workflow"

**What it does:**
- Bumps the version in `package.json`
- Builds the project (updates `dist/`)
- Commits changes with `[skip-build]` tag
- Creates and pushes git tag (`v0.11.3-preview.8`, etc.)
- Updates `latest-preview` tag for prerelease versions

### 2. Publishing to NPM (`publish-npm.yml`)

Automatically triggers when:
- Version in `package.json` changes on `main` branch
- Manually triggered via workflow_dispatch

**What it does:**
- Detects version change
- Builds the project
- Publishes to npm with `--access public`
- Creates GitHub release
- Adds install instructions to release notes

## Publishing a New Version

### For Preview Releases

```bash
# Option 1: Use GitHub Actions (Recommended)
# Go to Actions → Bump Version → Run workflow → Select "prerelease"

# Option 2: Manually
npm version prerelease --preid=preview
git push
git push --tags
# Publishing happens automatically
```

### For Stable Releases

```bash
# Option 1: Use GitHub Actions (Recommended)
# Go to Actions → Bump Version → Run workflow → Select "patch/minor/major"

# Option 2: Manually
npm version patch  # or minor, major
git push
git push --tags
# Publishing happens automatically
```

## Installation After Publishing

Once published to npm, users can install with:

```bash
# Latest stable version
npm install -g happy-next

# Latest preview version
npm install -g happy-next@preview

# Specific version
npm install -g happy-next@0.11.3-preview.7
```

## Benefits of NPM Publishing

✅ **No GitHub install issues** - Works perfectly with NVM
✅ **No path problems** - npm handles bin wrappers automatically
✅ **Faster installs** - Pre-built dist, no compilation needed
✅ **Better caching** - npm registry is more reliable than GitHub
✅ **Works like original** - Same experience as `happy-coder`

## NPM Token Setup

The `NPM_TOKEN` secret is already configured in the repository:
- **Location:** Repository Settings → Secrets and variables → Actions
- **Name:** `NPM_TOKEN`
- **Used by:** `publish-npm.yml` workflow

To regenerate the token:
1. Go to https://www.npmjs.com/settings/YOUR_USERNAME/tokens
2. Generate new token (Automation type)
3. Update the `NPM_TOKEN` secret in GitHub

## Distribution Tags

The package uses npm distribution tags:

- `latest` - Stable releases (default when running `npm install -g happy-next`)
- `preview` - Preview/beta releases (install with `npm install -g happy-next@preview`)

Prerelease versions automatically get the `preview` tag.

## Troubleshooting

### Publish Failed - Version Already Exists

If you try to publish a version that already exists on npm:
1. Bump the version: `npm version prerelease --preid=preview`
2. Commit and push
3. Publishing will retry automatically

### Publish Failed - Authentication Error

Check that the `NPM_TOKEN` secret is valid:
1. Go to Repository Settings → Secrets
2. Update `NPM_TOKEN` with a fresh token from npmjs.com

### Build Failed During Publish

The build must succeed before publishing:
1. Run `npm run build` locally to check for errors
2. Fix any TypeScript or build issues
3. Commit and push fixes
4. Workflow will retry

## Manual Publishing (Emergency)

If you need to publish manually:

```bash
# Build the project
npm run build

# Login to npm (first time only)
npm login

# Publish
npm publish --access public

# For preview releases, also tag as preview
npm dist-tag add happy-next@0.11.3-preview.7 preview
```

## Checking Published Versions

```bash
# View all published versions
npm view happy-next versions

# View latest version
npm view happy-next version

# View all dist-tags
npm view happy-next dist-tags
```

## Next Steps

After setting up publishing:
1. Merge this branch to `main`
2. Use "Bump Version" workflow to create first npm release
3. Update documentation to use `npm install -g happy-next`
4. Announce to users that they can now install from npm!
