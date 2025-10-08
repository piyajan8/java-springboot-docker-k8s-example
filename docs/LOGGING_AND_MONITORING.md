# Logging and Monitoring Enhancements

This document describes the logging and monitoring enhancements implemented for the Spring Boot application.

## Features Implemented

### 1. Structured JSON Logging

- **Development Mode**: Human-readable console logging with correlation IDs
- **Production/Kubernetes Mode**: Structured JSON logging for log aggregation systems
- **Configuration**: Automatic profile-based switching via `logback-spring.xml`

#### JSON Log Format
```json
{
  "@timestamp": "2025-10-05T04:36:31.683325Z",
  "@version": "1",
  "level": "INFO",
  "message": "Hello endpoint called with correlation ID: b8c00e18-453d-460d-9819-7f7e25bf5c54",
  "correlationId": "b8c00e18-453d-460d-9819-7f7e25bf5c54",
  "application": "java-springboot-docker-k8s-example",
  "environment": "development",
  "version": "unknown",
  "thread": "http-nio-8082-exec-1",
  "logger": "com.macode101.java_springboot_docker_k8s_example.controller.HelloWorld"
}
```

### 2. Request Correlation ID Generation and Propagation

- **Automatic Generation**: UUID-based correlation IDs for each request
- **Header Support**: Accepts existing `X-Correlation-ID` header or generates new one
- **Response Headers**: Returns correlation ID in response headers
- **MDC Integration**: Available in all log messages within request context
- **Utility Class**: `CorrelationIdUtil` for programmatic access

#### Usage Example
```java
String correlationId = CorrelationIdUtil.getCurrentCorrelationId();
logger.info("Processing request with correlation ID: {}", correlationId);
```

### 3. Custom Metrics for Business Logic Monitoring

#### Endpoint Metrics
- **Request Counters**: Track requests per endpoint
- **Response Times**: Measure endpoint performance
- **Active Requests**: Monitor concurrent request load
- **Error Counters**: Track errors by type and endpoint

#### Business Metrics
- **Custom Events**: Track business-specific events
- **Custom Gauges**: Monitor business metrics
- **Custom Timers**: Measure business operation duration
- **Memory Usage**: Track application memory consumption

#### Available Metrics
- `app.endpoint.hello.requests` - Hello endpoint request count
- `app.endpoint.config.requests` - Config endpoint request count  
- `app.endpoint.health.requests` - Health endpoint request count
- `app.endpoint.*.duration` - Endpoint response times
- `app.requests.active` - Active request count
- `app.memory.usage.bytes` - Current memory usage
- `app.errors.total` - Total error count by type
- `app.business.events` - Custom business events
- `app.business.metrics.*` - Custom business metrics
- `app.business.timers.*` - Custom business timers

## Configuration

### Application Properties

#### Development Mode
```properties
logging.level.com.macode101=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level [%X{correlationId:-}] %logger{36} - %msg%n
```

#### Production/Kubernetes Mode
```properties
logging.level.com.macode101=INFO
# JSON logging configured via logback-spring.xml
```

#### Metrics Configuration
```properties
management.metrics.tags.application=${spring.application.name}
management.metrics.tags.environment=${app.environment}
management.metrics.tags.version=${app.version}
```

### Dependencies Added

```xml
<!-- JSON logging support -->
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.4</version>
</dependency>

<!-- Micrometer for custom metrics -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

## Components

### 1. CorrelationIdFilter
- Servlet filter that generates/extracts correlation IDs
- Sets correlation ID in MDC for logging
- Adds correlation ID to response headers

### 2. MetricsService
- Centralized service for managing custom metrics
- Provides methods for counters, timers, and gauges
- Supports business-specific metric recording

### 3. MetricsConfig
- Configuration for meter registry customization
- Common tags for all metrics
- Environment-specific metric configuration

### 4. Enhanced Controllers
- All controllers now include correlation ID logging
- Metrics tracking for request counts and response times
- Business event recording for monitoring

## Testing

### Test Correlation ID
```bash
curl -H "X-Correlation-ID: test-123" http://localhost:8080/hello
```

### View Metrics (when actuator is properly configured)
```bash
curl http://localhost:8080/actuator/metrics
curl http://localhost:8080/actuator/metrics/app.endpoint.hello.requests
```

### Test JSON Logging
```bash
# Start with production profile
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=prod"

# Make requests and observe JSON log output
curl http://localhost:8080/hello
```

## Monitoring Integration

### Prometheus
- Metrics are automatically exposed in Prometheus format
- Custom business metrics included
- Common tags applied to all metrics

### Log Aggregation
- JSON logs are ready for ELK stack, Fluentd, or similar
- Correlation IDs enable request tracing across services
- Structured format enables easy parsing and filtering

### Alerting
- Error counters can trigger alerts
- Response time metrics for SLA monitoring
- Memory usage monitoring for resource alerts

## Best Practices

1. **Always use correlation IDs** in log messages for request tracing
2. **Record business events** using MetricsService for monitoring
3. **Use structured logging** in production environments
4. **Monitor custom metrics** for business-specific insights
5. **Set up alerts** on error counters and response times