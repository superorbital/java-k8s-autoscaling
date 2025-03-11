# Kubernetes Autoscaling Demo

A practical demonstration of Kubernetes Horizontal Pod Autoscaling (HPA) using a Spring Boot application that generates controllable CPU load. This project serves as an educational tool to understand how Kubernetes automatically scales resources based on demand.

## Overview

This demo provides a complete environment to:
- Demonstrate Kubernetes HPA functionality with a real application
- Generate CPU load on demand through a REST endpoint
- Visualize scaling events with Prometheus and Grafana
- Trigger autoscaling with k6 load tests
- Showcase both successful autoscaling and common mistakes

## Prerequisites

- Docker
- kubectl
- kind (Kubernetes in Docker)
- Helm
- Git

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/superorbital/java-k8s-autoscaling.git
cd autoscaling-demo
```

### 2. Run the setup script

```bash
chmod +x setup-demo.sh
./setup-demo.sh
```

This script will:
- Create a kind cluster with port mappings
- Deploy metrics-server for HPA
- Install Prometheus and Grafana using Helm
- Install k6 operator for load testing
- Build and load the application image
- Deploy the application to Kubernetes
- Apply the HPA configuration

### 3. Verify the installation

```bash
kubectl get pods
kubectl get hpa
```

## Usage

### Running the Demo

The project includes a guided demo script:

```bash
chmod +x run-demo.sh
./run-demo.sh
```

This script will:
1. Check the current state of the HPA
2. Set up monitoring terminals
3. Open Grafana in your browser
4. Start the load test
5. Guide you through the demo with narration points
6. Show common autoscaling mistakes
7. Clean up when done

#### Enhanced Demo: Understanding Resource Requests/Limits Impact

```bash
chmod +x run-demo-enhanced.sh
./run-demo-enhanced.sh
```

This enhanced script demonstrates how changes to resource requests/limits affect autoscaling through multiple scenarios:

1. **Baseline Configuration**: Standard setup with 200m CPU request
2. **Higher CPU Request**: Shows how doubling CPU request (400m) delays scaling
3. **Lower CPU Request**: Shows how halving CPU request (100m) triggers earlier scaling
4. **Memory-Based Scaling**: Demonstrates the challenges of memory-based scaling with JVM applications

Each scenario includes detailed narration points explaining the relationship between resource configuration and scaling behavior.

### Accessing the Components

- Application: http://localhost:8080
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (username: admin, password: admin)

### Manual Load Testing

To manually start the load test:

```bash
kubectl apply -f k8s/k6-load-test.yaml
```

To monitor the HPA:

```bash
kubectl get hpa -w
```

### Development Workflow

The project includes a couple of scripts to improve the development experience:

- `rebuild-deploy.sh`: Rebuilds and redeploys the application to the already-running kind cluster
- `monitor.sh`: Sets up monitoring terminals to track autoscaling behavior

## Project Components

### Spring Boot Application

The core application exposes endpoints to generate controlled CPU and memory load:

- `/api/cpu-load?durationSeconds=5&intensity=80`: Generates CPU load with configurable duration and intensity
- `/api/memory-load?durationSeconds=30&sizeInMB=100`: Allocates and holds memory with configurable size and duration

### Kubernetes Configuration

- Deployment with resource requests and limits
- HPA configured to scale based on CPU utilization (70% threshold)
- Service for internal and external access

### Resource Requests/Limits and Autoscaling

This project demonstrates how resource requests and limits affect Kubernetes autoscaling behavior:

#### How Kubernetes Calculates Resource Utilization

Kubernetes HPA calculates resource utilization as a percentage of the resource **request**, not the limit:

```
Utilization % = (Current Usage / Resource Request) * 100%
```

This means:
- With a CPU request of 200m, the pod will scale when using ~140m CPU (70% of 200m)
- With a CPU request of 400m, the pod will scale when using ~280m CPU (70% of 400m)
- With a CPU request of 100m, the pod will scale when using ~70m CPU (70% of 100m)

#### Impact of Different Resource Configurations

1. **Higher CPU Request**:
   - Delays scaling (requires more actual CPU usage to reach threshold)
   - Results in fewer, more utilized pods
   - Can reduce pod churn but might impact performance under sudden load spikes

2. **Lower CPU Request**:
   - Triggers earlier scaling (requires less actual CPU usage to reach threshold)
   - Results in more pods, each less utilized
   - Can improve performance under sudden load spikes but increases resource costs

3. **Memory Request Considerations**:
   - Memory request should be >= JVM heap size to prevent premature scaling
   - Memory-based scaling can be problematic for JVM applications due to upfront allocation

#### Best Practices

- Set CPU request based on actual application needs and desired scaling behavior
- For JVM apps, set memory request >= JVM heap size
- Consider disabling memory-based scaling for JVM applications
- Use explicit JVM heap settings instead of percentage-based allocation
- Monitor both resource usage and scaling events to fine-tune settings

### JVM and Kubernetes Autoscaling

This project demonstrates important considerations when running JVM applications with Kubernetes HPA:

#### The Problem

When using percentage-based JVM heap settings (like `-XX:MaxRAMPercentage=75.0`) with memory-based HPA:
1. The JVM allocates a large percentage of the container's memory upfront
2. This immediate allocation can trigger memory-based autoscaling prematurely
3. The result is unnecessary scaling events and resource inefficiency

This is especially problematic when Helm charts enable both CPU and memory-based autoscaling by default.

#### The Solution

This demo implements two key practices to address this issue:

1. **Explicit JVM Heap Settings**: 
   - We use `-Xms410m -Xmx410m` instead of percentage-based settings
   - These values are calculated as 80% of the container's memory limit (512Mi)
   - Setting both min and max to the same value prevents heap resizing overhead

2. **Balanced HPA Configuration**:
   - We demonstrate both proper configuration and common mistakes
   - The `hpa-mistake-memory.yaml` shows how memory metrics can cause premature scaling
   - The main HPA configuration focuses on CPU utilization which is more stable for JVM applications

#### Best Practices

When running JVM applications with Kubernetes HPA:
- Always consider the interaction between JVM memory settings and HPA thresholds
- Use explicit heap settings rather than percentage-based allocation
- Size the heap appropriately based on container limits (typically 70-80%)
- Be cautious with memory-based autoscaling for JVM applications
- Monitor both JVM heap usage and container memory usage

### Monitoring Stack

- Prometheus for collecting and storing metrics
- Grafana for visualizing metrics and scaling events
- Custom dashboards for monitoring the application and autoscaling behavior

### Load Testing

- k6 for generating realistic load patterns
- TestRun CRD for Kubernetes-native load testing
- Prometheus integration for metrics collection

## AI-Ready with Cline

This project is designed to work seamlessly with Cline, an AI assistant that uses a Memory Bank system for documentation.

### What is Cline?

Cline is an AI assistant with a unique characteristic: its memory resets completely between sessions. To overcome this limitation, Cline maintains a comprehensive Memory Bank that documents all aspects of the project. This ensures continuity and effectiveness across sessions.

Cline works best with Claude Sonnet, which has the capability to understand and process the Memory Bank structure.

### Memory Bank Structure

The Memory Bank consists of core files that build upon each other in a clear hierarchy:

```
memory-bank/
├── projectbrief.md       # Foundation document defining core requirements
├── productContext.md     # Why this project exists and problems it solves
├── systemPatterns.md     # System architecture and design patterns
├── techContext.md        # Technologies used and technical constraints
├── activeContext.md      # Current work focus and recent changes
├── progress.md           # What works and what's left to build
└── .clinerules           # Project-specific patterns and preferences
```

### Using Cline with This Project

1. When working with Cline, always reference the Memory Bank
2. Use the command "update memory bank" to have Cline review and update all documentation
3. For new features or changes, ensure they are documented in the appropriate Memory Bank files

Cline will use this documentation to understand:
- The project's purpose and architecture
- Current state and progress
- Technical decisions and patterns
- Development workflows

This approach ensures that anyone (human or AI) can quickly understand the project and contribute effectively, even without prior knowledge.

## Troubleshooting

### MacOS with Apple Silicon

If you're using a Mac with Apple Silicon and have installed OpenJDK via Homebrew, you may need to create a symlink for the Java installation:

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

This is required to properly link the Homebrew-installed OpenJDK for Maven wrapper commands to work correctly.

### Common Docker Issues

- **Resource Constraints**: Ensure Docker has enough resources allocated (CPU, memory)
- **Image Pull Failures**: Check internet connectivity and Docker Hub access

### Kubernetes Setup Issues

- **Metrics Server**: If HPA doesn't work, verify metrics-server is running with `kubectl get pods -n kube-system`
- **Kind Cluster Creation**: If kind cluster creation fails, try removing any existing cluster with `kind delete cluster --name autoscale-demo`

### Application Issues

- **Health Check Failures**: Verify the application is running with `kubectl logs deployment/autoscale-demo`
- **Autoscaling Not Triggering**: Check HPA status with `kubectl describe hpa autoscale-demo`

## Cleaning Up

To delete the entire demo environment:

```bash
kind delete cluster --name autoscale-demo
```

## License

[MIT License](LICENSE.txt)

## Acknowledgements

- Kubernetes community for HPA and metrics-server
- Spring Boot team for the application framework
- Prometheus and Grafana projects for monitoring capabilities
- k6 team for the load testing framework
