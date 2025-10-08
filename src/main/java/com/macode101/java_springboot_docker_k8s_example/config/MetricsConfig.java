package com.macode101.java_springboot_docker_k8s_example.config;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.config.MeterFilter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.autoconfigure.metrics.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for custom metrics and monitoring
 */
@Configuration
public class MetricsConfig {

    @Value("${spring.application.name}")
    private String applicationName;

    @Value("${app.environment:development}")
    private String environment;

    @Value("${app.version:unknown}")
    private String version;

    /**
     * Customize the meter registry with common tags
     */
    @Bean
    public MeterRegistryCustomizer<MeterRegistry> metricsCommonTags() {
        return registry -> registry.config()
                .commonTags(
                        "application", applicationName,
                        "environment", environment,
                        "version", version
                )
                .meterFilter(MeterFilter.deny(id -> {
                    // Filter out some noisy metrics if needed
                    String name = id.getName();
                    return name.startsWith("jvm.gc.pause") && name.contains("unknown");
                }));
    }

    /**
     * Additional meter registry customization for specific environments
     */
    @Bean
    public MeterRegistryCustomizer<MeterRegistry> metricsEnvironmentTags() {
        return registry -> {
            // Add environment-specific configuration
            if ("kubernetes".equals(environment) || "prod".equals(environment)) {
                registry.config()
                        .commonTags("deployment", "containerized");
            } else {
                registry.config()
                        .commonTags("deployment", "local");
            }
        };
    }
}