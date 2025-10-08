package com.macode101.java_springboot_docker_k8s_example.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.UUID;

/**
 * Filter to generate and propagate correlation IDs for request tracing
 */
@Component
@Order(1)
public class CorrelationIdFilter implements Filter {

    public static final String CORRELATION_ID_HEADER = "X-Correlation-ID";
    public static final String CORRELATION_ID_MDC_KEY = "correlationId";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        try {
            // Get correlation ID from header or generate new one
            String correlationId = httpRequest.getHeader(CORRELATION_ID_HEADER);
            if (correlationId == null || correlationId.trim().isEmpty()) {
                correlationId = generateCorrelationId();
            }
            
            // Set correlation ID in MDC for logging
            MDC.put(CORRELATION_ID_MDC_KEY, correlationId);
            
            // Add correlation ID to response header
            httpResponse.setHeader(CORRELATION_ID_HEADER, correlationId);
            
            // Continue with the request
            chain.doFilter(request, response);
            
        } finally {
            // Clean up MDC to prevent memory leaks
            MDC.remove(CORRELATION_ID_MDC_KEY);
        }
    }
    
    private String generateCorrelationId() {
        return UUID.randomUUID().toString();
    }
}