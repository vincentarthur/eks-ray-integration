---
title: "步骤三: 开始部署"
weight: 10
---

> 预计花费时间：20分钟
> 目前的REGION 请选择 US-EAST-1

1. 打开Cloud9 命令行(如已经打开则跳过)
2. 确认是否已经开启Python 虚拟环境 (命令行前缀有类似`(.venv)`字眼)，若有，则跳过此步骤 <br/>
   a) 如果没有开启，则需要运行以下命令

```shell
source .venv/source/bin
```

3. 运行以下命令来创建AWS资源，同时安装NitroDevicePlugin、IRSA的预设等。此过程需要等待约*20分钟*。 <br/>

```shell
bash 01_install.sh
```

涉及的AWS资源有： <br/>

```yaml
  - 1 VPC (if "create_new_vpc" set to true in cdk.json)
  - 1 EKS cluster
  - 1 default EKS nodegroup
  - 1 NitroEnclaves EKS nodegroup
```

![img.png](/static/workshop-step-3-wip.png)

4. 当看到以下类似信息打印在命令行，则表示部署完成。请复制 `EKS-Enclaves.eksclusterConfigCommandxxx`的值（到.txt)，后续步骤需要*_多次_*使用。 <br/>
   ![image.png](/static/workshop-step-3-deploy-success.png)

5. 进行IRSA在EKS cluster上的配置。

```shell
    bash 02_setup_irsa.sh cluster-eks-enclaves # cluster-eks-enclaves为集群名字，如需修改可在上一步骤中进行
```

![image.png](/static/workshop-step-3-deploy-irsa.png)<br/>

6. 验证EKS and Nitro Enclaves是否部署成功<br/>

```shell
  # 首先在 Cloud9 控制台中输入类似的命令
  # 改命令请参考步骤4 的输出
  ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
  REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region -s)
  
  # 运行eksclusterConfigCommandxxx的值（步骤4）
  aws eks update-kubeconfig --name cluster-eks-enclaves --region ${REGION} --role-arn arn:aws:iam::${ACCOUNT_ID}:role/EKS-Enclaves-ClusterAdminRolexxxx-xxxx

  # 查询所有的节点、pod 以及namespace
  kubectl get nodes,pods,ns -A
```

![Images](/static/workshop-step-3-res-output.png)<br/>