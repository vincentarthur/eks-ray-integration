#!/bin/bash

export CLUSTER_NAME=$(cat cdk.json | grep "eks_cluster_name" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")
export CLUSTER_REGION=$(cat cdk.json | grep "REGION" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")

cd ./stacks/kubeflow-manifests
# pip install -r tests/e2e/requirements.txt
# make install-yq
# make install-kustomize
# make install-helm
make deploy-kubeflow INSTALLATION_OPTION=kustomize DEPLOYMENT_OPTION=vanilla
