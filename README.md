# Spring Boot Kubernetes Deployment Example

A production-ready Spring Boot application with Docker containerization and Kubernetes deployment capabilities. This project demonstrates cloud-native best practices including health checks, configuration management, observability, and automated deployment workflows.

## 🚀 Quick Start

### Local Development with Docker Compose
```bash
./scripts/local-docker-setup.sh
```

### Local Development with Kubernetes
```bash
./scripts/local-k8s-setup.sh
```

### Production Deployment
```bash
./scripts/build-and-deploy.sh --version 1.0.0 --registry myregistry.com --push --deploy
```

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Local Development](#local-development)
- [Container Registry Deployment](#container-registry-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Configuration Management](#configuration-management)
- [Monitoring and Observability](#monitoring-and-observability)
- [Troubleshooting](#troubleshooting)
- [Scripts Reference](#scripts-reference)

## Prerequisites

### Required Tools
- **Java 17+** - Application runtime
- **Maven 3.6+** - Build tool
- **Docker** - Container runtime
- **kubectl** - Kubernetes CLI

### Optional Tools
- **Docker Compose** - Local development
- **Minikube/kind** - Local Kubernetes
- **Kustomize** - Kubernetes configuration management

### Kubernetes Cluster Options
- **Local**: Minikube, kind, Docker Desktop
- **Cloud**: GKE, EKS, AKS, or any Kubernetes cluster

## Project Structure

```
├── src/                          # Spring Boot application source
├── k8s/                          # Kubernetes manifests
│   ├── base/                     # Base Kubernetes resources
│   ├── overlays/                 # Environment-specific overlays
│   │   ├── local/               # Local development
│   │   └── registry/            # Registry-based deployment
├── scripts/                      # Automation scripts
├── docs/                         # Additional documentation
├── Dockerfile                    # Multi-stage container build
├── docker-compose.yml           # Local development setup
└── pom.xml                      # Maven configuration
```

## Local Development

### Option 1: Docker Compose (Recommended for simple development)

**Automated Setup:**
```bash
./scripts/local-docker-setup.sh
```

**Manual Setup:**
```bash
# Build and start
docker-compose up --build -d

# View logs
docker-compose logs -f app

# Stop
docker-compose down
```

**Access Points:**
- Application: http://localhost:8080
- Health Check: http://localhost:8080/actuator/health
- Metrics: http://localhost:8080/actuator/metrics

### Option 2: Local Kubernetes (Recommended for K8s-specific development)

**Prerequisites:**
```bash
# Start your local cluster
minikube start
# OR
kind create cluster --name springboot-local
```

**Automated Setup:**
```bash
./scripts/local-k8s-setup.sh
```

**Manual Setup:**
```bash
# Build image
docker build -t java-springboot-docker-k8s-example:local .

# Load into cluster
minikube image load java-springboot-docker-k8s-example:local
# OR for kind
kind load docker-image java-springboot-docker-k8s-example:local --name springboot-local

# Deploy
kubectl apply -k k8s/local/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/java-springboot-app-local -n springboot-local
```

**Access Application:**
```bash
# Minikube
minikube service java-springboot-service-local -n springboot-local --url

# Port forwarding (any cluster)
kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080
```

## Container Registry Deployment

### Build and Push Images

**Using Scripts:**
```bash
# Build for registry
./docker-build.sh 1.0.0 myregistry.com

# Push to registry
./docker-push.sh 1.0.0 myregistry.com

# Complete workflow
./scripts/build-and-deploy.sh --version 1.0.0 --registry myregistry.com --push --deploy
```

**Manual Commands:**
```bash
# Build
docker build -t myregistry.com/java-springboot-docker-k8s-example:1.0.0 .

# Push
docker push myregistry.com/java-springboot-docker-k8s-example:1.0.0
```

### Registry-Specific Examples

**Docker Hub:**
```bash
docker login
./docker-build.sh 1.0.0 docker.io/yourusername
./docker-push.sh 1.0.0 docker.io/yourusername
```

**Google Container Registry:**
```bash
gcloud auth configure-docker
./docker-build.sh 1.0.0 gcr.io/your-project
./docker-push.sh 1.0.0 gcr.io/your-project
```

**Amazon ECR:**
```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com
./docker-build.sh 1.0.0 123456789012.dkr.ecr.us-west-2.amazonaws.com
./docker-push.sh 1.0.0 123456789012.dkr.ecr.us-west-2.amazonaws.com
```

## Kubernetes Deployment

### Using Deployment Scripts

**Local Deployment:**
```bash
./scripts/k8s-deploy.sh --environment local --version latest
```

**Registry Deployment:**
```bash
./scripts/k8s-deploy.sh --environment registry --registry myregistry.com --version 1.0.0 --namespace production
```

**Dry Run:**
```bash
./scripts/k8s-deploy.sh --dry-run --environment registry --registry myregistry.com --version 1.0.0
```

### Manual Deployment

**Base Deployment:**
```bash
kubectl apply -k k8s/
```

**Environment-Specific:**
```bash
# Local
kubectl apply -k k8s/overlays/local/

# Registry
kubectl apply -k k8s/overlays/registry/
```

### Image Pull Secrets (for private registries)

```bash
kubectl create secret docker-registry registry-secret \
  --docker-server=<your-registry-server> \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email>
```

## Configuration Management

### Environment Profiles

The application supports multiple configuration profiles:

- **`local`** - Local development with debug logging
- **`dev`** - Development environment
- **`prod`** - Production environment with optimized settings
- **`k8s`** - Kubernetes-specific configuration

### Configuration Sources

1. **Application Properties** - Base configuration
2. **ConfigMaps** - Environment-specific settings
3. **Secrets** - Sensitive data (passwords, API keys)
4. **Environment Variables** - Runtime overrides

### Key Configuration Options

```yaml
# Server Configuration
server:
  port: 8080
  shutdown: graceful

# Actuator Configuration
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,info
  endpoint:
    health:
      show-details: always

# Logging Configuration
logging:
  level:
    com.macode101: INFO
  pattern:
    console: '%d{yyyy-MM-dd HH:mm:ss} - %msg%n'
```

## Monitoring and Observability

### Health Checks

The application provides comprehensive health checks:

- **Startup Probe**: `/actuator/health` - Container initialization
- **Liveness Probe**: `/actuator/health/liveness` - Container restart decisions
- **Readiness Probe**: `/actuator/health/readiness` - Traffic routing decisions

### Metrics and Monitoring

**Available Endpoints:**
- `/actuator/health` - Application health status
- `/actuator/metrics` - Application metrics
- `/actuator/info` - Application information
- `/actuator/prometheus` - Prometheus-formatted metrics

**Custom Metrics:**
- Request counters and timers
- Business logic metrics
- JVM and system metrics

### Logging

**Features:**
- Structured JSON logging
- Correlation ID tracking
- Request/response logging
- Error tracking and alerting

**Log Levels:**
- `ERROR` - Error conditions
- `WARN` - Warning conditions
- `INFO` - Informational messages
- `DEBUG` - Debug information (dev/local only)

## Troubleshooting

### Common Issues

#### Application Won't Start

**Symptoms:**
- Container exits immediately
- Health checks fail
- Pods in CrashLoopBackOff

**Solutions:**
```bash
# Check application logs
kubectl logs -l app=java-springboot-app --tail=50

# Check pod events
kubectl describe pod <pod-name>

# Verify configuration
kubectl get configmap app-config -o yaml
kubectl get secret app-secrets -o yaml
```

#### Image Pull Errors

**Symptoms:**
- `ImagePullBackOff` or `ErrImagePull` status
- Cannot pull image from registry

**Solutions:**
```bash
# Verify image exists
docker pull <registry>/<image>:<tag>

# Check image pull secrets
kubectl get secrets registry-secret -o yaml

# Verify registry authentication
docker login <registry-server>
```

#### Service Discovery Issues

**Symptoms:**
- Cannot reach other services
- DNS resolution failures
- Connection timeouts

**Solutions:**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>

# Check network policies
kubectl get networkpolicies
```

#### Resource Constraints

**Symptoms:**
- Pods pending or evicted
- Out of memory errors
- CPU throttling

**Solutions:**
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Review resource requests/limits
kubectl describe pod <pod-name>

# Check cluster capacity
kubectl describe nodes
```

### Debugging Commands

**Application Debugging:**
```bash
# Port forward for local access
kubectl port-forward service/java-springboot-app 8080:8080

# Execute commands in pod
kubectl exec -it <pod-name> -- bash

# View detailed pod information
kubectl describe pod <pod-name>
```

**Cluster Debugging:**
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# View all resources
kubectl get all -A

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

### Performance Tuning

**JVM Tuning:**
```bash
# Container-optimized JVM settings (already configured)
-XX:+UseContainerSupport
-XX:MaxRAMPercentage=75.0
-XX:+UseG1GC
-XX:+UseStringDeduplication
```

**Kubernetes Resource Tuning:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `docker-build.sh` | Build Docker images | `./docker-build.sh [version] [registry]` |
| `docker-push.sh` | Push images to registry | `./docker-push.sh [version] <registry>` |
| `scripts/local-docker-setup.sh` | Local Docker setup | `./scripts/local-docker-setup.sh` |
| `scripts/local-k8s-setup.sh` | Local Kubernetes setup | `./scripts/local-k8s-setup.sh` |
| `scripts/build-and-deploy.sh` | Complete build/deploy workflow | `./scripts/build-and-deploy.sh [options]` |
| `scripts/k8s-deploy.sh` | Kubernetes deployment | `./scripts/k8s-deploy.sh [options]` |
| `scripts/version-manager.sh` | Version management | `./scripts/version-manager.sh [command]` |

### Script Options

**build-and-deploy.sh:**
- `--version VERSION` - Specify version
- `--registry REGISTRY` - Container registry URL
- `--push` - Push to registry
- `--deploy` - Deploy to Kubernetes
- `--local` - Local development only

**k8s-deploy.sh:**
- `--environment ENV` - Deployment environment (local|registry)
- `--registry REGISTRY` - Container registry URL
- `--version VERSION` - Image version
- `--namespace NS` - Kubernetes namespace
- `--dry-run` - Show what would be deployed

## Additional Documentation

- [Docker Configuration](DOCKER.md) - Detailed Docker setup and configuration
- [Local Development](LOCAL_DEVELOPMENT.md) - Comprehensive local development guide
- [Registry Deployment](docs/REGISTRY_DEPLOYMENT.md) - Container registry integration
- [Configuration Management](docs/CONFIGURATION.md) - Application configuration details
- [Logging and Monitoring](docs/LOGGING_AND_MONITORING.md) - Observability setup
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Quick Reference](docs/QUICK_REFERENCE.md) - Quick commands for common tasks

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally using the provided scripts
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the logs using the provided commands
3. Open an issue with detailed information about your environment and the problem