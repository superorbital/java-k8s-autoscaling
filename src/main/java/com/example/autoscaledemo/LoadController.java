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
            @RequestParam(value = "durationSeconds", defaultValue = "30") int durationSeconds,
            @RequestParam(value = "sizeInMB", defaultValue = "100") int sizeInMB) {
        
        logger.info("Received memory load request: duration={}s, sizeInMB={}", durationSeconds, sizeInMB);
        
        // If we're shutting down, return immediately
        if (shuttingDown.get()) {
            logger.info("Application is shutting down, skipping memory load generation");
            return "Application is shutting down, memory load generation skipped";
        }
        
        // Limit the size to prevent OOM issues
        sizeInMB = Math.min(Math.max(sizeInMB, 1), 350); // Max 350MB to stay within container limits
        
        long startTime = System.currentTimeMillis();
        long endTime = startTime + (durationSeconds * 1000L);
        
        // Create a list to hold the byte arrays (to prevent GC from reclaiming them)
        List<byte[]> memoryBlocks = new ArrayList<>();
        
        try {
            // Allocate memory in smaller chunks to avoid large allocation failures
            int chunkSizeMB = 10;
            int numChunks = sizeInMB / chunkSizeMB;
            int remainderMB = sizeInMB % chunkSizeMB;
            
            logger.info("Allocating {}MB in {}MB chunks plus {}MB remainder", 
                       sizeInMB, chunkSizeMB, remainderMB);
            
            // Allocate the chunks
            for (int i = 0; i < numChunks && !shuttingDown.get(); i++) {
                memoryBlocks.add(new byte[chunkSizeMB * 1024 * 1024]);
                logger.debug("Allocated chunk {}/{} ({}MB)", i+1, numChunks, chunkSizeMB);
                
                // Touch the memory to ensure it's actually allocated
                touchMemory(memoryBlocks.get(i));
                
                // Brief pause between allocations
                TimeUnit.MILLISECONDS.sleep(50);
            }
            
            // Allocate the remainder
            if (remainderMB > 0 && !shuttingDown.get()) {
                memoryBlocks.add(new byte[remainderMB * 1024 * 1024]);
                logger.debug("Allocated remainder chunk ({}MB)", remainderMB);
                touchMemory(memoryBlocks.get(memoryBlocks.size() - 1));
            }
            
            logger.info("Memory allocation complete. Holding for duration...");
            
            // Hold the memory for the specified duration
            while (System.currentTimeMillis() < endTime && !shuttingDown.get()) {
                // Periodically touch the memory to prevent optimizations
                for (int i = 0; i < memoryBlocks.size() && !shuttingDown.get(); i++) {
                    touchMemory(memoryBlocks.get(i));
                }
                
                // Sleep briefly
                TimeUnit.MILLISECONDS.sleep(500);
            }
            
        } catch (InterruptedException e) {
            logger.info("Memory load generation interrupted during sleep");
            Thread.currentThread().interrupt();
        } catch (OutOfMemoryError e) {
            logger.error("Out of memory during allocation: {}", e.getMessage());
            return "Memory allocation failed: Out of memory. Try a smaller size.";
        } finally {
            // Clear the references to allow GC
            memoryBlocks.clear();
            // Suggest garbage collection
            System.gc();
        }
        
        // Check if we stopped due to shutdown
        if (shuttingDown.get()) {
            logger.info("Memory load generation stopped due to application shutdown");
        }
        
        long actualDuration = System.currentTimeMillis() - startTime;
        logger.info("Completed memory load: {}MB held for {}ms", sizeInMB, actualDuration);
        
        return String.format("Memory load completed: %dMB held for %.2f seconds", 
                             sizeInMB, actualDuration/1000.0);
    }
    
    // Helper method to ensure memory is actually allocated
    private void touchMemory(byte[] memory) {
        // Write to every 1024th byte to ensure pages are allocated
        for (int i = 0; i < memory.length; i += 1024) {
            memory[i] = 1;
        }
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
