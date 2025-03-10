#!/bin/bash
# run-demo.sh
# This script helps you run the demo step-by-step

set -e

echo "==== Autoscaling Demo Script ===="
echo ""
echo "This script will guide you through the demo steps."
echo "Press ENTER after each step to continue."
echo ""

read -p "Step 1: Check the current state of the HPA. Press ENTER to run: kubectl get hpa"
kubectl get hpa

read -p "Step 2: Look at current pods. Press ENTER to run: kubectl get pods"
kubectl get pods

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

echo ""
echo "Now we'll start the load test."
echo "This will simulate a gradually increasing load pattern over 6 minutes."
echo ""
read -p "Press ENTER to start the load test."

# Apply the k6 service monitors for Prometheus metrics
kubectl apply -f k8s/k6-service-and-service-monitor.yaml
kubectl apply -f k8s/k6-testrun-service-monitor.yaml

# Start the load test
kubectl apply -f k8s/k6-load-test.yaml
echo "Load test started!"
echo "Metrics will be available in Prometheus under k6_* metrics"

echo ""
echo "Demo Narration Talking Points:"
echo "1. Initial state: Single pod with minimal CPU usage"
echo "2. As load increases, watch CPU utilization rise in Grafana"
echo "3. When CPU passes 70% threshold, HPA will start new pods"
echo "4. Point out stabilization window (30s) before scaling occurs"
echo "5. Watch response times during scaling to see impact"
echo "6. After peak load, observe scale-down behavior"
echo ""
echo "Specific JVM Points to Highlight:"
echo "- JVM heap usage is fixed at 410MB (80% of container memory limit)"
echo "- Using explicit heap settings (-Xms410m -Xmx410m) instead of percentage-based allocation"
echo "- Fixed heap prevents premature scaling with memory-based HPA"
echo "- CPU usage directly correlates with request throughput"
echo "- Garbage collection patterns during high load"
echo ""

read -p "Press ENTER to show common mistakes (memory-based scaling)."
kubectl delete -f k8s/hpa-demo.yaml
kubectl apply -f k8s/hpa-mistake-memory.yaml
echo "Switched to memory-based scaling with both CPU and memory at 80% thresholds."
echo "Key points about memory-based scaling with JVM applications:"
echo "- JVM allocates heap memory upfront based on our explicit settings (-Xms410m)"
echo "- This immediate allocation can trigger memory-based HPA prematurely"
echo "- Company Helm charts often enable both CPU and memory metrics by default"
echo "- Our explicit heap settings (80% of container limit) help mitigate this issue"
echo "- Observe how the application behaves differently with memory metrics enabled"

read -p "Press ENTER to show common mistakes (identical min/max replicas)."
kubectl delete -f k8s/hpa-mistake-memory.yaml
kubectl apply -f k8s/hpa-mistake-threshold.yaml
echo "Switched to improper threshold configuration."

read -p "Press ENTER to restore proper HPA settings."
kubectl delete -f k8s/hpa-mistake-threshold.yaml
kubectl apply -f k8s/hpa-demo.yaml
echo "Restored proper HPA configuration."

read -p "Press ENTER to end the demo and clean up."
kubectl delete -f k8s/k6-load-test.yaml

echo ""
echo "Demo completed! Ready for Q&A."
echo "To clean up the entire environment when done, run: kind delete cluster --name autoscale-demo"
