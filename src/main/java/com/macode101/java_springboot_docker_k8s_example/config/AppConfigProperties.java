package com.macode101.java_springboot_docker_k8s_example.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Configuration properties for the application with validation
 */
@ConfigurationProperties(prefix = "app")
@Validated
public record AppConfigProperties(
    @NotBlank(message = "Application version cannot be blank")
    String version,
    
    @NotBlank(message = "Application environment cannot be blank")
    String environment,
    
    @NotNull(message = "Debug enabled flag cannot be null")
    Boolean debugEnabled,
    
    @Valid
    @NotNull(message = "Health configuration cannot be null")
    HealthConfig health,
    
    @Valid
    @NotNull(message = "External service configuration cannot be null")
    ExternalServiceConfig externalService
) {
    
    /**
     * Health check configuration
     */
    public record HealthConfig(
        @Min(value = 50, message = "Memory threshold must be at least 50%")
        @Max(value = 95, message = "Memory threshold must be at most 95%")
        int memoryThreshold,
        
        @Min(value = 50, message = "Disk threshold must be at least 50%")
        @Max(value = 95, message = "Disk threshold must be at most 95%")
        int diskThreshold
    ) {}
    
    /**
     * External service configuration
     */
    public record ExternalServiceConfig(
        @Min(value = 1000, message = "Service timeout must be at least 1000ms")
        @Max(value = 60000, message = "Service timeout must be at most 60000ms")
        int timeout,
        
        @Min(value = 1, message = "Retry attempts must be at least 1")
        @Max(value = 10, message = "Retry attempts must be at most 10")
        int retryAttempts
    ) {}
}
