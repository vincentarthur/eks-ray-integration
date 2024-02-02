---
title: "步骤三： 更改Cloud9 EC2 的IAM role"
weight: 10
---

这一步骤的目的在于将步骤一创建的IAM Role 配置到步骤二创建的Cloud9 环境中(EC2).

1) 首先进入EC2 console（可能需要等待1-2分钟才能看到运行中的实例)<br/>

```
https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:instanceState=running
```

2) 选择并勾选 `aws-cloud9-<cloud9 环境名字>` 的EC2 <br/>
   ![img.png](/static/prerequisite-step-3-cloud9-iam-1.png)

3) 选择右上角 "Actions" -- "Security" -- "Modify IAM Role"<br/>
   ![img.png](/static/prerequisite-step-3-cloud9-iam-2.png)

4) 选择步骤一创建的IAM Role(如 industry-tee-solution-workshop-deployment-role)，并点击 `Update IAM Role`.
