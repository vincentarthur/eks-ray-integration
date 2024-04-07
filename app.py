#!/usr/bin/env python3
import os, yaml, json
from aws_cdk import (
    Environment,
    aws_ec2 as ec2,
    aws_eks as eks,
    aws_iam as iam,
    Fn, App, RemovalPolicy, Stack,
)
from aws_cdk import Aspects

from cdk_nag import AwsSolutionsChecks, NagSuppressions

# For consistency with TypeScript code, `cdk` is the preferred import name for
# the CDK's core module.  The following line also imports it as `core` for use
# with examples from the CDK Developer's Guide, which are in the process of
# being updated to use `cdk`.  You may delete this import if you don't need it.
from stacks.eks_stack import EKSClusterStack
from stacks.ray_launch_template_stack import RayNodeLaunchStack


def _k8s_manifest_yaml_to_json(file_path):
    """
       Simple function to convert yaml to json
    """
    with open(file_path, 'r') as file:
        configuration = yaml.safe_load(file)

        return configuration


############################################################
#
#               Stack start point
#
############################################################
app = App()
account_id = app.node.try_get_context("ACCOUNT_ID")
region = app.node.try_get_context("REGION")

cdk_environment = Environment(
    account=account_id,
    region=region
)
resource_prefix = app.node.try_get_context("eks_cluster_name")

############################################################
## Step 1 - Create Launch Template for Enclave Template
############################################################
ray_node_launch_stack = RayNodeLaunchStack(
    app,
    f'RayNodeLaunchTemplate',
    env=cdk_environment,
    disk_size=app.node.try_get_context("ray_node_disk_size"),
    ebs_iops=app.node.try_get_context("ray_node_ebs_iops")
)

############################################################
## Step 2 - Create EKS cluster
############################################################
eks_stack = EKSClusterStack(
    app,
    f'EKS-Ray',
    env=cdk_environment,
    resource_prefix=resource_prefix,
    ray_node_group_launch_template=ray_node_launch_stack.lt
)

app.synth()
