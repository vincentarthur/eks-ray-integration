---
title: "步骤一: 创建一个用于部署Workshop 的IAM Role"
weight: 10
---

打开 AWS Console IAM 页面 - <br/>

```
https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/roles,
```

点击右上角"Create Role". <br/>
![Create Role](/static/prerequisite-step-1-iam-role.png)

然后如下图：

1) 选择`AWS Service` 作为 *"Trusted Entity Type"*
2) 选择`EC2`作为 *"Common Use Cases"*.
3) 点击 `Next`.

![Trusted Entity](/static/prerequisite-step-1-iam-role-2.png)

在 "Add Permissions"的搜索栏中输入 "AdministratorAccess" 并回车，勾选，点击`Next`.

![Permission](/static/prerequisite-step-1-iam-role-3.png)

在"Role Name"中输入角色名字（如 industry-tee-solution-workshop-deployment-role)后，点击 `Create Role` 创建角色.
