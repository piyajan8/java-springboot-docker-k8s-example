package com.macode101.java_springboot_docker_k8s_example.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Component to validate application configuration at startup
 */
@Component
public class ConfigurationValidator {
    
    private static final Logger logger = LoggerFactory.getLogger(ConfigurationValidator.class);
    
    private final Environment environment;
    private final AppConfigProperties appConfig;
    
    public ConfigurationValidator(Environment environment, AppConfigProperties appConfig) {
        this.environment = environment;
        this.appConfig = appConfig;
    }
    
    /**
     * Validate configuration after application is ready
     */
    @EventListener(ApplicationReadyEvent.class)
    public void validateConfiguration() {
        logger.info("Starting configuration validation...");
        
        List<String> validationErrors = new ArrayList<>();
        
        // Validate required environment variables for production
        if (isProductionEnvironment()) {
            validateProductionConfiguration(validationErrors);
        }
        
        // Validate port configuration
        validatePortConfiguration(validationErrors);
        
        // Validate health check thresholds
        validateHealthConfiguration(validationErrors);
        
        // Validate external service configuration
        validateExternalServiceConfiguration(validationErrors);
        
        if (!validationErrors.isEmpty()) {
            String errorMessage = "Configuration validation failed:\n" + String.join("\n", validationErrors);
            logger.error(errorMessage);
            throw new ConfigurationValidationException(errorMessage);
        }
        
        logger.info("Configuration validation completed successfully");
    }
    
    private boolean isProductionEnvironment() {
        String[] activeProfiles = environment.getActiveProfiles();
        for (String profile : activeProfiles) {
            if ("prod".equals(profile) || "production".equals(profile) || "k8s".equals(profile)) {
                return true;
            }
        }
        return false;
    }
    
    private void validateProductionConfiguration(List<String> errors) {
        // In production, certain environment variables should be explicitly set
        if (environment.getProperty("SERVER_PORT") == null) {
            logger.warn("SERVER_PORT environment variable not set, using default");
        }
        
        if (environment.getProperty("MANAGEMENT_PORT") == null) {
            logger.warn("MANAGEMENT_PORT environment variable not set, using default");
        }
        
        if (environment.getProperty("LOG_LEVEL") == null) {
            logger.warn("LOG_LEVEL environment variable not set, using default");
        }
    }
    
    private void validatePortConfiguration(List<String> errors) {
        try {
            int serverPort = Integer.parseInt(environment.getProperty("server.port", "8080"));
            int managementPort = Integer.parseInt(environment.getProperty("management.server.port", "8080"));
            
            if (serverPort < 1 || serverPort > 65535) {
                errors.add("Server port must be between 1 and 65535, got: " + serverPort);
            }
            
            if (managementPort < 1 || managementPort > 65535) {
                errors.add("Management port must be between 1 and 65535, got: " + managementPort);
            }
            
        } catch (NumberFormatException e) {
            errors.add("Port configuration contains invalid numbers: " + e.getMessage());
        }
    }
    
    private void validateHealthConfiguration(List<String> errors) {
        int memoryThreshold = appConfig.health().memoryThreshold();
        int diskThreshold = appConfig.health().diskThreshold();
        
        if (memoryThreshold >= diskThreshold) {
            logger.warn("Memory threshold ({}) is higher than or equal to disk threshold ({}). " +
                       "This might cause unexpected behavior.", memoryThreshold, diskThreshold);
        }
    }
    
    private void validateExternalServiceConfiguration(List<String> errors) {
        int timeout = appConfig.externalService().timeout();
        int retryAttempts = appConfig.externalService().retryAttempts();
        
        // Calculate total potential wait time
        long totalWaitTime = (long) timeout * retryAttempts;
        if (totalWaitTime > 300000) { // 5 minutes
            logger.warn("Total potential wait time for external service calls is {}ms ({}s). " +
                       "Consider reducing timeout or retry attempts.", totalWaitTime, totalWaitTime / 1000);
        }
    }
}