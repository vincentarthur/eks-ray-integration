# new branch

from aws_cdk import App, Stack, Environment, CfnOutput, RemovalPolicy, Tags
from aws_cdk import (
    aws_ec2 as ec2,
    aws_eks as eks,
    aws_iam as iam,
)

from constructs import Construct


class EKSClusterStack(Stack):

    def __init__(self,
                 scope: Construct,
                 id: str,
                 resource_prefix: str,
                 enclaves_node_group_launch_template: Construct,
                 **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        self.cluster_name = f"cluster-{resource_prefix}"
        self._create_iam_role()
        self._create_vpc()
        self._create_eks_cluster(resource_prefix, enclaves_node_group_launch_template)

        # Either create a new IAM role to administrate the cluster or create a new one

    def _create_iam_role(self) -> None:
        if self.node.try_get_context("create_new_cluster_admin_role") == "True":
            self.cluster_admin_role = iam.Role(self, "ClusterAdminRole",
                                               assumed_by=iam.CompositePrincipal(
                                                   iam.AccountRootPrincipal(),
                                                   iam.ServicePrincipal(
                                                       "ec2.amazonaws.com")
                                               ))
            cluster_admin_policy_statement_json_1 = {
                "Effect": "Allow",
                "Action": [
                    "eks:DescribeCluster"
                ],
                "Resource": "*"
            }
            self.cluster_admin_role.add_to_principal_policy(
                iam.PolicyStatement.from_json(cluster_admin_policy_statement_json_1))
        else:
            # You'll also need to add a trust relationship to ec2.amazonaws.com to sts:AssumeRole to this as well
            self.cluster_admin_role = iam.Role.from_role_arn(self, "ClusterAdminRole",
                                                             role_arn=self.node.try_get_context(
                                                                 "existing_admin_role_arn")
                                                             )

    def _create_vpc(self) -> None:
        """Deploys a VPC and needed subnets"""
        # Either create a new VPC with the options below OR import an existing one by name
        if self.node.try_get_context("create_new_vpc") == "True":
            self.eks_vpc = ec2.Vpc(
                self, "EKS_Enclaves_VPC",
                # We are choosing to spread our VPC across 3 availability zones
                max_azs=2,
                # cidr=self.node.try_get_context("vpc_cidr"),
                ip_addresses=ec2.IpAddresses.cidr(self.node.try_get_context("vpc_cidr")),
                subnet_configuration=[
                    # 2 x Public Subnets (1 per AZ) with 64 IPs each for our ALBs and NATs
                    ec2.SubnetConfiguration(
                        subnet_type=ec2.SubnetType.PUBLIC,
                        name="Public",
                        cidr_mask=self.node.try_get_context("vpc_cidr_mask_public")
                    ),
                    # 2 x Private Subnets (1 per AZ) with 256 IPs each for our Nodes and Pods
                    ec2.SubnetConfiguration(
                        subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS,
                        name="Private",
                        cidr_mask=self.node.try_get_context("vpc_cidr_mask_private")
                    )
                ]
            )
        else:
            self.eks_vpc = ec2.Vpc.from_lookup(self, 'VPC', vpc_name=self.node.try_get_context("existing_vpc_name"))

        # Add Tags for ALB - "kubernetes.io/cluster/cluster-eks-enclaves: shared"
        # for Public subnets
        [Tags.of(subnet).add(f'kubernetes.io/cluster/{self.cluster_name}', 'shared') for subnet in
         self.eks_vpc.select_subnets(subnet_type=ec2.SubnetType.PUBLIC).subnets]

        # for Private Subnets
        [Tags.of(subnet).add(f'kubernetes.io/cluster/{self.cluster_name}', 'shared') for subnet in
         self.eks_vpc.select_subnets(subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS).subnets]

    def _create_eks_cluster(self, resource_prefix, enclaves_node_group_launch_template) -> None:
        # Create an EKS Cluster
        self.eks_cluster = eks.Cluster(
            self, f'ekscluster',
            cluster_name=self.cluster_name,
            vpc=self.eks_vpc,
            masters_role=self.cluster_admin_role,
            # Make our cluster's control plane accessible only within our private VPC
            # This means that we'll have to ssh to a jumpbox/bastion or set up a VPN to manage it
            endpoint_access=eks.EndpointAccess.PUBLIC_AND_PRIVATE,
            version=eks.KubernetesVersion.of(
                self.node.try_get_context("eks_version")),
            default_capacity=0,

            # """
            #   Create ALB Controller for EKS
            #   Deployment will be placed into kube-system namespace.
            #   Require:
            #   1. Create IRSA (aws-load-balancer-controller) in kube-system namespace
            #   2. Create IAM policy and attach to IRSA
            #   3. Create ALB deployment in kube-system namespace
            # """
            alb_controller=eks.AlbControllerOptions(
                version=eks.AlbControllerVersion.V2_4_1
            )
        )

        """
        Hot Fix - Unable to Properly add "AddTags" permission to IAM role of ALB. So explicitly indicate policy attachmeng
        """
        cfn_alb_role = self.eks_cluster.alb_controller.node.try_find_child("alb-sa").node.try_find_child("Role")
        cfn_alb_role.add_to_policy(
            iam.PolicyStatement(
                actions=["elasticloadbalancing:AddTags"],
                resources=[
                    "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"],
                conditions={
                    "StringEquals": {
                        "elasticloadbalancing:CreateAction": [
                            "CreateTargetGroup",
                            "CreateLoadBalancer"
                        ]
                    },
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            )
        )

        # Add a Managed Node Group
        if self.node.try_get_context("eks_deploy_managed_nodegroup") == "True":
            # If we enabled spot then use that
            if self.node.try_get_context("eks_node_spot") == "True":
                node_capacity_type = eks.CapacityType.SPOT
            # Otherwise give us OnDemand
            else:
                node_capacity_type = eks.CapacityType.ON_DEMAND

            # Parse the instance types as comma seperated list turn into instance_types[]
            instance_types_context = self.node.try_get_context(
                "eks_node_instance_type").split(",")
            instance_types = []
            for value in instance_types_context:
                instance_type = ec2.InstanceType(value)
                instance_types.append(instance_type)

            eks_node_group = self.eks_cluster.add_nodegroup_capacity(
                "cluster-default-ng",
                capacity_type=node_capacity_type,
                desired_size=self.node.try_get_context("eks_node_quantity"),
                min_size=self.node.try_get_context("eks_node_min_quantity"),
                max_size=self.node.try_get_context("eks_node_max_quantity"),
                disk_size=self.node.try_get_context("eks_node_disk_size"),
                # The default in CDK is to force upgrades through even if they violate - it is safer to not do that
                force_update=False,
                instance_types=instance_types,
                release_version=self.node.try_get_context(
                    "eks_node_ami_version")
            )
            # eks_node_group.role.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore"))

            if self.node.try_get_context("enable_enclaves_nodegroup") == "True":
                # Create Enclaves NodeGroup
                enclaves_node_group = self.eks_cluster.add_nodegroup_capacity(
                    'extra-ng',
                    nodegroup_name='EnclavesNodeGroup',
                    labels=self.node.try_get_context("enclaves_node_label"),
                    # label nodes for NodeAffinity & AntiNodeAffinity
                    launch_template_spec=eks.LaunchTemplateSpec(
                        id=enclaves_node_group_launch_template.ref,
                        version=enclaves_node_group_launch_template.attr_latest_version_number,
                    ),
                    min_size=self.node.try_get_context("enclaves_node_min_capacity"),
                    max_size=self.node.try_get_context("enclaves_node_max_capacity"),
                )

        if self.node.try_get_context("create_cluster_exports") == "True":
            # Output the EKS Cluster Name and Export it
            CfnOutput(
                self, "EKSClusterName",
                value=self.eks_cluster.cluster_name,
                description="The name of the EKS Cluster",
                export_name="EKSClusterName"
            )
            # Output the EKS Cluster OIDC Issuer and Export it
            CfnOutput(
                self, "EKSClusterOIDCProviderARN",
                value=self.eks_cluster.open_id_connect_provider.open_id_connect_provider_arn,
                description="The EKS Cluster's OIDC Provider ARN",
                export_name="EKSClusterOIDCProviderARN"
            )
            # Output the EKS Cluster kubectl Role ARN
            CfnOutput(
                self, "EKSClusterKubectlRoleARN",
                value=self.eks_cluster.kubectl_role.role_arn,
                description="The EKS Cluster's kubectl Role ARN",
                export_name="EKSClusterKubectlRoleARN"
            )
            # Output the EKS Cluster SG ID
            CfnOutput(
                self, "EKSSGID",
                value=self.eks_cluster.kubectl_security_group.security_group_id,
                description="The EKS Cluster's kubectl SG ID",
                export_name="EKSSGID"
            )
        self.security_grp = self.eks_cluster.kubectl_security_group
