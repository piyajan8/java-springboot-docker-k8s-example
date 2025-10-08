package com.macode101.java_springboot_docker_k8s_example.util;

import org.slf4j.MDC;

/**
 * Utility class for working with correlation IDs
 */
public class CorrelationIdUtil {
    
    private static final String CORRELATION_ID_MDC_KEY = "correlationId";
    
    /**
     * Get the current correlation ID from MDC
     * @return correlation ID or null if not set
     */
    public static String getCurrentCorrelationId() {
        return MDC.get(CORRELATION_ID_MDC_KEY);
    }
    
    /**
     * Set correlation ID in MDC
     * @param correlationId the correlation ID to set
     */
    public static void setCorrelationId(String correlationId) {
        if (correlationId != null && !correlationId.trim().isEmpty()) {
            MDC.put(CORRELATION_ID_MDC_KEY, correlationId);
        }
    }
    
    /**
     * Clear correlation ID from MDC
     */
    public static void clearCorrelationId() {
        MDC.remove(CORRELATION_ID_MDC_KEY);
    }
}