package com.macode101.java_springboot_docker_k8s_example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.core.env.Environment;

@SpringBootApplication
@ConfigurationPropertiesScan
public class JavaSpringbootDockerK8sExampleApplication {

	private static final Logger logger = LoggerFactory.getLogger(JavaSpringbootDockerK8sExampleApplication.class);

	public static void main(String[] args) {
		try {
			SpringApplication app = new SpringApplication(JavaSpringbootDockerK8sExampleApplication.class);
			
			// Add shutdown hook for graceful shutdown
			Runtime.getRuntime().addShutdownHook(new Thread(() -> {
				logger.info("Application is shutting down gracefully...");
			}));
			
			Environment env = app.run(args).getEnvironment();
			
			logger.info("Application '{}' is running!", 
					   env.getProperty("spring.application.name"));
			logger.info("Access URLs:");
			logger.info("  Local: http://localhost:{}", 
					   env.getProperty("server.port"));
			logger.info("  Health: http://localhost:{}/actuator/health", 
					   env.getProperty("management.server.port"));
			logger.info("  Profile(s): {}", 
					   String.join(",", env.getActiveProfiles()));
			
		} catch (Exception e) {
			logger.error("Failed to start application", e);
			System.exit(1);
		}
	}
}
