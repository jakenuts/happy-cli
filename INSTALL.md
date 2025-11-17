# Installing Happy CLI

## Quick Install (Windows)

Install the latest preview from GitHub:

```powershell
npm install -g github:jakenuts/happy-cli#latest-preview
```

This gives you:
- `happy` - Main CLI command
- `happy-mcp` - MCP server command

## Install Specific Version

```powershell
# Install specific preview version
npm install -g github:jakenuts/happy-cli#v0.11.3-preview.5

# Install from main branch
npm install -g github:jakenuts/happy-cli#main
```

## Verify Installation

```powershell
# Check version
happy --version

# Check daemon status
happy daemon status

# Start daemon
happy daemon start
```

## From NPM (Once Published)

When published to npm:

```powershell
# Install stable
npm install -g happy-coder

# Install preview (side-by-side with stable)
npm install -g happy-next
```

## Troubleshooting

### Installation Fails with EOF Error

This is usually a transient network issue downloading binaries. Try:
1. Run the install command again
2. Clear npm cache: `npm cache clean --force`
3. Try again

### "happy command not found"

Ensure npm's global bin directory is in your PATH:

```powershell
# Check where npm installs global packages
npm bin -g

# On Windows, should output something like:
# C:\Users\YourName\AppData\Roaming\npm

# Verify it's in PATH
$env:PATH -split ';' | Select-String npm
```

If not in PATH, add it:
1. Search for "Environment Variables" in Windows
2. Edit user or system PATH
3. Add the npm bin directory
4. Restart PowerShell

### Update to Latest Preview

```powershell
# Uninstall current version
npm uninstall -g happy-coder

# Install latest
npm install -g github:jakenuts/happy-cli#latest-preview
```

## Development Install

If you have the repo cloned locally:

```bash
# Build the project
npm run build

# Install globally from local directory
npm install -g .

# Test it works
happy --version
```

## Repository Information

- **Fork (active development):** https://github.com/jakenuts/happy-cli
- **Upstream:** https://github.com/slopus/happy-cli
- **Server:** https://api.happy-servers.com

## What's Installed

When you install Happy CLI, you get:

1. **Commands:**
   - `happy` - Main CLI
   - `happy-mcp` - MCP server for Claude integration

2. **Config Directory:**
   - `~/.happy-dev/` (or `$HAPPY_HOME_DIR`)
   - Contains logs, daemon PID, access keys

3. **Dependencies:**
   - Claude Code SDK (2.0.24)
   - Platform-specific binaries (ripgrep, etc.)

## Uninstall

```powershell
npm uninstall -g happy-coder
```

This removes the commands but leaves your config directory (`~/.happy-dev/`) intact.
