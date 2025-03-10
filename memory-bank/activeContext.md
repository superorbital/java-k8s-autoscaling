# Active Context: Kubernetes Autoscaling Demo

## Current Work Focus
The current focus is on resolving Docker image build issues. Specifically, the project encountered an error with the base image `eclipse-temurin:17-jre-alpine` which could not be resolved by Docker.

## Recent Changes
1. **Graceful Shutdown Implementation**: Added graceful shutdown support to the Spring Boot application:
   - Added graceful shutdown configuration in application.properties
   - Updated AutoscaleDemoApplication to handle SIGTERM signals properly
   - Modified LoadController to safely handle interruptions during CPU and memory load operations
   - Added terminationGracePeriodSeconds to the Kubernetes deployment
2. **Rebuild Script Improvement**: Modified the rebuild-deploy.sh script to use the multi-stage Docker build process without requiring a local Java installation
3. **Base Image Update**: Changed the Docker base image from `eclipse-temurin:17-jre-alpine` to `amazoncorretto:17-alpine` to resolve image resolution issues.
4. **Multi-stage Docker Build**: Converted the Dockerfile to use a multi-stage build process that handles both building and running the application, eliminating the need for a local Java installation.
5. **Added Main Application Class**: Created the missing `AutoscaleDemoApplication.java` class with the main method required for Spring Boot.
6. **K6 Load Test Update**: Updated the k6 load test configuration to use the new TestRun CRD instead of the deprecated K6 CRD.
7. **Memory Bank Creation**: Established the Memory Bank documentation structure to maintain project knowledge.
8. **Development Workflow Improvements**: Created three new scripts to improve the development experience:
   - `rebuild-deploy.sh`: Automates rebuilding and redeploying the application to the kind cluster
   - `dev-mode.sh`: Runs the application locally with hot reloading for faster development
   - `monitor.sh`: Sets up monitoring terminals to track autoscaling behavior
9. **K6 Prometheus Integration**: Updated the k6 load test configuration to output metrics to Prometheus:
   - Modified TestRun CRD to use the `prometheus-remote` output
   - Created service monitors for k6 metrics
   - Updated service selectors to match the TestRun pods

## Next Steps
1. **Complete Setup**: Run the full setup script to verify the entire demo environment works correctly.
2. **Test Autoscaling**: Run the load tests to verify that the autoscaling functionality works as expected.
3. **Test Development Workflows**: Verify the new development scripts work as expected.
4. **Document Results**: Update documentation with any findings or additional configuration needed.

## Active Decisions and Considerations

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
- **Current Configuration**: Using container-aware JVM settings
  - `-XX:+UseContainerSupport`
  - `-XX:MaxRAMPercentage=75.0`
- **Consideration**: These settings are crucial for proper memory management in containerized environments
- **Monitoring Need**: Should verify that the JVM respects container memory limits during load testing

### Security Considerations
- **Current Approach**: Running as non-root user (spring)
- **Consideration**: Ensure all file permissions are correctly set for the non-root user
- **Future Enhancement**: Consider adding security scanning to the build process
