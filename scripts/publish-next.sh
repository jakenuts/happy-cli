#!/usr/bin/env bash

# Script to publish preview releases as happy-next package
# This allows users to install both stable (happy) and preview (happy-next) side-by-side

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo ""
print_step "Publishing happy-next preview release..."
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -f "package-next.json" ]; then
    print_error "Must be run from the project root directory"
    exit 1
fi

# Backup original package.json
print_step "Backing up package.json..."
cp package.json package.json.backup
print_success "Backup created"
echo ""

# Cleanup function
cleanup() {
    if [ -f "package.json.backup" ]; then
        print_step "Restoring package.json..."
        mv package.json.backup package.json
        print_success "Restored"
    fi
}

trap cleanup EXIT

# Replace package.json with package-next.json
print_step "Switching to happy-next configuration..."
cp package-next.json package.json
print_success "Switched to happy-next"
echo ""

# Build the project
print_step "Building project..."
npm run build
print_success "Build complete"
echo ""

# Run tests (optional - comment out if too slow)
# print_step "Running tests..."
# npm run test
# print_success "Tests passed"
# echo ""

# Get version from package.json
VERSION=$(node -p "require('./package.json').version")

# Publish
print_step "Publishing happy-next@$VERSION to npm..."
if [ "$DRY_RUN" = "1" ]; then
    print_step "DRY RUN - would publish with: npm publish --tag preview"
    npm publish --dry-run
else
    npm publish --tag preview
    print_success "Published happy-next@$VERSION"
fi
echo ""

# Final message
echo ""
echo "========================================="
print_success "Publish complete!"
echo "========================================="
echo ""
echo "Users can now install:"
echo "  npm install -g happy-next          # Latest preview"
echo "  npm install -g happy-next@$VERSION # Specific version"
echo ""
echo "Commands available after install:"
echo "  happy-next         # Preview CLI"
echo "  happy-next-mcp     # Preview MCP server"
echo ""
