#!/bin/bash
# setup-demo.sh
set -e

echo "Setting up autoscaling demo environment with monitoring..."

# Step 1: Check prerequisites
if ! command -v kind &> /dev/null; then
    echo "Error: kind is not installed. Please install it first."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install it first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install it first."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed. Please install it first."
    exit 1
fi

# Step 2: Create kind cluster with port mappings
echo "Creating kind cluster..."
cat << EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080  # App
    hostPort: 8080
    protocol: TCP
  - containerPort: 30090  # Prometheus
    hostPort: 9090
    protocol: TCP
  - containerPort: 30300  # Grafana
    hostPort: 3000
    protocol: TCP
  kubeadmConfigPatches:
  - |
    kind: KubeletConfiguration
    evictionHard:
      memory.available: "200Mi"
EOF

kind create cluster --name autoscale-demo --config kind-config.yaml

# Step 3: Deploy metrics-server for HPA
echo "Deploying metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch metrics-server to work with kind (insecure TLS)
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for metrics-server to be ready
echo "Waiting for metrics-server to be ready..."
kubectl -n kube-system wait --for=condition=available --timeout=60s deployment/metrics-server

# Step 4: Install Prometheus and Grafana using Helm
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Installing Prometheus and Grafana..."
helm install monitoring prometheus-community/kube-prometheus-stack \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30090 \
  --set prometheus.prometheusSpec.enableRemoteWriteReceiver=true \
  --set prometheus.prometheusSpec.remoteWriteDashboards=true \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30300 \
  --set grafana.adminPassword=admin

# Wait for Prometheus and Grafana to be ready
echo "Waiting for monitoring stack to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/monitoring-kube-prometheus-operator
kubectl wait --for=condition=available --timeout=120s deployment/monitoring-grafana

# Apply Grafana dashboards
echo "Applying Grafana dashboards..."
kubectl apply -f 'k8s/grafana-dashboard-*.yaml'

# Step 5: Install k6 operator for Kubernetes-native load testing
echo "Installing k6 operator..."
kubectl apply -f https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml

# Apply k6 service monitors for Prometheus metrics
echo "Setting up k6 service monitors for Prometheus..."
kubectl apply -f k8s/k6-service-and-service-monitor.yaml
kubectl apply -f k8s/k6-testrun-service-monitor.yaml

# Step 6: Build and load the application image
echo "Building application..."
mvn wrapper:wrapper
./mvnw clean package

echo "Building Docker image..."
echo "Note: The Dockerfile configures JVM with explicit heap settings (-Xms410m -Xmx410m)"
echo "      This is 80% of the container memory limit (512Mi) to prevent premature scaling with memory-based HPA"
docker build -t autoscale-demo:latest .

echo "Loading image into kind cluster..."
kind load docker-image autoscale-demo:latest --name autoscale-demo

# Step 7: Deploy application
echo "Deploying application to Kubernetes..."
kubectl apply -f k8s/deployment.yaml

# Create NodePort service for easy access
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: autoscale-demo-nodeport
spec:
  selector:
    app: autoscale-demo
  ports:
  - port: 8080
    nodePort: 30080
  type: NodePort
EOF

# Wait for deployment to be ready
echo "Waiting for application deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/autoscale-demo

# Step 8: Apply HPA
echo "Applying HPA configuration..."
kubectl apply -f k8s/hpa-demo.yaml

echo "Setup completed! Your autoscaling demo environment is ready."
echo ""
echo "Access points:"
echo "- Application: http://localhost:8080"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000 (username: admin, password: admin)"
echo ""
echo "To start the load test:"
echo "kubectl apply -f k8s/k6-load-test.yaml"
echo ""
echo "To monitor the HPA:"
echo "kubectl get hpa -w"
echo ""
