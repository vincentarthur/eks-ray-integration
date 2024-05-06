### Background

This repository focuses on utilizing Amazon EKS, Amazon EFS, Ray.IO and Kubeflow to build a Quantitative Investment Research Platform.
Along with KeyCloak as authentication framework.

Below cloud services from Amazon Web Services will be involved:

- Amazon EKS
- AWS KMS
- AWS VPC
- IAM
- AWS ECR
- CDK (deployment toolkit)
- Amazon EFS

---

### Prerequisites
Configure `cdk.json` with changing below items:
- ACCOUNT_ID
- REGION
- "eks_cluster_name" (if needed)
- "eks_default_node_role_managed_policies" (verify if addtional permission should be added)
- "enable_user_irsa": Enable IRSA or not (IRSA = IAM role for Service Account, allowing K8s service account to act as IAM role)
- "user_irsa_iam_role": IAM Role name for IRSA


### Installation Step1
1. Install EKS
```
   bash 01_install.sh
```

2. Install Kubeflow
   Before provisioning kubeflow, you will need to update the Certificate ARN (Amazon Certificate Manager, ACM) under `stacks/kubeflow-manifests/awsconfigs/common/istio-ingress/overlayes/https/params.env`
   This ACM can be imported from your customized cert (i.e. Letsencrypt) or Amazon issued cert.
  ```
   # ARN of an ACM certificate to configure in ALB's HTTPS listener rule
   certArn=
  ```

```
   bash 02_steup_kubeflow.sh
```

3. Install Karpenter
   This step aims to setup Karpenter to automatically handle resource provisioning, like GPU resources
```
   bash 04_karpenter_installation.sh
```

4. Create Ingress
```
   bash 04_create_ingress.sh
```

5. Setup EFS
```
   bash 05_efs_setup.sh
```

After setup all fundamental resources. Update OIDC-AuthService to integrate with KeyCloak.
```
# You will need to configure KeyCloak

cd stacks/kubeflow-manifests/upstream/common/oidc-authservice/base

# In "params.env", replace RIGHT Application Load Balancer to proper value
REDIRECT_URL=https:/<ALB_ID>.us-west-2.elb.amazonaws.com/authservice/oidc/callback


# In "params.env", replace <your keycloak url> & <your_realm_id> to proper value
OIDC_PROVIDER=https://<your keycloak url>/realms/<your_realm_id>
OIDC_AUTH_URL=https://<your keycloak url>/realms/<your_realm_id>/protocol/openid-connect/auth

# In "params.env"
OIDC_SCOPES=<Same scope as indicated in KeyCloak>


# In "secret_params.env", update CLIENT_ID & CLIENT_SECRET
CLIENT_ID=<REALM_ID>
CLIENT_SECRET=<REALM_SECRET>

```
Run below command to reactivate
```
    cd stacks/kubeflow-manifests
    kustomize build awsconfigs/common/upstream/common/oidc-authservice/base | kubectl delete -f - 
    kustomize build awsconfigs/common/upstream/common/oidc-authservice/base | kubectl apply -f - 
````


### User Onboarding
This section focuses on individual user setup, including
- Profile & IRSA
- Namespace level persistent volume
- Ray services

```
   cd user-onboarding
   
   bash user-setup.sh <username in email> <namespace>
   
   # Example:
   # bash user-setup.sh user@example.com kubeflow-user-example-com
   # bash user-setup.sh kubeflow-ray-user@example.com kubeflow-ray-user
```


### Simulation
In `examples` folder, there are some sample data of stocks, including date/open/close/high/low/volume.

1. Upload to S3 bucket
```
   # assuming that there is a bucket called quantbacktest-ray-testing-mock
   cd examples/
   aws s3 cp data/ s3://quantbacktest-ray-testing-mock/daily/ --recursive
   
```

2. Update the BUCKET_NAME in notebook to `quantbacktest-ray-testing-mock`
```
   # directly run the notebook
   # result will be uploaded to s3://quantbacktest-ray-testing-mock/result/, in a format: "Result<stock_id>.csv"
```

3. Can validate by getting result file
```
   aws s3 cp s3://quantbacktest-ray-testing-mock/result/Result000001.csv .
```