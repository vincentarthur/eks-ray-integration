
from aws_cdk import App, Stack, Environment, CfnOutput, RemovalPolicy, Fn
from aws_cdk import (
    aws_ec2 as ec2,
)

from constructs import Construct

class RayNodeLaunchStack(Stack):
    
    def __init__(self, scope: Construct, id: str, disk_size: int, ebs_iops: int, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        self.disk_size = disk_size
        self.ebs_iops  = ebs_iops 
        self._create_ec2_launch_template()
    
    def _create_ec2_launch_template(self):
        
        # Create LaunchTemplate
        self.lt = ec2.CfnLaunchTemplate(self, "LaunchTemplate",
            launch_template_name="EKS_Ray_NodeGroup_Launch_Template-0",
            launch_template_data=ec2.CfnLaunchTemplate.LaunchTemplateDataProperty(
                instance_type=self.node.try_get_context("ray_node_machine_type"),
                enclave_options=ec2.CfnLaunchTemplate.EnclaveOptionsProperty(
                    enabled=True
                ), # enable Enclave
                block_device_mappings = [ec2.CfnLaunchTemplate.BlockDeviceMappingProperty(
                        device_name   = "/dev/xvda",
                            ebs       = ec2.CfnLaunchTemplate.EbsProperty(
                            delete_on_termination = True,
                            encrypted             = False, # //TODO - enable for KMS
                            # kms_key_id="kmsKeyId",       # //TODO - enable for KMS
                            iops                  = self.ebs_iops,
                            volume_size           = self.disk_size,
                            volume_type           = "io2"
                        )
                )],
                metadata_options=ec2.CfnLaunchTemplate.MetadataOptionsProperty(
                    http_put_response_hop_limit=1, # block instance metadata access for IRSA 
                    http_tokens="required"
                )
            )
        )
        
        CfnOutput(
                self, "RayNodeLaunchTemplate",
                value=self.lt.ref,
                description="Ray Node Launch Template",
                export_name="RayNodeLaunchTemplate"
            )