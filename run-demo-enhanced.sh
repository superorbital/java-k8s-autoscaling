#!/bin/bash
# run-demo-enhanced.sh
# This script demonstrates how resource requests/limits affect autoscaling

set -e

echo "==== Enhanced Autoscaling Demo Script ===="
echo ""
echo "This script demonstrates how changes to resource requests/limits affect autoscaling."
echo "Press ENTER after each step to continue."
echo ""

# Function to clean up previous deployments
cleanup_previous() {
  echo "Cleaning up previous deployments..."
  kubectl delete hpa --all 2>/dev/null || true
  kubectl delete -f k8s/k6-load-test.yaml 2>/dev/null || true
  kubectl delete -f k8s/k6-high-cpu-load-test.yaml 2>/dev/null || true
  kubectl delete -f k8s/k6-low-cpu-load-test.yaml 2>/dev/null || true
  kubectl delete -f k8s/k6-memory-load-test.yaml 2>/dev/null || true
  kubectl delete deployment autoscale-demo-high-cpu 2>/dev/null || true
  kubectl delete deployment autoscale-demo-low-cpu 2>/dev/null || true
  kubectl delete deployment autoscale-demo-memory 2>/dev/null || true
  kubectl delete service autoscale-demo-high-cpu 2>/dev/null || true
  kubectl delete service autoscale-demo-low-cpu 2>/dev/null || true
  kubectl delete service autoscale-demo-memory 2>/dev/null || true
  sleep 2
}

# Initial setup
read -p "Step 1: Check the current state of the cluster. Press ENTER to run: kubectl get pods,hpa"
kubectl get pods,hpa

echo ""
echo "Setting up terminal windows for monitoring..."
echo "  - In a new terminal, run: kubectl get hpa -w"
echo "  - In another terminal, run: kubectl get pods -w"
echo ""
read -p "Press ENTER when monitoring windows are ready."

echo ""
echo "Opening Grafana in your browser..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  open http://localhost:3000/d/java-k8s-autoscaling-k6-dashboard/k6-prometheus
else
  xdg-open http://localhost:3000/d/java-k8s-autoscaling-k6-dashboard/k6-prometheus &> /dev/null || echo "Please open http://localhost:3000/d/java-k8s-autoscaling-k6-dashboard/k6-prometheus in your browser."
fi

# Apply the k6 service monitors for Prometheus metrics
kubectl apply -f k8s/k6-service-and-service-monitor.yaml
kubectl apply -f k8s/k6-testrun-service-monitor.yaml

# Scenario 1: Baseline Configuration
echo ""
echo "===== SCENARIO 1: BASELINE CONFIGURATION ====="
echo "Resource Configuration:"
echo "- CPU request: 200m (20% of a CPU core)"
echo "- Memory request: 256Mi"
echo "- Memory limit: 512Mi"
echo "- JVM heap: -Xms410m -Xmx410m (80% of memory limit)"
echo "- HPA: 70% CPU utilization threshold"
echo ""
echo "This is our baseline configuration. We'll compare other scenarios to this."
echo ""
read -p "Press ENTER to start the baseline load test."

# Start the load test
kubectl apply -f k8s/k6-load-test.yaml
echo "Baseline load test started!"
echo "Metrics will be available in Prometheus under k6_* metrics"

echo ""
echo "Baseline Narration Points:"
echo "1. Initial state: Single pod with minimal CPU usage"
echo "2. As load increases, watch CPU utilization rise in Grafana"
echo "3. When CPU passes 70% threshold, HPA will start new pods"
echo "4. Point out that CPU utilization is calculated as: (CPU usage / CPU request) * 100%"
echo "5. With 200m CPU request, the pod will scale when using ~140m CPU (70% of 200m)"
echo ""

read -p "Press ENTER when you're ready to move to the next scenario."
cleanup_previous

# Scenario 2: Higher CPU Request
echo ""
echo "===== SCENARIO 2: HIGHER CPU REQUEST ====="
echo "Resource Configuration:"
echo "- CPU request: 400m (40% of a CPU core) - DOUBLE the baseline"
echo "- Memory request: 256Mi (same as baseline)"
echo "- Memory limit: 512Mi (same as baseline)"
echo "- JVM heap: -Xms410m -Xmx410m (same as baseline)"
echo "- HPA: 70% CPU utilization threshold (same as baseline)"
echo ""
echo "This scenario demonstrates how increasing CPU request delays scaling."
echo ""
read -p "Press ENTER to deploy the high CPU request configuration."

kubectl apply -f k8s/deployment-high-cpu-request.yaml
kubectl apply -f k8s/hpa-high-cpu-request.yaml
echo "High CPU request deployment and HPA applied."

read -p "Press ENTER to start the high CPU request load test."
kubectl apply -f k8s/k6-high-cpu-load-test.yaml
echo "High CPU request load test started!"

echo ""
echo "Higher CPU Request Narration Points:"
echo "1. With 400m CPU request, the pod will scale when using ~280m CPU (70% of 400m)"
echo "2. This is DOUBLE the CPU usage required to trigger scaling compared to baseline"
echo "3. Observe how scaling occurs LATER than in the baseline scenario"
echo "4. The application can handle more load per pod before scaling"
echo "5. This can reduce pod churn but might impact performance under sudden load spikes"
echo ""

read -p "Press ENTER when you're ready to move to the next scenario."
cleanup_previous

# Scenario 3: Lower CPU Request
echo ""
echo "===== SCENARIO 3: LOWER CPU REQUEST ====="
echo "Resource Configuration:"
echo "- CPU request: 100m (10% of a CPU core) - HALF the baseline"
echo "- Memory request: 256Mi (same as baseline)"
echo "- Memory limit: 512Mi (same as baseline)"
echo "- JVM heap: -Xms410m -Xmx410m (same as baseline)"
echo "- HPA: 70% CPU utilization threshold (same as baseline)"
echo ""
echo "This scenario demonstrates how decreasing CPU request triggers earlier scaling."
echo ""
read -p "Press ENTER to deploy the low CPU request configuration."

kubectl apply -f k8s/deployment-low-cpu-request.yaml
kubectl apply -f k8s/hpa-low-cpu-request.yaml
echo "Low CPU request deployment and HPA applied."

read -p "Press ENTER to start the low CPU request load test."
kubectl apply -f k8s/k6-low-cpu-load-test.yaml
echo "Low CPU request load test started!"

echo ""
echo "Lower CPU Request Narration Points:"
echo "1. With 100m CPU request, the pod will scale when using ~70m CPU (70% of 100m)"
echo "2. This is HALF the CPU usage required to trigger scaling compared to baseline"
echo "3. Observe how scaling occurs EARLIER than in the baseline scenario"
echo "4. The application scales out more aggressively, potentially wasting resources"
echo "5. This can improve performance under sudden load spikes but increases resource costs"
echo ""

read -p "Press ENTER when you're ready to move to the next scenario."
cleanup_previous

# Scenario 4: Memory-Based Scaling
echo ""
echo "===== SCENARIO 4: MEMORY-BASED SCALING ====="
echo "Resource Configuration:"
echo "- CPU request: 200m (same as baseline)"
echo "- Memory request: 384Mi (1.5x the baseline)"
echo "- Memory limit: 512Mi (same as baseline)"
echo "- JVM heap: -Xms410m -Xmx410m (same as baseline)"
echo "- HPA: Both CPU (80%) and Memory (80%) metrics enabled"
echo ""
echo "This scenario demonstrates memory-based scaling with JVM applications."
echo ""
read -p "Press ENTER to deploy the memory-focused configuration."

kubectl apply -f k8s/deployment-memory-focus.yaml
kubectl apply -f k8s/hpa-memory-focus.yaml
echo "Memory-focused deployment and HPA applied."

read -p "Press ENTER to start the memory load test."
kubectl apply -f k8s/k6-memory-load-test.yaml
echo "Memory load test started!"

echo ""
echo "Memory-Based Scaling Narration Points:"
echo "1. JVM allocates heap memory upfront based on our explicit settings (-Xms410m)"
echo "2. With 384Mi memory request, the pod will scale at ~307Mi memory usage (80% of 384Mi)"
echo "3. Since our JVM heap is 410Mi, we're already using ~410Mi/512Mi of our limit"
echo "4. But we're using ~410Mi/384Mi of our request, which is >100%!"
echo "5. This demonstrates why memory-based scaling can be problematic for JVM applications"
echo "6. Company Helm charts often enable both CPU and memory metrics by default"
echo "7. Memory request should be set higher than JVM heap to prevent premature scaling"
echo ""

read -p "Press ENTER to show common mistakes (identical min/max replicas)."
kubectl delete -f k8s/hpa-memory-focus.yaml
kubectl apply -f k8s/hpa-mistake-threshold.yaml
echo "Switched to improper threshold configuration."
echo "Key points about threshold configuration:"
echo "- When min and max replicas are identical, no scaling will occur"
echo "- Very low CPU threshold (20%) will cause premature scaling"
echo "- Proper threshold selection depends on application characteristics"

read -p "Press ENTER to restore proper HPA settings and clean up."
cleanup_previous
kubectl apply -f k8s/hpa-demo.yaml
echo "Restored proper HPA configuration."

echo ""
echo "===== SUMMARY: HOW RESOURCE REQUESTS/LIMITS AFFECT AUTOSCALING ====="
echo ""
echo "1. CPU Request Impact:"
echo "   - Higher CPU request → Later scaling → Fewer, more utilized pods"
echo "   - Lower CPU request → Earlier scaling → More pods, less utilized"
echo "   - Scaling occurs at: (CPU usage / CPU request) * 100% = HPA threshold %"
echo ""
echo "2. Memory Request Impact:"
echo "   - JVM allocates heap memory upfront"
echo "   - Memory request should be >= JVM heap size to prevent premature scaling"
echo "   - Memory-based scaling can be problematic for JVM applications"
echo "   - Scaling occurs at: (Memory usage / Memory request) * 100% = HPA threshold %"
echo ""
echo "3. Best Practices:"
echo "   - Set CPU request based on actual application needs"
echo "   - For JVM apps, set memory request >= JVM heap size"
echo "   - Consider disabling memory-based scaling for JVM applications"
echo "   - Use explicit JVM heap settings instead of percentage-based allocation"
echo "   - Monitor both resource usage and scaling events to fine-tune settings"
echo ""

echo "Demo completed! Ready for Q&A."
echo "To clean up the entire environment when done, run: kind delete cluster --name autoscale-demo"
