#!/usr/bin/env bash

# Manual script to sync changes from upstream slopus/happy-cli
# Usage: ./scripts/sync-upstream.sh [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
    print_info "Running in DRY RUN mode - no changes will be made"
fi

echo ""
print_step "Syncing from upstream slopus/happy-cli..."
echo ""

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_error "You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

# Ensure upstream remote exists
print_step "Checking upstream remote..."
if ! git remote get-url upstream > /dev/null 2>&1; then
    print_step "Adding upstream remote..."
    if [ "$DRY_RUN" = false ]; then
        git remote add upstream https://github.com/slopus/happy-cli.git
    fi
    print_success "Upstream remote added"
else
    print_success "Upstream remote exists"
fi
echo ""

# Fetch upstream
print_step "Fetching from upstream..."
if [ "$DRY_RUN" = false ]; then
    git fetch upstream
fi
print_success "Fetch complete"
echo ""

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
print_info "Current branch: $CURRENT_BRANCH"
echo ""

# Show what would be merged
print_step "Changes from upstream:"
NEW_COMMITS=$(git rev-list HEAD..upstream/main --count 2>/dev/null || echo "0")

if [ "$NEW_COMMITS" -eq 0 ]; then
    print_success "Already up to date with upstream"
    exit 0
fi

print_info "Found $NEW_COMMITS new commit(s) from upstream"
echo ""
git log --oneline --graph HEAD..upstream/main | head -20
echo ""

# Show files that will be affected
print_step "Files that will be modified:"
git diff --name-status HEAD..upstream/main | head -20
echo ""

if [ "$DRY_RUN" = true ]; then
    print_info "DRY RUN: Would attempt to merge upstream/main into $CURRENT_BRANCH"
    echo ""
    echo "To perform the actual merge, run:"
    echo "  ./scripts/sync-upstream.sh"
    exit 0
fi

# Ask for confirmation
read -p "Merge these changes into $CURRENT_BRANCH? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Sync cancelled"
    exit 0
fi

echo ""
print_step "Attempting merge..."

# Try to merge
if git merge upstream/main --no-edit -m "chore: sync from upstream slopus/happy-cli"; then
    print_success "Merge successful!"
    echo ""

    # Ask if we should push
    read -p "Push changes to origin? (y/N) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Pushing to origin..."
        git push origin $CURRENT_BRANCH
        print_success "Push complete"
    else
        print_info "Changes merged locally but not pushed"
        print_info "To push later, run: git push origin $CURRENT_BRANCH"
    fi
else
    print_error "Merge conflicts detected!"
    echo ""
    echo "Conflicts in the following files:"
    git diff --name-only --diff-filter=U
    echo ""
    echo "To resolve:"
    echo "  1. Fix conflicts in the files listed above"
    echo "  2. Run: git add <resolved-files>"
    echo "  3. Run: git commit"
    echo "  4. Run: git push origin $CURRENT_BRANCH"
    echo ""
    echo "To abort the merge:"
    echo "  git merge --abort"
    exit 1
fi

echo ""
echo "========================================="
print_success "Sync complete!"
echo "========================================="
