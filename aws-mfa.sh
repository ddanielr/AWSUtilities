#!/bin/bash
# This script allows you to just pass in the MFA token code for a virtual MFA device.
# jq must be installed along with awscli"

set -e

AWS_CLI=`which aws`

if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
else
  echo "Using AWS CLI found at $AWS_CLI"
fi

profiles=$(cat ~/.aws/config | grep "\[" | awk '{print substr($0, 10, length(substr($0,10))-1)}' | sed -e 's/^$/default/g')
echo "Select AWS Profile"
echo "$profiles" 
read account
for profile in $profiles; do
    if [[ $account == $profile ]]; then
        AWS_CLI_PROFILE=$profile
    fi
done

ARN_OF_MFA=$(echo "aws iam list-mfa-devices --profile $AWS_CLI_PROFILE | jq -r .MFADevices[0].SerialNumber" | bash ) 

echo "Enter the MFA Token Code for the AWS profile:  $AWS_CLI_PROFILE"
read MFA_TOKEN_CODE

echo "AWS-CLI Profile: $AWS_CLI_PROFILE"
echo "MFA ARN: $ARN_OF_MFA"
echo "MFA Token Code: $MFA_TOKEN_CODE"

echo "aws --profile $AWS_CLI_PROFILE sts get-session-token --serial-number $ARN_OF_MFA --token-code $MFA_TOKEN_CODE --output text" | bash | awk '{printf("export AWS_ACCESS_KEY_ID=\"%s\"\nexport AWS_SECRET_ACCESS_KEY=\"%s\"\nexport AWS_SESSION_TOKEN=\"%s\"\n",$2,$4,$5)}' | bash

echo "MFA keys have been exported to your environment"
env | grep AWS

