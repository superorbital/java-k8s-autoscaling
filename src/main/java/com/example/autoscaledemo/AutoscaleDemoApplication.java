package com.example.autoscaledemo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
public class AutoscaleDemoApplication {
    private static final Logger logger = LoggerFactory.getLogger(AutoscaleDemoApplication.class);

    public static void main(String[] args) {
        ConfigurableApplicationContext context = SpringApplication.run(AutoscaleDemoApplication.class, args);
        
        // Register shutdown hook to handle SIGTERM gracefully
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            logger.info("Received shutdown signal. Starting graceful shutdown...");
            try {
                // Trigger Spring Boot's graceful shutdown
                if (context instanceof ServletWebServerApplicationContext) {
                    logger.info("Closing Spring application context...");
                    context.close();
                    logger.info("Application context closed successfully.");
                }
            } catch (Exception e) {
                logger.error("Error during graceful shutdown", e);
            }
        }));
        
        logger.info("Application started successfully with graceful shutdown support");
    }
}
