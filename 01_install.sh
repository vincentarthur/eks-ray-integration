#!/bin/bash
set -e

pip3 install -r requirements.txt
export ACCOUNT_ID=$(grep "ACCOUNT_ID" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export CLUSTER_NAME=$(cat cdk.json | grep "eks_cluster_name" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")
export AWS_REGION=$(grep "REGION" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export AWS_DEFAULT_REGION=$(grep "REGION" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")

cdk bootstrap "aws://${ACCOUNT_ID}/${AWS_REGION}"

cdk synth

cdk deploy --all --require-approval never

# Install EBS Addon
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster ${CLUSTER_NAME} \
    --region ${AWS_REGION} \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve

eksctl create addon --name aws-ebs-csi-driver --cluster ${CLUSTER_NAME} --service-account-role-arn arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole --force
