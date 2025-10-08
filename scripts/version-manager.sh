#!/bin/bash

# Version management script for Docker images
# Usage: ./scripts/version-manager.sh [command] [options]
# Commands:
#   current     - Show current version
#   bump        - Bump version (patch, minor, major)
#   tag         - Create git tag for current version
#   list        - List available image tags

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
POM_FILE="$PROJECT_ROOT/pom.xml"

# Function to extract version from pom.xml
get_current_version() {
    if [ -f "$POM_FILE" ]; then
        grep -o '<version>[^<]*</version>' "$POM_FILE" | head -1 | sed 's/<version>\(.*\)<\/version>/\1/'
    else
        echo "0.0.1-SNAPSHOT"
    fi
}

# Function to update version in pom.xml
update_pom_version() {
    local new_version=$1
    if [ -f "$POM_FILE" ]; then
        # Use sed to update the first version tag (project version, not parent version)
        sed -i.bak "0,/<version>.*<\/version>/s/<version>.*<\/version>/<version>$new_version<\/version>/" "$POM_FILE"
        rm "$POM_FILE.bak" 2>/dev/null || true
        echo "Updated pom.xml version to: $new_version"
    fi
}

# Function to bump version
bump_version() {
    local bump_type=$1
    local current_version=$(get_current_version)
    
    # Remove -SNAPSHOT suffix if present
    local base_version=$(echo "$current_version" | sed 's/-SNAPSHOT//')
    
    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$base_version"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    case $bump_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch|*)
            patch=$((patch + 1))
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    echo "$new_version"
}

# Function to create git tag
create_git_tag() {
    local version=$1
    if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        git tag -a "v$version" -m "Release version $version"
        echo "Created git tag: v$version"
        echo "To push tag: git push origin v$version"
    else
        echo "Git not available or not in a git repository"
    fi
}

# Function to list Docker image tags
list_image_tags() {
    local app_name="java-springboot-docker-k8s-example"
    echo "Available Docker image tags:"
    docker images "$app_name" --format "table {{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "No local images found"
}

# Main command handling
case ${1:-""} in
    current)
        echo "Current version: $(get_current_version)"
        ;;
    bump)
        bump_type=${2:-patch}
        current_version=$(get_current_version)
        new_version=$(bump_version "$bump_type")
        echo "Current version: $current_version"
        echo "New version: $new_version"
        
        read -p "Update version to $new_version? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_pom_version "$new_version"
            echo "Version updated successfully!"
            echo "Next steps:"
            echo "1. Build image: ./docker-build.sh $new_version"
            echo "2. Create git tag: $0 tag $new_version"
            echo "3. Push to registry: ./docker-push.sh $new_version <registry>"
        fi
        ;;
    tag)
        version=${2:-$(get_current_version | sed 's/-SNAPSHOT//')}
        create_git_tag "$version"
        ;;
    list)
        list_image_tags
        ;;
    *)
        echo "Version Manager for Spring Boot Docker Application"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  current              Show current version from pom.xml"
        echo "  bump [patch|minor|major]  Bump version (default: patch)"
        echo "  tag [version]        Create git tag for version"
        echo "  list                 List available Docker image tags"
        echo ""
        echo "Examples:"
        echo "  $0 current           # Show current version"
        echo "  $0 bump minor        # Bump minor version"
        echo "  $0 tag 1.0.0         # Create git tag v1.0.0"
        echo "  $0 list              # List Docker images"
        ;;
esac