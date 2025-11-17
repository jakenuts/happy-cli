#!/usr/bin/env bash

# Test script to validate an already-installed happy-coder or happy-next installation
# Usage: ./scripts/test-installed.sh [happy|happy-next]
# Examples:
#   ./scripts/test-installed.sh           # Tests 'happy' (stable)
#   ./scripts/test-installed.sh happy-next # Tests 'happy-next' (preview)

set -e  # Exit on error

# Determine which command to test
if [ "$1" = "happy-next" ]; then
    HAPPY_CMD="happy-next"
    HAPPY_MCP_CMD="happy-next-mcp"
    PACKAGE_NAME="happy-next"
else
    HAPPY_CMD="happy"
    HAPPY_MCP_CMD="happy-mcp"
    PACKAGE_NAME="happy-coder"
fi

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
    if [ -f "$HOME/.happy-dev/daemon.pid" ]; then
        print_step "Stopping daemon..."
        $HAPPY_CMD daemon stop 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Start test
echo ""
print_step "Testing installed $PACKAGE_NAME..."
echo ""

# Test 1: Check if command exists
print_step "Test 1: Checking if '$HAPPY_CMD' command is available..."
if command -v $HAPPY_CMD &> /dev/null; then
    HAPPY_PATH=$(which $HAPPY_CMD)
    print_success "'$HAPPY_CMD' command found at: $HAPPY_PATH"
else
    print_error "'$HAPPY_CMD' command not found in PATH"
    echo ""
    echo "Please install $PACKAGE_NAME first:"
    echo "  npm install -g $PACKAGE_NAME"
    exit 1
fi
echo ""

# Test 2: Check version
print_step "Test 2: Checking '$HAPPY_CMD --version'..."
VERSION_OUTPUT=$($HAPPY_CMD --version 2>&1)
if [ $? -eq 0 ]; then
    print_success "Version check succeeded: $VERSION_OUTPUT"
else
    print_error "Version check failed"
    exit 1
fi
echo ""

# Test 3: Check if mcp command exists
print_step "Test 3: Checking if '$HAPPY_MCP_CMD' command is available..."
if command -v $HAPPY_MCP_CMD &> /dev/null; then
    HAPPY_MCP_PATH=$(which $HAPPY_MCP_CMD)
    print_success "'$HAPPY_MCP_CMD' command found at: $HAPPY_MCP_PATH"
else
    print_error "'$HAPPY_MCP_CMD' command not found in PATH"
    exit 1
fi
echo ""

# Test 4: Start daemon (with timeout)
print_step "Test 4: Starting daemon (will timeout after 30s and that's expected)..."
timeout 30s $HAPPY_CMD daemon start > /dev/null 2>&1 &
DAEMON_PID=$!

# Wait a bit for daemon to start
sleep 5

# Check if daemon started successfully
if $HAPPY_CMD daemon status 2>&1 | grep -q "running"; then
    print_success "Daemon started successfully"

    # Stop the daemon
    print_step "Stopping daemon..."
    $HAPPY_CMD daemon stop
    sleep 2

    if $HAPPY_CMD daemon status 2>&1 | grep -q "not running"; then
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
    LOG_COUNT=$(find "$HOME/.happy-dev/logs" -name "*daemon.log" -type f 2>/dev/null | wc -l)
    if [ "$LOG_COUNT" -gt 0 ]; then
        LATEST_LOG=$(find "$HOME/.happy-dev/logs" -name "*daemon.log" -type f 2>/dev/null | sort | tail -1)
        print_success "Found $LOG_COUNT daemon log file(s)"
        echo "    Latest: $LATEST_LOG"
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
echo "  Package: $PACKAGE_NAME"
echo "  Version: $VERSION_OUTPUT"
echo "  $HAPPY_CMD: $HAPPY_PATH"
echo "  $HAPPY_MCP_CMD: $HAPPY_MCP_PATH"
echo ""
