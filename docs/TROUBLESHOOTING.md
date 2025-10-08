# Troubleshooting Guide

This guide provides solutions for common issues encountered when deploying and running the Spring Boot application with Docker and Kubernetes.

## 🚨 Common Issues

### Application Startup Issues

#### Issue: Application Won't Start

**Symptoms:**
- Container exits immediately with non-zero exit code
- Health checks fail continuously
- Pods stuck in `CrashLoopBackOff` state

**Diagnostic Commands:**
```bash
# Check application logs
kubectl logs -l app=java-springboot-app --tail=50

# Check pod events
kubectl describe pod <pod-name>

# Check container status
docker ps -a
docker logs <container-name>
```

**Common Causes & Solutions:**

1. **Configuration Issues**
   ```bash
   # Verify ConfigMap
   kubectl get configmap app-config -o yaml
   
   # Check environment variables
   kubectl exec <pod-name> -- env | grep -E "(SPRING|SERVER|MANAGEMENT)"
   ```

2. **Port Conflicts**
   ```bash
   # Check if port is already in use
   netstat -tulpn | grep :8080
   lsof -i :8080
   ```

3. **Memory Issues**
   ```bash
   # Check memory limits
   kubectl describe pod <pod-name> | grep -A 5 "Limits"
   
   # Monitor memory usage
   kubectl top pod <pod-name>
   ```

#### Issue: Slow Application Startup

**Symptoms:**
- Application takes longer than expected to start
- Startup probes timing out
- Readiness probes failing initially

**Solutions:**

1. **Adjust Probe Timings**
   ```yaml
   startupProbe:
     initialDelaySeconds: 60  # Increase for slow startup
     periodSeconds: 10
     timeoutSeconds: 5
     failureThreshold: 6
   ```

2. **JVM Optimization**
   ```bash
   # Add JVM flags for faster startup
   -XX:+TieredCompilation
   -XX:TieredStopAtLevel=1
   -Djava.security.egd=file:/dev/./urandom
   ```

### Container and Image Issues

#### Issue: Image Pull Errors

**Symptoms:**
- Pods stuck in `ImagePullBackOff` or `ErrImagePull`
- Cannot pull image from registry

**Diagnostic Commands:**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Verify image exists
docker pull <registry>/<image>:<tag>

# Check image pull secrets
kubectl get secrets registry-secret -o yaml
```

**Solutions:**

1. **Registry Authentication**
   ```bash
   # Create image pull secret
   kubectl create secret docker-registry registry-secret \
     --docker-server=<registry-server> \
     --docker-username=<username> \
     --docker-password=<password> \
     --docker-email=<email>
   
   # Verify secret
   kubectl get secret registry-secret -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
   ```

2. **Image Availability**
   ```bash
   # List available tags
   docker images | grep java-springboot-docker-k8s-example
   
   # Check registry
   curl -X GET https://<registry>/v2/<image>/tags/list
   ```

3. **Network Issues**
   ```bash
   # Test registry connectivity
   telnet <registry-server> 443
   
   # Check DNS resolution
   nslookup <registry-server>
   ```

#### Issue: Image Build Failures

**Symptoms:**
- Docker build fails with errors
- Maven build issues during image creation
- Out of space errors

**Solutions:**

1. **Build Context Issues**
   ```bash
   # Clean build context
   docker system prune -f
   
   # Check .dockerignore
   cat .dockerignore
   ```

2. **Maven Build Issues**
   ```bash
   # Test Maven build locally
   mvn clean package -DskipTests
   
   # Check Maven settings
   mvn help:effective-settings
   ```

3. **Disk Space**
   ```bash
   # Check disk usage
   df -h
   
   # Clean Docker system
   docker system prune -a -f
   ```

### Kubernetes Deployment Issues

#### Issue: Service Discovery Problems

**Symptoms:**
- Cannot reach other services
- DNS resolution failures
- Connection timeouts between services

**Diagnostic Commands:**
```bash
# Check service endpoints
kubectl get endpoints <service-name>

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup <service-name>

# Check service configuration
kubectl describe service <service-name>
```

**Solutions:**

1. **Service Configuration**
   ```yaml
   # Verify service selector matches pod labels
   selector:
     app: java-springboot-app
   ```

2. **Network Policies**
   ```bash
   # Check network policies
   kubectl get networkpolicies
   
   # Describe network policy
   kubectl describe networkpolicy <policy-name>
   ```

3. **DNS Issues**
   ```bash
   # Check CoreDNS
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   
   # Test DNS from pod
   kubectl exec -it <pod-name> -- nslookup kubernetes.default.svc.cluster.local
   ```

#### Issue: Resource Constraints

**Symptoms:**
- Pods pending or evicted
- Out of memory (OOMKilled) errors
- CPU throttling

**Diagnostic Commands:**
```bash
# Check resource usage
kubectl top pods
kubectl top nodes

# Check pod resource requests/limits
kubectl describe pod <pod-name>

# Check node capacity
kubectl describe nodes
```

**Solutions:**

1. **Adjust Resource Limits**
   ```yaml
   resources:
     requests:
       memory: "512Mi"  # Increase memory request
       cpu: "500m"      # Increase CPU request
     limits:
       memory: "1Gi"    # Increase memory limit
       cpu: "1000m"     # Increase CPU limit
   ```

2. **Node Resources**
   ```bash
   # Check node allocatable resources
   kubectl describe node <node-name>
   
   # Check resource quotas
   kubectl describe resourcequota
   ```

### Health Check Issues

#### Issue: Health Checks Failing

**Symptoms:**
- Liveness probes failing, causing pod restarts
- Readiness probes failing, preventing traffic routing
- Health endpoint returning unhealthy status

**Diagnostic Commands:**
```bash
# Test health endpoint directly
kubectl port-forward <pod-name> 8080:8080
curl http://localhost:8080/actuator/health

# Check probe configuration
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness\|Startup"
```

**Solutions:**

1. **Probe Configuration**
   ```yaml
   livenessProbe:
     httpGet:
       path: /actuator/health/liveness
       port: 8080
     initialDelaySeconds: 60
     periodSeconds: 30
     timeoutSeconds: 10
     failureThreshold: 3
   ```

2. **Health Indicator Issues**
   ```bash
   # Check specific health indicators
   curl http://localhost:8080/actuator/health/db
   curl http://localhost:8080/actuator/health/diskSpace
   ```

### Configuration Issues

#### Issue: Configuration Not Loading

**Symptoms:**
- Application using default values instead of configured ones
- ConfigMap or Secret changes not reflected
- Environment variables not set

**Diagnostic Commands:**
```bash
# Check ConfigMap
kubectl get configmap app-config -o yaml

# Check Secret
kubectl get secret app-secrets -o yaml

# Check environment variables in pod
kubectl exec <pod-name> -- env | sort
```

**Solutions:**

1. **ConfigMap Issues**
   ```bash
   # Restart deployment to pick up ConfigMap changes
   kubectl rollout restart deployment/java-springboot-app
   
   # Verify ConfigMap mounting
   kubectl exec <pod-name> -- ls -la /app/config/
   ```

2. **Secret Issues**
   ```bash
   # Check secret data encoding
   kubectl get secret app-secrets -o jsonpath='{.data}' | base64 -d
   
   # Verify secret mounting
   kubectl exec <pod-name> -- ls -la /app/secrets/
   ```

### Performance Issues

#### Issue: High Memory Usage

**Symptoms:**
- Pods being OOMKilled
- High memory consumption
- Garbage collection issues

**Diagnostic Commands:**
```bash
# Check memory usage
kubectl top pod <pod-name>

# Check JVM memory settings
kubectl exec <pod-name> -- java -XX:+PrintFlagsFinal -version | grep -i heap
```

**Solutions:**

1. **JVM Tuning**
   ```bash
   # Optimize heap settings
   -XX:MaxRAMPercentage=75.0
   -XX:+UseG1GC
   -XX:+UseStringDeduplication
   ```

2. **Memory Profiling**
   ```bash
   # Enable JFR for profiling
   -XX:+FlightRecorder
   -XX:StartFlightRecording=duration=60s,filename=app.jfr
   ```

#### Issue: High CPU Usage

**Symptoms:**
- CPU throttling
- Slow response times
- High CPU utilization

**Solutions:**

1. **CPU Optimization**
   ```yaml
   resources:
     requests:
       cpu: "1000m"  # Increase CPU request
     limits:
       cpu: "2000m"  # Increase CPU limit
   ```

2. **JVM Optimization**
   ```bash
   # Optimize for CPU
   -XX:+UseG1GC
   -XX:MaxGCPauseMillis=200
   ```

## 🔧 Debugging Tools and Commands

### Application Debugging

**Port Forwarding:**
```bash
# Forward application port
kubectl port-forward service/java-springboot-app 8080:8080

# Forward management port (if different)
kubectl port-forward service/java-springboot-app 8081:8081
```

**Log Analysis:**
```bash
# Follow logs
kubectl logs -f deployment/java-springboot-app

# Get logs from all pods
kubectl logs -l app=java-springboot-app --tail=100

# Get previous container logs
kubectl logs <pod-name> --previous
```

**Interactive Debugging:**
```bash
# Execute shell in pod
kubectl exec -it <pod-name> -- /bin/bash

# Run debug commands
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- netstat -tulpn
kubectl exec <pod-name> -- df -h
```

### Cluster Debugging

**Cluster Information:**
```bash
# Cluster info
kubectl cluster-info
kubectl cluster-info dump

# Node information
kubectl get nodes -o wide
kubectl describe node <node-name>
```

**Resource Monitoring:**
```bash
# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events --field-selector type=Warning
```

**Network Debugging:**
```bash
# Test connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# DNS testing
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Network policies
kubectl get networkpolicies --all-namespaces
```

### Docker Debugging

**Container Inspection:**
```bash
# Inspect container
docker inspect <container-name>

# Container logs
docker logs <container-name> --tail=50 --follow

# Execute in container
docker exec -it <container-name> /bin/bash
```

**Image Analysis:**
```bash
# Image history
docker history <image-name>

# Image layers
docker inspect <image-name> | jq '.[0].RootFS.Layers'

# Image size analysis
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

## 📊 Monitoring and Alerting

### Key Metrics to Monitor

**Application Metrics:**
- Response time and throughput
- Error rates
- JVM memory and GC metrics
- Thread pool utilization

**Infrastructure Metrics:**
- CPU and memory usage
- Disk I/O and network traffic
- Pod restart frequency
- Node resource utilization

### Health Check Endpoints

```bash
# Application health
curl http://localhost:8080/actuator/health

# Detailed health information
curl http://localhost:8080/actuator/health | jq '.'

# Specific health indicators
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness
```

### Log Analysis

**Common Log Patterns:**
```bash
# Error patterns
kubectl logs -l app=java-springboot-app | grep -i error

# Performance issues
kubectl logs -l app=java-springboot-app | grep -i "slow\|timeout\|gc"

# Configuration issues
kubectl logs -l app=java-springboot-app | grep -i "config\|property"
```

## 🆘 Emergency Procedures

### Application Recovery

**Quick Recovery Steps:**
```bash
# 1. Restart deployment
kubectl rollout restart deployment/java-springboot-app

# 2. Scale down and up
kubectl scale deployment java-springboot-app --replicas=0
kubectl scale deployment java-springboot-app --replicas=3

# 3. Rollback to previous version
kubectl rollout undo deployment/java-springboot-app
```

### Data Recovery

**Configuration Backup:**
```bash
# Backup ConfigMaps and Secrets
kubectl get configmap app-config -o yaml > app-config-backup.yaml
kubectl get secret app-secrets -o yaml > app-secrets-backup.yaml
```

### Incident Response

**Information Gathering:**
```bash
# Collect diagnostic information
kubectl get all -o wide > cluster-state.txt
kubectl describe deployment java-springboot-app > deployment-details.txt
kubectl logs -l app=java-springboot-app --tail=1000 > application-logs.txt
```

## 📞 Getting Help

### Before Seeking Help

1. **Check this troubleshooting guide**
2. **Review application logs**
3. **Verify configuration**
4. **Test with minimal setup**

### Information to Provide

When reporting issues, include:

- **Environment details** (Kubernetes version, cluster type)
- **Application version** and configuration
- **Error messages** and logs
- **Steps to reproduce** the issue
- **Expected vs actual behavior**

### Useful Commands for Issue Reports

```bash
# Environment information
kubectl version
docker version
java -version

# Application state
kubectl get all -l app=java-springboot-app
kubectl describe deployment java-springboot-app
kubectl logs -l app=java-springboot-app --tail=50
```