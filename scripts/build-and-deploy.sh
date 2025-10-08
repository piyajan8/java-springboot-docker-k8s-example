#!/bin/bash

# Comprehensive build and deployment script
# Usage: ./scripts/build-and-deploy.sh [options]
# Options:
#   --version VERSION    Specify version (default: from pom.xml)
#   --registry REGISTRY  Container registry URL
#   --push              Push to registry after build
#   --deploy            Deploy to Kubernetes after push
#   --local             Build for local development only
#   --help              Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
VERSION=""
REGISTRY=""
PUSH=false
DEPLOY=false
LOCAL=false
APP_NAME="java-springboot-docker-k8s-example"

# Function to show help
show_help() {
    echo "Build and Deployment Script for Spring Boot Application"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --version VERSION    Specify version (default: from pom.xml)"
    echo "  --registry REGISTRY  Container registry URL (required for --push)"
    echo "  --push              Push to registry after build"
    echo "  --deploy            Deploy to Kubernetes after push"
    echo "  --local             Build for local development only"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --local                                    # Local build only"
    echo "  $0 --version 1.0.0 --registry myregistry.com --push"
    echo "  $0 --version 1.0.0 --registry myregistry.com --push --deploy"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --deploy)
            DEPLOY=true
            shift
            ;;
        --local)
            LOCAL=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Get version from pom.xml if not specified
if [ -z "$VERSION" ]; then
    if [ -f "$PROJECT_ROOT/pom.xml" ]; then
        VERSION=$(grep -o '<version>[^<]*</version>' "$PROJECT_ROOT/pom.xml" | head -1 | sed 's/<version>\(.*\)<\/version>/\1/')
    else
        VERSION="0.0.1-SNAPSHOT"
    fi
fi

# Validate arguments
if [ "$PUSH" = true ] && [ -z "$REGISTRY" ]; then
    echo "Error: --registry is required when using --push"
    exit 1
fi

if [ "$DEPLOY" = true ] && [ "$PUSH" = false ]; then
    echo "Error: --deploy requires --push"
    exit 1
fi

echo "=== Spring Boot Application Build and Deployment ==="
echo "Application: $APP_NAME"
echo "Version: $VERSION"
echo "Registry: ${REGISTRY:-"local only"}"
echo "Push to registry: $PUSH"
echo "Deploy to Kubernetes: $DEPLOY"
echo "Local development: $LOCAL"
echo ""

# Step 1: Build the application
echo "Step 1: Building Docker image..."
cd "$PROJECT_ROOT"

if [ "$LOCAL" = true ]; then
    ./docker-build.sh "$VERSION"
else
    ./docker-build.sh "$VERSION" "$REGISTRY"
fi

echo "✓ Docker image built successfully"
echo ""

# Step 2: Push to registry if requested
if [ "$PUSH" = true ]; then
    echo "Step 2: Pushing to container registry..."
    ./docker-push.sh "$VERSION" "$REGISTRY"
    echo "✓ Images pushed to registry successfully"
    echo ""
fi

# Step 3: Deploy to Kubernetes if requested
if [ "$DEPLOY" = true ]; then
    echo "Step 3: Deploying to Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Update deployment image
    FULL_IMAGE="$REGISTRY/$APP_NAME:$VERSION"
    echo "Updating deployment with image: $FULL_IMAGE"
    
    if kubectl get deployment spring-boot-app &> /dev/null; then
        kubectl set image deployment/spring-boot-app container="$FULL_IMAGE"
        kubectl rollout status deployment/spring-boot-app
        echo "✓ Deployment updated successfully"
    else
        echo "Warning: Deployment 'spring-boot-app' not found"
        echo "Please apply your Kubernetes manifests first:"
        echo "kubectl apply -f k8s/"
    fi
    echo ""
fi

# Summary
echo "=== Build and Deployment Summary ==="
echo "✓ Docker image built: $APP_NAME:$VERSION"

if [ "$PUSH" = true ]; then
    echo "✓ Images pushed to: $REGISTRY"
fi

if [ "$DEPLOY" = true ]; then
    echo "✓ Deployed to Kubernetes"
fi

echo ""
echo "Next steps:"
if [ "$LOCAL" = true ]; then
    echo "- Run locally: docker run -p 8080:8080 $APP_NAME:$VERSION"
    echo "- Test health: curl http://localhost:8080/actuator/health"
elif [ "$PUSH" = false ]; then
    echo "- Push to registry: ./docker-push.sh $VERSION <registry>"
    echo "- Deploy to K8s: kubectl set image deployment/spring-boot-app container=$REGISTRY/$APP_NAME:$VERSION"
fi

echo "- Check version: ./scripts/version-manager.sh current"
echo "- List images: ./scripts/version-manager.sh list"