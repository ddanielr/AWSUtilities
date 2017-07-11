#!/bin/bash
# This script allows you to just pass in the MFA token code for a virtual MFA device.
# jq must be installed along with awscli"
set -e 

while [[ $# -gt 0 ]]
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
    -?|--help|-h)
    echo "Usage: $0 -p [profile] -t [token]";
    echo "options:";
    echo "     -p, --profile = Profile name of matching AWS profile in ~/.aws/config";
    echo "     -t, --token = MFA token string to be passed to aws cli call";
    exit 0
    ;;
esac
shift 
done

AWS_CLI=`which aws`

if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
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

call=$(aws --profile $AWS_PROFILE sts get-session-token --serial-number $MFA --token-code $MFA_TOKEN) 
aws_vars=$( echo $call | jq -r '( .Credentials | ("export AWS_SECRET_ACCESS_KEY=" + .SecretAccessKey)) + "\n" + (.Credentials | ("export AWS_SESSION_TOKEN=" + .SessionToken)) + "\n" + ( .Credentials | ("export AWS_ACCESS_KEY_ID=" + .AccessKeyId))')
echo "$aws_vars"

