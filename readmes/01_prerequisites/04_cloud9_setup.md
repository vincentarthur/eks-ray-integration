---
title: "步骤四： 登陆和设置Cloud9 环境"
weight: 10
---

1. 打开以下链接:

```
https://us-east-1.console.aws.amazon.com/cloud9control/home?region=us-east-1#/
```

2. 点击步骤二创建的Cloud9 环境的 `Open` 按钮打开 <br /><br />
   ![img.png](/static/prerequisite-step-4-cloud9-setup-1.png)<br /><br />

3. 点击右上方齿轮⚙️ <br /><br />
   ![img.png](/static/prerequisite-step-4-cloud9-setup-2.png)<br /><br />

4. 选择 `AWS Settings`- `Credentials`-`disable AWS Managed temporarily credentials`,如下图: <br /><br />
   ![img.png](/static/prerequisite-step-4-cloud9-setup-3.png)<br /><br />

5. 打开terminal 并运行以下命令安装`nitro-cli`。<br/><br />

```shell
    sudo amazon-linux-extras install aws-nitro-enclaves-cli -y
    sudo yum install aws-nitro-enclaves-cli-devel jq -y
    sudo usermod -aG ne ec2-user
    sudo usermod -aG docker ec2-user
    sudo systemctl start docker && sudo systemctl enable docker
    
    nitro-cli --version
    
    sudo growpart /dev/nvme0n1 1
    sudo xfs_growfs -d /
    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    echo "alias aws='/usr/local/bin/aws'" >> ~/.bashrc
    source ~/.bashrc
```

6. 安装完成后，重新开启新的 terminal激活Docker在当前账户使用。
