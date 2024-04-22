#!/bin/bash


export STORAGE_DIR="./stacks/kubeflow-manifests/deployments/add-ons/storage/"

export ACCOUNT_ID=$(grep "ACCOUNT_ID" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export CLUSTER_NAME=$(cat cdk.json | grep "eks_cluster_name" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")
export CLUSTER_REGION=$(grep "REGION" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export CLAIM_NAME=$(cat cdk.json | grep "efs_default_claim_name" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")

echo "Start to install EFS..."
export SECURITY_GROUP_TO_CREATE=$CLAIM_NAME

cd stacks/kubeflow-manifests/tests/e2e
python utils/auto-efs-setup.py --region $CLUSTER_REGION \
         --cluster $CLUSTER_NAME \
         --efs_file_system_name $CLAIM_NAME \
         --efs_security_group_name $SECURITY_GROUP_TO_CREATE
         
echo "Patching EFS Storage Class as default SC for EKS..."
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass efs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
echo "Patched."

kubectl get sc


# This part should be moved to user-onboarding
# PVC_NAMESPACE="xxxxxxx"

# yq e '.metadata.namespace = env(PVC_NAMESPACE)' -i $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml
# yq e '.metadata.name = env(CLAIM_NAME)' -i $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml

# kubectl apply -f $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml


########################################################
#
#.   Manual Setup
#
########################################################

# # Install EFS CSI Driver
# kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=tags/v1.7.7"

# kubectl get csidriver

# # Download IAM policy
# curl -o efs-csi-iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.7.7/docs/iam-policy-example.json

# aws iam create-policy \
#     --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
#     --policy-document file://efs-csi-iam-policy.json
    
# eksctl create iamserviceaccount \
#     --name efs-csi-controller-sa \
#     --namespace kube-system \
#     --cluster $CLUSTER_NAME \
#     --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AmazonEKS_EFS_CSI_Driver_Policy \
#     --approve \
#     --override-existing-serviceaccounts \
#     --region $CLUSTER_REGION

# echo "IRSA for EFS CSI Driver has been setup."

# # Describe
# kubectl describe -n kube-system serviceaccount efs-csi-controller-sa

# # Setup Dynamic Provisioning
# file_system_id=$file_system_id yq e '.parameters.fileSystemId = env(file_system_id)' -i $STORAGE_DIR/efs/dynamic-provisioning/sc.yaml

# # Create Storage Class
# kubectl apply -f $STORAGE_DIR/efs/dynamic-provisioning/sc.yaml
# if [[ $? -ne 0 ]];then
#     echo "Unable to create Storage Class."
#     exit 999
# fi

# echo "Created EFS Storage Class."

# # Create PVC - should be moved to user-onboarding
# yq e '.metadata.namespace = env(PVC_NAMESPACE)' -i $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml
# yq e '.metadata.name = env(CLAIM_NAME)' -i $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml

# kubectl apply -f $STORAGE_DIR/efs/dynamic-provisioning/pvc.yaml


