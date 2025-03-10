#!/bin/bash
# monitor.sh
# Script to set up monitoring terminals for the autoscaling demo

set -e

echo "==== Setting Up Monitoring for Autoscaling Demo ===="

# Function to check if command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Function to open a new terminal with a command
open_terminal() {
  local cmd="$1"
  local title="$2"
  
  if command_exists osascript; then
    # macOS
    osascript -e "tell application \"Terminal\" to do script \"echo -e '\\033]0;$title\\007' && cd $(pwd) && $cmd\""
  elif command_exists gnome-terminal; then
    # Linux with GNOME
    gnome-terminal -- bash -c "echo -e '\\033]0;$title\\007' && cd $(pwd) && $cmd; exec bash"
  elif command_exists xterm; then
    # Linux with xterm
    xterm -title "$title" -e "cd $(pwd) && $cmd; exec bash" &
  else
    echo "Could not open a new terminal. Please run these commands manually:"
    echo "$cmd"
  fi
}

# Check if kubectl is available
if ! command_exists kubectl; then
  echo "Error: kubectl is not installed. Please install it first."
  exit 1
fi

echo "Opening monitoring terminals..."

# Terminal 1: Watch HPA status
open_terminal "kubectl get hpa -w" "HPA Monitor"

# Terminal 2: Watch pods
open_terminal "kubectl get pods -w" "Pods Monitor"

# Terminal 3: Watch CPU metrics
open_terminal "kubectl top pods --containers -l app=autoscale-demo --watch" "CPU Monitor"

echo ""
echo "Monitoring terminals have been opened."
echo ""
echo "To access the Grafana dashboard:"
if command_exists open; then
  echo "Opening Grafana in your browser..."
  open http://localhost:3000
else
  echo "Visit http://localhost:3000 in your browser"
  echo "Username: admin, Password: admin"
fi
echo ""
echo "Useful commands for monitoring:"
echo "- kubectl logs -f deployment/autoscale-demo    # Follow application logs"
echo "- kubectl describe hpa autoscale-demo          # View detailed HPA status"
echo "- kubectl get events --sort-by=.metadata.creationTimestamp  # View cluster events"
echo ""
