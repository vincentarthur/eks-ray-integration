#!/bin/bash

##################################################################################################
#
#  This script takes care of all steps and resource creation when a brand-new user onboarding.
#  It includes:
#    1. Kubeflow User Namespace Creation
#    2. Kubeflow User Profile Creation (and IRSA)
#    3. PVC/PV creation in user namespace
#    4. RayCluster Installation in user namespace
#    5. Virtual Service for exposing RayCluster Head node
#    6. Embed RayCluster Virtual Service in Jupyternotebook ENV
#
#
##################################################################################################

export CLUSTER_NAME=$(cat ../cdk.json | grep "eks_cluster_name" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")
export CLUSTER_REGION=$(cat ../cdk.json | grep "REGION" |perl -p -E "s/(.*): \"//g;s/\",?//g;s/\s//g")
export ACCOUNT_ID=$(grep "ACCOUNT_ID" ../cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export ENABLE_USER_IRSA=$(grep "enable_user_irsa" ../cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
export USER_IRSA_ROLE_NAME=$(grep "user_irsa_iam_role" ../cdk.json | perl -p -E "s/(.*): \"//g;s/\",?//g")
# KUBEFLOW_USER_IRSA_ROLE="kubeflow-user-irsa-role"

if [[ $# -le 1 ]];then
  #echo "Required two parameters : User Name (Email) and EFS System ID(fs-xxx). Namespace will be prefix before @ symbal."
  echo "Required two parameters : User Name (Email) and User Namespace."
  echo "For example: user name \"user2@example.com\", the namespace will be user2. Which should align to Keycloak profile."
  exit 999
fi

if [[ ! "$1" =~ "@" ]];then
  echo "Incorrect email format.Please correct EMAIL format."
  exit 999
fi

export PROFILE_USER=$1
export PROFILE_NAMESPACE=$2 #$(echo $PROFILE_USER|cut -d "@" -f 1)
#EFS_SYSTEM_ID=$2

#1. Create User Namespace
echo "#1 - Create user namespace"
echo "PROFILE_NAMESPACE: ${PROFILE_NAMESPACE}"

export OIDC_URL=$(aws eks describe-cluster --region $CLUSTER_REGION --name $CLUSTER_NAME  --query "cluster.identity.oidc.issuer" --output text | cut -c9-)

# if IRSA does not exist, returns NULL(Empty)
if [[ $ENABLE_USER_IRSA == "True" ]]; then
   
    irsa_exists=$(aws iam get-role --role-name ${USER_IRSA_ROLE_NAME} 2>/dev/null)

    if [[ $irsa_exists == "" ]];then
    
        echo "IAM Role does not exist, will create one."
    
        cat <<EOF > trust.json
{
"Version": "2012-10-17",
"Statement": [
    {
    "Effect": "Allow",
    "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${OIDC_URL}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
        "StringEquals": {
        "${OIDC_URL}:aud": "sts.amazonaws.com",
        "${OIDC_URL}:sub": "system:serviceaccount:*:default-editor"
        }
    }
    }
]
}
EOF
    
        # example policy, change accordingly, like EFS
    #     cat <<EOF > s3_policy.json
    # {
    #     "Version": "2012-10-17",
    #     "Statement": [
    #           {
    #         "Effect": "Allow",
    #         "Action": "s3:*",
    #         "Resource": [
    #             "arn:aws:s3:::536704830979-kubeflow-ray-bucket",
    #             "arn:aws:s3:::536704830979-kubeflow-ray-bucket/*"
    #               ]
    #           }
    #      ]
    # }
    # EOF
    
        aws iam create-role --role-name kubeflow-user-irsa-role --assume-role-policy-document file://trust.json 1> /dev/null
        
        if [[ $? -eq 0 ]];then
            echo "IAM Role \"kubeflow-user-irsa-role\" created."
        fi
    
    else
        echo "IAM Role already exists, skip IAM role creation."
    fi
    
    
# 2 Setup IRSA

    echo "2 - Setup IRSA for profile for default-editor"
    cat <<EOF > profile_iam.yaml
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: ${PROFILE_NAMESPACE}
spec:
  owner:
    kind: User
    name: ${PROFILE_USER}
  plugins:
  - kind: AwsIamForServiceAccount
    spec:
      awsIamRole: $(aws iam get-role --role-name kubeflow-user-irsa-role --output text --query 'Role.Arn')
      annotateOnly: true
EOF

    kubectl apply -f profile_iam.yaml
    
    if [[ $? -eq 0 ]];then
        echo "Profile and IRSA setup completed."
    else
        echo "Error happened. Please check, fix and retry."
        exit 999
    fi
else
    echo "Skip IRSA setup for individual user."
    echo "Setup Profile for default-editor"
    cat <<EOF > profile_iam.yaml
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: ${PROFILE_NAMESPACE}
spec:
  owner:
    kind: User
    name: ${PROFILE_USER}
EOF
    kubectl apply -f profile_iam.yaml
fi


######################################################################
#
#   3. Setup PVC for individual namespace
#
######################################################################
## Assume EFS & SC already created, and set SC to default
echo "3 - Install PVC/PV to individual namespace [${PROFILE_NAMESPACE}]"
yq e '.metadata.namespace = env(PROFILE_NAMESPACE)' -i ../stacks/kubeflow-manifests/deployments/add-ons/storage/efs/dynamic-provisioning/pvc.yaml
yq e '.metadata.name = env(PROFILE_NAMESPACE)' -i ../stacks/kubeflow-manifests/deployments/add-ons/storage/efs/dynamic-provisioning/pvc.yaml

kubectl apply -f ../stacks/kubeflow-manifests/deployments/add-ons/storage/efs/dynamic-provisioning/pvc.yaml

if [[ $? -eq 0 ]];then
    echo "Created PVC for Namspace: ${PROFILE_NAMESPACE}."
    kubectl get pvc,pv -n ${PROFILE_NAMESPACE}
fi


echo "4 - Intall RayOperator and KubeRay to individual Namespace [${PROFILE_NAMESPACE}]"
helm install kuberay-operator ../stacks/kuberay/helm-chart/kuberay-operator/ -n ${PROFILE_NAMESPACE}
helm install ray-cluster ../stacks/kuberay/helm-chart/ray-cluster/ -n ${PROFILE_NAMESPACE}
echo "RayOperator and cluster installed to namespace [${PROFILE_NAMESPACE}]"