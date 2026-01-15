#!/bin/bash

# Quick script to get SHA256 checksum for a version tag
# Usage: ./get-checksum.sh [version] [username] [repo]
# Example: ./get-checksum.sh v1.0.0 shubhdevelop prefix

set -e

VERSION="${1:-v1.0.0}"
USERNAME="${2:-shubhdevelop}"
REPO="${3:-prefix}"

TARBALL_URL="https://github.com/${USERNAME}/${REPO}/archive/refs/tags/${VERSION}.tar.gz"

echo "Getting SHA256 for: ${TARBALL_URL}"
echo ""

SHA256=$(curl -sL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

if [ -z "$SHA256" ]; then
    echo "Error: Could not calculate checksum"
    echo "Make sure the tag exists: https://github.com/${USERNAME}/${REPO}/releases/tag/${VERSION}"
    exit 1
fi

echo "SHA256: ${SHA256}"
echo ""
echo "For your formula, use:"
echo "  url \"${TARBALL_URL}\""
echo "  sha256 \"${SHA256}\""
