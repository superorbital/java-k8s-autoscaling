# Technical Context: Kubernetes Autoscaling Demo

## Technologies Used

### Core Application
- **Java 17**: The application is built using Java 17, leveraging modern language features
- **Spring Boot 3.2.3**: Framework for building the REST API and application infrastructure
- **Spring Actuator**: Provides built-in endpoints for health checks and metrics
- **Micrometer with Prometheus**: For collecting and exposing application metrics

### Containerization
- **Docker**: For containerizing the application
- **Amazon Corretto 17 Alpine**: Base image for the application container (updated from eclipse-temurin)
- **Multi-stage Docker build**: 
  - First stage builds the application using Maven
  - Second stage creates a minimal runtime image
  - Eliminates need for local Java installation
  - Optimizes the final container image size

### Kubernetes & Orchestration
- **Kind (Kubernetes in Docker)**: Local Kubernetes cluster for development and demonstration
- **Kubernetes Deployments**: For declarative application deployment
- **Horizontal Pod Autoscaler (HPA)**: For automatic scaling based on resource metrics
- **Kubernetes Services**: For internal and external access to the application
- **Kubernetes ConfigMaps**: For configuration management

### Monitoring & Observability
- **Metrics Server**: Collects resource metrics from Kubernetes nodes and pods
- **Prometheus**: Time-series database for storing metrics
- **Grafana**: Visualization and dashboarding for metrics
- **kube-prometheus-stack**: Helm chart that bundles Prometheus and Grafana

### Load Testing
- **k6**: Modern load testing tool for generating traffic
- **k6 Operator**: Kubernetes-native way to run k6 load tests
- **TestRun CRD**: The custom resource definition used to define k6 load tests (replacing the deprecated K6 CRD)

### Build & Development
- **Maven**: Build tool for Java applications
- **Maven Wrapper**: Ensures consistent Maven version across environments

## Development Setup
The development environment requires:
1. Docker installed and running
2. kubectl CLI tool
3. kind CLI tool
4. Helm CLI tool
5. Java 17 JDK (for local development)
6. Maven (or use the provided wrapper)

## Technical Constraints

### Resource Limits
- The application container has defined resource limits:
  - CPU: 500m (half a CPU core)
  - Memory: 512Mi
- Resource requests:
  - CPU: 200m
  - Memory: 256Mi

### JVM Configuration
- The JVM is configured with container-aware settings:
  - UseContainerSupport enabled
  - MaxRAMPercentage set to 75% to leave headroom for the JVM itself

### Network Configuration
- The application exposes port 8080 internally
- Kind cluster maps:
  - Port 8080 -> 30080 (Application)
  - Port 9090 -> 30090 (Prometheus)
  - Port 3000 -> 30300 (Grafana)

### Security Considerations
- The application runs as a non-root user (spring)
- Container follows security best practices

## Dependencies

### Runtime Dependencies
- Spring Web: For REST endpoints
- Spring Actuator: For health checks and metrics
- Micrometer Prometheus Registry: For exposing metrics in Prometheus format

### Infrastructure Dependencies
- Metrics Server: Required for HPA to function
- Prometheus: For storing metrics
- Grafana: For visualizing metrics

### External Dependencies
- Docker Hub: For base container images
- Maven Central: For Java dependencies
