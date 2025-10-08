# Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Spring Boot application.

## Files

- `deployment.yaml` - Kubernetes Deployment with pod template, resource limits, and health probes
- `service.yaml` - ClusterIP Service for internal communication
- `configmap.yaml` - Application configuration data
- `secret.yaml` - Template for sensitive configuration data
- `kustomization.yaml` - Kustomize configuration for managing resources

## Deployment Instructions

### Prerequisites

1. Kubernetes cluster (local or remote)
2. kubectl configured to connect to your cluster
3. Docker image built and available (locally or in registry)

### Deploy to Kubernetes

1. **Update secrets** (if needed):
   ```bash
   # Edit secret.yaml and add your base64 encoded secrets
   echo -n "your-secret-value" | base64
   ```

2. **Deploy using kubectl**:
   ```bash
   kubectl apply -f k8s/
   ```

3. **Or deploy using kustomize**:
   ```bash
   kubectl apply -k k8s/
   ```

### Verify Deployment

```bash
# Check deployment status
kubectl get deployments

# Check pods
kubectl get pods -l app=java-springboot-app

# Check service
kubectl get services

# Check logs
kubectl logs -l app=java-springboot-app

# Port forward for testing
kubectl port-forward service/java-springboot-service 8080:8080
```

### Health Checks

The deployment includes three types of probes:

- **Startup Probe**: `/actuator/health` - Ensures container has started
- **Liveness Probe**: `/actuator/health/liveness` - Restarts unhealthy containers
- **Readiness Probe**: `/actuator/health/readiness` - Controls traffic routing

### Configuration

Application configuration is managed through:

- **ConfigMap** (`app-config`): Non-sensitive configuration
- **Secret** (`app-secrets`): Sensitive configuration (passwords, API keys)
- **Environment Variables**: Injected from ConfigMap and Secrets

### Scaling

```bash
# Scale deployment
kubectl scale deployment java-springboot-app --replicas=5

# Or edit the deployment
kubectl edit deployment java-springboot-app
```

### Cleanup

```bash
kubectl delete -f k8s/
# or
kubectl delete -k k8s/
```