# Local Development Setup

This document provides instructions for setting up and running the Spring Boot application in a local development environment using Docker and Kubernetes.

## Prerequisites

### For Docker Development
- Docker Desktop or Docker Engine
- Docker Compose

### For Kubernetes Development
- Docker Desktop or Docker Engine
- One of the following:
  - [Minikube](https://minikube.sigs.k8s.io/docs/start/)
  - [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
  - Docker Desktop with Kubernetes enabled
- kubectl

## Quick Start

### Option 1: Docker Compose (Recommended for simple development)

1. **Automated Setup**
   ```bash
   ./scripts/local-docker-setup.sh
   ```

2. **Manual Setup**
   ```bash
   # Build and start the application
   docker-compose up --build -d
   
   # View logs
   docker-compose logs -f app
   
   # Stop the application
   docker-compose down
   ```

### Option 2: Local Kubernetes (Recommended for Kubernetes-specific development)

1. **Start your local Kubernetes cluster**
   
   For Minikube:
   ```bash
   minikube start
   ```
   
   For kind:
   ```bash
   kind create cluster --name springboot-local
   ```

2. **Automated Setup**
   ```bash
   ./scripts/local-k8s-setup.sh
   ```

3. **Manual Setup**
   ```bash
   # Build the Docker image
   docker build -t java-springboot-docker-k8s-example:local .
   
   # Load image into cluster (minikube)
   minikube image load java-springboot-docker-k8s-example:local
   
   # Or for kind
   kind load docker-image java-springboot-docker-k8s-example:local --name springboot-local
   
   # Apply Kubernetes manifests
   kubectl apply -k k8s/local/
   
   # Wait for deployment
   kubectl wait --for=condition=available --timeout=300s deployment/java-springboot-app-local -n springboot-local
   ```

## Accessing the Application

### Docker Compose
- Application: http://localhost:8080
- Health Check: http://localhost:8080/actuator/health
- All Actuator Endpoints: http://localhost:8080/actuator

### Kubernetes

#### Minikube
```bash
# Get service URL
minikube service java-springboot-service-local -n springboot-local --url

# Or use port forwarding
kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080
```

#### kind or Docker Desktop
```bash
# Use port forwarding
kubectl port-forward -n springboot-local service/java-springboot-service-local 8080:8080

# Or access via NodePort (if available)
# The service is configured with NodePort 30080
```

## Configuration Profiles

The application uses different configuration profiles for local development:

- **`dev`**: Basic development profile (application-dev.properties)
- **`local`**: Enhanced local development profile (application-local.properties)

### Key differences in local configuration:
- More verbose logging (DEBUG level)
- All actuator endpoints exposed
- Relaxed health check thresholds
- Shorter timeouts for faster feedback
- JMX enabled for monitoring

## Development Workflow

### Making Code Changes

#### Docker Compose
```bash
# Rebuild and restart after code changes
docker-compose up --build -d

# Or restart just the app service
docker-compose restart app
```

#### Kubernetes
```bash
# Rebuild image
docker build -t java-springboot-docker-k8s-example:local .

# Reload image into cluster
minikube image load java-springboot-docker-k8s-example:local  # for minikube
# or
kind load docker-image java-springboot-docker-k8s-example:local --name springboot-local  # for kind

# Restart deployment
kubectl rollout restart deployment/java-springboot-app-local -n springboot-local
```

### Viewing Logs

#### Docker Compose
```bash
# View all logs
docker-compose logs -f

# View only app logs
docker-compose logs -f app
```

#### Kubernetes
```bash
# View deployment logs
kubectl logs -f deployment/java-springboot-app-local -n springboot-local

# View specific pod logs
kubectl logs -f <pod-name> -n springboot-local
```

## Troubleshooting

### Common Issues

1. **Application not starting**
   - Check logs for errors
   - Verify Docker is running
   - Ensure ports are not in use

2. **Image not found in Kubernetes**
   - Make sure to load the image into your cluster
   - Verify image name and tag match

3. **Health checks failing**
   - Check if application is fully started
   - Verify actuator endpoints are accessible
   - Review application logs for startup errors

### Useful Commands

#### Docker Compose
```bash
# View running containers
docker-compose ps

# Execute commands in container
docker-compose exec app bash

# View container resource usage
docker stats
```

#### Kubernetes
```bash
# View all resources in namespace
kubectl get all -n springboot-local

# Describe deployment
kubectl describe deployment java-springboot-app-local -n springboot-local

# Get pod details
kubectl get pods -n springboot-local -o wide

# Execute commands in pod
kubectl exec -it <pod-name> -n springboot-local -- bash

# View events
kubectl get events -n springboot-local --sort-by='.lastTimestamp'
```

## Cleanup

### Docker Compose
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (if any)
docker-compose down -v

# Remove images
docker rmi java-springboot-docker-k8s-example:local
```

### Kubernetes
```bash
# Delete all resources
kubectl delete -k k8s/local/

# Or delete namespace (removes everything)
kubectl delete namespace springboot-local
```

## Configuration Files

### Local Development Files
- `docker-compose.yml` - Docker Compose configuration
- `k8s/local/` - Local Kubernetes manifests
- `src/main/resources/application-local.properties` - Local development properties
- `scripts/local-docker-setup.sh` - Docker setup automation
- `scripts/local-k8s-setup.sh` - Kubernetes setup automation

### Key Configuration Differences
- **Resource limits**: Lower limits for local development
- **Replica count**: Single replica for local testing
- **Service type**: NodePort for easy access
- **Image pull policy**: IfNotPresent to use local images
- **Probes**: Faster intervals for quicker feedback

## Next Steps

After setting up your local environment:

1. Make code changes and test locally
2. Run integration tests
3. Test Kubernetes-specific features
4. Prepare for production deployment

For production deployment, refer to the main deployment documentation and use the production Kubernetes manifests in the `k8s/` directory.