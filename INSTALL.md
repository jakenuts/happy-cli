# Installing Happy CLI

## Quick Install (Windows)

Install the latest preview from GitHub:

```powershell
npm install -g github:jakenuts/happy-cli#latest-preview
```

This gives you:
- `happy-next` - Main CLI command
- `happy-next-mcp` - MCP server command

**Note:** This installs as `happy-next` so it won't conflict with the stable `happy` version from the upstream repo.

## Install Specific Version

```powershell
# Install specific preview version
npm install -g github:jakenuts/happy-cli#v0.11.3-preview.5

# Install from a specific tag
npm install -g github:jakenuts/happy-cli#latest-preview
```

## Verify Installation

```powershell
# Check version
happy-next --version

# Check daemon status
happy-next daemon status

# Start daemon
happy-next daemon start
```

## Side-by-Side with Stable

You can install both the stable upstream version and this preview fork:

```powershell
# Install stable from upstream (slopus/happy-cli)
npm install -g github:slopus/happy-cli

# Install preview fork (jakenuts/happy-cli)
npm install -g github:jakenuts/happy-cli#latest-preview

# Use either version
happy --version           # Stable (upstream)
happy-next --version      # Preview (fork)

happy daemon start        # Stable daemon
happy-next daemon start   # Preview daemon
```

## Troubleshooting

### Installation Fails with EOF Error

This is usually a transient network issue downloading binaries. Try:
1. Run the install command again
2. Clear npm cache: `npm cache clean --force`
3. Try again

### "happy-next command not found"

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
npm uninstall -g happy-next

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
happy-next --version
```

## Repository Information

- **Fork (active development):** https://github.com/jakenuts/happy-cli
- **Upstream:** https://github.com/slopus/happy-cli
- **Server:** https://api.happy-servers.com

## What's Installed

When you install Happy CLI Next (preview fork), you get:

1. **Commands:**
   - `happy-next` - Main CLI
   - `happy-next-mcp` - MCP server for Claude integration

2. **Config Directory:**
   - `~/.happy-dev/` (or `$HAPPY_HOME_DIR`)
   - Contains logs, daemon PID, access keys
   - **Shared with stable version** if both are installed

3. **Dependencies:**
   - Claude Code SDK (2.0.24)
   - Platform-specific binaries (ripgrep, etc.)

## Uninstall

```powershell
npm uninstall -g happy-next
```

This removes the commands but leaves your config directory (`~/.happy-dev/`) intact.

## Comparison: Stable vs Preview

| Feature | Stable (`happy`) | Preview Fork (`happy-next`) |
|---------|------------------|---------------------------|
| Source | slopus/happy-cli | jakenuts/happy-cli |
| Install | `npm install -g github:slopus/happy-cli` | `npm install -g github:jakenuts/happy-cli#latest-preview` |
| Commands | `happy`, `happy-mcp` | `happy-next`, `happy-next-mcp` |
| Updates | Upstream releases | Daily synced + fork features |
| Use Case | Stable production use | Testing new features, Codex improvements |
