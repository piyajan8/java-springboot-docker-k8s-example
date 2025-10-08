package com.macode101.java_springboot_docker_k8s_example.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * Main application configuration class
 */
@Configuration
@EnableConfigurationProperties(AppConfigProperties.class)
public class ApplicationConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(ApplicationConfig.class);
    
    private final Environment environment;
    private final AppConfigProperties appConfig;
    
    public ApplicationConfig(Environment environment, AppConfigProperties appConfig) {
        this.environment = environment;
        this.appConfig = appConfig;
        logConfigurationInfo();
    }
    
    /**
     * Log important configuration information at startup
     */
    private void logConfigurationInfo() {
        logger.info("Application Configuration:");
        logger.info("  Version: {}", appConfig.version());
        logger.info("  Environment: {}", appConfig.environment());
        logger.info("  Debug Enabled: {}", appConfig.debugEnabled());
        logger.info("  Active Profiles: {}", String.join(",", environment.getActiveProfiles()));
        logger.info("  Server Port: {}", environment.getProperty("server.port"));
        logger.info("  Management Port: {}", environment.getProperty("management.server.port"));
        logger.info("  Health Thresholds - Memory: {}%, Disk: {}%", 
                   appConfig.health().memoryThreshold(), 
                   appConfig.health().diskThreshold());
        logger.info("  External Service - Timeout: {}ms, Retry Attempts: {}", 
                   appConfig.externalService().timeout(), 
                   appConfig.externalService().retryAttempts());
    }
    

}
