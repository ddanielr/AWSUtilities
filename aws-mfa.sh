#!/bin/bash
# This script allows you to just pass in the MFA token code for a virtual MFA device.
# jq must be installed along with awscli"
set -e 

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -p|--profile)
    AWS_PROFILE="$2"
    shift # past argument
    ;;
    -t|--token)
    MFA_TOKEN="$2"
    shift # past argument
    ;;
    *)
          # unknown option
    ;;
esac
shift 
done

AWS_CLI=`which aws`

if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
else
  echo "Using AWS CLI found at $AWS_CLI"
fi

if [ -z ${AWS_PROFILE+x} ]; then
     profiles=$(cat ~/.aws/config | grep "\[" | awk '{print substr($0, 10, length(substr($0,10))-1)}' | sed -e 's/^$/default/g')
     echo "Select AWS Profile"
     echo "$profiles" 
     read account
     for profile in $profiles; do
        if [[ $account == $profile ]]; then
         AWS_PROFILE=$profile
        fi
     done
fi
MFA=$(echo "aws iam list-mfa-devices --profile $AWS_PROFILE | jq -r .MFADevices[0].SerialNumber" | bash ) 

if [ -z ${MFA_TOKEN+x} ]; then
     echo "Enter the MFA Token Code for the AWS profile:  $AWS_PROFILE"
     read MFA_TOKEN
fi

echo "AWS PROFILE: $AWS_PROFILE"
echo "MFA ARN: $MFA"
echo "MFA Token Code: $MFA_TOKEN"

echo "aws --profile $AWS_PROFILE sts get-session-token --serial-number $MFA --token-code $MFA_TOKEN --output text" | bash | awk '{printf("export AWS_ACCESS_KEY_ID=\"%s\"\nexport AWS_SECRET_ACCESS_KEY=\"%s\"\nexport AWS_SESSION_TOKEN=\"%s\"\n",$2,$4,$5)}' | bash

echo "MFA keys have been exported to your environment"
env | grep AWS
