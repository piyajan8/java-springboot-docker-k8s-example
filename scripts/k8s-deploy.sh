#!/bin/bash

# Kubernetes deployment script with registry support
# Usage: ./scripts/k8s-deploy.sh [options]
# Options:
#   --environment ENV    Deployment environment (local|registry)
#   --registry REGISTRY  Container registry URL
#   --version VERSION    Image version/tag
#   --namespace NS       Kubernetes namespace (default: default)
#   --dry-run           Show what would be deployed without applying
#   --help              Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
ENVIRONMENT="local"
REGISTRY=""
VERSION="latest"
NAMESPACE="default"
DRY_RUN=false
APP_NAME="java-springboot-docker-k8s-example"

# Function to show help
show_help() {
    echo "Kubernetes Deployment Script for Spring Boot Application"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --environment ENV    Deployment environment (local|registry) [default: local]"
    echo "  --registry REGISTRY  Container registry URL (required for registry environment)"
    echo "  --version VERSION    Image version/tag [default: latest]"
    echo "  --namespace NS       Kubernetes namespace [default: default]"
    echo "  --dry-run           Show what would be deployed without applying"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment local                                    # Deploy locally built image"
    echo "  $0 --environment registry --registry myregistry.com --version v1.0.0"
    echo "  $0 --environment registry --registry gcr.io/my-project --version v1.2.3 --namespace production"
    echo "  $0 --dry-run --environment registry --registry myregistry.com --version v1.0.0"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

# Validate arguments
if [ "$ENVIRONMENT" != "local" ] && [ "$ENVIRONMENT" != "registry" ]; then
    echo "Error: Environment must be 'local' or 'registry'"
    exit 1
fi

if [ "$ENVIRONMENT" = "registry" ] && [ -z "$REGISTRY" ]; then
    echo "Error: --registry is required when environment is 'registry'"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kustomize is available
if ! command -v kustomize &> /dev/null; then
    echo "Warning: kustomize not found, using kubectl with -k flag"
    KUSTOMIZE_CMD="kubectl apply -k"
else
    KUSTOMIZE_CMD="kustomize build"
fi

echo "=== Kubernetes Deployment ==="
echo "Environment: $ENVIRONMENT"
echo "Registry: ${REGISTRY:-"local"}"
echo "Version: $VERSION"
echo "Namespace: $NAMESPACE"
echo "Dry run: $DRY_RUN"
echo ""

# Set up kustomization directory
KUSTOMIZE_DIR="$PROJECT_ROOT/k8s/overlays/$ENVIRONMENT"

if [ ! -d "$KUSTOMIZE_DIR" ]; then
    echo "Error: Kustomization directory not found: $KUSTOMIZE_DIR"
    exit 1
fi

# Create temporary kustomization file with updated image
TEMP_KUSTOMIZE="$KUSTOMIZE_DIR/kustomization-temp.yaml"
cp "$KUSTOMIZE_DIR/kustomization.yaml" "$TEMP_KUSTOMIZE"

# Update image configuration based on environment
if [ "$ENVIRONMENT" = "registry" ]; then
    # Update registry image configuration
    cat >> "$TEMP_KUSTOMIZE" << EOF

# Updated image configuration for deployment
images:
- name: $APP_NAME
  newName: $REGISTRY/$APP_NAME
  newTag: $VERSION
EOF
else
    # Update local image configuration
    cat >> "$TEMP_KUSTOMIZE" << EOF

# Updated image configuration for deployment
images:
- name: $APP_NAME
  newTag: $VERSION
EOF
fi

# Function to cleanup temporary files
cleanup() {
    rm -f "$TEMP_KUSTOMIZE"
}
trap cleanup EXIT

echo "Deploying to Kubernetes..."
echo "Using kustomization: $KUSTOMIZE_DIR"
echo ""

# Generate and apply/show the manifests
cd "$KUSTOMIZE_DIR"

if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN - Generated Manifests ==="
    if command -v kustomize &> /dev/null; then
        kustomize build . --load-restrictor LoadRestrictionsNone
    else
        kubectl kustomize .
    fi
else
    echo "Applying manifests to namespace: $NAMESPACE"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply the manifests
    if command -v kustomize &> /dev/null; then
        kustomize build . --load-restrictor LoadRestrictionsNone | kubectl apply -n "$NAMESPACE" -f -
    else
        kubectl apply -k . -n "$NAMESPACE"
    fi
    
    echo ""
    echo "✓ Deployment applied successfully"
    
    # Wait for rollout to complete
    echo "Waiting for deployment rollout..."
    kubectl rollout status deployment/java-springboot-app -n "$NAMESPACE" --timeout=300s
    
    echo ""
    echo "=== Deployment Status ==="
    kubectl get pods -l app=java-springboot-app -n "$NAMESPACE"
    
    echo ""
    echo "=== Service Information ==="
    kubectl get svc -l app=java-springboot-app -n "$NAMESPACE"
    
    echo ""
    echo "To check application logs:"
    echo "kubectl logs -l app=java-springboot-app -n $NAMESPACE --tail=50"
    echo ""
    echo "To port-forward for testing:"
    echo "kubectl port-forward svc/java-springboot-app 8080:8080 -n $NAMESPACE"
    echo ""
    echo "To test health endpoint:"
    echo "curl http://localhost:8080/actuator/health"
fi