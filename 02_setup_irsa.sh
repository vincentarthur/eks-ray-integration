#!/bin/bash

if [[ $# -lt 1 ]];then
  echo "Missing parameters. Expect [cluster_name]"
  echo "[Example] bash 02_setup_irsa.sh cluster-eks_enclaves"
  exit 999
fi

CLUSTER_NAME=$1
ACCOUNT_ID=$(aws sts get-caller-identity | grep "Account" |perl -p -E "s/(.*): \"//g;s/\",//g;s/\s//g")
REGION=$(cat cdk.json | grep "REGION" |perl -p -E "s/(.*): \"//g;s/\",//g;s/\s//g")
POLICY_NAME="privacy-computing-eks-irsa-policy"
IAM_ROLE_NAME=$(cat cdk.json | grep "enclaves_iam_role" |perl -p -E "s/(.*): \"//g;s/\"//g;s/,$//g")
NAMESPACE=$(cat cdk.json | grep "enclaves_namespace" |perl -p -E "s/(.*): \"//g;s/\"//g;s/,$//g")
KSA=$(cat cdk.json | grep "enclaves_k8s_service_account" |perl -p -E "s/(.*): \"//g;s/\"//g;s/,$//g")

policy_arn="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
iam_role_arn="arn:aws:iam::${ACCOUNT_ID}:role/${IAM_ROLE_NAME}"

echo "Expected policy ARN: ${policy_arn}."
echo "Expected IAM Role ARN: ${iam_role_arn}."

# Verify if iam exists
aws iam get-policy --policy-arn "${policy_arn}" > /dev/null

# create iam policy if not exists
if [[ $? -ne 0 ]];then
    echo "Policy not found. Creating..."
    aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://stacks/manifest/iam_policy_for_ksa.json
    echo "Policy created."
fi

# Get OIDC Provider (via awscli or from CFNout of cdk)
oidc_provider=$(aws eks describe-cluster --name ${CLUSTER_NAME} --region ${REGION} --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
echo "OIDC provider: ${oidc_provider}."

cat > ./stacks/manifest/trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/$oidc_provider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$oidc_provider:aud": "sts.amazonaws.com",
          "$oidc_provider:sub": "system:serviceaccount:$NAMESPACE:$KSA"
        }
      }
    }
  ]
}
EOF

# Create role if not exist
aws iam get-role --role-name ${IAM_ROLE_NAME} > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "IAM Role not found. Creating..."
    aws iam create-role --role-name ${IAM_ROLE_NAME} --assume-role-policy-document file://stacks/manifest/trust-relationship.json --description "IRSA for FL"
    echo "IAM Role [${IAM_ROLE_NAME}] does not exist, created."
else
    echo "IAM Role found, updating Assume-role-policy..."
    aws iam update-assume-role-policy --role-name ${IAM_ROLE_NAME} --policy-document file://stacks/manifest/trust-relationship.json
    echo "Assume-role-policy updated."
fi

# Attach policy
echo "Attaching policy to IAM Role[${IAM_ROLE_NAME}].."
aws iam attach-role-policy --role-name ${IAM_ROLE_NAME} --policy-arn=${policy_arn}
echo "Attached policy. And KSA annotation has been completed in EKS provision stage (IRSA_Stack)."