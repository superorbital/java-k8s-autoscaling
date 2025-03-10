# Kubernetes Autoscaling Demo

A practical demonstration of Kubernetes Horizontal Pod Autoscaling (HPA) using a Spring Boot application that generates controllable CPU and memory load. This project serves as an educational tool to understand how Kubernetes automatically scales resources based on demand.

## Overview

This demo provides a complete environment to:
- Demonstrate Kubernetes HPA functionality with a real application
- Generate CPU and memory load on demand through REST endpoints
- Visualize scaling events with Prometheus and Grafana
- Trigger autoscaling with k6 load tests
- Showcase both successful autoscaling and common mistakes

![Kubernetes Autoscaling](https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/application/hpa/images/hpa.svg)

## Prerequisites

- Docker
- kubectl
- kind (Kubernetes in Docker)
- Helm
- Git

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/autoscaling-demo.git
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

The project includes several scripts to improve the development experience:

- `rebuild-deploy.sh`: Rebuilds and redeploys the application to the kind cluster
- `dev-mode.sh`: Runs the application locally with hot reloading
- `monitor.sh`: Sets up monitoring terminals to track autoscaling behavior

## Project Components

### Spring Boot Application

The core application exposes endpoints to generate controlled CPU and memory load:

- `/api/cpu-load?durationSeconds=5&intensity=80`: Generates CPU load with configurable duration and intensity
- `/api/memory-load?sizeMB=10&durationSeconds=10`: Allocates memory with configurable size and duration

### Kubernetes Configuration

- Deployment with resource requests and limits
- HPA configured to scale based on CPU utilization (70% threshold)
- Service for internal and external access

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

[MIT License](LICENSE)

## Acknowledgements

- Kubernetes community for HPA and metrics-server
- Spring Boot team for the application framework
- Prometheus and Grafana projects for monitoring capabilities
- k6 team for the load testing framework
