# Product Context: Kubernetes Autoscaling Demo

## Why This Project Exists
This project exists to provide a practical, hands-on demonstration of Kubernetes Horizontal Pod Autoscaling (HPA). While autoscaling is a fundamental concept in cloud-native applications, understanding how it works in practice can be challenging without a concrete example. This demo bridges the gap between theory and implementation.

## Problems It Solves
1. **Learning Gap**: Abstract concepts like autoscaling are difficult to understand without practical examples
2. **Testing Environment**: Provides a controlled environment to experiment with autoscaling parameters
3. **Demonstration Tool**: Enables showing autoscaling in action for educational or presentation purposes
4. **Best Practices**: Illustrates containerization and resource management best practices
5. **Common Pitfalls**: Demonstrates common mistakes in autoscaling configuration

## How It Should Work
1. Users deploy the complete demo environment using the setup script
2. The Spring Boot application exposes endpoints to generate controlled CPU and memory load
3. Kubernetes HPA monitors the resource usage and scales the application pods accordingly
4. Prometheus collects metrics, and Grafana visualizes the scaling events
5. k6 load tests can be run to simulate real-world traffic patterns and trigger scaling

## User Experience Goals
1. **Simplicity**: One-command setup for the entire demo environment
2. **Visibility**: Clear visualization of resource usage and scaling events
3. **Control**: Ability to adjust load parameters to see different scaling scenarios
4. **Education**: Demonstrate both successful scaling and common mistakes
5. **Completeness**: Include all necessary components (app, monitoring, load testing) in one package
