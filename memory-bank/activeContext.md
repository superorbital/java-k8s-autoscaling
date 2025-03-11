# Active Context: Kubernetes Autoscaling Demo

## Current Work Focus
The current focus is on enhancing the demo to better illustrate how changes to resource requests/limits affect autoscaling behavior. This enhancement addresses user feedback: "I think a lot of our users are trying to understand how changes to requests/limits affect the autoscaling. If the demo / discussion can illustrate that, I think it would be great."

## Recent Changes

### Latest Enhancements
1. **Memory Load Generation**: Added a new endpoint to generate controlled memory load:
   - Implemented `/api/memory-load` endpoint in LoadController
   - Supports configurable duration and memory size parameters
   - Includes proper memory allocation and cleanup with graceful shutdown support
   - Allows demonstration of memory-based autoscaling behavior

2. **Multiple Resource Configuration Scenarios**: Created additional deployment configurations to demonstrate how different resource settings affect scaling:
   - High CPU request (400m) deployment to show delayed scaling
   - Low CPU request (100m) deployment to show earlier scaling
   - Memory-focused deployment with higher memory request (384Mi)
   - Each with corresponding HPA configuration

3. **Enhanced Load Testing**: Created specialized k6 load tests for each scenario:
   - CPU-focused load tests with different intensity profiles
   - Memory-focused load test that allocates and holds memory
   - Each test targets the specific deployment it's designed to test

4. **Enhanced Demo Script**: Created a comprehensive demo script (`run-demo-enhanced.sh`) that:
   - Demonstrates each resource configuration scenario sequentially
   - Provides detailed narration about how resource changes affect scaling
   - Includes clear explanations of how Kubernetes calculates resource percentages
   - Summarizes best practices for setting requests/limits for effective autoscaling

5. **Updated Documentation**: Enhanced the README.md with:
   - Detailed explanation of how resource requests/limits affect autoscaling
   - Information about the new memory load generation capabilities
   - Instructions for running the enhanced demo
   - Best practices for resource configuration in Kubernetes

### Previous Changes
1. **JVM Memory Configuration Update**: Modified the JVM heap settings to address autoscaling issues:
   - Changed from percentage-based settings (`-XX:MaxRAMPercentage=75.0`) to explicit heap settings (`-Xms410m -Xmx410m`)
   - Set heap size to exactly 80% of the container's memory limit (512Mi)
   - Added documentation about JVM and HPA interaction in README.md
2. **HPA Memory Example Enhancement**: Updated the memory-based HPA example to demonstrate common issues:
   - Added CPU metric with 80% utilization target
   - Updated memory utilization target from 70% to 80%
   - Demonstrates the problem with company Helm charts that enable both CPU and memory metrics by default
3. **Graceful Shutdown Implementation**: Added graceful shutdown support to the Spring Boot application:
   - Added graceful shutdown configuration in application.properties
   - Updated AutoscaleDemoApplication to handle SIGTERM signals properly
   - Modified LoadController to safely handle interruptions during CPU and memory load operations
   - Added terminationGracePeriodSeconds to the Kubernetes deployment
4. **Rebuild Script Improvement**: Modified the rebuild-deploy.sh script to use the multi-stage Docker build process without requiring a local Java installation
5. **Base Image Update**: Changed the Docker base image from `eclipse-temurin:17-jre-alpine` to `amazoncorretto:17-alpine` to resolve image resolution issues.
6. **Multi-stage Docker Build**: Converted the Dockerfile to use a multi-stage build process that handles both building and running the application, eliminating the need for a local Java installation.
7. **Added Main Application Class**: Created the missing `AutoscaleDemoApplication.java` class with the main method required for Spring Boot.
8. **K6 Load Test Update**: Updated the k6 load test configuration to use the new TestRun CRD instead of the deprecated K6 CRD.
9. **Memory Bank Creation**: Established the Memory Bank documentation structure to maintain project knowledge.
10. **Development Workflow Improvements**: Created three new scripts to improve the development experience:
    - `rebuild-deploy.sh`: Automates rebuilding and redeploying the application to the kind cluster
    - `dev-mode.sh`: Runs the application locally with hot reloading for faster development
    - `monitor.sh`: Sets up monitoring terminals to track autoscaling behavior
11. **K6 Prometheus Integration**: Updated the k6 load test configuration to output metrics to Prometheus:
    - Modified TestRun CRD to use the `prometheus-remote` output
    - Created service monitors for k6 metrics
    - Updated service selectors to match the TestRun pods

## Next Steps
1. **Test Enhanced Demo**: Run the enhanced demo script to verify all scenarios work correctly.
2. **Gather Feedback**: Collect feedback on the enhanced demo to see if it effectively illustrates the relationship between resource requests/limits and autoscaling.
3. **Consider Additional Visualizations**: Explore creating dedicated Grafana dashboards that better visualize the relationship between resource usage and scaling events.
4. **Document Results**: Update documentation with any findings or additional insights from testing the enhanced scenarios.

## Active Decisions and Considerations

### Resource Configuration Scenarios
- **Decision**: Created three distinct resource configurations (baseline, high CPU, low CPU, memory-focused)
- **Rationale**: Demonstrates the full spectrum of how resource settings affect scaling behavior
- **Considerations**:
  - High CPU request (400m) shows delayed scaling but better resource utilization
  - Low CPU request (100m) shows earlier scaling but potentially wasted resources
  - Memory-focused configuration demonstrates the challenges of memory-based scaling with JVM applications

### Memory Load Implementation
- **Decision**: Implemented memory allocation in chunks with explicit touching of memory
- **Rationale**: Ensures memory is actually allocated and not optimized away
- **Considerations**:
  - Limited maximum allocation to 350MB to prevent OOM issues
  - Implemented proper cleanup to prevent memory leaks
  - Added graceful shutdown support to handle interruptions

### Demo Script Structure
- **Decision**: Created a separate enhanced demo script rather than modifying the original
- **Rationale**: Preserves the simpler original demo while offering a more comprehensive option
- **Benefits**:
  - Users can choose between a simpler or more detailed demonstration
  - Each scenario is clearly separated with its own explanation
  - Includes a comprehensive summary of best practices


### Docker Base Image Selection
- **Decision**: Switched to Amazon Corretto as the base image
- **Rationale**: Amazon Corretto is a well-maintained, production-ready distribution of OpenJDK with good Alpine support
- **Alternatives Considered**:
  - `eclipse-temurin:17-jre` (non-Alpine version)
  - `openjdk:17-alpine`
  - Platform-specific builds

### Docker Build Process
- **Decision**: Implemented a multi-stage Docker build
- **Rationale**: Eliminates the need for a local Java installation and ensures consistent builds across environments
- **Benefits**:
  - Self-contained build process
  - Smaller final image (build dependencies not included in runtime image)
  - Consistent build environment

### Container Optimization
- **Current Approach**: Using Alpine-based images for smaller footprint
- **Implementation**: Explicitly installing wget for health checks in the runtime container
- **Consideration**: Alpine uses musl libc instead of glibc, which can occasionally cause compatibility issues with Java applications

### JVM Container Settings
- **Current Configuration**: Using container-aware JVM settings with explicit heap sizes
  - `-XX:+UseContainerSupport`
  - `-Xms410m -Xmx410m` (80% of container memory limit)
- **Consideration**: Explicit heap settings prevent premature scaling with memory-based HPA
- **Rationale**: 
  - Percentage-based settings cause immediate memory allocation that can trigger HPA
  - Fixed heap size provides predictable memory usage
  - Setting min and max to the same value prevents heap resizing overhead
- **Monitoring Need**: Verify that the explicit heap settings prevent unnecessary scaling events

### Security Considerations
- **Current Approach**: Running as non-root user (spring)
- **Consideration**: Ensure all file permissions are correctly set for the non-root user
- **Future Enhancement**: Consider adding security scanning to the build process
