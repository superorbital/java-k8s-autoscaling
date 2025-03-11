# Cline Rules for Kubernetes Autoscaling Demo

## Project Patterns

### Docker Image Selection
- Prefer Alpine-based images for smaller footprint when possible
- For Java applications, ensure the selected image has proper container support
- Amazon Corretto is the preferred JDK distribution for this project
- Explicitly install required tools (like wget) that may not be included in Alpine images

### Docker Build Process
- Use multi-stage builds to separate build and runtime environments
- Build stage should include all necessary tools and dependencies for compilation
- Runtime stage should be minimal and only include what's needed to run the application
- Ensure proper file permissions when copying files between stages

### Kubernetes Configuration
- Resource limits and requests should always be specified
- Use NodePort services for demo accessibility
- HPA should be configured with demo-friendly stabilization windows (faster than production defaults)
- When creating multiple deployment scenarios:
  - Keep service names consistent with deployment names
  - Use clear naming conventions that indicate the purpose (e.g., high-cpu, low-cpu)
  - Maintain consistent labels across related resources

### Resource Requests and Limits
- CPU requests directly affect when autoscaling occurs
- Higher CPU requests delay scaling but improve resource utilization
- Lower CPU requests trigger earlier scaling but may waste resources
- Memory requests should be >= JVM heap size for JVM applications
- Document the relationship between resource settings and scaling behavior

### Java Application
- Use container-aware JVM settings with explicit heap sizes
- Set both -Xms and -Xmx to the same value (80% of container memory limit)
- Avoid percentage-based settings like MaxRAMPercentage when using memory-based HPA
- Run as non-root user for security
- Always include a main application class with @SpringBootApplication annotation
- Implement graceful shutdown to handle Kubernetes pod termination properly
- Use Spring Boot's built-in graceful shutdown support
- Check for shutdown signals in long-running operations

### JVM and Kubernetes Autoscaling
- Be cautious with memory-based HPA for JVM applications
- JVM allocates heap memory upfront which can trigger premature scaling
- Use explicit heap settings (-Xms and -Xmx) instead of percentage-based allocation
- Set heap size to match the expected memory usage (typically 80% of container limit)
- When company Helm charts enable both CPU and memory metrics by default:
  - Ensure JVM heap settings align with HPA thresholds
  - Consider disabling memory-based scaling for JVM applications
  - Document the interaction between JVM memory settings and HPA configuration
- For memory-based scaling demonstrations:
  - Set memory request higher than JVM heap size to prevent immediate scaling
  - Implement controlled memory allocation that can be held for a specified duration
  - Include proper cleanup to prevent memory leaks

### Monitoring
- Prometheus and Grafana are the standard monitoring tools
- Expose metrics via Spring Actuator and Micrometer
- Consider creating dedicated dashboards for specific demonstration scenarios
- Include visualizations that show the relationship between resource usage and scaling events

## User Preferences
- Prefer comprehensive documentation
- Favor educational value over production optimization
- Demonstrate both successful patterns and common mistakes

## Critical Implementation Paths
1. Docker build → Kind load → Kubernetes deployment
2. Metrics Server → HPA configuration → Autoscaling
3. Load testing → Resource utilization → Pod scaling
4. Development workflows:
   - Local development: `dev-mode.sh` → Hot reloading → Local testing
   - Cluster deployment: `rebuild-deploy.sh` → Kind load → Kubernetes rollout
   - Monitoring: `monitor.sh` → Multiple terminal views → Grafana dashboard

## Known Challenges
- Alpine images may have compatibility issues with some Java applications
- Container resource limits must be properly configured for effective autoscaling
- Health checks require wget which must be available in the container

### Load Testing
- Use the TestRun CRD instead of the deprecated K6 CRD
- Configure load tests with realistic ramp-up and ramp-down periods
- Include appropriate thresholds for error rates and response times
- Create specialized load tests for different demonstration scenarios
- For CPU-focused tests:
  - Adjust intensity and duration parameters to create appropriate load patterns
  - Use higher user counts for high CPU request scenarios
  - Use lower user counts for low CPU request scenarios
- For memory-focused tests:
  - Allocate memory in smaller chunks to avoid allocation failures
  - Include longer hold times to demonstrate memory usage patterns
  - Use longer sleep times between requests to allow for memory operations

## Project Evolution
- Started with eclipse-temurin base image
- Switched to Amazon Corretto for better compatibility
- Converted to multi-stage Docker build for improved build process
- Added missing main application class
- Updated K6 load test configuration to use TestRun CRD
- Memory Bank documentation established for knowledge persistence
- Development workflow improved with specialized scripts

## Development Workflow Patterns
- Use `dev-mode.sh` for rapid local development with hot reloading
- Use `rebuild-deploy.sh` for testing in the Kubernetes environment
- Use `monitor.sh` to set up monitoring terminals for observing autoscaling behavior
- Use `setup-demo.sh` for initial environment setup
- Use `run-demo.sh` for basic guided demonstration of autoscaling concepts
- Use `run-demo-enhanced.sh` for comprehensive demonstration of how resource requests/limits affect autoscaling

## Demo Script Patterns
- Organize demo scripts into clear scenarios with distinct configurations
- Include detailed narration points for each scenario
- Provide cleanup between scenarios to prevent interference
- Include summary sections that reinforce key concepts
- Use consistent formatting for resource configuration explanations
- Calculate and explain the actual values that trigger scaling (e.g., 70% of 200m = 140m)
