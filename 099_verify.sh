#!/bin/bash

KARPENTER_NAMESPACE="karpenter"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload
                operator: In
                values:
                - gpu
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: workload
                operator: In
                values:
                - gpu
      containers:
        - name: inflate
          image: nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda10.2
          resources:
            limits:
              nvidia.com/gpu: 1 # requesting 1 GPU
      tolerations:
      - key: nvidia.com/gpu
        operator: Exists
        effect: NoSchedule
EOF

kubectl scale deployment inflate --replicas 2
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
