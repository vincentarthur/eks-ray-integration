#!/bin/bash

### Patch "istio-ingressgateway" in kube-system to LoadBalancer
echo "Patching Kubeflow entry point from ClusterIP to LoadBalancer"
kubectl patch svc/istio-ingressgateway -n istio-system  -p '{"spec":{"type": "LoadBalancer"}}'

# Set the ingress name
SVC_NAME="istio-ingressgateway"

# Set the namespace (if applicable)
NAMESPACE="istio-system"

# Set the output format for kubectl
OUTPUT_FORMAT='{.status.loadBalancer.ingress[0].hostname}'

# Function to get the ingress address
get_alb_address() {
    ALB_ADDRESS=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath="$OUTPUT_FORMAT" 2>/dev/null)
    if [ -z "ALB_ADDRESS" ]; then
        echo "Application Loadbalancer address is pending..."
    else
        echo "Application Loadbalancer: $ALB_ADDRESS"
    fi
}

# Keep querying the ingress address until it's not null
while true; do
    get_alb_address
    if [ -n "ALB_ADDRESS" ]; then
        break
    fi
    sleep 10
done
