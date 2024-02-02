---
title: "步骤二: 修改配置"
weight: 10
---

> 预计花费时间：10分钟
> 目前的REGION 请选择 US-EAST-1

为了灵活配置以及隐藏细节内容，本workshop 提供了配置驱动的方式进行包括EKS cluster，Nitro-enclaves等配置项，降低准入门槛。 同时使用CDK (Infrastructure as Code)
来简化开发和提高部署效率。<br/>

所涉及的配置在 ``cdk.json``

```json
{
  "app": "python3 app.py",
  "context": {
    "@aws-cdk/aws-apigateway:usagePlanKeyOrderInsensitiveId": false,
    "@aws-cdk/aws-cloudfront:defaultSecurityPolicyTLSv1.2_2021": false,
    "@aws-cdk/aws-rds:lowercaseDbIdentifier": false,
    "@aws-cdk/core:stackRelativeExports": false,
    "ACCOUNT_ID": "xxxxxxx",
    "REGION": "us-east-1",
    "create_new_cluster_admin_role": "True",
    "existing_admin_role_arn": "",
    "create_new_vpc": "True",
    "vpc_cidr": "10.0.0.0/22",
    "vpc_cidr_mask_public": 26,
    "vpc_cidr_mask_private": 24,
    "existing_vpc_name": "VPC",
    "eks_version": "1.23",
    "eks_deploy_managed_nodegroup": "True",
    "eks_node_quantity": 2,
    "eks_node_max_quantity": 5,
    "eks_node_min_quantity": 1,
    "eks_node_disk_size": 20,
    "eks_node_instance_type": "m5.xlarge,m5a.xlarge",
    "eks_node_ami_version": "1.23.17-20230513",
    "eks_node_spot": "False",
    "create_cluster_exports": "True",
    "deploy_aws_lb_controller": "True",
    "deploy_external_dns": "True",
    "deploy_aws_ebs_csi": "True",
    "deploy_aws_efs_csi": "True",
    "deploy_cluster_autoscaler": "True",
    "deploy_managed_opensearch": "False",
    "enable_enclaves_nodegroup": "True",
    "enable_enclaves_ng_max_instance_count": 6,
    "enclaves_node_label": {
      "aws-nitro-enclaves-k8s-dp": "enabled"
    },
    "enclaves_node_min_capacity": 2,
    "enclaves_node_max_capacity": 10,
    "enclaves_node_iam_role": "eks-nitro-enclaves-nodegroup-iam-role",
    "enclaves_node_disk_size": 50,
    "enclaves_node_machine_type": "r5.2xlarge",
    "enclaves_node_ebs_iops": 500,
    "enclaves_namespace": "fl",
    "enclaves_k8s_service_account": "fl-ksa",
    "enclaves_iam_role": "privacy-computing-eks-irsa-role",
    "arbiter_server_disk_size": 30
  }
}
```

在 Cloud9 环境下，双击打开 `cdk.json` 进行编辑。需要对以下参数进行修改：<br/>

```
    - ACCOUNT_ID         : 修改称为您当前的AWS 账号, 可以通过运行以下命令获得： aws sts get-caller-identity --query "Account" --output text
    - REGION             : us-east-1
    - eks_version        : 默认是1.23, 但由于k8s 版本会迭代，所以请按需修改
    - enclaves_iam_role  : 请填入上一步骤创建的 IRSA role name (默认是privacy-computing-eks-irsa-role）
```

其他参数如`*_disk_size`, `*_min_capacity`,`*_max_capacity` 请按需修改. <br/>

```
注意：
- 默认会创建一个名为 "fl" 的namespace
- 默认会在 "fl" namespace下创建一个名为"fl-ksa" 的k8s service account

如果需要更改名字，请按需修改 `enclaves_namespace` & `enclaves_k8s_service_account`
```
