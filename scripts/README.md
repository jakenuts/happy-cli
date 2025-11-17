# Happy CLI Scripts

This directory contains scripts for testing, publishing, and managing happy-coder installations.

## Dual Package Strategy

Happy CLI is published under two package names for different use cases:

- **`happy-coder`** (stable) - Main stable release, commands: `happy`, `happy-mcp`
- **`happy-next`** (preview) - Preview/beta releases, commands: `happy-next`, `happy-next-mcp`

This allows users to:
1. Test preview features without affecting stable installations
2. Run both versions side-by-side for comparison
3. Gradually migrate to new features

## Available Scripts

### test-install.sh

Installs happy-coder from GitHub and validates the installation works correctly.

**Usage:**
```bash
# Install from current branch
./scripts/test-install.sh

# Install from specific tag
./scripts/test-install.sh v0.11.3-preview.4

# Install from specific branch
./scripts/test-install.sh main

# Install from commit hash
./scripts/test-install.sh abc1234
```

**What it tests:**
1. happy command is available in PATH
2. `happy --version` works
3. happy-mcp command is available
4. Daemon can start and stop successfully
5. Daemon logs are created

**Notes:**
- Uninstalls any existing happy-coder before installing
- Automatically cleans up daemon on exit
- Requires network access to GitHub

### test-installed.sh

Tests an already-installed happy-coder or happy-next installation without reinstalling.

**Usage:**
```bash
# Test stable version
./scripts/test-installed.sh

# Test preview version
./scripts/test-installed.sh happy-next
```

**What it tests:**
1. Command is available in PATH
2. `--version` works
3. MCP command is available
4. Daemon can start and stop successfully
5. Daemon logs are created

**Notes:**
- Does not modify the installation
- Faster than test-install.sh
- Use this to verify an existing installation
- Supports testing both stable and preview side-by-side

### publish-next.sh

Publishes the project as `happy-next` for preview releases.

**Usage:**
```bash
# Publish to npm
./scripts/publish-next.sh

# Dry run (test without publishing)
DRY_RUN=1 ./scripts/publish-next.sh
```

**What it does:**
1. Backs up `package.json`
2. Replaces with `package-next.json` (changes name to `happy-next`)
3. Builds the project
4. Publishes to npm with `--tag preview`
5. Restores original `package.json`

**Notes:**
- Requires npm publish permissions
- Published under the `preview` tag (not `latest`)
- Automatically restores package.json even if publish fails

### sync-upstream.sh

Syncs changes from upstream slopus/happy-cli repository into your fork.

**Usage:**
```bash
# Preview what would be synced (no changes made)
./scripts/sync-upstream.sh --dry-run

# Sync changes from upstream
./scripts/sync-upstream.sh
```

**What it does:**
1. Checks for uncommitted changes (blocks if found)
2. Fetches latest from upstream
3. Shows commits and files that will change
4. Attempts automatic merge
5. Prompts to push if successful
6. Provides conflict resolution instructions if needed

**Notes:**
- Requires clean working directory
- Interactive - prompts for confirmation
- Safe to run anytime
- Also automated via GitHub Actions (daily at 2 AM UTC)

### unpack-tools.cjs

Internal script called during npm install to unpack platform-specific binaries (ripgrep, etc.) from tar archives in the `tools/` directory.

**Features:**
- Automatically detects platform and architecture
- Gracefully handles missing tar dependency during GitHub installs
- Creates `.unpacked` marker file to avoid redundant unpacking
- Lazy loads tar dependency to prevent install failures

**Direct usage (not typically needed):**
```bash
node scripts/unpack-tools.cjs
```

## Common Workflows

### Syncing from Upstream

Keep your fork up-to-date with slopus/happy-cli:

```bash
# Check what would be synced (safe, no changes)
./scripts/sync-upstream.sh --dry-run

# Sync changes
./scripts/sync-upstream.sh

# Manual sync if needed
git fetch upstream
git merge upstream/main
```

**Automatic sync:**
- GitHub Actions runs daily at 2 AM UTC
- Auto-merges if no conflicts
- Creates issue if conflicts detected
- Issue auto-closes when resolved

### Publishing a Preview Release

```bash
# 1. Update version for preview
npm version prerelease --preid=preview

# 2. Publish as happy-next
./scripts/publish-next.sh

# 3. Test the published version
npm install -g happy-next
./scripts/test-installed.sh happy-next
```

### Testing Both Versions Side-by-Side

```bash
# Install both packages
npm install -g happy-coder        # Stable
npm install -g happy-next         # Preview

# Test stable
./scripts/test-installed.sh

# Test preview
./scripts/test-installed.sh happy-next

# Use either version
happy --version                   # Stable
happy-next --version              # Preview
```

### Testing Local Changes

```bash
# 1. Build locally
npm run build

# 2. Install locally as stable
npm install -g .

# 3. Validate the installation
./scripts/test-installed.sh
```

### Publishing Stable Release

```bash
# 1. Update version
npm version patch  # or minor, major

# 2. Build and test
npm run build
npm test

# 3. Publish to npm (as happy-coder)
npm publish

# 4. Test the published version
npm install -g happy-coder
./scripts/test-installed.sh
```

## Important Notes

### Claude Code Dependency Version

Happy CLI currently pins `@anthropic-ai/claude-code` to version **2.0.24** because:
- Versions 2.0.25+ removed the SDK exports (`sdk.mjs`, `sdk.d.ts`)
- We depend on these SDK types for integration
- Version 2.0.24 is the latest with full SDK support

**Do not update** to newer versions of `@anthropic-ai/claude-code` without verifying the SDK is still exported.

### Package Names and Commands

| Package | Commands | Use Case |
|---------|----------|----------|
| `happy-coder` | `happy`, `happy-mcp` | Stable releases |
| `happy-next` | `happy-next`, `happy-next-mcp` | Preview/beta releases |

Both packages share the same codebase but use different command names to avoid conflicts.

## Troubleshooting

### "happy command not found"

The installation may have failed. Check:
1. npm install output for errors
2. Try: `npm install -g happy-coder`
3. Verify npm global bin directory is in PATH: `npm bin -g`

### Daemon fails to start

1. Check if another daemon is running: `happy daemon status`
2. Stop existing daemon: `happy daemon stop`
3. Check logs in `~/.happy-dev/logs/`

### Installation from GitHub fails

This can happen due to:
1. Network issues downloading binaries
2. Branch/tag not pushed to remote
3. Missing dependencies (the `prepare` script should handle this)

Try:
- Installing from npm registry instead: `npm install -g happy-coder`
- Running the install command again (sometimes transient network issues)
- Installing from a released tag instead of a branch

### Both versions installed but want to use specific one

If you have both `happy-coder` and `happy-next` installed:
```bash
# Use stable explicitly
command -v happy

# Use preview explicitly
command -v happy-next

# Uninstall one if needed
npm uninstall -g happy-coder   # Remove stable
npm uninstall -g happy-next    # Remove preview
```
