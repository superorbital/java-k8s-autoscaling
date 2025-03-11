#!/bin/bash
# rebuild-deploy-enhanced.sh
# Script to rebuild the Java application, create a new Docker image, and redeploy to the kind cluster
# This enhanced version handles all deployment configurations

set -e

echo "==== Rebuilding and Redeploying Enhanced Autoscaling Demo ===="

# Step 1: Build Docker image (using multi-stage build that compiles the application)
echo "Building Docker image..."
docker build -t autoscale-demo:latest .

# Step 2: Load image into kind cluster
echo "Loading image into kind cluster..."
kind load docker-image autoscale-demo:latest --name autoscale-demo

# Step 3: Check which deployments exist and restart them
echo "Checking for existing deployments..."

# Array of possible deployments
DEPLOYMENTS=(
  "autoscale-demo"
  "autoscale-demo-high-cpu"
  "autoscale-demo-low-cpu"
  "autoscale-demo-memory"
)

# Restart each deployment if it exists
for deployment in "${DEPLOYMENTS[@]}"; do
  if kubectl get deployment $deployment &>/dev/null; then
    echo "Restarting deployment $deployment to apply changes..."
    kubectl rollout restart deployment/$deployment
    
    echo "Waiting for deployment $deployment to be ready..."
    kubectl rollout status deployment/$deployment
  else
    echo "Deployment $deployment not found, skipping..."
  fi
done

# Step 4: Apply any missing deployments if requested
if [[ "$1" == "--apply-all" ]]; then
  echo "Applying all deployment configurations..."
  
  # Apply base deployment if it doesn't exist
  if ! kubectl get deployment autoscale-demo &>/dev/null; then
    echo "Applying base deployment..."
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/hpa-demo.yaml
  fi
  
  # Apply high CPU deployment if it doesn't exist
  if ! kubectl get deployment autoscale-demo-high-cpu &>/dev/null; then
    echo "Applying high CPU deployment..."
    kubectl apply -f k8s/deployment-high-cpu-request.yaml
    kubectl apply -f k8s/hpa-high-cpu-request.yaml
  fi
  
  # Apply low CPU deployment if it doesn't exist
  if ! kubectl get deployment autoscale-demo-low-cpu &>/dev/null; then
    echo "Applying low CPU deployment..."
    kubectl apply -f k8s/deployment-low-cpu-request.yaml
    kubectl apply -f k8s/hpa-low-cpu-request.yaml
  fi
  
  # Apply memory-focused deployment if it doesn't exist
  if ! kubectl get deployment autoscale-demo-memory &>/dev/null; then
    echo "Applying memory-focused deployment..."
    kubectl apply -f k8s/deployment-memory-focus.yaml
    kubectl apply -f k8s/hpa-memory-focus.yaml
  fi
fi

echo ""
echo "Rebuild and redeploy completed successfully!"
echo "Your changes are now live in the cluster."
echo ""
echo "Access the applications at:"
echo "- Base deployment: http://localhost:8080"
echo "- Other deployments are accessible via their ClusterIP services within the cluster"
echo ""
echo "To apply all deployment configurations if they don't exist, run:"
echo "  ./rebuild-deploy-enhanced.sh --apply-all"
echo ""
