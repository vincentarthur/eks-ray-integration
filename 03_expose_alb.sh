#!/bin/bash

### Patch "istio-ingressgateway" in kube-system to LoadBalancer
echo "Patching Kubeflow entry point from ClusterIP to LoadBalancer"
kubectl patch svc/istio-ingressgateway -n istio-system  -p '{"spec":{"type": "LoadBalancer"}}'
alb=$(kubectl get svc/istio-ingressgateway -n istio-system --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Creating..."
sleep 1m
echo "Patched to Loadbalancer. Please access Kubeflow via - http://${alb}"