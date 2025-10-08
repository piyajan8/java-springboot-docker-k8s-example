#!/bin/bash

# Comprehensive Deployment Script for Spring Boot Kubernetes Application
# This script provides a unified interface for all deployment scenarios
# Usage: ./scripts/deploy.sh [command] [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
COMMAND=""
ENVIRONMENT="local"
VERSION=""
REGISTRY=""
NAMESPACE="default"
DRY_RUN=false
FORCE=false
VERBOSE=false
APP_NAME="java-springboot-docker-k8s-example"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

# Function to show help
show_help() {
    cat << EOF
Comprehensive Deployment Script for Spring Boot Kubernetes Application

Usage: $0 [command] [options]

Commands:
  setup-local-docker    Set up local development with Docker Compose
  setup-local-k8s      Set up local development with Kubernetes
  build                Build Docker image
  push                 Push image to registry
  deploy               Deploy to Kubernetes
  full-deploy          Complete build, push, and deploy workflow
  status               Show deployment status
  logs                 Show application logs
  cleanup              Clean up resources
  help                 Show this help message

Options:
  --environment ENV    Deployment environment (local|registry) [default: local]
  --version VERSION    Image version/tag [default: from pom.xml]
  --registry REGISTRY  Container registry URL (required for registry environment)
  --namespace NS       Kubernetes namespace [default: default]
  --dry-run           Show what would be done without executing
  --force             Force operations without confirmation
  --verbose           Enable verbose output
  --help              Show this help message

Examples:
  # Local development setup
  $0 setup-local-docker
  $0 setup-local-k8s

  # Build and test locally
  $0 build --version 1.0.0
  $0 deploy --environment local --version 1.0.0

  # Full production deployment
  $0 full-deploy --environment registry --registry myregistry.com --version 1.0.0 --namespace production

  # Check deployment status
  $0 status --namespace production
  $0 logs --namespace production --follow

  # Cleanup
  $0 cleanup --environment local
  $0 cleanup --namespace production --force

Environment Variables:
  REGISTRY             Default container registry
  NAMESPACE            Default Kubernetes namespace
  VERSION              Default version
  KUBECONFIG           Kubernetes configuration file

EOF
}

# Function to get version from pom.xml
get_version() {
    if [ -n "$VERSION" ]; then
        echo "$VERSION"
        return
    fi
    
    if [ -f "$PROJECT_ROOT/pom.xml" ]; then
        grep -o '<version>[^<]*</version>' "$PROJECT_ROOT/pom.xml" | head -1 | sed 's/<version>\(.*\)<\/version>/\1/'
    else
        echo "0.0.1-SNAPSHOT"
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    local command=$1
    
    case $command in
        setup-local-docker|build)
            if ! command -v docker &> /dev/null; then
                log_error "Docker is not installed or not in PATH"
                exit 1
            fi
            
            if ! docker info > /dev/null 2>&1; then
                log_error "Docker is not running"
                exit 1
            fi
            ;;
        setup-local-k8s|deploy|status|logs|cleanup)
            if ! command -v kubectl &> /dev/null; then
                log_error "kubectl is not installed or not in PATH"
                exit 1
            fi
            
            if ! kubectl cluster-info > /dev/null 2>&1; then
                log_error "Cannot connect to Kubernetes cluster"
                exit 1
            fi
            ;;
        push|full-deploy)
            if [ "$ENVIRONMENT" = "registry" ] && [ -z "$REGISTRY" ]; then
                log_error "Registry is required for registry environment"
                exit 1
            fi
            ;;
    esac
}

# Function to confirm action
confirm_action() {
    local message=$1
    
    if [ "$FORCE" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi
    
    echo -n "$message (y/N): "
    read -r response
    case $response in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "Operation cancelled"
            exit 0
            ;;
    esac
}

# Command implementations
cmd_setup_local_docker() {
    log_step "Setting up local Docker development environment"
    
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        log_error "docker-compose.yml not found"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would execute: docker-compose up --build -d"
        return
    fi
    
    log_info "Building and starting services with Docker Compose"
    docker-compose up --build -d
    
    log_info "Waiting for application to be ready"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
            log_info "Application is ready!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Application failed to start within expected time"
            log_warn "Check logs with: docker-compose logs app"
            exit 1
        fi
        
        log_debug "Attempt $attempt/$max_attempts - waiting for application"
        sleep 5
        ((attempt++))
    done
    
    log_info "Local Docker environment is ready!"
    echo ""
    echo "Available endpoints:"
    echo "  Application: http://localhost:8080"
    echo "  Health: http://localhost:8080/actuator/health"
    echo "  Metrics: http://localhost:8080/actuator/metrics"
}

cmd_setup_local_k8s() {
    log_step "Setting up local Kubernetes development environment"
    
    # Detect Kubernetes environment
    local k8s_env=""
    if command -v minikube > /dev/null 2>&1 && minikube status > /dev/null 2>&1; then
        k8s_env="minikube"
        log_info "Detected minikube environment"
    elif command -v kind > /dev/null 2>&1 && kind get clusters > /dev/null 2>&1; then
        k8s_env="kind"
        log_info "Detected kind environment"
    else
        k8s_env="other"
        log_info "Detected other Kubernetes environment"
    fi
    
    local version=$(get_version)
    local image_name="$APP_NAME:local"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would build image: $image_name"
        log_info "Would load image into $k8s_env cluster"
        log_info "Would apply manifests from k8s/local/"
        return
    fi
    
    cd "$PROJECT_ROOT"
    
    log_info "Building Docker image: $image_name"
    docker build -t "$image_name" .
    
    # Load image into cluster
    case $k8s_env in
        minikube)
            log_info "Loading image into minikube"
            minikube image load "$image_name"
            ;;
        kind)
            log_info "Loading image into kind cluster"
            local cluster_name=$(kind get clusters | head -n 1)
            kind load docker-image "$image_name" --name "${cluster_name:-kind}"
            ;;
        *)
            log_warn "Unknown Kubernetes environment. Make sure image is available in cluster"
            ;;
    esac
    
    log_info "Applying Kubernetes manifests"
    kubectl apply -k k8s/local/
    
    log_info "Waiting for deployment to be ready"
    kubectl wait --for=condition=available --timeout=300s deployment/java-springboot-app-local -n springboot-local
    
    log_info "Local Kubernetes environment is ready!"
    echo ""
    echo "To access the application:"
    if [ "$k8s_env" = "minikube" ]; then
        echo "  minikube service java-springboot-service-local -n springboot-local --url"
    else
        echo "  kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080"
    fi
}

cmd_build() {
    local version=$(get_version)
    local image_name="$APP_NAME:$version"
    
    if [ -n "$REGISTRY" ]; then
        image_name="$REGISTRY/$APP_NAME:$version"
    fi
    
    log_step "Building Docker image: $image_name"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would build image: $image_name"
        return
    fi
    
    cd "$PROJECT_ROOT"
    docker build -t "$image_name" .
    
    log_info "Image built successfully: $image_name"
}

cmd_push() {
    local version=$(get_version)
    
    if [ -z "$REGISTRY" ]; then
        log_error "Registry is required for push command"
        exit 1
    fi
    
    local image_name="$REGISTRY/$APP_NAME:$version"
    
    log_step "Pushing image to registry: $image_name"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would push image: $image_name"
        return
    fi
    
    docker push "$image_name"
    log_info "Image pushed successfully: $image_name"
}

cmd_deploy() {
    local version=$(get_version)
    
    log_step "Deploying to Kubernetes"
    log_info "Environment: $ENVIRONMENT"
    log_info "Version: $version"
    log_info "Namespace: $NAMESPACE"
    
    if [ "$ENVIRONMENT" = "registry" ] && [ -z "$REGISTRY" ]; then
        log_error "Registry is required for registry environment"
        exit 1
    fi
    
    local kustomize_dir="$PROJECT_ROOT/k8s/overlays/$ENVIRONMENT"
    
    if [ ! -d "$kustomize_dir" ]; then
        log_error "Kustomization directory not found: $kustomize_dir"
        exit 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would deploy using kustomization: $kustomize_dir"
        log_info "Would create namespace: $NAMESPACE"
        log_info "Would apply manifests with image: $REGISTRY/$APP_NAME:$version"
        return
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy using the k8s-deploy.sh script
    "$SCRIPT_DIR/k8s-deploy.sh" \
        --environment "$ENVIRONMENT" \
        --version "$version" \
        --namespace "$NAMESPACE" \
        ${REGISTRY:+--registry "$REGISTRY"}
    
    log_info "Deployment completed successfully"
}

cmd_full_deploy() {
    log_step "Starting full deployment workflow"
    
    local version=$(get_version)
    log_info "Version: $version"
    log_info "Environment: $ENVIRONMENT"
    log_info "Registry: ${REGISTRY:-"local"}"
    log_info "Namespace: $NAMESPACE"
    
    confirm_action "Proceed with full deployment?"
    
    # Build
    cmd_build
    
    # Push (if registry environment)
    if [ "$ENVIRONMENT" = "registry" ]; then
        cmd_push
    fi
    
    # Deploy
    cmd_deploy
    
    log_info "Full deployment completed successfully!"
}

cmd_status() {
    log_step "Checking deployment status"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would check status in namespace: $NAMESPACE"
        return
    fi
    
    echo ""
    echo "=== Deployment Status ==="
    kubectl get deployments -n "$NAMESPACE" -l app=java-springboot-app
    
    echo ""
    echo "=== Pod Status ==="
    kubectl get pods -n "$NAMESPACE" -l app=java-springboot-app -o wide
    
    echo ""
    echo "=== Service Status ==="
    kubectl get services -n "$NAMESPACE" -l app=java-springboot-app
    
    echo ""
    echo "=== Recent Events ==="
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
}

cmd_logs() {
    log_step "Showing application logs"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would show logs from namespace: $NAMESPACE"
        return
    fi
    
    local follow_flag=""
    if [ "$1" = "--follow" ] || [ "$1" = "-f" ]; then
        follow_flag="-f"
    fi
    
    kubectl logs -l app=java-springboot-app -n "$NAMESPACE" --tail=50 $follow_flag
}

cmd_cleanup() {
    log_step "Cleaning up resources"
    
    if [ "$ENVIRONMENT" = "local" ]; then
        log_info "Cleaning up local resources"
        
        confirm_action "This will remove local Docker containers and Kubernetes resources. Continue?"
        
        if [ "$DRY_RUN" = true ]; then
            log_info "Would stop Docker Compose services"
            log_info "Would delete local Kubernetes resources"
            return
        fi
        
        # Docker Compose cleanup
        if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
            cd "$PROJECT_ROOT"
            docker-compose down -v
            log_info "Docker Compose services stopped"
        fi
        
        # Local Kubernetes cleanup
        if kubectl get namespace springboot-local > /dev/null 2>&1; then
            kubectl delete -k k8s/local/ || true
            log_info "Local Kubernetes resources deleted"
        fi
        
    else
        log_info "Cleaning up resources in namespace: $NAMESPACE"
        
        confirm_action "This will delete all resources in namespace $NAMESPACE. Continue?"
        
        if [ "$DRY_RUN" = true ]; then
            log_info "Would delete resources in namespace: $NAMESPACE"
            return
        fi
        
        kubectl delete all -l app=java-springboot-app -n "$NAMESPACE"
        log_info "Resources cleaned up successfully"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        setup-local-docker|setup-local-k8s|build|push|deploy|full-deploy|status|logs|cleanup|help)
            COMMAND="$1"
            shift
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
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
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --follow|-f)
            # Pass through for logs command
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set defaults from environment variables
REGISTRY=${REGISTRY:-$REGISTRY}
NAMESPACE=${NAMESPACE:-$NAMESPACE}
VERSION=${VERSION:-$VERSION}

# Validate command
if [ -z "$COMMAND" ]; then
    log_error "No command specified"
    show_help
    exit 1
fi

# Validate prerequisites
validate_prerequisites "$COMMAND"

# Execute command
case $COMMAND in
    setup-local-docker)
        cmd_setup_local_docker
        ;;
    setup-local-k8s)
        cmd_setup_local_k8s
        ;;
    build)
        cmd_build
        ;;
    push)
        cmd_push
        ;;
    deploy)
        cmd_deploy
        ;;
    full-deploy)
        cmd_full_deploy
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs "$@"
        ;;
    cleanup)
        cmd_cleanup
        ;;
    help)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac