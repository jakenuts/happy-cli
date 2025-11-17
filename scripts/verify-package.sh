#!/usr/bin/env bash

# Script to verify package contents are correct before installation
# Usage: ./scripts/verify-package.sh

echo "Verifying happy-next package contents..."
echo ""

echo "=== Bin files ==="
ls -lh bin/
echo ""

echo "=== Package.json bin config ==="
grep -A 3 '"bin"' package.json
echo ""

echo "=== Files that will be included in package ==="
npm pack --dry-run 2>&1 | grep "npm notice"
echo ""

echo "=== Git status ==="
git status --short
echo ""

echo "Verification complete!"
