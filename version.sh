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

update_version_references() {
    local new_version=$1
    
    # Update version.txt
    echo "$new_version" > "$VERSION_FILE"
    
    # Update version in zsh_upgrade.sh
    sed -i "s/CURRENT_VERSION=\".*\"/CURRENT_VERSION=\"$new_version\"/" shell/zsh_upgrade.sh
    
    # Add more files that need version updates here
}

# Main script
case "$1" in
    major|minor|patch)
        NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$1")
        update_version_references "$NEW_VERSION"
        
        # Git operations
        git add "$VERSION_FILE" shell/zsh_upgrade.sh
        git commit -m "chore: bump version to $NEW_VERSION"
        git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"
        
        echo "Version bumped to $NEW_VERSION"
        echo "Run 'git push && git push --tags' to trigger release"
        ;;
    *)
        echo "Usage: $0 {major|minor|patch}"
        echo "Current version: $CURRENT_VERSION"
        exit 1
        ;;
esac