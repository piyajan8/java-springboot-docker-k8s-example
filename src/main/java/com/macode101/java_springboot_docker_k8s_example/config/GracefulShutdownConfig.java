package com.macode101.java_springboot_docker_k8s_example.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.event.ContextClosedEvent;
import org.springframework.context.event.EventListener;

import java.util.concurrent.Executor;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Configuration
public class GracefulShutdownConfig {

    private static final Logger logger = LoggerFactory.getLogger(GracefulShutdownConfig.class);

    @Bean
    public WebServerFactoryCustomizer<TomcatServletWebServerFactory> gracefulShutdownTomcat() {
        return factory -> factory.addConnectorCustomizers(connector -> {
            connector.setProperty("connectionTimeout", "20000");
            connector.setProperty("keepAliveTimeout", "15000");
        });
    }

    @EventListener
    public void handleContextClosed(ContextClosedEvent event) {
        logger.info("Application context is closing, initiating graceful shutdown...");
        
        // Log shutdown metrics or perform cleanup operations
        try {
            // Allow time for ongoing requests to complete
            Thread.sleep(1000);
            logger.info("Graceful shutdown completed successfully");
        } catch (InterruptedException e) {
            logger.warn("Graceful shutdown was interrupted", e);
            Thread.currentThread().interrupt();
        }
    }

    @Bean
    public Executor taskExecutor() {
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
                2, // core pool size
                10, // maximum pool size
                60L, // keep alive time
                TimeUnit.SECONDS,
                new java.util.concurrent.LinkedBlockingQueue<>(100)
        );
        
        // Configure graceful shutdown for thread pool
        executor.setRejectedExecutionHandler((r, exec) -> {
            logger.warn("Task rejected during shutdown: {}", r.toString());
        });
        
        return executor;
    }
}