#!/bin/bash

ENCLAVES_GROUP_NAME="eksclusterNodegroupextrang6-W4fv05VCj0vc"

kubectl get nodes -o json -l eks.amazonaws.com/nodegroup=${ENCLAVES_GROUP_NAME} | jq -r '.items[].metadata.name'