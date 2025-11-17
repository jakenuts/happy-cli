# Happy CLI Next - Preview Fork

> Code on the go controlling Claude Code from your mobile device.
>
> Free. Open source. Code anywhere.

**This is a preview fork** with experimental features and improvements. For the stable version, see [slopus/happy-cli](https://github.com/slopus/happy-cli).

## Quick Install

```bash
npm install -g github:jakenuts/happy-cli#latest-preview
```

This installs as **`happy-next`** so it won't conflict with the stable `happy` version.

📖 **[Complete Installation Guide](./INSTALL.md)** - Side-by-side setup, troubleshooting, etc.

## What's New in This Fork

### 🔧 Codex Integration Fixes
- Fixed race conditions in WebSocket connections
- Added subprocess health monitoring and auto-recovery
- Windows console window fixes
- Permission handling with timeouts
- Improved error recovery and reconnection logic

### 📦 Installation Improvements
- GitHub install support (no npm publish needed)
- Automatic dist building via GitHub Actions on every commit
- Resilient postinstall script handling
- Better missing dependency recovery
- Cross-platform CI testing (Windows, macOS, Linux)

### 🔄 Upstream Sync
- Automated daily sync from upstream (slopus/happy-cli)
- Manual sync: `./scripts/sync-upstream.sh`
- Auto-merges when no conflicts

## Usage

```bash
happy-next
```

This will:
1. Start a Claude Code session
2. Display a QR code to connect from your mobile device
3. Allow real-time session sharing between Claude Code and your mobile app

## Commands

- `happy-next auth` – Manage authentication
- `happy-next codex` – Start Codex mode
- `happy-next connect` – Store AI vendor API keys in Happy cloud
- `happy-next notify` – Send a push notification to your devices
- `happy-next daemon` – Manage background service
- `happy-next doctor` – System diagnostics & troubleshooting

## Options

- `-h, --help` - Show help
- `-v, --version` - Show version
- `-m, --model <model>` - Claude model to use (default: sonnet)
- `-p, --permission-mode <mode>` - Permission mode: auto, default, or plan
- `--claude-env KEY=VALUE` - Set environment variable for Claude Code
- `--claude-arg ARG` - Pass additional argument to Claude CLI

## Environment Variables

- `HAPPY_SERVER_URL` - Custom server URL (default: https://api.cluster-fluster.com)
- `HAPPY_WEBAPP_URL` - Custom web app URL (default: https://app.happy.engineering)
- `HAPPY_HOME_DIR` - Custom home directory for Happy data (default: ~/.happy)
- `HAPPY_DISABLE_CAFFEINATE` - Disable macOS sleep prevention (set to `true`, `1`, or `yes`)
- `HAPPY_EXPERIMENTAL` - Enable experimental features (set to `true`, `1`, or `yes`)

## Side-by-Side with Stable

Run both versions simultaneously:

```bash
# Install stable
npm install -g github:slopus/happy-cli

# Install preview
npm install -g github:jakenuts/happy-cli#latest-preview

# Use either
happy --version           # Stable
happy-next --version      # Preview
```

Both share the same config directory (`~/.happy-dev/`) but use different command names.

## Requirements

- Node.js >= 20.0.0
- Claude CLI installed & logged in (`claude` command available in PATH)
- **Claude Code SDK:** Pinned to 2.0.24 (last version with SDK exports)

## Documentation

- 📦 [Installation Guide](./INSTALL.md) - Complete setup instructions
- 🔧 [Scripts Documentation](./scripts/README.md) - Testing, publishing, syncing
- 📚 [Codebase Overview](./CLAUDE.md) - Architecture and code style
- 🏗️ [Technical Details](./PROJECT.md) - Deep dive into implementation

## Repository Info

- **Fork (active):** https://github.com/jakenuts/happy-cli
- **Upstream:** https://github.com/slopus/happy-cli
- **Server:** https://api.happy-servers.com/

## License

MIT
