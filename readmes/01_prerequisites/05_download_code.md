---
title: "步骤五： 下载代码"
weight: 10
---

在Cloud9 的命令行中輸入一下命令：

```shell
    git clone https://github.com:vincentarthur/privacy-computing-tee-on-eks.git
```

等待代码下载完成。

接下来进行必要工具的安装和配置。

1. 安装kubectl/eksctl

```shell
   cd privacy-computing-tee-on-eks
   bash utils_scripts/00_install_kubectl_eksctl.sh
```

2. 安装cdk2

```shell
   npm install -g aws-cdk@latest
   
   # 如果上述命令遇到error 请运行一下命令
   npm install -g aws-cdk@latest --force
```

3. 创建并准备python 虚拟环境

```shell
   python3 -m venv .venv
   source .venv/bin/activate
   python3 -m pip install -r requirements.txt
   
   ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
   REGION=$(curl http://169.254.169.254/latest/meta-data/placement/region -s)
   
   # 准备CDK 环境
   ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
   cdk bootstrap aws://${ACCOUNT_ID}/${REGION}
```

准备工作到此完成，接下来可以进行Workshop 的实际操作。