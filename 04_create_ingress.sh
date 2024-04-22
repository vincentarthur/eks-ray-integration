#!/bin/bash

cd stacks/kubeflow-manifests
kustomize build awsconfigs/common/istio-ingress/overlays/https | kubectl apply -f -

# Set the ingress name
INGRESS_NAME="istio-ingress"

# Set the namespace (if applicable)
NAMESPACE="istio-system"

# Set the output format for kubectl
OUTPUT_FORMAT="{range .items[?(.metadata.name==\"$INGRESS_NAME\")]}{@.status.loadBalancer.ingress[0].hostname}{end}"

# Function to get the ingress address
get_ingress_address() {
    INGRESS_ADDRESS=$(kubectl get ingress -n "$NAMESPACE" -o jsonpath="$OUTPUT_FORMAT" 2>/dev/null)
    if [ -z "$INGRESS_ADDRESS" ]; then
        echo "Ingress address is pending..."
    else
        echo "Ingress address: $INGRESS_ADDRESS"
    fi
}

# Keep querying the ingress address until it's not null
while true; do
    get_ingress_address
    if [ -n "$INGRESS_ADDRESS" ]; then
        break
    fi
    sleep 10
done

echo "Ingress address: $INGRESS_ADDRESS"