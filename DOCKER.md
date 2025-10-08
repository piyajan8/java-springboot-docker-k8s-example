# Docker Configuration

This document describes the Docker containerization setup for the Spring Boot application.

## Dockerfile Features

### Multi-Stage Build
- **Build Stage**: Uses `maven:3.9.6-eclipse-temurin-17` for compiling the application
- **Runtime Stage**: Uses `eclipse-temurin:17-jre` for running the application
- Optimized layer caching by copying dependencies first

### Security Features
- **Non-root User**: Application runs as `appuser` (UID 1001) for security
- **Minimal Runtime**: Uses JRE-only base image to reduce attack surface
- **Signal Handling**: Uses `dumb-init` for proper signal handling

### Optimization Features
- **Layer Caching**: Dependencies are downloaded in a separate layer for better caching
- **JVM Tuning**: Container-optimized JVM settings:
  - `UseContainerSupport`: Enables container-aware JVM
  - `MaxRAMPercentage=75.0`: Limits heap to 75% of container memory
  - `UseG1GC`: Uses G1 garbage collector for better performance
  - `UseStringDeduplication`: Reduces memory usage

### Health Check
- **Built-in Health Check**: Docker health check using Spring Boot Actuator
- **Configuration**: 30s interval, 3s timeout, 60s start period, 3 retries
- **Endpoint**: `/actuator/health`

## Building the Image

### Using the build script:
```bash
./docker-build.sh [tag]
```

### Manual build:
```bash
docker build -t spring-boot-k8s-app:latest .
```

## Running the Container

### Basic run:
```bash
docker run -p 8080:8080 spring-boot-k8s-app:latest
```

### With environment variables:
```bash
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SERVER_PORT=8080 \
  spring-boot-k8s-app:latest
```

### With health check monitoring:
```bash
docker run -d --name spring-app -p 8080:8080 spring-boot-k8s-app:latest
docker ps  # Check health status
```

## Testing the Container

### Health Check:
```bash
curl http://localhost:8080/actuator/health
```

### Application Endpoints:
```bash
curl http://localhost:8080/hello
curl http://localhost:8080/config
```

## Image Details

- **Base Images**: 
  - Build: `maven:3.9.6-eclipse-temurin-17`
  - Runtime: `eclipse-temurin:17-jre`
- **User**: `appuser` (UID 1001)
- **Working Directory**: `/app`
- **Exposed Port**: `8080`
- **Health Check**: Enabled with Spring Boot Actuator

## .dockerignore

The `.dockerignore` file excludes unnecessary files from the build context:
- Target directory (except JAR files)
- IDE files
- Documentation
- Git files
- Temporary files

This reduces build context size and improves build performance.