#!/usr/bin/env python3

from aws_cdk import App, Stack, Environment, CfnOutput, RemovalPolicy, Fn, CfnResource
from aws_cdk import (
    aws_ec2 as ec2,
)

from constructs import Construct

class IRSAStack(Stack):
    
    def __init__(self, scope: Construct, id: str, eks_cluster: CfnResource, namespace: str, ksa: str, iam_role_arn: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        
        ns_yaml = {
            "apiVersion": "v1",
            "kind": "Namespace",
            "metadata": { 
                "name": namespace, 
                "labels": {
                    "pod-security.kubernetes.io/audit": "privileged",
                    "pod-security.kubernetes.io/enforce": "privileged",
                    "pod-security.kubernetes.io/warn": "privileged"
                }
            }
        }
        
        ksa_yaml = {
            "apiVersion": "v1",
            "kind": "ServiceAccount",
            "metadata": {
                "name": ksa,
                "namespace": namespace,
                "annotations": {
                    "eks.amazonaws.com/sts-regional-endpoints": "true",
                    "eks.amazonaws.com/role-arn": iam_role_arn
                }
            }
        }
        
        namespace = eks_cluster.add_manifest("ns", ns_yaml)
        ksa = eks_cluster.add_manifest("ksa", ksa_yaml)
        
        ksa.node.add_dependency(namespace)