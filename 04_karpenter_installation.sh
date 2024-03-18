#!/bin/bash

# #################
#  Set Envrionment
# #################
# export KARPENTER_NAMESPACE="kube-system"
export KARPENTER_VERSION="0.35.1"
export K8S_VERSION="1.27"
export AWS_PARTITION="aws" # if you are not using standard partitions, you may need to configure to aws-cn / aws-us-gov
export CLUSTER_NAME=$(cat cdk.json | grep "eks_cluster_name" |perl -p -E "s/(.*): \"//g;s/\",//g;s/\s//g")
export CLUSTER_REGION=$(cat cdk.json | grep "REGION" |perl -p -E "s/(.*): \"//g;s/\",//g;s/\s//g")
export AWS_DEFAULT_REGION=${CLUSTER_REGION}
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT="$(mktemp)"
export ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
export AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
export GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"

# Get Yaml for creating KarpenterNodeRole
YAML='./karpenter/cloudformation.yaml'
aws cloudformation deploy \
--stack-name "Karpenter-${CLUSTER_NAME}" \
--template-file "${YAML}" \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides "ClusterName=${CLUSTER_NAME}"
 
# # Configure Permission for KarpenterNodeRole
eksctl create iamidentitymapping \
--username system:node:{{EC2PrivateDNSName}} \
--cluster "${CLUSTER_NAME}" \
--arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
--group system:bootstrappers \
--group system:nodes
 
# # # Create IAM Role and SA for Karpenter Controller
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} –approve

eksctl create iamserviceaccount \
--cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
--role-name "${CLUSTER_NAME}-karpenter" \
--attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
--role-only \
--approve

# echo "IAM service account has been created."
 
export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"

# # Install Karpenter Helm Chart
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"

helm upgrade --install --namespace karpenter --create-namespace \
karpenter oci://public.ecr.aws/karpenter/karpenter \
--version ${KARPENTER_VERSION} \
--set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=${KARPENTER_IAM_ROLE_ARN}" \
--set settings.clusterName=${CLUSTER_NAME} \
--set settings.clusterEndpoint=${CLUSTER_ENDPOINT} \
--set aws.defaultInstanceProfile=${KARPENTER_IAM_ROLE_ARN##*/} \
--wait
 
echo "Karpetner Helm installed to EKS."


# Install GPU Device Plugin
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.5/nvidia-device-plugin.yml
echo "Installed Nvidia Device Plugin."

# ##Create nodepool for scaling --- Test
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: gpu
spec:
  template:
    metadata:
      labels:
        workload: gpu
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["on-demand"] 
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["g5.xlarge"]
      taints:
        - key: nvidia.com/gpu
          value: "true"
          effect: NoSchedule
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
  # limits:
  #   cpu: 1000
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 10m #720h # 30 * 24h = 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2 # Amazon Linux 2
  detailedMonitoring: true
  role: "KarpenterNodeRole-${CLUSTER_NAME}"
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 50Gi
        volumeType: gp3
        encrypted: true
        deleteOnTermination: true
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/${CLUSTER_NAME}: shared
  securityGroupSelectorTerms:
    - tags:
        aws:eks:cluster-name: ${CLUSTER_NAME}
        kubernetes.io/cluster/${CLUSTER_NAME}: owned  # need to change according to VPC setup
  amiSelectorTerms:
    - id: "${GPU_AMI_ID}" # <- GPU Optimized AMD AMI 
EOF
if [[ $? -ne 0 ]];then
    echo "Error occuried when creating NodePool and EC2Node Class."
    exit 999
else
    echo "Created NodePool and EC2Node Class."
fi 