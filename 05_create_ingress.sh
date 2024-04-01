#!/bin/bash

cd stacks/kubeflow-manifest
kustomize build awsconfigs/common/istio-ingress/overlays/https | kubectl apply -f -

kubectl get ingress -A