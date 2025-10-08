#!/bin/bash

# Local Kubernetes Development Setup Script
# This script helps set up the local development environment using minikube or kind

set -e

echo "🚀 Setting up local Kubernetes development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Detect Kubernetes environment
K8S_ENV=""
if command -v minikube > /dev/null 2>&1 && minikube status > /dev/null 2>&1; then
    K8S_ENV="minikube"
    print_status "Detected minikube environment"
elif command -v kind > /dev/null 2>&1 && kind get clusters > /dev/null 2>&1; then
    K8S_ENV="kind"
    print_status "Detected kind environment"
elif kubectl cluster-info > /dev/null 2>&1; then
    K8S_ENV="other"
    print_status "Detected other Kubernetes environment"
else
    print_error "No Kubernetes environment detected. Please start minikube or kind cluster."
    echo "For minikube: minikube start"
    echo "For kind: kind create cluster --name springboot-local"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl > /dev/null 2>&1; then
    print_error "kubectl is not installed. Please install kubectl and try again."
    exit 1
fi

print_step "Building Docker image..."

# Build the Docker image
docker build -t java-springboot-docker-k8s-example:local .

# Load image into the cluster based on environment
if [ "$K8S_ENV" = "minikube" ]; then
    print_step "Loading image into minikube..."
    minikube image load java-springboot-docker-k8s-example:local
elif [ "$K8S_ENV" = "kind" ]; then
    print_step "Loading image into kind cluster..."
    # Try to detect the cluster name
    CLUSTER_NAME=$(kind get clusters | head -n 1)
    if [ -z "$CLUSTER_NAME" ]; then
        CLUSTER_NAME="kind"
    fi
    kind load docker-image java-springboot-docker-k8s-example:local --name "$CLUSTER_NAME"
else
    print_warning "Unknown Kubernetes environment. Make sure the image is available in your cluster."
fi

print_step "Applying Kubernetes manifests..."

# Apply the local Kubernetes manifests
kubectl apply -k k8s/local/

print_step "Waiting for deployment to be ready..."

# Wait for the deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/java-springboot-app-local -n springboot-local

print_status "Deployment is ready!"

# Get service information
if [ "$K8S_ENV" = "minikube" ]; then
    SERVICE_URL=$(minikube service java-springboot-service-local -n springboot-local --url)
    print_status "Application is accessible at: $SERVICE_URL"
else
    print_status "Application is accessible via NodePort 30080"
    if [ "$K8S_ENV" = "kind" ]; then
        print_warning "For kind, you may need to port-forward: kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080"
    fi
fi

print_status "Local Kubernetes development environment is ready!"
echo ""
echo "📋 Useful commands:"
echo "   View pods: kubectl get pods -n springboot-local"
echo "   View services: kubectl get services -n springboot-local"
echo "   View logs: kubectl logs -f deployment/java-springboot-app-local -n springboot-local"
echo "   Port forward: kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080"
echo "   Delete resources: kubectl delete -k k8s/local/"
echo ""
echo "🔍 Health check endpoints:"
echo "   Health: /actuator/health"
echo "   Metrics: /actuator/metrics"
echo "   Info: /actuator/info"
echo ""
print_status "Setup complete! Happy coding! 🎉"