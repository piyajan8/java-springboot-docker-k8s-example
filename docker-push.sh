#!/bin/bash

# Docker push script for Spring Boot application
# Usage: ./docker-push.sh [version] [registry]
# Examples:
#   ./docker-push.sh 1.0.0 myregistry.com      # Push specific version to registry
#   ./docker-push.sh latest docker.io/myuser   # Push latest to Docker Hub
#   ./docker-push.sh                           # Push default version to default registry

set -e

# Configuration
APP_NAME="java-springboot-docker-k8s-example"
DEFAULT_VERSION="0.0.1-SNAPSHOT"
DEFAULT_REGISTRY=""

# Parse arguments
VERSION=${1:-$DEFAULT_VERSION}
REGISTRY=${2:-$DEFAULT_REGISTRY}

# Validate registry is provided
if [ -z "$REGISTRY" ]; then
    echo "Error: Registry must be specified for push operation"
    echo "Usage: $0 [version] <registry>"
    echo "Examples:"
    echo "  $0 1.0.0 myregistry.com"
    echo "  $0 latest docker.io/myuser"
    echo "  $0 v1.2.3 gcr.io/my-project"
    exit 1
fi

# Generate image names
BASE_IMAGE="$REGISTRY/$APP_NAME"
LOCAL_IMAGE="$APP_NAME"

# Images to push
IMAGES_TO_PUSH=(
    "$BASE_IMAGE:$VERSION"
    "$BASE_IMAGE:latest"
)

# Add git commit SHA if available
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_SHA=$(git rev-parse --short HEAD)
    IMAGES_TO_PUSH+=("$BASE_IMAGE:$GIT_SHA")
fi

echo "Pushing Docker images to registry"
echo "Registry: $REGISTRY"
echo "Application: $APP_NAME"
echo "Version: $VERSION"
echo ""

# Check if local images exist and tag them for registry
echo "Preparing images for push..."
for image in "${IMAGES_TO_PUSH[@]}"; do
    # Extract tag from registry image name
    TAG=$(echo "$image" | cut -d':' -f2)
    LOCAL_TAG="$LOCAL_IMAGE:$TAG"
    
    # Check if local image exists
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$LOCAL_TAG$"; then
        echo "Tagging $LOCAL_TAG as $image"
        docker tag "$LOCAL_TAG" "$image"
    else
        echo "Warning: Local image $LOCAL_TAG not found, skipping..."
        continue
    fi
done

echo ""
echo "Pushing images to registry..."

# Push each image
for image in "${IMAGES_TO_PUSH[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
        echo "Pushing $image..."
        if docker push "$image"; then
            echo "✓ Successfully pushed $image"
        else
            echo "✗ Failed to push $image"
            exit 1
        fi
    fi
done

echo ""
echo "All images pushed successfully!"
echo ""
echo "Pushed images:"
for image in "${IMAGES_TO_PUSH[@]}"; do
    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
        echo "  - $image"
    fi
done

echo ""
echo "To deploy to Kubernetes with registry images:"
echo "kubectl set image deployment/spring-boot-app container=$BASE_IMAGE:$VERSION"
echo ""
echo "Or update your deployment.yaml to use:"
echo "image: $BASE_IMAGE:$VERSION"