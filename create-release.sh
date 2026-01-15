#!/bin/bash

# Helper script to create a release tag and get SHA256 checksum
# Usage: ./create-release.sh [version]
# Example: ./create-release.sh v1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from argument or prompt
if [ -z "$1" ]; then
    echo -e "${YELLOW}No version specified.${NC}"
    echo "Usage: $0 [version]"
    echo "Example: $0 v1.0.0"
    read -p "Enter version (e.g., v1.0.0): " VERSION
else
    VERSION="$1"
fi

# Validate version format
if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo -e "${RED}Error: Version should be in format v1.0.0${NC}"
    exit 1
fi

# Get repository info
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [ -z "$REPO_URL" ]; then
    echo -e "${RED}Error: No git remote found${NC}"
    exit 1
fi

# Extract username and repo name from URL
if [[ $REPO_URL =~ github.com[:/]([^/]+)/([^/]+)\.git ]]; then
    USERNAME="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    REPO_NAME="${REPO_NAME%.git}"  # Remove .git if present
else
    echo -e "${YELLOW}Warning: Could not parse repository URL. Using defaults.${NC}"
    read -p "Enter GitHub username: " USERNAME
    read -p "Enter repository name: " REPO_NAME
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Creating Release: ${VERSION}${NC}"
echo -e "${BLUE}  Repository: ${USERNAME}/${REPO_NAME}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}Warning: You have uncommitted changes.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag ${VERSION} already exists locally${NC}"
    read -p "Delete and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$VERSION"
        git push origin --delete "$VERSION" 2>/dev/null || true
    else
        exit 1
    fi
fi

# Create tag
echo -e "${GREEN}Step 1: Creating tag ${VERSION}...${NC}"
read -p "Enter release message (or press Enter for default): " RELEASE_MSG
if [ -z "$RELEASE_MSG" ]; then
    RELEASE_MSG="Release ${VERSION}"
fi

git tag -a "$VERSION" -m "$RELEASE_MSG"
echo -e "${GREEN}✓ Tag created locally${NC}"
echo ""

# Push tag
echo -e "${GREEN}Step 2: Pushing tag to GitHub...${NC}"
git push origin "$VERSION"
echo -e "${GREEN}✓ Tag pushed to GitHub${NC}"
echo ""

# Wait for GitHub Actions
echo -e "${YELLOW}Step 3: Waiting for GitHub Actions to create release...${NC}"
echo -e "${YELLOW}This usually takes 5-10 minutes.${NC}"
echo ""
echo "You can check progress at:"
echo -e "${BLUE}https://github.com/${USERNAME}/${REPO_NAME}/actions${NC}"
echo ""
read -p "Press Enter when the GitHub Actions workflow has completed..."

# Get SHA256 checksum
TARBALL_URL="https://github.com/${USERNAME}/${REPO_NAME}/archive/refs/tags/${VERSION}.tar.gz"
echo ""
echo -e "${GREEN}Step 4: Calculating SHA256 checksum...${NC}"
echo -e "${BLUE}Downloading: ${TARBALL_URL}${NC}"

SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

if [ -z "$SHA256" ]; then
    echo -e "${RED}Error: Could not calculate checksum${NC}"
    echo "Make sure the tag exists on GitHub and the tarball is available."
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Release Information${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Version:${NC} ${VERSION}"
echo -e "${BLUE}Tarball URL:${NC} ${TARBALL_URL}"
echo -e "${BLUE}SHA256:${NC} ${SHA256}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Show formula update instructions
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Update Formula/prefix.rb with:"
echo ""
echo -e "${BLUE}   url \"${TARBALL_URL}\"${NC}"
echo -e "${BLUE}   sha256 \"${SHA256}\"${NC}"
echo ""
echo "2. Remove the TODO comments from the formula"
echo ""
echo "3. Test the formula:"
echo -e "${BLUE}   brew install --build-from-source Formula/prefix.rb${NC}"
echo ""

# Optionally update formula automatically
read -p "Update Formula/prefix.rb automatically? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    FORMULA_FILE="Formula/prefix.rb"
    if [ -f "$FORMULA_FILE" ]; then
        # Create backup
        cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"
        
        # Update URL (remove TODO comment if present)
        sed -i '' "s|url \".*\"|url \"${TARBALL_URL}\"|" "$FORMULA_FILE"
        sed -i '' "s|# TODO: Replace.*version tag||" "$FORMULA_FILE"
        
        # Update SHA256
        sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|" "$FORMULA_FILE"
        sed -i '' "s|# TODO: Replace.*SHA256.*||" "$FORMULA_FILE"
        
        # Remove other TODO comments
        sed -i '' "s|# TODO: Replace YOUR_USERNAME.*||" "$FORMULA_FILE"
        
        echo -e "${GREEN}✓ Formula updated${NC}"
        echo -e "${YELLOW}Backup saved to: ${FORMULA_FILE}.backup${NC}"
        echo ""
        echo "Review the changes:"
        echo -e "${BLUE}   git diff ${FORMULA_FILE}${NC}"
    else
        echo -e "${RED}Error: Formula file not found at ${FORMULA_FILE}${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ Release process complete!${NC}"
