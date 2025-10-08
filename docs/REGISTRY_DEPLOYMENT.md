# Container Registry Deployment Guide

This guide explains how to deploy the Spring Boot application using container registries with Kubernetes.

## Overview

The application supports both local development and production deployment scenarios:

- **Local Development**: Uses locally built Docker images
- **Registry Deployment**: Uses images from container registries (Docker Hub, GCR, ECR, ACR, etc.)

## Quick Start

### 1. Local Development Deployment

```bash
# Build and deploy locally
./scripts/build-and-deploy.sh --local
./scripts/k8s-deploy.sh --environment local
```

### 2. Registry Deployment

```bash
# Build, push, and deploy to registry
./scripts/build-and-deploy.sh --version 1.0.0 --registry myregistry.com --push --deploy
```

## Detailed Workflow

### Building and Pushing Images

#### 1. Build Docker Image

```bash
# Build with default version
./docker-build.sh

# Build with specific version
./docker-build.sh 1.0.0

# Build with registry prefix
./docker-build.sh 1.0.0 myregistry.com
```

#### 2. Push to Registry

```bash
# Push to registry
./docker-push.sh 1.0.0 myregistry.com

# Push to Docker Hub
./docker-push.sh 1.0.0 docker.io/myusername

# Push to Google Container Registry
./docker-push.sh 1.0.0 gcr.io/my-project
```

### Version Management

#### Update Application Version

```bash
# Show current version
./scripts/version-manager.sh current

# Bump patch version (0.0.1 -> 0.0.2)
./scripts/version-manager.sh bump patch

# Bump minor version (0.0.1 -> 0.1.0)
./scripts/version-manager.sh bump minor

# Bump major version (0.0.1 -> 1.0.0)
./scripts/version-manager.sh bump major

# Create git tag
./scripts/version-manager.sh tag 1.0.0
```

### Kubernetes Deployment

#### 1. Local Development

```bash
# Deploy with local images
./scripts/k8s-deploy.sh --environment local --version latest

# Deploy to specific namespace
./scripts/k8s-deploy.sh --environment local --namespace development
```

#### 2. Registry Deployment

```bash
# Deploy from registry
./scripts/k8s-deploy.sh --environment registry --registry myregistry.com --version 1.0.0

# Deploy to production namespace
./scripts/k8s-deploy.sh --environment registry --registry myregistry.com --version 1.0.0 --namespace production

# Dry run to see what would be deployed
./scripts/k8s-deploy.sh --dry-run --environment registry --registry myregistry.com --version 1.0.0
```

## Registry Configuration

### Docker Hub

```bash
# Login to Docker Hub
docker login

# Build and push
./docker-build.sh 1.0.0 docker.io/yourusername
./docker-push.sh 1.0.0 docker.io/yourusername

# Deploy
./scripts/k8s-deploy.sh --environment registry --registry docker.io/yourusername --version 1.0.0
```

### Google Container Registry (GCR)

```bash
# Configure authentication
gcloud auth configure-docker

# Build and push
./docker-build.sh 1.0.0 gcr.io/your-project
./docker-push.sh 1.0.0 gcr.io/your-project

# Create image pull secret
kubectl create secret docker-registry registry-secret \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat path/to/service-account-key.json)" \
  --docker-email=your-email@example.com

# Deploy
./scripts/k8s-deploy.sh --environment registry --registry gcr.io/your-project --version 1.0.0
```

### Amazon Elastic Container Registry (ECR)

```bash
# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Build and push
./docker-build.sh 1.0.0 123456789012.dkr.ecr.us-west-2.amazonaws.com
./docker-push.sh 1.0.0 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Create image pull secret
kubectl create secret docker-registry registry-secret \
  --docker-server=123456789012.dkr.ecr.us-west-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region us-west-2)" \
  --docker-email=your-email@example.com

# Deploy
./scripts/k8s-deploy.sh --environment registry --registry 123456789012.dkr.ecr.us-west-2.amazonaws.com --version 1.0.0
```

### Azure Container Registry (ACR)

```bash
# Login to ACR
az acr login --name myregistry

# Build and push
./docker-build.sh 1.0.0 myregistry.azurecr.io
./docker-push.sh 1.0.0 myregistry.azurecr.io

# Create image pull secret
kubectl create secret docker-registry registry-secret \
  --docker-server=myregistry.azurecr.io \
  --docker-username=service-principal-id \
  --docker-password=service-principal-password \
  --docker-email=your-email@example.com

# Deploy
./scripts/k8s-deploy.sh --environment registry --registry myregistry.azurecr.io --version 1.0.0
```

## Image Pull Secrets

For private registries, you need to create image pull secrets:

### Manual Creation

```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=<your-registry-server> \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email>
```

### Using Existing Docker Config

```bash
kubectl create secret generic registry-secret \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

## Kustomization Overlays

The project uses Kustomize overlays for different deployment scenarios:

### Local Development (`k8s/overlays/local/`)

- Uses local Docker images
- Reduced resource requirements
- Single replica
- Faster startup probes
- `imagePullPolicy: IfNotPresent`

### Registry Deployment (`k8s/overlays/registry/`)

- Uses registry images
- Production resource requirements
- Multiple replicas
- Production-ready probes
- `imagePullPolicy: Always`
- Image pull secrets enabled

## Troubleshooting

### Image Pull Errors

```bash
# Check image pull secrets
kubectl get secrets registry-secret -o yaml

# Check pod events
kubectl describe pod <pod-name>

# Check if image exists in registry
docker pull <registry>/<image>:<tag>
```

### Deployment Issues

```bash
# Check deployment status
kubectl rollout status deployment/java-springboot-app

# Check pod logs
kubectl logs -l app=java-springboot-app --tail=50

# Check service endpoints
kubectl get endpoints java-springboot-app
```

### Registry Authentication

```bash
# Test registry login
docker login <registry-server>

# Verify image push
docker images | grep <image-name>
docker push <registry>/<image>:<tag>
```

## Best Practices

### Image Tagging Strategy

1. **Semantic Versioning**: Use `v1.0.0`, `v1.1.0`, etc.
2. **Git SHA**: Include git commit SHA for traceability
3. **Environment Tags**: Use `dev`, `staging`, `prod` for environment-specific builds
4. **Latest Tag**: Always maintain a `latest` tag for development

### Security

1. **Use Image Pull Secrets**: Always use secrets for private registries
2. **Scan Images**: Regularly scan images for vulnerabilities
3. **Non-root User**: Run containers as non-root user (already configured)
4. **Minimal Base Images**: Use minimal base images to reduce attack surface

### Performance

1. **Multi-stage Builds**: Use multi-stage Dockerfiles for smaller images
2. **Layer Caching**: Optimize Dockerfile for better layer caching
3. **Resource Limits**: Set appropriate resource limits and requests
4. **Health Checks**: Configure proper health checks for faster recovery

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `docker-build.sh` | Build Docker images | `./docker-build.sh [version] [registry]` |
| `docker-push.sh` | Push images to registry | `./docker-push.sh [version] <registry>` |
| `scripts/version-manager.sh` | Manage application versions | `./scripts/version-manager.sh [command]` |
| `scripts/build-and-deploy.sh` | Complete build and deploy | `./scripts/build-and-deploy.sh [options]` |
| `scripts/k8s-deploy.sh` | Deploy to Kubernetes | `./scripts/k8s-deploy.sh [options]` |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VERSION` | Application version | From pom.xml |
| `REGISTRY` | Container registry URL | None |
| `NAMESPACE` | Kubernetes namespace | `default` |
| `APP_NAME` | Application name | `java-springboot-docker-k8s-example` |