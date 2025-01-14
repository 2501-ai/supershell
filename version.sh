#!/bin/bash

# Constants
VERSION_FILE="version.txt"
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

# Functions
increment_version() {
    local version=$1
    local position=$2
    
    IFS='.' read -ra parts <<< "$version"
    case $position in
        major)
            ((parts[0]++))
            parts[1]=0
            parts[2]=0
            ;;
        minor)
            ((parts[1]++))
            parts[2]=0
            ;;
        patch)
            ((parts[2]++))
            ;;
    esac
    
    echo "${parts[0]}.${parts[1]}.${parts[2]}"
}

# Main script
case "$1" in
    major|minor|patch)
        NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$1")
        echo "$NEW_VERSION" > "$VERSION_FILE"
        
        # Git operations
        git add "$VERSION_FILE"
        git commit -m "chore: bump version to $NEW_VERSION"
        
        echo "Version bumped to $NEW_VERSION"
        ;;
    *)
        echo "Usage: $0 {major|minor|patch}"
        echo "Current version: $CURRENT_VERSION"
        exit 1
        ;;
esac