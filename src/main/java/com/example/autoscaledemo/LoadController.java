// src/main/java/com/example/autoscaledemo/LoadController.java
package com.example.autoscaledemo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.context.event.ContextClosedEvent;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

@RestController
public class LoadController {
    private static final Logger logger = LoggerFactory.getLogger(LoadController.class);
    private final Random random = new Random();
    private final AtomicBoolean shuttingDown = new AtomicBoolean(false);
    
    /**
     * Listen for Spring context closed event to handle graceful shutdown
     */
    @EventListener(ContextClosedEvent.class)
    public void onContextClosedEvent() {
        logger.info("Received Spring context closed event. Marking controller for shutdown...");
        shuttingDown.set(true);
    }

    @GetMapping("/api/cpu-load")
    public String generateCpuLoad(
            @RequestParam(value = "durationSeconds", defaultValue = "5") int durationSeconds,
            @RequestParam(value = "intensity", defaultValue = "80") int intensity) {
        
        logger.info("Received CPU load request: duration={}s, intensity={}%", durationSeconds, intensity);
        
        // If we're shutting down, return immediately
        if (shuttingDown.get()) {
            logger.info("Application is shutting down, skipping CPU load generation");
            return "Application is shutting down, CPU load generation skipped";
        }
        
        long startTime = System.currentTimeMillis();
        long endTime = startTime + (durationSeconds * 1000L);
        
        int computedResults = 0;
        
        // Adjust intensity (0-100) to control CPU usage
        intensity = Math.min(Math.max(intensity, 0), 100);
        
        while (System.currentTimeMillis() < endTime && !shuttingDown.get()) {
            // CPU-intensive calculation: Compute prime factors
            int num = 10000 + random.nextInt(90000);
            List<Integer> factors = findPrimeFactors(num);
            computedResults++;
            
            // Throttle based on intensity
            if (intensity < 100) {
                try {
                    // Sleep to reduce CPU usage according to intensity
                    TimeUnit.MILLISECONDS.sleep((100 - intensity) / 5);
                } catch (InterruptedException e) {
                    logger.info("CPU load generation interrupted during sleep");
                    Thread.currentThread().interrupt();
                    break;
                }
            }
            
            // Periodically check if we should stop (every few iterations)
            if (computedResults % 10 == 0 && shuttingDown.get()) {
                logger.info("Shutdown signal detected, stopping CPU load generation");
                break;
            }
        }
        
        // Check if we stopped due to shutdown
        if (shuttingDown.get()) {
            logger.info("CPU load generation stopped due to application shutdown");
        }
        
        long actualDuration = System.currentTimeMillis() - startTime;
        logger.info("Completed CPU load: {}ms, {} calculations", actualDuration, computedResults);
        
        return String.format("CPU load completed: %d calculations in %.2f seconds", 
                             computedResults, actualDuration/1000.0);
    }

    @GetMapping("/api/memory-load")
    public String generateMemoryLoad(
            @RequestParam(value = "sizeMB", defaultValue = "10") int sizeMB,
            @RequestParam(value = "durationSeconds", defaultValue = "10") int durationSeconds) {
        
        logger.info("Received memory load request: size={}MB, duration={}s", sizeMB, durationSeconds);
        
        // If we're shutting down, return immediately
        if (shuttingDown.get()) {
            logger.info("Application is shutting down, skipping memory load generation");
            return "Application is shutting down, memory load generation skipped";
        }
        
        // Cap the memory usage for safety
        sizeMB = Math.min(sizeMB, 500);
        
        // Allocate memory
        List<byte[]> memoryChunks = new ArrayList<>();
        long startTime = System.currentTimeMillis();
        long actualDuration = 0;
        
        try {
            // Allocate in 1MB chunks, checking for shutdown between allocations
            for (int i = 0; i < sizeMB && !shuttingDown.get(); i++) {
                memoryChunks.add(new byte[1024 * 1024]);
                
                // Check for shutdown every 10MB
                if (i % 10 == 0 && shuttingDown.get()) {
                    logger.info("Shutdown signal detected during memory allocation, stopping");
                    break;
                }
            }
            
            if (!shuttingDown.get()) {
                logger.info("Allocated {}MB of memory", memoryChunks.size());
                
                // Hold the memory for the specified duration, but check for shutdown
                long endTime = System.currentTimeMillis() + (durationSeconds * 1000L);
                while (System.currentTimeMillis() < endTime && !shuttingDown.get()) {
                    // Sleep in smaller increments to be more responsive to shutdown
                    TimeUnit.MILLISECONDS.sleep(500);
                    
                    if (shuttingDown.get()) {
                        logger.info("Shutdown signal detected during memory hold, releasing memory");
                        break;
                    }
                }
            }
            
        } catch (InterruptedException e) {
            logger.info("Memory load generation interrupted during sleep");
            Thread.currentThread().interrupt();
        } finally {
            // Always clear memory (will be garbage collected)
            actualDuration = System.currentTimeMillis() - startTime;
            logger.info("Releasing {}MB of allocated memory after {}ms", memoryChunks.size(), actualDuration);
            memoryChunks.clear();
        }
        
        // Check if we stopped due to shutdown
        if (shuttingDown.get()) {
            logger.info("Memory load generation stopped due to application shutdown");
        }
        
        return String.format("Memory load completed: %dMB held for %d seconds", sizeMB, durationSeconds);
    }

    @GetMapping("/")
    public String home() {
        return "Autoscaling Demo App is running!";
    }

    private List<Integer> findPrimeFactors(int number) {
        List<Integer> factors = new ArrayList<>();
        
        // Find the prime factors
        for (int i = 2; i <= number; i++) {
            while (number % i == 0) {
                factors.add(i);
                number /= i;
            }
        }
        
        return factors;
    }
}
