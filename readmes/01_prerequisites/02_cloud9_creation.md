---
title: "步骤二： 创建Cloud9 环境"
weight: 10
---

> 预计花费时间：5分钟
> 目前的REGION 请选择 US-EAST-1

1) 下载并保存Cloud9部署文件到本地电脑, 此文件用于下一步CloudFormation 上传。

```shell
    # 需要替换成为 tee-on-eks/prerequisites/cloud9.yaml
    curl https://raw.githubusercontent.com/aws-samples/aws-nitro-enclaves-workshop/main/resources/templates/cloud9.yaml -o cloud9.yaml
    
    # 若没有命令行，则可以在浏览器输入以下地址并手动复制，保存到本地 cloud9.yaml文件
    https://raw.githubusercontent.com/aws-samples/aws-nitro-enclaves-workshop/main/resources/templates/cloud9.yaml
```

2) 浏览器打开AWS Console, 定位到CloudFormation <br/>

```yaml
    https://console.aws.amazon.com/cloudformation/home#/stacks/create/template
```

3) 点击 "Create Stack", 并按下图上传步骤1下载的cloud9.yaml <br/>
   ![Create](/static/prerequisite-step-2-cloudformation.png)

4) 输入 Stack Name(如 Industry-Tee-Solution-Workshop)；EBSVolume 默认80Gi（不需要修改) <br/>
   ![Create](/static/prerequisite-step-2-cloudformation-input.png)

5) 直接点击"下一步" (Next) <br/>
   ![img.png](/static/prerequisite-step-2-cloudformation-input-2.png)

6) 勾选底部3个选项，直接创建堆栈`Create Stack`. <br/>
   ![img.png](/static/prerequisite-step-2-cloudformation-input-3.png)

此时Cloud9环境处于创建状态，请进行进入下一步。