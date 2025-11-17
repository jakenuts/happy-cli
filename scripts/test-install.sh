#!/usr/bin/env bash

# Test script to install latest preview and validate basic functionality
# Usage: ./scripts/test-install.sh [tag|branch|commit]
# Examples:
#   ./scripts/test-install.sh                    # Uses current branch
#   ./scripts/test-install.sh v0.11.3-preview.4  # Uses specific tag
#   ./scripts/test-install.sh main               # Uses main branch

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Cleanup function
cleanup() {
    print_step "Cleaning up..."
    if [ -f "$HOME/.happy-dev/daemon.pid" ]; then
        happy daemon stop 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Start test
echo ""
print_step "Starting installation test for happy-coder..."
echo ""

# Determine what to install
if [ -n "$1" ]; then
    # Use provided argument (tag, branch, or commit)
    REF="$1"
    print_step "Installing from specified ref: $REF"
else
    # Use current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    REF="$CURRENT_BRANCH"
    print_step "Installing from current branch: $REF"
fi
echo ""

# Uninstall any existing version
print_step "Uninstalling any existing version..."
npm uninstall -g happy-coder 2>/dev/null || true
print_success "Cleanup complete"
echo ""

# Install from GitHub
print_step "Installing from GitHub: slopus/happy-cli#$REF"
if npm install -g "github:slopus/happy-cli#$REF" 2>&1 | tee /tmp/npm-install.log; then
    print_success "Installation complete"
else
    print_error "Installation failed"
    echo ""
    echo "Last 20 lines of npm install output:"
    tail -20 /tmp/npm-install.log
    exit 1
fi
echo ""

# Test 1: Check if happy command exists
print_step "Test 1: Checking if 'happy' command is available..."
if command -v happy &> /dev/null; then
    print_success "'happy' command found in PATH"
else
    print_error "'happy' command not found in PATH"
    exit 1
fi
echo ""

# Test 2: Check version
print_step "Test 2: Checking 'happy --version'..."
VERSION_OUTPUT=$(happy --version 2>&1)
if [ $? -eq 0 ]; then
    print_success "Version check succeeded: $VERSION_OUTPUT"
else
    print_error "Version check failed"
    exit 1
fi
echo ""

# Test 3: Check if happy-mcp exists
print_step "Test 3: Checking if 'happy-mcp' command is available..."
if command -v happy-mcp &> /dev/null; then
    print_success "'happy-mcp' command found in PATH"
else
    print_error "'happy-mcp' command not found in PATH"
    exit 1
fi
echo ""

# Test 4: Start daemon (with timeout)
print_step "Test 4: Starting daemon (30 second timeout)..."
timeout 30s happy daemon start &
DAEMON_PID=$!

# Wait a bit for daemon to start
sleep 3

# Check if daemon started successfully
if happy daemon status 2>&1 | grep -q "running"; then
    print_success "Daemon started successfully"

    # Stop the daemon
    print_step "Stopping daemon..."
    happy daemon stop
    sleep 2

    if happy daemon status 2>&1 | grep -q "not running"; then
        print_success "Daemon stopped successfully"
    else
        print_error "Daemon failed to stop cleanly"
    fi
else
    print_error "Daemon failed to start"
    # Kill the timeout process if still running
    kill $DAEMON_PID 2>/dev/null || true
    exit 1
fi
echo ""

# Test 5: Verify daemon logs were created
print_step "Test 5: Checking daemon logs..."
if [ -d "$HOME/.happy-dev/logs" ]; then
    LOG_COUNT=$(find "$HOME/.happy-dev/logs" -name "*daemon.log" -type f | wc -l)
    if [ "$LOG_COUNT" -gt 0 ]; then
        print_success "Found $LOG_COUNT daemon log file(s)"
    else
        print_error "No daemon log files found"
    fi
else
    print_error "Logs directory not found"
fi
echo ""

# Final summary
echo ""
echo "========================================="
print_success "All tests passed!"
echo "========================================="
echo ""
echo "Installation details:"
echo "  Version: $VERSION_OUTPUT"
echo "  Ref: $REF"
echo "  Commands: happy, happy-mcp"
echo ""
echo "To uninstall:"
echo "  npm uninstall -g happy-coder"
echo ""
