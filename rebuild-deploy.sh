#!/bin/bash
# rebuild-deploy.sh
# Script to rebuild the Java application, create a new Docker image, and redeploy to the kind cluster

set -e

echo "==== Rebuilding and Redeploying Autoscaling Demo ===="

# Step 1: Build Docker image (using multi-stage build that compiles the application)
echo "Building Docker image..."
docker build -t autoscale-demo:latest .

# Step 2: Load image into kind cluster
echo "Loading image into kind cluster..."
kind load docker-image autoscale-demo:latest --name autoscale-demo

# Step 3: Restart the deployment to pick up the new image
echo "Restarting deployment to apply changes..."
kubectl rollout restart deployment/autoscale-demo

# Step 4: Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/autoscale-demo

echo ""
echo "Rebuild and redeploy completed successfully!"
echo "Your changes are now live in the cluster."
echo ""
echo "Access the application at: http://localhost:8080"
echo ""
