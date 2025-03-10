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
  open http://localhost:3000
else
  xdg-open http://localhost:3000 &> /dev/null || echo "Please open http://localhost:3000 in your browser."
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
echo "- JVM heap usage mostly stable despite load (good!)"
echo "- CPU usage directly correlates with request throughput"
echo "- Garbage collection patterns during high load"
echo ""

read -p "Press ENTER to show common mistakes (memory-based scaling)."
kubectl delete -f k8s/hpa-demo.yaml
kubectl apply -f k8s/hpa-mistake-memory.yaml
echo "Switched to memory-based scaling. Observe how it doesn't scale properly."

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
