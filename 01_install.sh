#!/bin/bash
set -e

pip3 install -r requirements.txt
account_id=$(grep "ACCOUNT_ID" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",//g")
aws_region=$(grep "REGION" ./cdk.json | perl -p -E "s/(.*): \"//g;s/\",//g")

cdk bootstrap "aws://${account_id}/${aws_region}"

cdk synth

cdk deploy --all --require-approval never