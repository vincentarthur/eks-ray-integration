### Background

This repository focuses on using `Nitro Enclaves` (Trust Execution Environment) of Amazon Web Services to implement
privacy data computing and collaboration.

Below cloud services from Amazon Web Services will be involved:

- Amazon EKS
- AWS Nitro Enclaves
- AWS KMS
- AWS VPC
- IAM
- AWS ECR
- CDK (deployment toolkit)

In this repo, it will be split into below sections:

- Prerequisites
- EKS Deployment
- Hello World App demo
- Nitro Enclave and KMS Integration Demo
- Medical Image Diagnosis Demo
    - Single AWS Account
    - Multiple AWS Account

Please follow below sections to start and experience.

---

### Prerequisites

- [01. Create IAM Role for Workshop Deployment](./readmes/01_prerequisites/01_workshop_deployment_iam_creation.md)
- [02. Cloud9 Environment creation](./readmes/01_prerequisites/02_cloud9_creation.md)
- [03. Cloud9 IAM modification](./readmes/01_prerequisites/03_cloud9_iam_modification.md)
- [04. Cloud9 Environment Setup](./readmes/01_prerequisites/04_cloud9_setup.md)
- [05. Checkout Source Code](./readmes/01_prerequisites/05_download_code.md)

### EKS Preparation

- [01. IRSA Creation](./readmes/02_eks_preparation/01_irsa_creation.md)
- [02. Deployment Configure Update](./readmes/02_eks_preparation/02_config_update.md)
- [03, Deploy EKS](./readmes/02_eks_preparation/03_eks_deploy.md)

### Simple Examples

- [01. Hello World](./readmes/03_simple_examples/01_helloworld.md)
- [02. KMS Integration](./readmes/03_simple_examples/02_kms_integration.md)
- [03. Clean Up](./readmes/03_simple_examples/03_clean_up.md)

### [Single AWS Account] Medical Image Diagnosis

- [01. Base Image Creation](./readmes/04_single_aws_account_medical_image_diagnosis/01_build_base_image.md)
- [02. Create KMS Key for Model](./readmes/04_single_aws_account_medical_image_diagnosis/02_create_model_kms.md)
- [03. Build Server App](./readmes/04_single_aws_account_medical_image_diagnosis/03_build_server_app.md)
- [04. Build Client App](./readmes/04_single_aws_account_medical_image_diagnosis/04_build_client_app.md)
- [05. Manual Trigger](./readmes/04_single_aws_account_medical_image_diagnosis/05_manual_trigger.md)

### [Multiple AWS Accounts] Medical Image Diagnosis

- [01. ECR Replication Setup](./readmes/05_multiple_aws_account_medical_image_diagnosis/01_ecr_replication.md)
- [02. Data Owner Setup IRSA](./readmes/05_multiple_aws_account_medical_image_diagnosis/02_data_owner_create_irsa.md)
- [03. Data Owner Creates Data KMS Key](./readmes/05_multiple_aws_account_medical_image_diagnosis/03_data_owner_create_data_kms_key.md)
- [04. Tech Provider Creates Model KMS Key](./readmes/05_multiple_aws_account_medical_image_diagnosis/04_tech_provider_create_model_kms_key.md)
- [05. Tech Provider Builds Server app](./readmes/05_multiple_aws_account_medical_image_diagnosis/05_tech_provider_create_server_app_image.md)
- [06. Data Owner Updates IAM Policy](./readmes/05_multiple_aws_account_medical_image_diagnosis/06_data_owner_update_iam_policy.md)
- [07. Data Owner Builds Env](./readmes/05_multiple_aws_account_medical_image_diagnosis/07_data_owner_build_env.md)
- [08. Data Owner Builds Apps](./readmes/05_multiple_aws_account_medical_image_diagnosis/08_data_owner_build_apps.md)
- [09. Data Owner Triggers Inference](./readmes/05_multiple_aws_account_medical_image_diagnosis/09_data_owner_inference.md)
- [10. Add PCR0 for Cryptographic Attestation](./readmes/05_multiple_aws_account_medical_image_diagnosis/10_add_pcr0_for_cryptographic_attestation.md)

### [Multiple AWS Accounts] Medical Image Diagnosis - With WebUI

- [01. ECR Replication Setup](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/01_ecr_replication.md)
- [02. Data Owner Setup IRSA](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/02_data_owner_create_irsa.md)
- [03. Data Owner Creates Data KMS Key](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/03_data_owner_create_data_kms_key.md)
- [04. Tech Provider Creates Model KMS Key](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/04_tech_provider_create_model_kms_key.md)
- [05. Tech Provider Builds Server app](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/05_tech_provider_create_server_app_image.md)
- [06. Data Owner Updates IAM Policy](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/06_data_owner_update_iam_policy.md)
- [07. Data Owner Builds Env](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/07_data_owner_build_env.md)
- [08. Data Owner Builds Apps](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/08_data_owner_build_apps.md)
- [09. Data Owner Triggers Inference](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/09_data_owner_inference.md)
- [10. Add PCR0 for Cryptographic Attestation](./readmes/06_multiple_aws_account_medical_image_diagnosis_with_ui/10_add_pcr0_for_cryptographic_attestation.md)

### Summary

- [Summary](./readmes/10_summary/summary.md)
- [FAQ](./readmes/10_summary/faq.md)
- [Cleanup](./readmes/10_summary/cleanup.md)