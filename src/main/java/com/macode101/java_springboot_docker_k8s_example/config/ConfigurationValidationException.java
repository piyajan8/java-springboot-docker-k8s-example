package com.macode101.java_springboot_docker_k8s_example.config;

/**
 * Exception thrown when configuration validation fails
 */
public class ConfigurationValidationException extends RuntimeException {
    
    public ConfigurationValidationException(String message) {
        super(message);
    }
    
    public ConfigurationValidationException(String message, Throwable cause) {
        super(message, cause);
    }
}